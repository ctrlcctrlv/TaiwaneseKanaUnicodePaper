local defaultRubyFont = { size = "0.6zw", weight = 800 }
local rubyBFont = defaultRubyFont
SILE.registerCommand("rubyB:font", function (options, _)
  if options then
    for k, v in pairs(options) do rubyBFont[k] = v end
  end
  SILE.call("font", rubyBFont)
end)

local defaultRubyHeight = SILE.measurement("1zw")
local rubyBHeight = defaultRubyHeight
SILE.registerCommand("rubyB:set", function (options, _)
  rubyBHeight = SILE.measurement(options.height)
end)

SILE.settings.declare({
    name = "rubyB.latinspacer",
    type = "glue",
    default = SILE.nodefactory.glue("0.25em"),
    help = "Glue added between consecutive Latin rubyB"
  })

local isLatin = function (char)
  return (char > 0x20 and char <= 0x24F) or (char >= 0x300 and char <= 0x36F)
    or (char >= 0x1DC0 and char <= 0x1EFF) or (char >= 0x2C60 and char <= 0x2c7F)
end

local checkIfSpacerNeeded = function (reading)
  -- First, did we have a rubyB node at all?
  if not SILE.scratch.lastRubyBox then return end
  -- Does the current reading start with a latin?
  if not isLatin(SU.codepoint(SU.firstChar(reading))) then return end
  -- Did we have some nodes recently?
  local top = #SILE.typesetter.state.nodes
  if top < 2 then return end
  -- Have we had other stuff since the last rubyB node?
  if SILE.typesetter.state.nodes[top] ~= SILE.scratch.lastRubyBox
     and SILE.typesetter.state.nodes[top-1] ~= SILE.scratch.lastRubyBox then
    return
  end
  -- Does the previous reading end with a latin?
  if not isLatin(SU.codepoint(SU.lastChar(SILE.scratch.lastRubyText))) then return end
  -- OK, we need a spacer!
  SILE.typesetter:pushGlue(SILE.settings.get("rubyB.latinspacer"))
end

SILE.registerCommand("rubyB", function (options, content)
  local reading = SU.required(options, "reading", "\\rubyB")
  SILE.typesetter:setpar("")

  checkIfSpacerNeeded(reading)

  SILE.call("hbox", {}, function ()
    SILE.settings.temporarily(function ()
      SILE.call("noindent")
      SILE.call("rubyB:font")
      SILE.typesetter:typeset(reading)
    end)
  end)
  local rubyBbox = SILE.typesetter.state.nodes[#SILE.typesetter.state.nodes]
  rubyBbox.outputYourself = function (self, typesetter, line)
    local ox = typesetter.frame.state.cursorX
    local oy = typesetter.frame.state.cursorY
    typesetter.frame:advanceWritingDirection(rubyBbox.width)
    typesetter.frame:advancePageDirection(-rubyBHeight)
    SILE.outputter:moveTo(typesetter.frame.state.cursorX, typesetter.frame.state.cursorY)
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
  SU.debug("rubyB", "base box is " .. cbox)
  SU.debug("rubyB", "reading is  " .. rubyBbox)
  if cbox:lineContribution() > rubyBbox:lineContribution() then
    SU.debug("rubyB", "Base is longer, offsetting rubyB to fit")
    -- This is actually the offset against the base
    rubyBbox.width = SILE.length(cbox:lineContribution() - rubyBbox:lineContribution())/2
  else
    local diff = rubyBbox:lineContribution() - cbox:lineContribution()
    local to_insert = SILE.length(diff / 2)
    SU.debug("rubyB", "Ruby is longer, inserting " .. to_insert .. " either side of base")
    cbox.width = rubyBbox:lineContribution()
    rubyBbox.height = 0
    rubyBbox.width = 0
    -- add spaces at beginning and end
    --table.insert(cbox.value, 1, SILE.nodefactory.glue(to_insert))
    --table.insert(cbox.value, SILE.nodefactory.glue(to_insert))
  end
  SILE.scratch.lastRubyBox = rubyBbox
  SILE.scratch.lastRubyText = reading
end)
