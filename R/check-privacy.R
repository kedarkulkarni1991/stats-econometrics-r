## check-privacy.R -----------------------------------------------------------
##
## Run before publishing:  make check
##
## This book is public. The class survey was collected with students' real
## first names next to their age, height and gender, and those names reached
## the rendered HTML once already before being caught. This script is the guard
## against that happening again.
##
## It deliberately does NOT contain the names themselves — a checker that
## hardcodes the secret defeats the purpose. It checks structure instead.

fail <- character()

## 1. No CSV anywhere in the repo may carry a name-like column ----------------

csvs <- list.files("data", pattern = "\\.csv$", recursive = TRUE,
                   full.names = TRUE)

for (f in csvs) {
  nms <- names(utils::read.csv(f, nrows = 1, check.names = FALSE))
  hits <- nms[grepl("name|firstname|surname|student$|respondent_name",
                    nms, ignore.case = TRUE)]
  # `student_id` is the anonymised replacement and is fine.
  hits <- setdiff(hits, c("student_id"))
  if (length(hits)) {
    fail <- c(fail, sprintf("%s has identifying column(s): %s",
                            f, paste(hits, collapse = ", ")))
  }
}

## 2. The class survey must be anonymised to S01-style ids --------------------

cls <- "data/stats-class.csv"
if (file.exists(cls)) {
  d <- utils::read.csv(cls)
  if (!"student_id" %in% names(d)) {
    fail <- c(fail, "data/stats-class.csv has no student_id column")
  } else if (!all(grepl("^S[0-9]+$", d$student_id))) {
    bad <- utils::head(d$student_id[!grepl("^S[0-9]+$", d$student_id)], 3)
    fail <- c(fail, sprintf(
      "data/stats-class.csv student_id is not anonymised (e.g. %s)",
      paste(bad, collapse = ", ")))
  }
}

## 3. Nothing matching the private-file patterns may be present --------------

private <- c(list.files(".", pattern = "-(identifying|namekey)\\.csv$",
                        recursive = TRUE),
             list.files(".", pattern = "^private$", include.dirs = TRUE))
if (length(private)) {
  fail <- c(fail, sprintf("private file present in repo: %s", private))
}

## Report ---------------------------------------------------------------------

if (length(fail)) {
  cat("\nPRIVACY CHECK FAILED\n\n")
  cat(paste0("  - ", fail, collapse = "\n"), "\n\n")
  cat("Fix these before pushing. The book is public.\n\n")
  quit(status = 1)
}

cat("Privacy check passed:", length(csvs), "datasets, no identifying columns.\n")
