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
    local hascomb = false
    if tkana[2] == 0x1b31e or tkana[2] == 0x1b31f then
        content[1] = content[1] .. utf8.char(tkana[2])
        hascomb = true
    end
    SILE.call("rebox", {width = 0}, function()
        SILE.call("raise", {height = SILE.measurement("1em")}, content)
    end)
    local idx = nil
    if hascomb then idx=3 else idx=2 end
    content[1] = utf8.char(tkana[idx])
    SILE.call("rebox", {width = 0}, content)
    content[1] = utf8.char(tkana[#tkana])
    if tkana[#tkana] >= 0x1B300 and tkana[#tkana] <= 0x1B31F then
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
