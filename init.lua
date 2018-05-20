--[[
based of chat colours by red-001, with many new features added by fiftysix. Pastel added by dhausmig.

chat commands:  (note: all colours must be a 6 letter hex code with a "#" - eg: "#ffffff")

	.get_colour <name>  					-  get the hex value from a colour name
	.get_color <name> 						-  same as get_colour, but with different spelling
	.set_colour [<col1> [<col2] ]   		-  Set the default chat colour to either one solid colour, or a fade between two colours. Leave blank to reset.
	.set_color [<col1> [<col2] ]			-  same as set_colour, but with different spelling.
	.rainbow <message>  					-  send a message with rainbow colours.
	.pastel <message>  						-  similar to rainbow, but easier to read.
	.alternate [<col1> <col2>] <message>	-  alternate between two colours, only send a message to use red and green, long messages are split over multiple messages.
	.fade <col1> <col2> <message>  			-  fade message between two colours  -  works with long messages!!
	.custom <message with colours>  		-  send a message with custom colour changes. Use "#------" anywhere in the text to change colours.
	.msg <playername> <message>				-  send a private message, the same as "/msg", but with your colour applied to it
	.mw <message>  							-  send a message with a red "MODERATOR WARNING:  ".
	.say <message>  						-  send a plain, white message.
]]--

local modstorage = core.get_mod_storage()

local function rgb_to_hex(rgb)
	local hexadecimal = '#'

	for key, value in pairs(rgb) do
		local hex = ''

		while(value > 0) do
			local index = math.fmod(value, 16) + 1
			value = math.floor(value / 16)
			hex = string.sub('0123456789ABCDEF', index, index) .. hex			
		end

		if(string.len(hex) == 0)then
			hex = '00'

		elseif(string.len(hex) == 1)then
			hex = '0' .. hex
		end

		hexadecimal = hexadecimal .. hex
	end

	return hexadecimal
end

local function color_from_hue(hue)
	local h = hue / 60
	local c = 255
	local x = (1 - math.abs(h%2 - 1)) * 255

  	local i = math.floor(h);
  	if (i == 0) then
		return rgb_to_hex({c, x, 0})
  	elseif (i == 1) then 
		return rgb_to_hex({x, c, 0})
  	elseif (i == 2) then 
		return rgb_to_hex({0, c, x})
	elseif (i == 3) then
		return rgb_to_hex({0, x, c});
	elseif (i == 4) then
		return rgb_to_hex({x, 0, c});
	else 
		return rgb_to_hex({c, 0, x});
	end
end

local function pastel_from_hue(hue) -- added by dhausmig
	local h = hue / 60
	local c = 255
   local d = 192
	local x = (1 - math.abs(h%2 - 1)) * 255

  	local i = math.floor(h);
  	if (i == 0) then
		return rgb_to_hex({c, x, d})
  	elseif (i == 1) then 
		return rgb_to_hex({x, c, d})
  	elseif (i == 2) then 
		return rgb_to_hex({d, c, x})
	elseif (i == 3) then
		return rgb_to_hex({d, x, c});
	elseif (i == 4) then
		return rgb_to_hex({x, d, c});
	else 
		return rgb_to_hex({c, d, x});
	end
end

function hex2rgb(hex)  -- added - found on github
    hex = hex:gsub("#","")
    return {tonumber("0x"..hex:sub(1,2)), tonumber("0x"..hex:sub(3,4)), tonumber("0x"..hex:sub(5,6))}
end

local function colour_step(pos, col1, col2)  -- added - gets a colour between colours
	local rgb1 = hex2rgb(col1)
	local rgb2 = hex2rgb(col2)
	local rgb = {}
	for i, v in pairs(rgb1) do
		rgb[i] = rgb1[i]+(rgb2[i]-rgb1[i])*(pos/255)
	end
	local colour = rgb_to_hex(rgb)
	return string.sub(colour, 1, 2) .. string.sub(colour, 4, 4) .. string.sub(colour, 6, 6)  -- reduce to shorter hex
end

local register_on_message = core.register_on_sending_chat_message
if core.register_on_sending_chat_messages then
	register_on_message = core.register_on_sending_chat_messages
end

local function canTalk()
	if core.get_privilege_list then
		return core.get_privilege_list().shout
	else
		return true
	end
end

