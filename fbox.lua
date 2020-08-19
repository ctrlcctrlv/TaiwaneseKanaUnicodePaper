local evalstatements = {}

local multiEval = function(loadme)
  evalstatements[#evalstatements+1] = loadme
end

local eval = function(evalme, typesetme, imatree)
  if not evalme then
    evalme = table.concat(evalstatements, "\n")
  end
  if not typesetme then
    evalme = "{" .. evalme .. "}"
  end
  local tree
  if not imatree then
    tree = SILE.inputs.TeXlike.docToTree(evalme)
  else
    tree = evalme
  end
  SILE.process(tree)
  -- SU.dump(tree) -- for debugging
end

local fboxid = 0
local fbox = function(options, content)
  SU.dump(options)
  local framefunc = options.framefunc or "\\frame"
  --local x = SILE.typesetter.frame.state.cursorX:tonumber()
  local x = options.x and SILE.parseComplexFrameDimension(options.x) or SILE.parseComplexFrameDimension("2zw") + SILE.typesetter.frame:width():tonumber() / 2
  local y = options.y and SILE.parseComplexFrameDimension(options.y) or SILE.typesetter.frame.state.cursorY:tonumber() + SILE.pagebuilder:collateVboxes(SILE.typesetter.state.outputQueue).height:tonumber()
  multiEval("\\begin[first-content-frame=content]{pagetemplate}")
  local warnbefore = SU.warn
  SU.warn = function() end -- lol
  if not SILE.getFrame("twilightzone") then
    multiEval("\\frame[id=twilightzone]")
  end
  SU.warn = warnbefore
  -- print(x);print(y)
  multiEval(string.format("%s[next=twilightzone,top=%d,left=%d,id=fbox%d,height=height(page)%s]", framefunc, y, x, fboxid,options.width and (',width='..options.width) or ",width=2zw"))
  multiEval("\\end{pagetemplate}\n")
  -- print(table.concat(evalstatements,"\n")) -- for debugging
  eval()
  eval(SILE.inputs.TeXlike.docToTree("{\\"..string.format("typeset-into[frame=fbox%d]{%s}", fboxid, options._).."}"), true, true)
  fboxid=fboxid+1
  -- SU.dump(content)
end, "\\fbox - a frame, right here, that the frame you're in won't write over."
SILE.registerCommand("fbox", fbox)

local fhbox = function(options, content)
  eval(SILE.inputs.TeXlike.docToTree(string.format("{\\hbox{%s}", content[1]:gsub("𗂧","}"):gsub("𗂦","{"):gsub("𗂥","\\")).."}"), true, true)
  local rubybox = SILE.typesetter.state.nodes[#SILE.typesetter.state.nodes]
  SILE.typesetter.frame:advanceWritingDirection(-rubybox.width)
end, "floating \\hbox"
SILE.registerCommand("fhbox", fhbox)
