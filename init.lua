--[[
based of chat colours by red-001, with some fancy new features added by fiftysix. Pastel command added by dhausmig.

chat commands:  (note: all colours must be a 6 letter hex code with a "#" - eg: "#ffffff")

    .set_colour [<col1> [<col2> [<times>] ] ]  -  Set the default chat colour to either one solid colour, or a fade between two colours. 'times' is how many times to fade between them. Leave blank to reset to white.
    .set_max_message_length <value>            -  set the maximum chat message length for the current server.
    .rainbow <message>                         -  Send a message with rainbow colours.
    .pastel <message>                          -  Similar to rainbow, but easier to read.
    .alternate [<col1> <col2>] <message>       -  alternate between two colours.
    .fade <col1> <col2> [<times>] <message>    -  fade message between two colours, fade multiple times  -  works with long messages.
    .custom <message with colours>             -  send a message with custom colour changes. Use #------ anywhere in the text to change colours.
    .msg <name> <message>                      -  send a private message, the same as "/msg", but with your colours applied to it.
    .say <message>                             -  send a plain, white message.
    
changes:
    
    - messages can fade through colours multiple times
    - short messages don't fade
    - .alternate uses users colours instead of red and green if no parameters are given
    - comments and code cleaned up a little
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
]]--

local modstorage = minetest.get_mod_storage()

if modstorage:get_int("max_len") == 0 then
    modstorage:set_int("max_len", 500)
end

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

function hex2rgb(hex)  -- found on github
    hex = hex:gsub("#","")
    return {tonumber("0x"..hex:sub(1,2)), tonumber("0x"..hex:sub(3,4)), tonumber("0x"..hex:sub(5,6))}
end

local function colour_at_point(pos, col1, col2)  -- gets a colour at a point between 2 colours
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


local function say(message)
    minetest.send_chat_message(message)
    if minetest.get_server_info().protocol_version < 29 then
        local name = minetest.localplayer:get_name()
        minetest.display_chat_message("<"..name.."> " .. message)
    end
end


local register_on_message = minetest.register_on_sending_chat_message
if minetest.register_on_sending_chat_messages then
    register_on_message = minetest.register_on_sending_chat_messages
end
register_on_message(function(message)
    local colour = modstorage:get_string("colour")
    if message:sub(1,1) == "/" or colour == "" or colour == "#ffffff #ffffff 1" or colour:len() ~= 17 then
        return false
    end

    fade(colour .. " " .. message)
    return true
end)

minetest.register_on_receiving_chat_message(function(message)
    if message == "Your message exceed the maximum chat message limit set on the server. It was refused. Send a shorter message" then
        minetest.display_chat_message(message.."\nThis server may have reduced their maximum message length. Try .set_max_message_length <value> with a value lower than 500")
        return true
    end
end)


function fade_string(text, col1, col2, char_max)  -- adds all the colour changes to fade between two colours to a string, but makes sure it doesn't pass the character limit
    if char_max == nil then
        local server = minetest.get_server_info()
        char_max = modstorage:get_int(server.address.."_max_len")
    end
    char_max = char_max - minetest.localplayer:get_name():len() - 0.1
    local col_len = 9
    local output = ""
    local step = 1
    if text:len()+text:len()*col_len > char_max then
        local sections = ((char_max-text:len())/col_len)
        if sections < 1 then
            sections = 1
        end
        step = text:len()/sections
    end
    for pos=0, text:len(), step do  
        local section = string.sub(text, math.floor(pos+1.5), math.floor(pos+step+0.5))
        if section ~= "" then
            local col = minetest.get_color_escape_sequence(colour_at_point(pos/(text:len()-1)*255, col1, col2))  -- find the colour
            output = output .. col .. section  -- insert the part of text which uses the colour
        end
    end
    return output
end

function fade(parameter, give)  -- parse message for parameters, and send a message with colours applied
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
    
    local max_chars = modstorage:get_int("max_len")
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

minetest.register_chatcommand("set_colour", {
    description = minetest.gettext("Change the colour you chat with. 1 colour for solid colour, 2 colours to fade between colours, optional 3rd parameter to alternate between the 2 colours multiple times. use without params to reset"),
    params = "[<colour1>] [<colour2>] [times]",
    func = function(parameter)  -- parses the parameter and changes the colour
        if parameter:len() == 7 then
            modstorage:set_string("colour", parameter.." "..parameter.." 1")
        elseif parameter:len() == 15 then
            modstorage:set_string("colour", parameter.." 1")
        else
            modstorage:set_string("colour", parameter)
        end
        return true, "Chat colour changed."
    end,
})

minetest.register_chatcommand("set_max_message_length", {  -- sets the maximum message length
    description = minetest.gettext("Change the maximum chat message length for the current server (default: 500 characters)"),
    params = "<value>",
    func = function(param)
        local new_val = tonumber(param)
        if new_val == nil then
            new_val = 500
        end
        local server = minetest.get_server_info()
        modstorage:set_int(server.address.."_max_len", new_val)
        return true, "message maximum length set to "..new_val.." characters for \""..server.address.."\""
    end,
})

minetest.register_chatcommand("rainbow", {
    description = minetest.gettext("Applies a rainbow effect to a message."),
    params = "<message>",
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
    description = minetest.gettext("Applies a pastel rainbow effect to a message."),
    params = "<message>",
    func = function(param)
        local step = 360 / param:len()
        local hue = 0
        local output = ""
        -- iterate the whole 360 degrees
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

minetest.register_chatcommand("alternate", {  -- alternates between two colours
    description = minetest.gettext("Alternate between two colours each letter"),
    params = "[<colour1> <colour2>] <message>",
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
            local char = string.sub(message, i, i)
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

minetest.register_chatcommand("fade", {  -- fades between any two colours
    description = minetest.gettext("Apply a fade between 2 colours to the message."),
    params = "<colour1> <colour2> [<times>] <message>",
    func = fade,
})

minetest.register_chatcommand("custom", {  -- change colour anywhere in a message
    description = minetest.gettext("Use #<6-digits> anywhere in the message to change the colour."),
    config = "<message (with colour codes)>",
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

minetest.register_chatcommand("msg", {  -- lets you use /msg with colours
    description = minetest.gettext("Send a private message to a player. Same as using /msg, but uses the current colour style"),
    params = "<name> <message>",
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
        message = fade(colour.." "..message, modstorage:get_int("max_len")-50)
        say("/msg "..name..message)
    end,
})

minetest.register_chatcommand("say", {
    description = minetest.gettext("Send text without applying colour to it"),
    params = "<message>",
    func = function(text)
        say(text)
        return true
    end,
})
