# Godot Overlay

A chatbot/stream overlay running in the Godot engine.

Coded live at [twitch.tv/rpwtf](https://twitch.tv/rpwtf)!

## Requirements

Godot 4.2

## Setup

Create a folder for the configuration files:

* Linux: ~/.local/share/rpoverlay
* Windows %APPDATA%\rpoverlay

### Custom commands

Store custom commands in "commands.csv" where the first column in the command trigger, and the second column is the response, e.g.

```csv
hello,hello {{user}}
github,https://github.com/paskausks
```

`{{user}}` will be replaced with the user name.

### General configuration

Create a file "config.ini" in the configuration directory with the following contents:

```ini
[main]
nickname="rpWTF" # capitalization does not matter
channel="rpwtf"
client_id="8c111f1b955a94fefbe03e762145f418"
```

Where `nick` is your twitch.tv nickname, `channel` is the target channel for the chatbot/chat overlay and `client_id` is the client id of your Twitch application.

### Authentication

An OAuth token will be fetched on the first run, or if you launch the application with the `--auth` argument.
