-- This should probably be upstreamed to core/settings.lua

local get = function(options, content)
  local parameter = SU.required(options, "parameter", "\\get command")
  return SILE.settings.get(options.parameter)
end

SILE.registerCommand("get", get)

-- This too, but to frame.lua

local firstContentFrame = function(_, _)
  return SILE.documentState.thisPageTemplate.firstContentFrame
end

SILE.registerCommand("first-content-frame", firstContentFrame)