local function canBan()  -- this doesn't work for me, don't know how to fix it
	if core.get_privilege_list then
		return core.get_privilege_list().ban
	else
		return true
	end
end

local function say(message)
	if not canTalk() then
		minetest.display_chat_message("You need 'shout' in order to talk")
		return
	end
	minetest.send_chat_message(message)
	if minetest.get_server_info().protocol_version < 29 then
		local name = minetest.localplayer:get_name()
		minetest.display_chat_message("<"..name.."> " .. message)
	end
end

function fade_string(text, col1, col2, char_max)  -- added - puts all the colour changes to fade between a two colours, but makes sure it doesn't pass the character limit
	if char_max == nil then
		char_max = 500
	end
	char_max = char_max - minetest.localplayer:get_name():len() - 0.1
	local col_len = 9
	local output = ""
	local step = 1
	if text:len()+text:len()*col_len > char_max then
		step = text:len()/((char_max-text:len())/col_len)
	end
	for pos=0, text:len(), step do
		local col = core.get_color_escape_sequence(colour_step(pos/(text:len()-1)*255, col1, col2))  -- find the colour
		output = output .. col .. string.sub(text, math.floor(pos+1.5), math.floor(pos+step+0.5))  -- cut out the part of text which uses the colour
	end
	return output
end

function fade(parameter)  -- added - parse message for parameters, and output a message with colours applied
	local col1 = string.sub(parameter, 1, 7)
	local col2 = string.sub(parameter, 9, 15)
	local message = string.sub(parameter, 17)
	if string.sub(col1, 1, 1) ~= "#" then
		col1 = "#ffffff"
		col2 = "#ffffff"
		message = parameter
	end
	if col1 == col2 then
		say(core.get_color_escape_sequence(col1) .. message)
		return true
	end
	say(fade_string(message, col1, col2))
	return true
end

register_on_message(function(message)
	if message:sub(1,1) == "/" or modstorage:get_string("colour") == "" or modstorage:get_string("colour") == "#ffffff #ffffff" or modstorage:get_string("colour"):len() ~= 15 then
		return false
	end

	fade(modstorage:get_string("colour") .. " " .. message)  -- changed
	return true
end)

local colour_names = {
	red = "#ff0000",
	green = "#00ff00",
	blue = "#0000ff",
	yellow = "#ffff00",
	turquois = "#00ffff",
	purple = "#ff00ff",
	white = "#ffffff",
	black = "#000000",
	orange = "#ff8800",
	pink = "#ff00aa",
	gray = "#777777",
	--  add more colours here!
}

core.register_chatcommand("get_colour", {  --  added - get a hex colour from a colour name
	description = core.gettext(".get_colour <colour name>  -  displays the hex colour for a colour name"),
	func = function(parameter)
		if colour_names[parameter] == nil then
			return "unknown, try https://htmlcolorcodes.com/color-picker/"
		end
		return true, colour_names[parameter]
	end,
})

core.register_chatcommand("get_color", {  --  added - the american spelling for colour, same as get_colour()
	description = core.gettext(".get_color <colour name>  -  displays the hex colour for a color name"),
	func = function(parameter)
		if colour_names[parameter] == nil then
			return "unknown, try https://htmlcolorcodes.com/color-picker/"
		end
		return true, colour_names[parameter]
	end,
})

core.register_chatcommand("set_colour", {
	description = core.gettext(".set_colour [col1] [col2] - Change chat colour to solid, fade, or reset"),
	func = function(colour)
		if colour:len() == 7 then
			modstorage:set_string("colour", colour.." "..colour)  -- changed
		else
			modstorage:set_string("colour", colour)
		end
		return true, "Chat colour changed."
	end,
})

core.register_chatcommand("set_color", {  -- for people that always use  "color"
	description = core.gettext(".set_color [col1] [col2] - Change chat color to solid, fade, or reset"),
	func = function(colour)
		if colour:len() == 7 then
			modstorage:set_string("colour", colour.." "..colour)
		else
			modstorage:set_string("colour", colour)
		end
		return true, "Chat color changed."
	end,
})

core.register_chatcommand("rainbow", {
	description = core.gettext(".rainbow <message> - rainbow text"),
	func = function(param)
		if not canTalk() then
			return false, "You need 'shout' in order to use this command"
		end
		local step = 360 / param:len()
 		local hue = 0
		local output = ""
      		for i = 1, param:len() do
			local char = param:sub(i,i)
			if char:match("%s") then
				output = output .. char
			else
        			output = output  .. core.get_color_escape_sequence(color_from_hue(hue)) .. char 
			end
        		hue = hue + step
		end
		say(output)
		return true
end,
})

