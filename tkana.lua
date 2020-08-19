SILE.baseClass:loadPackage("rebox")
SILE.baseClass:loadPackage("raiselower")

SILE.registerCommand("tkanav", function(options, content)
    SILE.settings.temporarily(function()

    SILE.call("font", {size= "0.5em", filename= "./FRBTaiwaneseKana.otf", features="+ruby"})
    local i = 0
    local tkana = {}
    SU.dump(content)
    for p, c in utf8.codes(content[1]) do
        i = i + 1
        tkana[i] = c
    end

    content[1] = utf8.char(tkana[1])
    local hascomb, hascomb2 = false
    if tkana[2] == 0x0323 or tkana[2] == 0x0305 then
        content[1] = content[1] .. utf8.char(tkana[2])
        hascomb = true
    end
    if tkana[3] == 0x0323 or tkana[3] == 0x0305 then
        content[1] = content[1] .. utf8.char(tkana[3])
        hascomb2 = true
    end
    SILE.call("rebox", {width = 0}, function()
        SILE.call("raise", {height = SILE.measurement("1em")}, content)
    end)
    local idx = nil
    local lower = SILE.measurement(0)
    if hascomb2 then idx=4 else if hascomb then idx=3 else idx=2 end end
    if idx+1 < #tkana then
        SILE.call("rebox", {width = 0}, function() SILE.call("raise", {height = SILE.measurement("0.6ex")}, {utf8.char(tkana[idx])}) end)
        lower = SILE.measurement("1.0ex")
        content[1] = utf8.char(tkana[idx+1])
    elseif (tkana[#tkana] <= 0x1BA00 or tkana[#tkana] >= 0x1BA0F) then
        SILE.call("rebox", {width = 0}, function() SILE.call("raise", {height = SILE.measurement("0.6ex")}, {utf8.char(tkana[idx])}) end)
        lower = SILE.measurement("1.0ex")
        content[1] = utf8.char(tkana[#tkana])
    else
        content[1] = utf8.char(tkana[idx])
    end
    SILE.call("rebox", {width = 0}, function() SILE.call("lower", {height = lower}, content) end)
    content[1] = utf8.char(tkana[#tkana])
    if tkana[#tkana] >= 0x1BA00 and tkana[#tkana] <= 0x1BA0F then
        SILE.call("font", {size= "1.2em"})
        local hbox = nil
        SILE.call("rebox", {width = 0}, function()
            SILE.call("glue", {width = SILE.measurement("0.8em")})
            SILE.call("raise", {height = SILE.measurement("0.33em")}, function()
                hbox = SILE.call("hbox", {}, content)
            end)
        end)
        SILE.call("glue", {width = SILE.measurement("0.8em"):absolute()+hbox.width})
    else
        SILE.call("glue", {width = SILE.measurement("1em")})
    end
    end)
end, "Taiwanese kana vertical")
