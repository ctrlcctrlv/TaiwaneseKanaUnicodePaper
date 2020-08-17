SILE.baseClass:loadPackage("rules")
SILE.baseClass:loadPackage("rebox")
SILE.baseClass:loadPackage("raiselower")
SILE.baseClass:loadPackage("color")

SILE.registerCommand("strike", function(options, content)
    -- next 2 lines from float in frametricks.lua
    local hbox = SILE.call("hbox", {}, content)
    table.remove(SILE.typesetter.state.nodes) -- steal it back

    SILE.call("rebox", {width = 0}, content)
    local first = options.raise or SILE.parseComplexFrameDimension("2zw")
    local i = 0
    local height = options.height or SILE.parseComplexFrameDimension("1.5zw")

    if options.n and options.n == "triple" then
        i = 2
        first = options.raise or SILE.parseComplexFrameDimension("1.5zw")
    elseif options.n and options.n == "double" then
        i = 1
    end

    if i > 0 and not options.height then
        height = SILE.parseComplexFrameDimension("1.0zw")
    end

    if options.color then
        SU.dump(options)
        SILE.call("color", {color = options.color})
    end

    for _ = 0, i, 1 do
        SILE.call("rebox", {width = 0}, function()
            SILE.call("raise", {height = first}, function()
                SILE.call("color", {color = options.color or "black"}, function()
                    SILE.call("hrule", {width = hbox.width, height = height})
                end)
            end)
        end)
        first = first + SILE.parseComplexFrameDimension("2zw")
    end
    SILE.call("glue", {width = hbox.width})
end, "Strikethrough text")
