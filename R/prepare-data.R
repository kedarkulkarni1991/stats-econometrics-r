## prepare-data.R ------------------------------------------------------------
##
## Turns the raw exports in data/raw/ into the analysis-ready files in data/.
##
## Scope is deliberately narrow. This script fixes *export artifacts* only:
## empty trailing columns, blank rows, byte-order marks, column names R cannot
## use without backticks, and stray whitespace that silently splits a category
## in two.
##
## It does NOT impute, drop outliers, or fill in missing values. Those are
## judgement calls that belong in the text where students can see them argued,
## not buried in a setup script.
##
## Run from the book root:  Rscript R/prepare-data.R

raw <- function(f) file.path("data", "raw", f)

## Missing values are written as the literal string NA, not as an empty field.
##
## This matters more than it looks. An empty field in a *numeric* column is
## read back as NA, but an empty field in a *character* column is read back as
## the empty string "" — which complete.cases(), is.na() and na.rm all treat as
## a perfectly good value. A student following the book with a plain
## read.csv("data/x.csv") would silently miss those gaps.
##
## Writing "NA" means the default read.csv() behaviour is correct for every
## column type, with no extra arguments to remember.
clean <- function(d, f) {
  utils::write.csv(d, file.path("data", f), row.names = FALSE, na = "NA")
  cat(sprintf("  %-32s %4d x %2d\n", f, nrow(d), ncol(d)))
}

## Helpers --------------------------------------------------------------------

drop_empty_cols <- function(d) d[, colSums(!is.na(d) & d != "") > 0, drop = FALSE]
drop_empty_rows <- function(d) d[rowSums(!is.na(d)) > 0, , drop = FALSE]
trim_chars      <- function(d) {
  chr <- vapply(d, is.character, logical(1))
  d[chr] <- lapply(d[chr], trimws)
  d
}

cat("Writing analysis-ready data ...\n")

## 1. Attendance and grades (n = 680) -----------------------------------------
## Column names carried spaces from the spreadsheet export.
##
## The raw file reports GPA on the 4-point scale; the 100-row extract reports
## the SAME students on the 10-point scale (verified: the extract is a subset
## of these ids with GPA multiplied by exactly 2.5). The book standardises on
## the 10-point scale throughout, so the conversion happens here, once.

d <- read.csv(raw("attendance-grades.csv"), check.names = FALSE)
names(d) <- c("id", "attendance", "sem_gpa", "cum_gpa", "admission_score",
              "final_score", "year1", "year2", "classes_missed", "sex")
d$sem_gpa <- d$sem_gpa * 2.5     # 4-point -> 10-point
d$cum_gpa <- d$cum_gpa * 2.5
clean(d, "attendance-grades.csv")

## 2. Attendance and grades, 100-row extract ----------------------------------
## Three unnamed trailing columns from the spreadsheet export. One of them
## holds a single orphan value (1.352701 at row 16) that belongs to no
## variable and matches nothing else in the file — a leftover cell formula.
## All three are dropped by name, not by an "is it empty" rule, so the orphan
## is discarded knowingly rather than by accident.
##
## Already on the 10-point scale, so no conversion needed here. Column names
## are aligned with the 680-row file so the two are drop-in compatible.

d <- read.csv(raw("attendance-grades-small.csv"), check.names = FALSE)
d <- d[, names(d) != "", drop = FALSE]
names(d) <- c("id", "attendance", "sem_gpa", "cum_gpa", "admission_score",
              "final_score", "classes_missed", "sex")
clean(d, "attendance-grades-small.csv")

## 3. Class survey (n = 33) ---------------------------------------------------
## Two genuine gaps: one student did not give a gender, another left age and
## height blank. Both are KEPT — they are the worked example for missing data.
##
## PRIVACY: the survey as collected carried students' real first names next to
## their age, height and gender. Since this book is published publicly, the
## name column was replaced with a sequential `student_id` (S01-S33) before
## anything entered this repository — including data/raw/. The identifying
## version exists only on the instructor's own machine. Nothing in the book
## depends on the names.

d <- read.csv(raw("stats-class.csv"), na.strings = c("", "NA"))
names(d) <- tolower(names(d))
clean(d, "stats-class.csv")

## 4. Student survey — sleep and social media (n = 106) -----------------------
## "South India " and "South India" were being read as two separate regions,
## which silently splits every group comparison. Trimmed.

d <- read.csv(raw("student-survey-sleep.csv"))
d <- trim_chars(d)
names(d)[names(d) == "region1"] <- "region"
names(d)[names(d) == "region2"] <- "residence"
clean(d, "student-survey-sleep.csv")

## 5. Student survey — height (n = 100) ---------------------------------------

d <- trim_chars(read.csv(raw("student-survey-height.csv")))
clean(d, "student-survey-height.csv")


## 7. Beauty and wages (n = 1260) ---------------------------------------------

