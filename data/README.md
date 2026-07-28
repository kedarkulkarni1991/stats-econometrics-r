# Datasets

Nineteen datasets, all shipped with the book. A student clones or downloads
once and every code block in every chapter runs — no Moodle, no downloads, and
no `read.csv(file.choose())`.

Every chapter reads them the same way:

```r
students <- read.csv("data/stats-class.csv")
```

## Layout

- `data/*.csv` — analysis-ready files. Use these.
- `data/raw/*.csv` — your original exports, untouched, kept for provenance.
- `R/prepare-data.R` — the script that turns one into the other. Run it with
  `Rscript R/prepare-data.R` from the book root.

The prepare step fixes **export artifacts only**: empty columns, blank rows,
byte-order marks, column names R can't use without backticks, and stray
whitespace. It does not impute, drop outliers, or otherwise make decisions that
belong in the text.

## What's here, and where it goes

| File | n | Contents | Used for |
|:--|--:|:--|:--|
| `stats-class.csv` | 33 | name, age, height, gender | **First dataset in the book.** Descriptive stats, histograms, boxplots, bar charts — reproduces your `histogram-height.png`, `Boxplotheight.png`, `bar graph gender.png` |
| `attendance-grades.csv` | 680 | attendance, semester & cumulative GPA (10-point), admission score, final score, classes missed, sex | **The spine of the regression chapters.** This is the grades-on-attendance example your Simple Linear Regression notes build the PRF/SRF around |
| `attendance-grades-small.csv` | 100 | a subset of the above, same variables and scale | Hand-calculable regressions; exam questions |
| `student-survey-height.csv` | 100 | region, residence, age, household size, height | Two-sample tests (North vs South, Urban vs Rural), sampling |
| `student-survey-sleep.csv` | 106 | region, residence, age, social media hours, sleep, household size | Correlation, two-sample tests, multiple regression |
| `marriage-ages.csv` | 10 | ages of both partners in 10 couples | **Paired-sample t-test** — the one design a two-sample test gets wrong |
| `wages-india-synthetic.csv` | 20,000 | annual earnings, education, age, religion, sex, urban/rural | **Simulated, calibrated to real IHDS-II estimates — see below.** Wage regressions, dummy variables, log-linear form, discrimination |
| `beauty-wages.csv` | 1260 | log wage, experience, gender, city size, relationship | Multiple regression, interaction terms, functional form |
| `leisure-labor.csv` | 239 | total work, sleep hours, gender, relationship, health | The work–sleep tradeoff; two-sample tests; controls |
| `marital-happiness.csv` | 492 | age, marital happiness, gender, income | Categorical predictors, ordered outcomes |
| `car-mileage.csv` | 74 | mileage (km/l), weight (kg) | Simple linear regression with an obvious negative slope; the cleanest first regression in the book |
| `housing-prices.csv` | 142 | price, rooms, area, land, baths, distance, highway (+ logs) | Multiple regression, log-log and log-level forms, elasticities |
| `apples.csv` | 660 | regular vs eco apple prices, quantities, income, education | Demand estimation; willingness to pay |
| `vote.csv` | 173 | vote share, campaign spending by both candidates, party strength | Log specifications; the classic spending-and-votes regression |
| `guns-murders.csv` | 51 | state, region, population, murders, south | Dummy variables; regional comparisons; per-capita transformations |
| `job-training.csv` | 1130 | training assignment, age, education, race, earnings 1996 & 1998 | **Causal inference.** Treatment effects, before/after, IV |
| `nba-salaries.csv` | 269 | salary, experience, points, position, draft, race, +14 more | Multiple regression, functional forms, quadratics (`expersq`) |
| `india-production.csv` | 40 | 1981–2020: output, labour, capital (+ logs and ratios) | **Cobb–Douglas production function.** Log-log regression, returns to scale, F-tests of restrictions |
| `mexico-gdp.csv` | 20 | 1955–1974: GDP, employment, fixed capital | Second Cobb–Douglas example; small-sample inference |

## What I changed, and why

| File | Change |
|:--|:--|
| `attendance-grades.csv` | Column names had spaces (`Semester GPA`, `No of Classes Missed`). Renamed to `sem_gpa`, `classes_missed`, etc. **GPA converted from the 4-point to the 10-point scale (× 2.5)** so the whole book runs on one scale. |
| `attendance-grades-small.csv` | Column names aligned with the 680-row file so the two are drop-in compatible. Already on the 10-point scale. |
| `attendance-grades-small.csv` | Three unnamed trailing columns dropped. One held a single orphan value (`1.352701` at row 16) belonging to no variable — a leftover cell formula. Dropped knowingly; flagging it here rather than deleting it silently. |
| `student-survey-sleep.csv` | **`"South India "` and `"South India"` were being read as two different regions**, which silently splits every group comparison in two. Whitespace trimmed. `region1`/`region2` renamed to `region`/`residence`. |
| `job-training.csv` | A byte-order mark was prefixed to the first column name, so `d$train` returned `NULL`. Also a trailing blank row that became a row of `NA`s. Both fixed. |
| `marriage-ages.csv` | `Partner-1` → `partner1`. Hyphens force backticks in every formula. |
| `car-mileage.csv` | `Mileage_of_the_Car_in_km/l` → `mileage_kmpl`. |
| `mexico-gdp.csv` | `Fixed Capital` → `capital`. |
| several | Trailing whitespace trimmed from text columns. |

