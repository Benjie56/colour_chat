# colour_chat
A minetest CSM mod for changing the colour of text sent to the server.
[First version](https://github.com/red-001/colour_chat) was made by red-001, more features were added by me. Pastel added by dhausmig.

## chat commands:  
(note: all colours must be a 6 letter hex code with a "#" - eg: "#ffffff")

	.get_colour <name>  			-  get the hex value from a colour name
	.get_color <name> 			-  same as get_colour, but with different spelling
	.set_colour [<col1> [<col2]]   		-  Set the default chat colour to either one solid colour, or a fade between two colours. Leave blank to reset.
	.set_color [<col1> [<col2]]		-  same as set_colour, but with different spelling.
	.rainbow <message>  			-  send a message with rainbow colours.
	.pastel <message>  			-  similar to rainbow, but easier to read.
	.alternate [<col1> <col2>] <message>	-  alternate between two colours, only put the message to use red and green, long messages are split over multiple messages.
	.fade <col1> <col2> <message>  		-  fade message between two colours  -  works with long messages!!
	.custom <message with colours>  	-  send a message with custom colour changes. Use "#------" anywhere in the text to change colours.
	.msg <playername> <message>		-  send a private message, the same as "/msg", but with your colour applied to it
	.mw <message>  				-  send a message with a red "MODERATOR WARNING:  ".
	.say <message>  			-  send a plain, white message.
