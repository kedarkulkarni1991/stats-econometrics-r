-- Turn the book's fenced divs into the LaTeX environments defined in
-- preamble.tex. Pandoc drops unrecognised Divs in LaTeX output, so without
-- this every callout in the book would silently vanish from the PDF.
-- Div class -> LaTeX environment. Mostly identity, but `solution` is renamed
-- because \solution is already taken by one of the loaded packages.
local known = {
  intuition = "intuition", watchout = "watchout", keyidea  = "keyidea",
  theory    = "theory",    inr      = "inr",      yourturn = "yourturn",
  solution  = "booksolution"
}

function Div(el)
  for _, class in ipairs(el.classes) do
    local env = known[class]
    if env then
      return {
        pandoc.RawBlock("latex", "\\begin{" .. env .. "}"),
        el,
        pandoc.RawBlock("latex", "\\end{" .. env .. "}")
      }
    end
  end
end
