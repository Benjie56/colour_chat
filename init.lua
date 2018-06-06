--[[
based of chat colours by red-001, with many new features added by fiftysix. Pastel added by dhausmig.

chat commands:  (note: all colours must be a 6 letter hex code with a "#" - eg: "#ffffff")

    .get_colour <name>                         -  get the hex value from a colour name
    .get_color <name>                          -  same as get_colour, but with different spelling
    .set_colour [<col1> [<col2> [<times>] ] ]  -  Set the default chat colour to either one solid colour, or a fade between two colours. 'times' is how many times to fade between them. Leave blank to reset to white.
    .set_color [<col1> [<col2> [<times>] ] ]   -  same as .set_colour, but with american spelling.
    .rainbow <message>                         -  send a message with rainbow colours.
    .pastel <message>                          -  similar to rainbow, but easier to read.
    .alternate [<col1> <col2>] <message>       -  alternate between two colours.
    .fade <col1> <col2> [<times>] <message>    -  fade message between two colours, fade multiple times  -  works with long messages!!
    .custom <message with colours>             -  send a message with custom colour changes. Use "#------" anywhere in the text to change colours.
    .msg <playername> <message>                -  send a private message, the same as "/msg", but with your colours applied to it
    .mw <message>                              -  send a message with a red "MODERATOR WARNING:  ".
    .say <message>                             -  send a plain, white message.
    
changes:
    
    - messages can fade through colours multiple times
    - short messages don't fade
    - .alternate uses users colours instead of red and green if no parameters are given
    - moderator warning now gives a warning before sending the message
    - comments and code cleaned up a little
    
]]--

local modstorage = minetest.get_mod_storage()

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
    if rgb1 == nil or rgb2 == nil then
        return "#fff"
    end
    if pos > 255 then
        pos = 255
    end
    local rgb = {}
    for i, v in pairs(rgb1) do
        rgb[i] = rgb1[i]+(rgb2[i]-rgb1[i])*(pos/255)
    end
    local colour = rgb_to_hex(rgb)
    return string.sub(colour, 1, 2) .. string.sub(colour, 4, 4) .. string.sub(colour, 6, 6)  -- reduce to shorter hex
end

local register_on_message = minetest.register_on_sending_chat_message
if minetest.register_on_sending_chat_messages then
    register_on_message = minetest.register_on_sending_chat_messages
end

local do_say = nil  -- for multi step confirmation in .mw

local function say(message)
    minetest.send_chat_message(message)
    if minetest.get_server_info().protocol_version < 29 then
        local name = minetest.localplayer:get_name()
        minetest.display_chat_message("<"..name.."> " .. message)
    end
    do_say = nil  -- reset if ignored
end

function fade_string(text, col1, col2, char_max)  -- added - adds all the colour changes to fade between two colours to a string, but makes sure it doesn't pass the character limit
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
        local section = string.sub(text, math.floor(pos+1.5), math.floor(pos+step+0.5))
        if section ~= "" then
            local col = minetest.get_color_escape_sequence(colour_step(pos/(text:len()-1)*255, col1, col2))  -- find the colour
            output = output .. col .. section  -- insert the part of text which uses the colour
        end
    end
    return output
end

function fade(parameter, give)  -- added - parse message for parameters, and send a message with colours applied
    if parameter:len() <= 14 then
        return true, "see '.help fade' or '.help set_colour' for usage"
    end
    local col1 = string.sub(parameter, 1, 7)
    local col2 = string.sub(parameter, 9, 15)
    local times = tonumber(string.sub(parameter, 17, 17))
    local message = string.sub(parameter, 19)
    if times == nil then
        times = 1
        message = string.sub(parameter, 17)
    end
    if string.sub(col1, 1, 1) ~= "#" then
        col1 = "#ffffff"
        col2 = "#ffffff"
        message = parameter
        times = 1
    end
    while message:len() < times*2 and message:len() > 4 do
        times = times - 1
    end
    if col1 == col2 or message:len() < 4 then
        if type(give) == "number" then
            return minetest.get_color_escape_sequence(col1) .. message
        end
        say(minetest.get_color_escape_sequence(col1) .. message)
        return true
    end
    
    local max_chars = 500
    if type(give) == "number" then
        max_chars = give
    end
    
    local text = ""
    for i=1, times do
        local section = fade_string(string.sub(message, (i-1)/times*message:len()+1, i/times*message:len()+1), col1, col2, max_chars/times)
        text = string.sub(text, 0, -2)..section
        col1, col2 = col2, col1
    end
    if type(give) == "number" then
        return text
    end
    say(text)
    return true
end