## What I deliberately left alone

**Missing values are kept.** `stats-class.csv` has one student with no gender
and another with no age or height. `nba-salaries.csv` has 29 players with no
draft position — because they went undrafted. These are the worked examples for
handling missing data; imputing them away in a setup script would delete the
lesson.

**Outliers are kept, and taught.** `student-survey-sleep.csv` has respondents
aged 82, 52 and 49 in what is otherwise an 18-year-old cohort, and
`student-survey-height.csv` has a height of 135 cm. These are almost certainly
data-entry errors.

They stay in, and the descriptive-statistics chapter uses them as its worked
example: compute the mean age of the sleep survey, notice it is nearly a year
above the median, find the 82-year-old, and decide what to do. A student who
has seen one outlier drag a mean around will check for them ever after; a
student handed pre-cleaned data never learns that they exist.

## Withdrawn: the wage dataset

`wages.csv` has been removed pending a replacement. It was not what it claimed
to be.

It was **Wooldridge's `wage1` — US Census data from 1976 — relabelled**.
`education` and `experience` were byte-identical to `educ` and `exper`;
`gender` and `marital_status` matched `female` and `married` exactly; salary
was `wage` multiplied by a constant. And the US variable **`nonwhite` had been
relabelled `caste`**, with `nonwhite == 1` becoming "Lower Caste".

A student regressing log salary on caste in that file and reporting "the caste
wage gap in India" would in fact have measured the Black–white wage gap in
1976 America. In a public textbook from an Indian university, that is a false
claim about Indian society, not a harmless teaching shortcut.

The file is recoverable from git history, and is in any case just
`wooldridge::wage1`.

### Why IHDS is not the replacement

The obvious substitute is IHDS, and it fails on two independent counts:

1. **Redistribution is prohibited.** IHDS is distributed through ICPSR under a
   data use agreement that forbids redistributing the data or derived extracts
   without written permission. Publishing an extract in this repository would
   breach the agreement personally signed by whoever downloaded it.
2. **The caste variable is masked anyway.** In the public-use file, both
   `GROUPS` and `ID13` are 100% `MASKED BY ICPSR` — 79,956 of 80,036
   households, with zero usable values. The caste analysis cannot be done with
   the public file at all, redistribution question aside.

## The replacement: `wages-india-synthetic.csv`

The book ships a **simulated** dataset calibrated to real IHDS-II (2011–12)
estimates, plus the script that produces the real ones.

**Why simulated.** The estimates below are genuine, from 44,361 wage earners
aged 18–65 in IHDS-II. Regression coefficients and group means are research
output — the thing every paper using IHDS publishes — and reproducing them in
a simulation redistributes no microdata. The microdata itself cannot ship.

**Why religion and not caste.** Caste would be the better variable, and it is
unusable: both `GROUPS` and `ID13` are 100% masked in the public-use file.
Religion is fully observed. Using it is a real limitation of the public data,
not a modelling preference, and the book says so.

### How faithful is it?

`R/make-wages-synthetic.R` checks itself on every run:

| Term | Real IHDS-II | Simulated | Difference |
|:--|--:|--:|--:|
| Year of education | 0.0734 | 0.0753 | +0.0020 |
| Female | −0.7789 | −0.7690 | +0.0098 |
| Urban | 0.8049 | 0.8084 | +0.0035 |
| Muslim vs Hindu | 0.1063 | 0.1049 | −0.0015 |
| Christian vs Hindu | 0.3940 | 0.4195 | +0.0255 |
| Tribal vs Hindu | 0.3141 | 0.3184 | +0.0043 |
| Education mean / sd | 5.80 / 4.97 | 5.71 / 4.97 | — |
| R² | 0.347 | 0.324 | −0.023 |

A student estimating the return to a year of schooling gets ≈7.5%, which is
the real figure. The gender gap and urban premium are likewise right. R² runs
slightly low because the simulation does not reproduce every correlation among
the covariates.

### Getting the real numbers

`R/ihds-wages-real.R` runs the identical analysis against genuine IHDS. Edit
`IHDS_PATH`, and it prints both the full regression and every calibration
target above so the simulation can be audited. IHDS-II is
[ICPSR study 36151](https://www.icpsr.umich.edu/web/DSDR/studies/36151);
registration is free.

**Do not commit IHDS files to this repository.** `data/raw/` is tracked.
`private/` is git-ignored if you need somewhere local.

### What the book must say

Wherever this dataset appears, the text has to state plainly that it is
simulated and cite the IHDS estimates it reproduces. Students may absolutely
learn regression mechanics on simulated data; they may not be led to believe
they have measured something about India when they have not. That distinction
is exactly what went wrong with the dataset this one replaces.

## Settled decisions

- **GPA is on the 10-point scale everywhere.** The 680-row file is converted at
  prepare time; the 100-row extract already was.
- **The 82-year-old stays**, as a data-quality lesson in the descriptive
  statistics chapter.
