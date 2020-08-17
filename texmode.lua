-- LaTeX ligatures in SILE.
-- Original author: Fredrick R. Brennan (@ctrlcctrlv)
-- Note: This script relies on PR #940 and won't work in SILE <= 0.10.5.

-- This list is quite complete. See unicoder.lua
-- Thank you Cumhur "Joomy" Korkut 🥰
local symbols = require("unicoder")
local combining = {}
local simple_symbols = {}

local TEXLIKECC = function(command, char, name)
    combining[command] = char
end

local TEXLIKESYM = function(command, char, name)
    simple_symbols[command] = char
end

-- To be used by texmode(...)
local define_symbols = function()
    for n, s in pairs(symbols) do
        if not string.match(n, '^[%\\%_%^]') then
            goto continue
        end
        if string.match(n, '^\\') then
            TEXLIKESYM(n:gsub('^\\', ''), utf8.codepoint(s), string.format("U+%08x (%s)", utf8.codepoint(s), s))
            goto continue
        end
        ::continue::
    end
end

-- Accents from https://mirrors.concertpass.com/tex-archive/info/symbols/comprehensive/symbols-a4.pdf , p20 (table 18)
local define_combining_characters = function()
    -- A macro, sorta, thus, capitals. :-)
    TEXLIKECC('"', 0x0308, "Dieresis")
    TEXLIKECC("'", 0x0301, "Acute")
    TEXLIKECC('.', 0x0307, "Dot above")
    TEXLIKECC('=', 0x0304, "Macron")
    TEXLIKECC('^', 0x0302, "Circumflex")
    TEXLIKECC('`', 0x0300, "Grave")
    TEXLIKECC('|', 0x030D, "Vertical line above")
    -- Easter egg, e.g. for old-Spanish style Tagalog orthography
    TEXLIKECC('~~', 0x0360, "Double tilde")
    TEXLIKECC('~', 0x0303, "Tilde")
    TEXLIKECC('b', 0x0331, "Macron below")
    TEXLIKECC('c', 0x0327, "Cedilla")
    -- Why are there two of these ??
    TEXLIKECC('C', 0x030F, "Double grave")
    --------------------------------
    TEXLIKECC('d', 0x0323, "Dot below")
    TEXLIKECC('f', 0x0311, "Inverted breve")
    -- Why are there two of these ??
    TEXLIKECC('G', 0x030F, "Double grave")
    --------------------------------
    TEXLIKECC('h', 0x0309, "Hook above")
    TEXLIKECC('H', 0x030B, "Hungarumlaut")
    TEXLIKECC('k', 0x0328, "Ogonek")
    TEXLIKECC('r', 0x0351, "Ring above")
    TEXLIKECC('t', 0x0361, "Tie above")
    TEXLIKECC('u', 0x0306, "Breve")
    TEXLIKECC('U', 0x030E, "Double vertical line above")
    TEXLIKECC('v', 0x030C, "Háček")
end

local inputfilter = SILE.require("inputfilter").exports
-- not done elsewhere so it doesn't mess up arguments to other commands
local function dblquotes(options, content) 
    if type(content) ~= "string" then return content end
    return content:gsub('%"', '”')
end -- "Handle double quotes"

local function texmode(options, content)
    local input = options._
    if not input or type(input) ~= "string" then
        SU.warn("You're holding it wrong, please read texmode documentation")
        return
    end
    if not options.nosymbols then define_symbols() end
    if not options.nocombine then define_combining_characters() end
    input = input 
                  :gsub(       "([^\x5c])%-%-%-%-%-%-", '%1⸺')
                  :gsub(       "([^\x5c])%-%-%-"      , '%1—')
                  :gsub(       "([^\x5c])%-%-"        , '%1–')
                  :gsub(       "([^\x5c])%?%`"        , '%1¿')
                  :gsub(       "([^\x5c])%!%`"        , '%1¡')
                  :gsub(       "([^\x5c])%'%'"        , '%1”')
                --:gsub(       "([^\x5c])%\""         , '%1”') -- see comment @ function dblquotes
                  :gsub(       "([^\x5c])%`%`"        , '%1“')
                  :gsub(       "([^\x5c])%`"          , '%1‘')
                  :gsub(       "([^\x5c])%'"          , '%1’')
                  :gsub(       "([^\x5c])%<%<"        , '%1«')
                  :gsub(       "([^\x5c])%>%>"        , '%1»')
                  :gsub(       "([^\x5c])%,%,"        , '%1„')
                  :gsub(       "([^\x5c])%<"          , '%1‹')
                  :gsub(       "([^\x5c])%>"          , '%1›')
    local output = ''
    local utf8l = 1
    local bytel = 1
    local maxslen = 0
    local maxclen = 0
    for k, v in pairs(simple_symbols) do
        if string.len(k) > maxslen then maxslen = string.len(k) end
    end
    for k, v in pairs(combining) do
        if string.len(k) > maxclen then maxclen = string.len(k) end
    end
    local skip = 0
    -- below line from https://stackoverflow.com/a/13238257 by @prapin
    for code in input:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        local smatched = nil
        local cmatched = nil
        local carg = nil
        local j = 0
        if skip > 0 then
            goto continue2
        end

        if code == '\\' or code == '_' or code == '^' then
            for jj=maxslen,1,-1 do
                smatched = simple_symbols[string.sub(input, bytel+1, bytel+jj)] 
                if smatched then
                    if string.sub(input, bytel+jj+1, bytel+jj+1):match('[a-zA-Z0-9]') then 
                        smatched = nil
                    end
                    j=jj; break
                end
            end
        end

        if smatched then
            SU.debug("texmode", string.format("Matched %s, skipped %d", utf8.char(smatched), j))
            output = output .. utf8.char(smatched)
            skip = j
            goto continue2
        end

        if code ~= '\\' then goto continue2 end

        for jj=maxslen,1,-1 do
            cmatched = combining[string.sub(input, bytel+1, bytel+jj)]
            if cmatched then
                carg = string.sub(input, bytel+jj+1):match("^%{[%z\1-\127\194-\244][\128-\191]-%}")
                j = jj
                if carg then
                    carg = carg:match("^%{([%z\1-\127\194-\244][\128-\191]-)%}")
                    SU.debug("texmode", string.format("Matched combining %s, got arg %s", string.sub(input, bytel+1, bytel+jj), carg))
                    skip = jj+3
                    break
                else
                    cmatched = nil
                end
            end
        end

        if cmatched and carg then
            output = output .. carg
            output = output .. utf8.char(cmatched)
        end

        ::continue2::
        if not cmatched and not smatched and skip < 0 then output = output .. code end
        skip = skip -1
        utf8l = utf8l + 1
        bytel = bytel + string.len(code)
    end
    SU.debug("texmode", "Output was \n", output)
    SILE.doTexlike(output)
end

SILE.registerCommand("texmode", texmode, "Enable standard LaTeX ligatures in the environment")

SILE.registerCommand("notexliga", function(_, content)
    SILE.process(content) 
end, "Disable standard LaTeX ligatures for whatever is inside this")

local newline = function(_, content)
  SILE.settings.temporarily(function()
    SILE.settings.set("typesetter.parseppattern", "\n")
    SILE.doTexlike(" \n\\skip[height=0em]")
  end)
end

SILE.registerCommand("newline", newline)
SILE.registerCommand("\\", newline)
