local function transformContent(content, transformFunction, extraArgs)
  local newContent = {}
  for k, v in pairs(content) do
    if type(k) == "number" then
      local transformed = transformFunction(v, content, extraArgs)
      newContent[k] = transformed
    end
  end
  return newContent
end

local function createCommand(pos, col, line, command, options, content)
  local result = { content }
  result.col = col
  result.line = line
  result.pos = pos
  result.options = options
  result.command = command
  result.id = "command"
  return result
end

return {
  exports = {
    createCommand = createCommand,
    transformContent = transformContent
  },
  documentation = [[\begin{document}
The \code{inputfilter} package provides ways for class authors to transform the
input of a SILE document after it is parsed but before it is processed. It does
this by allowing you to rewrite the abstract syntax tree representing the document.

Loading \code{inputfilter} into your class with \code{class:loadPackage("inputfilter")}
provides you with two new Lua functions: \code{transformContent} and \code{createCommand}.
\code{transformContent} takes a content tree and applies a transformation function to the
text within it. See \code{examples/inputfilter.sil} for a simple example, and
\code{packages/chordmode.sil} for a more complete one.
\end{document}
]]}