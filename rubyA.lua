local defaultRubyFont = { size = "0.42zw", weight = 800 }
local rubyAFont = defaultRubyFont
SILE.registerCommand("rubyA:font", function (options, _)
  if options then
    for k, v in pairs(options) do rubyAFont[k] = v end
  end
  SILE.call("font", rubyAFont)
end)

local defaultRubyHeight = SILE.measurement("1zw")
local rubyAHeight = defaultRubyHeight
SILE.registerCommand("rubyA:set", function (options, _)
  rubyAHeight = SILE.measurement(options.height)
end)

SILE.settings.declare({
    name = "rubyA.latinspacer",
    type = "glue",
    default = SILE.nodefactory.glue("0.25em"),
    help = "Glue added between consecutive Latin rubyA"
  })

local isLatin = function (char)
  return (char > 0x20 and char <= 0x24F) or (char >= 0x300 and char <= 0x36F)
    or (char >= 0x1DC0 and char <= 0x1EFF) or (char >= 0x2C60 and char <= 0x2c7F)
end

local checkIfSpacerNeeded = function (reading)
  -- First, did we have a rubyA node at all?
  if not SILE.scratch.lastRubyBox then return end
  -- Does the current reading start with a latin?
  if not isLatin(SU.codepoint(SU.firstChar(reading))) then return end
  -- Did we have some nodes recently?
  local top = #SILE.typesetter.state.nodes
  if top < 2 then return end
  -- Have we had other stuff since the last rubyA node?
  if SILE.typesetter.state.nodes[top] ~= SILE.scratch.lastRubyBox
     and SILE.typesetter.state.nodes[top-1] ~= SILE.scratch.lastRubyBox then
    return
  end
  -- Does the previous reading end with a latin?
  if not isLatin(SU.codepoint(SU.lastChar(SILE.scratch.lastRubyText))) then return end
  -- OK, we need a spacer!
  SILE.typesetter:pushGlue(SILE.settings.get("rubyA.latinspacer"))
end

SILE.registerCommand("rubyA", function (options, content)
  local reading = SU.required(options, "reading", "\\rubyA")
  SILE.typesetter:setpar("")

  checkIfSpacerNeeded(reading)

  SILE.call("hbox", {}, function ()
    SILE.settings.temporarily(function ()
      SILE.call("noindent")
      SILE.call("rubyA:font")
      SILE.doTexlike(reading)
    end)
  end)
  local rubyAbox = SILE.typesetter.state.nodes[#SILE.typesetter.state.nodes]
  rubyAbox.outputYourself = function (self, typesetter, line)
    local ox = typesetter.frame.state.cursorX
    local oy = typesetter.frame.state.cursorY
    typesetter.frame:advanceWritingDirection(rubyAbox.width)
    typesetter.frame:advancePageDirection(-rubyAHeight)
    SILE.outputter:setCursor(typesetter.frame.state.cursorX, typesetter.frame.state.cursorY)
    for i = 1, #(self.value) do
      local node = self.value[i]
      node:outputYourself(typesetter, line)
    end
    typesetter.frame.state.cursorX = ox
    typesetter.frame.state.cursorY = oy
  end
  -- measure the content
  SILE.call("hbox", {}, content)
  local cbox = SILE.typesetter.state.nodes[#SILE.typesetter.state.nodes]
  SU.debug("rubyA", "base box is " .. cbox)
  SU.debug("rubyA", "reading is  " .. rubyAbox)
  if cbox:lineContribution() > rubyAbox:lineContribution() then
    SU.debug("rubyA", "Base is longer, offsetting rubyA to fit")
    -- This is actually the offset against the base
    rubyAbox.width = SILE.length(cbox:lineContribution() - rubyAbox:lineContribution())/2
  else
    local diff = rubyAbox:lineContribution() - cbox:lineContribution()
    local to_insert = SILE.length(diff / 2)
    SU.debug("rubyA", "Ruby is longer, inserting " .. to_insert .. " either side of base")
    cbox.width = rubyAbox:lineContribution()
    rubyAbox.height = 0
    rubyAbox.width = 0
    -- add spaces at beginning and end
    --table.insert(cbox.value, 1, SILE.nodefactory.glue(to_insert))
    --table.insert(cbox.value, SILE.nodefactory.glue(to_insert))
  end
  SILE.scratch.lastRubyBox = rubyAbox
  SILE.scratch.lastRubyText = reading
end)
