--[[
  Turn the book's fenced divs into LaTeX environments for the PDF edition.

  Pandoc does not do this on its own: a div with a class is simply unwrapped
  in LaTeX output, so without this filter every callout would lose its box and
  its label ("Common mistake", "Remember this") and print as ordinary prose.

  The environments themselves are defined in latex/preamble.tex.
  Any class not listed here is left alone.
--]]

local environments = {
  intuition = "intuition",
  theory    = "theory",
  inr       = "inr",
  watchout  = "watchout",
  yourturn  = "yourturn",
  keyidea   = "keyidea",
  deeper    = "deeper",
  question  = "sectionquestion",
  realworld = "realworld",
  answer    = "booksolution",
}

function Div (el)
  if not FORMAT:match("latex") then return nil end

  for _, class in ipairs(el.classes) do
    local env = environments[class]
    if env then
      local out = el.content
      table.insert(out, 1, pandoc.RawBlock("latex", "\\begin{" .. env .. "}"))
      table.insert(out, pandoc.RawBlock("latex", "\\end{" .. env .. "}"))
      return out
    end
  end

  return nil
end
