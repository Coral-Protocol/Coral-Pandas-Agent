import os
import pandas as pd
import asyncio
import traceback
from dotenv import load_dotenv
from langchain.chat_models import init_chat_model
from langchain_experimental.agents.agent_toolkits import create_pandas_dataframe_agent
from langchain.agents.agent_types import AgentType

# Load environment variables
load_dotenv()

# Function to create a pandas agent and run analysis
async def create_pandas_agent(file_path: str, prompt: str):
    try:
        df = pd.read_csv(file_path)
        agent = create_pandas_dataframe_agent(
            llm=init_chat_model(
                model=os.getenv("MODEL_NAME"),
                model_provider=os.getenv("MODEL_PROVIDER"),
                api_key=os.getenv("API_KEY"),
                temperature=0.3,
                max_tokens=32768
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


# Entry point
if __name__ == "__main__":
    # Parameters
    file_path = "https://raw.githubusercontent.com/pandas-dev/pandas/main/doc/data/titanic.csv"
    prompt = "Provide a summary of its columns"

    result = asyncio.run(create_pandas_agent(file_path, prompt))
    print("\n=== Agent Result ===")
    print(result)
