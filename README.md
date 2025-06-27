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
uv run python langchain-pandas-agent.py
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