register_on_message(function(message)
    if message:sub(1,1) == "/" or modstorage:get_string("colour") == "" or modstorage:get_string("colour") == "#ffffff #ffffff 1" or modstorage:get_string("colour"):len() ~= 17 then
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

minetest.register_chatcommand("get_colour", {  --  added - get a hex colour from a colour name
    description = minetest.gettext(".get_colour <colour name>  -  displays the hex colour for a colour name"),
    func = function(parameter)
        if colour_names[parameter] == nil then
            return "unknown, try https://htmlcolorcodes.com/color-picker/"
        end
        return true, colour_names[parameter]
    end,
})

minetest.register_chatcommand("get_color", {  --  added - the american spelling for colour, same as get_colour()
    description = minetest.gettext(".get_color <colour name>  -  displays the hex colour for a color name"),
    func = function(parameter)
        if colour_names[parameter] == nil then
            return "unknown, try https://htmlcolorcodes.com/color-picker/"
        end
        return true, colour_names[parameter]
    end,
})

local function set_colour(colour)  -- added - parses the parameter and changes the colour
    if colour:len() == 7 then
        modstorage:set_string("colour", colour.." "..colour.." 1")
    elseif colour:len() == 15 then
        modstorage:set_string("colour", colour.." 1")
    else
        modstorage:set_string("colour", colour)  -- (not added)
    end
    return true, "Chat colour changed."
end

minetest.register_chatcommand("set_colour", {
    description = minetest.gettext(".set_colour [col1] [col2] - Change chat colour to solid, fade, or reset"),
    func = set_colour,  -- changed
})

minetest.register_chatcommand("set_color", {  -- for people that automatically use "color"
    description = minetest.gettext(".set_color [col1] [col2] - Change chat color to solid, fade, or reset"),
    func = set_colour,
})

minetest.register_chatcommand("rainbow", {
    description = minetest.gettext(".rainbow <message> - rainbow text"),
    func = function(param)
        local step = 360 / param:len()
        local hue = 0
        local output = ""
              for i = 1, param:len() do
            local char = param:sub(i,i)
            if char:match("%s") then
                output = output .. char
            else
                    output = output  .. minetest.get_color_escape_sequence(color_from_hue(hue)) .. char 
            end
                hue = hue + step
        end
        say(output)
        return true
end,
})

minetest.register_chatcommand("pastel", {  -- added by dhausmig
    description = minetest.gettext(".pastel <message> - pastel rainbow text"),
    func = function(param)
        local step = 360 / param:len()
        local hue = 0
              -- iterate the whole 360 degrees
        local output = ""
              for i = 1, param:len() do
            local char = param:sub(i,i)
            if char:match("%s") then
                output = output .. char
            else
                output = output  .. minetest.get_color_escape_sequence(pastel_from_hue(hue)) .. char 
            end
                hue = hue + step
        end
        say(output)
        return true
    end,
})

minetest.register_chatcommand("alternate", {  -- added - alternates between two colours
    description = minetest.gettext(".alternate [<col1> <col2>] <message> - alternate between two colours"),
    func = function(parameter)
        local col1 = string.sub(parameter, 1, 7)
        local col2 = string.sub(parameter, 9, 15)
        local message = string.sub(parameter, 17)
        if string.sub(col1, 1, 1) ~= "#" then
            col1 = string.sub(modstorage:get_string("colour"), 1, 7)
            col2 = string.sub(modstorage:get_string("colour"), 9, 15)
            message = parameter
        else
            col1 = string.sub(col1, 1, 2) .. string.sub(col1, 4, 4) .. string.sub(col1, 6, 6)
            col2 = string.sub(col2, 1, 2) .. string.sub(col2, 4, 4) .. string.sub(col2, 6, 6)
        end
        
        local output = ""
        local colr = col1
        for i=1, message:len() do
            char = string.sub(message, i, i)
            output = output .. minetest.get_color_escape_sequence(colr) .. char
            if char ~= " " then
                if colr == col1 then
                    colr = col2
                else
                    colr = col1
                end
            end
        end
        say(output)
        return true
    end,
})

minetest.register_chatcommand("fade", {  -- added - fades between any two colours#
    description = minetest.gettext(".fade <col1> <col2> [<times 1-9>] <message> - fade message between two colours"),
    func = fade,
})

minetest.register_chatcommand("custom", {  -- added - change colour anywhere in a message
    description = minetest.gettext(".custom <message with colours> - use #<6-digits> anywhere  in the message to change the colour"),
    func = function(message)
        local output = ""
        local i = 0
        while i < message:len() do
            i = i + 1
            local char = string.sub(message, i, i)
            if char == "#" then
                output = output .. minetest.get_color_escape_sequence(string.sub(message, i, i+6))
                i = i + 6
            else
                output = output .. char
            end
        end
        say(output)
    end,
})

minetest.register_chatcommand("msg", {  -- added - lets you use /msg with colours
    description = minetest.gettext(".msg <playername> <message> - send a pm to player using /msg, but use the current colour style"),
    func = function(parameter)
        local colour = modstorage:get_string("colour")
        if colour == "" or colour == "#ffffff #ffffff 1" or colour:len() ~= 17 then
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
        message = fade(colour.." "..message, 450)
        say("/msg "..name..message)
    end,
})


minetest.register_chatcommand("mw", {  -- added - send a moderator warning
    description = minetest.gettext("moderator warning - for moderators only!"),
    func = function(message)
        do_say = minetest.get_color_escape_sequence("#f00").."MODERATOR WARNING:  "..minetest.get_color_escape_sequence("#fff")..message
        return true, minetest.get_color_escape_sequence("#f00").."THIS COMMAND IS MEANT FOR MODERATORS ONLY!  to send the message type '.y'"
    end,
})

minetest.register_chatcommand("y", {  -- added - accept sending a moderator warning
    description = minetest.gettext("accept the warning and continue from .mw"),
    func = function(param)
        if do_say ~= nil then
            say(do_say)
        end
    end,
})

minetest.register_chatcommand("say", {
    description = minetest.gettext("Send text without applying colour to it"),
    func = function(text)
        say(text)
        return true
    end,
})