core.register_chatcommand("pastel", {  -- added by dhausmig
	description = core.gettext(".pastel <message> - pastel rainbow text"),
	func = function(param)
		if not canTalk() then
			return false, "You need 'shout' in order to use this command"
		end
		local step = 360 / param:len()
 		local hue = 0
     		 -- iterate the whole 360 degrees
		local output = ""
      		for i = 1, param:len() do
			local char = param:sub(i,i)
			if char:match("%s") then
				output = output .. char
			else
        			output = output  .. core.get_color_escape_sequence(pastel_from_hue(hue)) .. char 
			end
        		hue = hue + step
		end
		say(output)
		return true
end,
})

core.register_chatcommand("alternate", {  -- added - alternates between two colours
	description = core.gettext(".alternate <col1> <col2> <message> - alternate between two colours"),
	func = function(parameter)
		if not canTalk() then
			return false, "You need 'shout' in order to use this command"
		end
		local col1 = string.sub(parameter, 1, 7)
		local col2 = string.sub(parameter, 9, 15)
		local message = string.sub(parameter, 17)
		if string.sub(col1, 1, 1) ~= "#" then
			col1 = "#0a1"
			col2 = "#f00"
			message = parameter
		else
			col1 = string.sub(col1, 1, 2) .. string.sub(col1, 4, 4) .. string.sub(col1, 6, 6)
			col2 = string.sub(col2, 1, 2) .. string.sub(col2, 4, 4) .. string.sub(col2, 6, 6)
		end
		local max_len = math.floor((500-minetest.localplayer:get_name():len())/9)-8
		for part=1, math.floor(message:len()/max_len)+1 do
			local msg = string.sub(message, (part-1)*max_len, part*max_len-1)
			local output = ""
			local colr = col1
			for i=1, msg:len() do
				char = string.sub(msg, i, i)
				output = output .. core.get_color_escape_sequence(colr) .. char
				if char ~= " " then
					if colr == col1 then
						colr = col2
					else
						colr = col1
					end
				end
			end
			say(output)
		end
		return true
	end,
})

core.register_chatcommand("fade", {  -- added - fades between any two colours
	description = core.gettext(".fade <col1> <col2> <message> - fade message between two colours"),
	func = fade,
})

core.register_chatcommand("custom", {  -- added - change colour anywhere in a message
	description = core.gettext(".custom <message with colours> - use #<6-digits> anywhere  in the message to change the colour"),
	func = function(message)
		local output = ""
		local i = 0
		while i < message:len() do
			i = i + 1
			local char = string.sub(message, i, i)
			if char == "#" then
				output = output .. core.get_color_escape_sequence(string.sub(message, i, i+6))
				i = i + 6
			else
				output = output .. char
			end
		end
		say(output)
	end,
})

core.register_chatcommand("msg", {  -- added - lets you use /msg with colours
	description = core.gettext(".msg <playername> <message> - send a pm to player using /msg, but use the current colour style"),
	func = function(parameter)
		local colour = modstorage:get_string("colour")
		if colour == "" or colour == "#ffffff #ffffff" or colour:len() ~= 15 then
			say("/msg "..parameter)
			return true
		end
		
		local name = ""
		local i = 0
		while string.sub(parameter, i, i) ~= " " and i < parameter:len() do
			i = i + 1
			name = name .. string.sub(parameter, i, i)  -- contains leading space
		end
		local message = string.sub(parameter, i+1)
		message = fade_string(message, string.sub(colour, 1, 7), string.sub(colour, 9, 15), 450)
		say("/msg "..name..message)
	end,
})

core.register_chatcommand("mw", {
	description = core.gettext("moderator warning - ban priv only"),
	func = function(message)
		if not canBan() then  -- I don't think this works
			return false, "failed to send..."
		end
		say(core.get_color_escape_sequence("#f00").."MODERATOR WARNING:  "..core.get_color_escape_sequence("#fff")..message)
		return true
	end,
})

core.register_chatcommand("say", {
	description = core.gettext("Send text without applying colour to it"),
	func = function(text)
		say(text)
		return true
	end,
})
