rocal eval = function(evalme

local fboxid = 0
local fbox = function(options, content)
  local framefunc = options.framefunc or "\\frame"
  SILE.call("begin",    {["first-content-frame"]="twilightzone"}, "pagetemplate")
  SILE.call("frame",    {id="twilightzone"})
  SILE.call("end", {},  "pagetemplate")
  SILE.call("typeset-into", {"frame", options.frameid or string.format("fbox%d", fboxid)})
  fboxid=fboxid+1
end, "\\fbox - a frame, right here, that the frame you're in won't write over."

SILE.registerCommand("fbox", fbox)