d <- trim_chars(read.csv(raw("beauty-wages.csv")))
clean(d, "beauty-wages.csv")

## 8. Work and sleep (n = 239) ------------------------------------------------

d <- trim_chars(read.csv(raw("leisure-labor.csv")))
clean(d, "leisure-labor.csv")

## 9. Marital happiness and income (n = 492) ----------------------------------

d <- trim_chars(read.csv(raw("marital-happiness.csv")))
clean(d, "marital-happiness.csv")

## 10. Ages of married partners (n = 10) --------------------------------------
## Hyphens in "Partner-1" force backticks in every formula. Paired-sample data.

d <- read.csv(raw("marriage-ages.csv"), check.names = FALSE)
names(d) <- c("partner1", "partner2")
clean(d, "marriage-ages.csv")

## 11. Car mileage and weight (n = 74) ----------------------------------------
## "Mileage_of_the_Car_in_km/l" contains a slash.

d <- read.csv(raw("car-mileage.csv"), check.names = FALSE)
names(d) <- c("mileage_kmpl", "weight_kg")
clean(d, "car-mileage.csv")

## 12. Housing prices (n = 142) -----------------------------------------------

clean(read.csv(raw("housing-prices.csv")), "housing-prices.csv")

## 13. Apple demand (n = 660) -------------------------------------------------

clean(read.csv(raw("apples.csv")), "apples.csv")

## 14. Campaign spending and votes (n = 173) ----------------------------------

clean(read.csv(raw("vote.csv")), "vote.csv")

## 15. Guns and murders by state (n = 51) -------------------------------------

d <- trim_chars(read.csv(raw("guns-murders.csv")))
clean(d, "guns-murders.csv")

## 16. Job training programme (n = 1130) --------------------------------------
## A byte-order mark prefixed the first column name, and the file ended with a
## blank row that read.csv turned into a row of NAs.

d <- read.csv(raw("job-training.csv"), fileEncoding = "UTF-8-BOM")
d <- drop_empty_rows(d)
clean(d, "job-training.csv")

## 17. NBA salaries (n = 269) -------------------------------------------------
## 29 missing values in `draft` are real: those players went undrafted. Kept.

clean(read.csv(raw("nba-salaries.csv")), "nba-salaries.csv")

## 18. India production function, 1981-2020 -----------------------------------

clean(read.csv(raw("india-production.csv")), "india-production.csv")

## 19. Mexico production function, 1955-1974 ----------------------------------

d <- read.csv(raw("mexico-gdp.csv"), check.names = FALSE)
names(d) <- c("year", "gdp", "employment", "capital")
clean(d, "mexico-gdp.csv")

## ---------------------------------------------------------------------------
## Indian economy data
## ---------------------------------------------------------------------------
##
## Public-source series: Annual Survey of Industries, NSS Employment-
## Unemployment, Labour Bureau CPI for agricultural labourers, ICRISAT prices.
## Assembled originally for research, reshaped here for teaching.
##
## Deliberately NOT included: the constructed analysis panels from the
## climate-terms-of-trade paper (output_shares, terms_of_trade,
## mechanism_panel, analysis_panel). That paper is under review, and this book
## is CC BY, which would let anyone reuse the panels commercially the day it
## goes up. Revisit once the paper is out.

## 20. ASI state value added, 1980-2015 ---------------------------------------
## Heavily right-skewed across states, which is the point: it is the book's
## running example of an average that conceals more than it reveals.

d <- trim_chars(read.csv(raw("asi-state-gva.csv")))
clean(d, "asi-state-gva.csv")

## 21. ASI state value added and profit ---------------------------------------

d <- trim_chars(read.csv(raw("asi-state-profit.csv")))
clean(d, "asi-state-profit.csv")

## 22. NSS employment, 1983 cross-section (31 states) -------------------------
## Small enough to regress by hand and check against lm().

d <- read.csv(raw("nss-employment-1983.csv"))
clean(d, "nss-employment-1983.csv")

## 23. CPI inflation, agricultural labourers ----------------------------------

d <- trim_chars(read.csv(raw("cpi-agri-labour.csv")))
clean(d, "cpi-agri-labour.csv")

## 24. ICRISAT agricultural price inflation -----------------------------------

d <- trim_chars(read.csv(raw("icrisat-prices.csv")))
clean(d, "icrisat-prices.csv")

## 25. Cricket toss records ---------------------------------------------------
## Team-by-team toss results across all international cricket, compiled by the
## author from public match records. Used in Unit 1 as a real-world
## demonstration of the Law of Large Numbers: the toss is a fair coin, so a
## team's toss-win percentage should scatter around 50 with a spread of
## 50/sqrt(n) percentage points.

d <- trim_chars(read.csv(raw("cricket-toss.csv")))
clean(d, "cricket-toss.csv")

cat("Done.\n")
