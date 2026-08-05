# From Chance to Decisions

*Statistics and Econometrics with R*

Source for an open textbook used in *Introduction to Statistics and
Programming* and *Econometric Methods* at Azim Premji University.

**Read it here:** https://kedarkulkarni1991.github.io/stats-econometrics-r/

Every idea is developed three times in a row — in plain words, then on paper,
then in R on the same numbers. There is no separate "R chapter". Every result
printed in the book is computed when the page is built, so the text cannot
drift away from the code.

## Building it yourself

You need R, and these packages:

```r
install.packages(c("bookdown", "rmarkdown", "knitr", "ggplot2", "BSDA"))
```

You also need pandoc. If you have RStudio you already have it, and the
`Makefile` finds it automatically.

```
make book     # render into docs/
make serve    # live preview that reloads as you edit
make data     # rebuild data/ from data/raw/
make check    # privacy check — run before publishing
make clean
```

## Layout

| Path | What it is |
|:--|:--|
| `index.Rmd` | Preface and book metadata |
| `NN-*.Rmd` | One file per chapter |
| `_bookdown.yml` | Chapter order and output directory |
| `_output.yml` | gitbook theme settings |
| `_common.R` | Shared knitr options, plot theme, teaching helpers |
| `css/style.css` | Callout boxes, collapsible solutions, typography |
| `data/` | Analysis-ready datasets — see `data/README.md` |
| `data/raw/` | The original exports, kept for provenance |
| `R/prepare-data.R` | Turns `data/raw/` into `data/` |
| `R/check-privacy.R` | Guards against identifying data being published |
| `docs/` | Rendered book. **Committed on purpose** — GitHub Pages serves it |

## A note on the data

All datasets ship with the book, so any reader can run any code block without
downloading anything.

The class survey (`data/stats-class.csv`) was collected with students' real
first names. Because this book is public, the name column was replaced with a
sequential `student_id` before anything entered this repository, `data/raw/`
included. Nothing in the book depends on the names. `make check` fails the
build if an identifying column ever reappears — run it before you publish.

## Licence

**Text, figures, exercises and datasets:**
[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) — see [LICENSE](LICENSE).
You may share and adapt this material for any purpose, including commercially,
provided you give appropriate credit.

**Code:** [MIT](LICENSE-CODE).

CC BY is the licence the open educational resources community recommends, and
what OpenStax and most institutional OER programmes use. The deliberate choice
here is *not* adding a NonCommercial clause: "commercial" is far broader than
it sounds and would block a fee-charging university from putting these
chapters in a course pack, a translator from selling a printed edition at
cost, and anyone who is unsure from using it at all. Requiring attribution and
otherwise getting out of the way spreads teaching material further.

### How to cite

> Kulkarni, K. (2026). *From Chance to Decisions: Statistics and Econometrics
> with R.* Azim Premji
> University. https://kedarkulkarni1991.github.io/stats-econometrics-r/
> Licensed under CC BY 4.0.
