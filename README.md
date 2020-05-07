# colour_chat
A minetest client side mod for changing the colour of messages you send to the server.
[Original version](https://github.com/red-001/colour_chat) was made by red-001, more features (mainly colour fading) were added by me. Pastel added by dhausmig.


## chat commands:
(note: all colours must be a 6 letter hex code with a "#" - eg: "#ffffff")

    .set_colour [<col1> [<col2> [<times>] ] ]  -  Set the default chat colour to either one solid colour, or a fade between two colours. 'times' is how many times to fade between them. Leave blank to reset to white.
    .set_max_message_length <value>            -  set the maximum chat message length for the current server.
    .rainbow <message>                         -  Send a message with rainbow colours.
    .pastel <message>                          -  Similar to rainbow, but easier to read.
    .alternate [<col1> <col2>] <message>       -  alternate between two colours.
    .fade <col1> <col2> [<times>] <message>    -  fade message between two colours, fade multiple times  -  works with long messages.
    .custom <message with colours>             -  send a message with custom colour changes. Use #------ anywhere in the text to change colours.
    .msg <name> <message>                      -  send a private message, the same as "/msg", but with your colours applied to it.
    .say <message>                             -  send a plain, white message.


- [Forum Topic](https://forum.minetest.net/viewtopic.php?f=53&t=20152)


changes:

- messages can fade through colours multiple times
- short messages don't fade
- .alternate uses users colours instead of red and green if no parameters are given
- comments and code cleaned up a little
- the maximum message length can be changed with a command for servers that don't use the default.
---
- .mw and .get_colour commands removed
- extra spellings of chat commands removed
- command descriptions cleaned
- set_max_message_length
---
TODO:
- use config files instead of mod storage
- clean up fade()
- better calculation of message length
