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
| `wages.csv` | 526 | monthly salary, education, experience, caste, gender, marital status | Wage regressions, dummy variables, discrimination, log-linear form |
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

## Settled decisions

- **GPA is on the 10-point scale everywhere.** The 680-row file is converted at
  prepare time; the 100-row extract already was.
- **The 82-year-old stays**, as a data-quality lesson in the descriptive
  statistics chapter.
