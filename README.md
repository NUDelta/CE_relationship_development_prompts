# CE_relationship_development_prompts
Discord bot and R Shiny chat for scaffolding conversations with LLM generated prompts

## Discrod chatbot
[Python bot script](discord_bot/bot_DTR.py)

prerequists:
0. Python
1. DISCORD_TOKEN [guide for creating a discord bot](https://discordpy.readthedocs.io/en/stable/discord.html)
2. OPENAI_KEY [OpenAI API key](https://platform.openai.com/account/api-keys)
3. add DISCORD_TOKEN and OPENAI_KEY to the environment
4. install all dependent packages
5. change channel id for you channel
6. run [Python bot script](discord_bot/bot_DTR.py)

Using bot:
Talk with each other, or on you own. Write __!prompt__ to recive a message with prompt


## Shiny chat with prompts
[App folder](shiny_chat)

prerequists:
0. R
1. OPENAI_KEY [OpenAI API key](https://platform.openai.com/account/api-keys)
2. (optional) Project on Atlas Mongo to store loggs externally
3. creaete a file called secret.R and put all you key inside
4. run [shiny app](shiny_chat/app.R)

Using chat:
write !show_prompt to show the _get prompt_ botton
write !show_likert_1 for the first survey question
write !show_likert_2 for the second survey question
write !show_users to see all active sessions
write !delete to clean all log
write !dump to send the chat history to mongo
