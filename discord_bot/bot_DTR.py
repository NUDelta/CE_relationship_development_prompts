# bot.py
import os
import json

import openai
import discord
from discord import Interaction
from discord.ext import commands
from discord import app_commands
from dotenv import load_dotenv

load_dotenv()

TOKEN = os.getenv('DISCORD_TOKEN')
OPENAI_KEY = os.getenv('OPENAI_KEY')

# Set up the OpenAI API client
openai.api_key = OPENAI_KEY

intents = discord.Intents.all()
client_bot = commands.Bot(command_prefix='!', intents=intents)

### system prompt

conversation = [{"role": "system",
                 "content": "You are AVGST Bot. An AI system that is an expert in communication and self disclosure. Each message starts with user_id and followed by a message text. You will generate short prompts for self-disclosure and communication, that are relevant for the previous discussion and are one or two sentences maximum. These are example of such prompts: Given the choice of anyone in the world, whom would you want as a dinner guest? Would you like to be famous? In what way? Before making a telephone call, do you ever rehearse what you are going to say? Why? What would constitute a perfect day for you? When did you last sing to yourself? To someone else? If you were able to live to the age of 90 and retain either the mind or body of a 30-year-old for the last 60 years of your life, which would you want? Do you have a secret hunch about how you will die? If a crystal ball could tell you the truth about yourself, your life, the future, or anything else, what would you want to know? Is there something that you've dreamed of doing for a long time? Why haven't you done it? What is the greatest accomplishment of your life? What do you value most in a friendship? What is your most treasured memory? What is your most terrible memory? If you knew that in one year you would die suddenly, would you change anything about the way you are now living? Why? What does friendship mean to you? What roles do love and affection play in your life?  Alternate sharing something you consider a positive characteristic of your partner. Share a total of 5 items."}]

# this is the code we will use first to test the connection
# @client_bot.event
# async def on_ready():
#     print(f'Logged in as {client_bot.user.name} ({client_bot.user.id})')
    # channel = client_bot.get_channel(1095042684776886397)
    # await channel.send("AVGST is running please use command ...")
@client_bot.event
async def on_ready():
    await client_bot.tree.sync(guild=discord.Object(id=1105594896598962258))
    channel = client_bot.get_channel(1105594896598962261)
    await channel.send("AVGST is running please use command /promt to get a prompt")

@client_bot.tree.command(name = "prompt", description = "Get a prompt form AVGST", guild=discord.Object(id=1105594896598962258)) #Add the guild ids in which the slash command will appear. If it should be in all, remove the argument, but note that it will take some time (up to an hour) to register the command if it's for all guilds.
async def first_command(interaction):
    await interaction.response.send_message('This is a placehlder reply: Talk about cats', ephemeral=True)
    # response = openai.ChatCompletion.create(
    #                 model="gpt-4",
    #                 # model="gpt-3.5-turbo",
    #                 messages=conversation,
    #                 max_tokens=2048,
    #                 temperature=0.5
    #                 )
    # conversation.append(json.loads(str(response.choices[0].message)))
    #         #     # Send the response as a message
    # rsp = response.choices[0].message.content
    # placeholder = interaction.original_message()
    # # await asyncio.sleep(5) # Doing stuff
    # await placeholder.edit('This message has now been edited')



@client_bot.command(name="prompt", description="Ask AVGST for a prompt")
async def prompt(ctx):
    response = openai.ChatCompletion.create(
                    model="gpt-4",
                    # model="gpt-3.5-turbo",
                    messages=conversation,
                    max_tokens=2048,
                    temperature=0.5
                    )
    conversation.append(json.loads(str(response.choices[0].message)))
            #     # Send the response as a message
    rsp = response.choices[0].message.content
    await ctx.reply(rsp)
@client_bot.event
async def on_message(message):
    # Only respond to messages from other users, not from the bot itself
    if message.author == client_bot.user:
        return
    # do not reply to short messages
    if len(message.content) < 3:
        return
    ### add typing indicator
    # async with message.channel.typing():
        # Use the OpenAI API to generate a response to the message
    conversation.append({"role": "user",
                        "content": f"user_id: {message.author}; message:{message.content}"})

    await client_bot.process_commands(message)
    # if message.content.startswith('!prompt'):
    #     response = openai.ChatCompletion.create(
    #             model="gpt-4",
    #             # model="gpt-3.5-turbo",
    #             messages=conversation,
    #             max_tokens=2048,
    #             temperature=0.5
    #             )
    #
    #     conversation.append(json.loads(str(response.choices[0].message)))
    #     #     # Send the response as a message
    #     rsp = response.choices[0].message.content
    #     await message.reply(rsp, ephemeral=True)

        ### add stora


#     ### on bot stop
# @client_bot.command(name='quit', help='Disconnect the bot')
# async def shutdown(message):
#     exit()
#     print("Bot is disconnected")
#     # save the conversation
#     with open('conversation_log', 'w') as fout:
#         json.dump(conversation, fout)
#     # close the bot
#     await client_bot.close()

# start the bot
client_bot.run(TOKEN)
#https://community.openai.com/t/build-your-own-ai-assistant-in-10-lines-of-code-python/83210
#%%
