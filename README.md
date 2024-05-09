# Godot Chatbox

A chatbot/chatbox running in the Godot engine.

Coded live at [twitch.tv/rpwtf](https://twitch.tv/rpwtf)!

## Requirements

Godot 4.2

## Setup

Acquire an OAuth user access token following the steps outlined [here](https://dev.twitch.tv/docs/irc/authenticate-bot/) (make sure to include the "moderator:read:followers" scope as required by the `channel.follow` [event](https://dev.twitch.tv/docs/eventsub/eventsub-subscription-types/#channelfollow)), then store the access token in a file called `access_token` and the client id in a file called `client_id` moderator:read:followers.
