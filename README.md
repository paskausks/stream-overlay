# Godot Chatbox

A chatbot/chatbox running in the Godot engine.

Coded live at [twitch.tv/rpwtf](https://twitch.tv/rpwtf)!

## Requirements

Godot 4.2

## Setup

Create a folder for the configuration files:

* Linux: ~/.local/share/rpchatbot
* Windows %APPDATA%\rpchatbot

### Custom commands

Store custom commands in "commands.csv" where the first column in the command trigger, and the second column is the response, e.g.

```csv
hello,hello {{user}}
github,https://github.com/paskausks
```

`{{user}}` will be replaced with the user name.

### Authentication data

Acquire an OAuth user access token following the steps outlined [here](https://dev.twitch.tv/docs/irc/authenticate-bot/) (make sure to include the "moderator:read:followers" scope as required by the `channel.follow` [event](https://dev.twitch.tv/docs/eventsub/eventsub-subscription-types/#channelfollow)).

Create a file called "access.ini" with the following structure:

```ini
[auth]
client_id="8c111f1b955a94fefbe03e762145f418"
access_token="ea9b2060a024022a71ea6fa088f099ae"
```

Where `client_id` is the client id of your Twitch application and `access_token` is the token you, hopefully, acquired in the previous step.
