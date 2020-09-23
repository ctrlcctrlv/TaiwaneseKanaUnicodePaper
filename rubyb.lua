SILE.registerCommand("rubyb:font", function (_, _)
  SILE.call("font", { size = "0.4zw", weight = 800 })
end)

SILE.settings.declare({
    name = "rubyb.height",
    type = "measurement",
    default = SILE.measurement("1zw"),
    help = "Vertical offset between the rubyb and the main text"
  })

SILE.settings.declare({
    name = "rubyb.latinspacer",
    type = "glue",
    default = SILE.nodefactory.glue("0.25em"),
    help = "Glue added between consecutive Latin rubyb"
  })

local isLatin = function (char)
  return (char > 0x20 and char <= 0x24F) or (char >= 0x300 and char <= 0x36F)
    or (char >= 0x1DC0 and char <= 0x1EFF) or (char >= 0x2C60 and char <= 0x2c7F)
end

local checkIfSpacerNeeded = function (reading)
  -- First, did we have a rubyb node at all?
  if not SILE.scratch.lastRubyBox then return end
  -- Does the current reading start with a latin?
  if not isLatin(SU.codepoint(SU.firstChar(reading))) then return end
  -- Did we have some nodes recently?
  local top = #SILE.typesetter.state.nodes
  if top < 2 then return end
  -- Have we had other stuff since the last rubyb node?
  if SILE.typesetter.state.nodes[top] ~= SILE.scratch.lastRubyBox
     and SILE.typesetter.state.nodes[top-1] ~= SILE.scratch.lastRubyBox then
    return
  end
  -- Does the previous reading end with a latin?
  if not isLatin(SU.codepoint(SU.lastChar(SILE.scratch.lastRubyText))) then return end
  -- OK, we need a spacer!
  --SILE.typesetter:pushGlue(SILE.settings.get("rubyb.latinspacer"))
end

SILE.registerCommand("rubyb", function (options, content)
  local reading = SU.required(options, "reading", "\\rubyb")
  SILE.typesetter:setpar("")

  checkIfSpacerNeeded(reading)

  SILE.call("hbox", {}, function ()
    SILE.settings.temporarily(function ()
      SILE.call("noindent")
      SILE.call("rubyb:font")
      SILE.typesetter:typeset(reading)
    end)
  end)
  local rubybbox = SILE.typesetter.state.nodes[#SILE.typesetter.state.nodes]
  rubybbox.outputYourself = function (self, typesetter, line)
    local ox = typesetter.frame.state.cursorX
    local oy = typesetter.frame.state.cursorY
    typesetter.frame:advanceWritingDirection(rubybbox.width)
    typesetter.frame:advancePageDirection(-SILE.settings.get("rubyb.height"))
    SILE.outputter.setCursor(typesetter.frame.state.cursorX, typesetter.frame.state.cursorY)
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
  SU.debug("rubyb", "base box is " .. cbox)
  SU.debug("rubyb", "reading is  " .. rubybbox)
  if cbox:lineContribution() > rubybbox:lineContribution() then
    SU.debug("rubyb", "Base is longer, offsetting rubyb to fit")
    -- This is actually the offset against the base
    rubybbox.width = SILE.length(cbox:lineContribution() - rubybbox:lineContribution())/2
  else
    local diff = rubybbox:lineContribution() - cbox:lineContribution()
    local to_insert = SILE.length(diff / 2)
    SU.debug("rubyb", "Ruby is longer, inserting " .. to_insert .. " either side of base")
    cbox.width = rubybbox:lineContribution()
    rubybbox.height = 0
    rubybbox.width = 0
    -- add spaces at beginning and end
    --table.insert(cbox.value, 1, SILE.nodefactory.glue(to_insert))
    --table.insert(cbox.value, SILE.nodefactory.glue(to_insert))
  end
  SILE.scratch.lastRubyBox = rubybbox
  SILE.scratch.lastRubyText = reading
end)
