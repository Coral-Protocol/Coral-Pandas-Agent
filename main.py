import urllib.parse
from dotenv import load_dotenv
import os, json, asyncio, traceback
import pandas as pd
from langchain.chat_models import init_chat_model
from langchain.prompts import ChatPromptTemplate
from langchain_mcp_adapters.client import MultiServerMCPClient
from langchain.agents import create_tool_calling_agent, AgentExecutor
from langchain_experimental.agents.agent_toolkits import create_pandas_dataframe_agent
from langchain.agents.agent_types import AgentType
from langchain_core.tools import StructuredTool
import logging
import traceback

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Load environment variables
load_dotenv()

base_url = os.getenv("CORAL_SSE_URL")
agentID = os.getenv("CORAL_AGENT_ID")

coral_params = {
    "agentId": agentID,
    "agentDescription": "An agent that interacts with other agents and performs data analysis on pandas DataFrames to fulfill user requests."
}

query_string = urllib.parse.urlencode(coral_params)

from pydantic import BaseModel, Field
class AgentArgs(BaseModel):
    file_path: str = Field(description="Path to the CSV file to be analyzed")
    prompt: str = Field(description="Prompt describing the analysis to be performed on the DataFrame")


def get_tools_description(tools):
    def serialize_schema(tool):
        if isinstance(tool.args_schema, type) and issubclass(tool.args_schema, BaseModel):
            return json.dumps(tool.args_schema.model_json_schema()).replace('{', '{{').replace('}', '}}')
        elif isinstance(tool.args_schema, dict):
            return json.dumps(tool.args_schema).replace('{', '{{').replace('}', '}}')
        else:
            return "{}"

    return "\n".join(
        f"Tool: {tool.name}, Schema: {serialize_schema(tool)}"
        for tool in tools
    )


async def create_pandas_agent(file_path: str, prompt: str):
    try:
        df = pd.read_csv(file_path)
        agent = create_pandas_dataframe_agent(
            llm=init_chat_model(
                model=os.getenv("MODEL_NAME"),
                model_provider=os.getenv("MODEL_PROVIDER"),
                api_key=os.getenv("API_KEY"),
                temperature=os.getenv("MODEL_TEMPERATURE", 0.3),
                max_tokens=os.getenv("MODEL_TOKEN", 8000),
            ),
            df=df,
            verbose=True,
            agent_type=AgentType.OPENAI_FUNCTIONS,
            allow_dangerous_code=True,
        )
        result = await agent.ainvoke(prompt)
        return result
    except Exception:
        return "Traceback:\n" + traceback.format_exc()

async def create_agent(coral_tools, agent_tools):
    coral_tools_description = get_tools_description(coral_tools)
    agent_tools_description = get_tools_description(agent_tools)
    combined_tools = coral_tools + agent_tools

    prompt = ChatPromptTemplate.from_messages([
        (
            "system",
            f"""You are an agent interacting with tools from Coral Server and capable of analyzing pandas DataFrames. Your task is to perform instructions from other agents, including data analysis tasks on provided datasets. 
            Follow these steps in order:
            1. Call wait_for_mentions from coral tools (timeoutMs: 30000) to receive mentions from other agents.
            2. When you receive a mention, keep the thread ID and the sender ID.
            3. Take 2 seconds to think about the content (instruction) of the message and check the available tools.
            4. If the instruction involves data analysis and includes a file_path (e.g., 'https://raw.githubusercontent.com/pandas-dev/pandas/main/doc/data/titanic.csv'), attempt to load it as a pandas DataFrame using pd.read_csv.
            5. If the file_path cannot be loaded as a valid DataFrame (e.g., due to invalid URL, file format, or other errors), use `send_message` from coral tools to send a message in the same thread ID to the sender ID with content: "Error: Invalid DataFrame source at <file_path>", replacing <file_path> with the actual file_path provided in the mention.
            6. If the file_path is valid and loads a DataFrame, use the pandas_dataframe_analysis tool to process the instruction.
            7. Check the tool schema and make a plan in steps for the task you want to perform.
            8. Only call the tools you need to perform each step of the plan to complete the instruction in the content.
            9. Take 3 seconds and think about the content to ensure you have executed the instruction to the best of your ability and the tools. Make this your response as "answer".
            10. Use `send_message` from coral tools to send a message in the same thread ID to the sender ID you received the mention from, with content: "answer".
            11. If any error occurs during execution (other than an invalid DataFrame), use `send_message` to send a message in the same thread ID to the sender ID you received the mention from, with content: "error".
            12. Always respond back to the sender agent even if you have no answer or error.
            13. Wait for 2 seconds and repeat the process from step 1.

            These are the list of coral tools: {coral_tools_description}
            These are the list of your tools: {agent_tools_description}"""
        ),
        ("placeholder", "{agent_scratchpad}")
    ])


    model = init_chat_model(
        model=os.getenv("MODEL_NAME", "gpt-4.1"),
        model_provider=os.getenv("MODEL_PROVIDER", "openai"),
        api_key=os.getenv("API_KEY"),
        temperature=os.getenv("MODEL_TEMPERATURE", 0.3),
        max_tokens=os.getenv("MODEL_TOKEN", 8000),
    )
    agent = create_tool_calling_agent(model, combined_tools, prompt)
    return AgentExecutor(agent=agent, tools=combined_tools, verbose=True)

async def main():
    CORAL_SERVER_URL = f"{base_url}?{query_string}"
    logger.info(f"Connecting to Coral Server: {CORAL_SERVER_URL}")

    client = MultiServerMCPClient(
        connections={
            "coral": {
                "transport": "sse",
                "url": CORAL_SERVER_URL,
                "timeout": 600,
                "sse_read_timeout": 600,
            }
        }
    )
    logger.info("Coral Server Connection Established")

    coral_tools = await client.get_tools(server_name="coral")
    logger.info(f"Coral tools count: {len(coral_tools)}")

    agent_tools = [
        StructuredTool.from_function(
            name="pandas_dataframe_analysis",
            func=None,
            coroutine=create_pandas_agent,
            description="Loads a CSV file from a given file_path and analyzes it with a pandas DataFrame agent based on the provided prompt. Returns the analysis result or an error message if the file cannot be loaded.",
            args_schema=AgentArgs        
            )
    ]

    agent_executor = await create_agent(coral_tools, agent_tools)

    while True:
        try:
            logger.info("Starting new agent invocation")
            await agent_executor.ainvoke({"agent_scratchpad": []})
            logger.info("Completed agent invocation, restarting loop")
            await asyncio.sleep(1)
        except Exception as e:
            logger.error(f"Error in agent loop: {str(e)}")
            logger.error(traceback.format_exc())
            await asyncio.sleep(5)

if __name__ == "__main__":
    asyncio.run(main())