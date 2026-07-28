# Build the book.
#
# Needs R with: bookdown, rmarkdown, knitr, ggplot2, BSDA
#
# pandoc is required too. If it is not on your PATH we fall back to the copy
# bundled inside RStudio, which is why this works on a Mac with RStudio
# installed and nothing else. On CI pandoc is on the PATH, so the fallback is
# skipped and this same file works there unchanged.

RSTUDIO_PANDOC_MAC := /Applications/RStudio.app/Contents/Resources/app/quarto/bin/tools/aarch64
ifeq ($(shell command -v pandoc 2>/dev/null),)
  ifneq ($(wildcard $(RSTUDIO_PANDOC_MAC)/pandoc),)
    export RSTUDIO_PANDOC := $(RSTUDIO_PANDOC_MAC)
  endif
endif

.PHONY: book serve data check clean

## Render the book into docs/
book:
	Rscript -e 'bookdown::render_book("index.Rmd", "bookdown::gitbook")'
	@touch docs/.nojekyll

## Live preview that reloads as you edit
serve:
	Rscript -e 'bookdown::serve_book(dir = ".", output_dir = "docs", preview = TRUE)'

## Rebuild data/ from data/raw/, and regenerate the simulated wage dataset
data:
	Rscript R/prepare-data.R
	@Rscript R/make-wages-synthetic.R

## Fail if identifying student data has crept back in. Run before publishing.
check:
	@Rscript R/check-privacy.R

clean:
	rm -rf docs _bookdown_files *_files *.knit.md *.utf8.md
