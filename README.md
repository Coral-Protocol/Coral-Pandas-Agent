## [Coral Pandas Agent](https://github.com/Coral-Protocol/Coral-Pandas-Agent)
 
Coral Pandas Agent interacts with other agents and performs data analysis on pandas DataFrames to fulfill user requests.

## Responsibility

The Coral Pandas Agent's main responsibility is to interpret natural language instructions from users or other agents and translate them into actionable pandas DataFrame operations. It collaborates with other agents by fulfilling delegated data-related requests and delivers clear, concise insights or results to the requester.

## Details
- **Framework**: LangChain
- **Tools used**: Coral MCP Tools, Langchain Pandas Tool
- **AI model**: GPT-4.1. Groq- llama-3.3-70b-versatile
- **Date added**: June 27, 2025
- **License**: MIT

## Use the Agent in Orchestration

### 1. Executable Agent Definition

<details>

For Linux or MAC:

```bash
# PROJECT_DIR="/PATH/TO/YOUR/PROJECT"

applications:
  - id: "app"
    name: "Default Application"
    description: "Default application for testing"
    privacyKeys:
      - "default-key"
      - "public"
      - "priv"

registry:
  interface:
    options:
      - name: "API_KEY"
        type: "string"
        description: "API key for the service"
    runtime:
      type: "executable"
      command: ["bash", "-c", "${PROJECT_DIR}/run_agent.sh main.py"]
      
      environment:
        - name: "API_KEY"
          from: "API_KEY"
        - name: "MODEL"
          value: "gpt-4.1"
        - name: "LLM_MODEL_PROVIDER"
          value: "openai"
```

For Windows, create a powershell command and run:

```bash
command: ["powershell","-ExecutionPolicy", "Bypass", "-File", "${PROJECT_DIR}/run_agent.ps1","main.py"]
```

</details>


## Use the Agent in Dev Mode

### 1. Clone & Install Dependencies


<details>  

Ensure that the [Coral Server](https://github.com/Coral-Protocol/coral-server) is running on your system. If you are trying to run Interface agent and require coordination with other agents, you can run additional agents that communicate on the coral server.

```bash
# In a new terminal clone the repository:
git clone https://github.com/Coral-Protocol/Coral-Pandas-Agent

# Navigate to the project directory:
cd Coral-Pandas-Agent

# Install `uv`:
pip install uv

# Install dependencies from `pyproject.toml` using `uv`:
uv sync
```

</details>
 

### 2. Configure Environment Variables

<details>
 
Get the API Key:
[OpenAI](https://platform.openai.com/api-keys)


```bash
# Create .env file in project root
cp -r .env_sample .env
```
</details>


### 3. Run Agent

<details>

```bash
# Run the agent using `uv`:
uv run python main.py
```
</details>


### 4. Example

<details>


```bash
# Input:
For https://raw.githubusercontent.com/pandas-dev/pandas/main/doc/data/titanic.csv how describe me the columns"

#Output:
The agent will respond back with the column description.
```
</details>


## Creator Details
- **Name**: Suman Deb
- **Affiliation**: Coral Protocol
- **Contact**: [Discord](https://discord.com/invite/Xjm892dtt3)
