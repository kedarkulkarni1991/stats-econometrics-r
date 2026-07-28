## ihds-wages-real.R ----------------------------------------------------------
##
## The real version of the wage analysis, against genuine IHDS-II microdata.
##
## The book ships a simulated dataset (data/wages-india-synthetic.csv, built by
## R/make-wages-synthetic.R) because IHDS cannot be redistributed. This script
## is the other half of that arrangement: if you have IHDS access, run it and
## you will get the true figures, which is what the simulation was calibrated
## against.
##
## GETTING THE DATA
##
## IHDS-II (2011-12) is distributed by ICPSR as study 36151:
##   https://www.icpsr.umich.edu/web/DSDR/studies/36151
##
## Registration is free. Download the Stata version and point IHDS_PATH below
## at the individual-level file.
##
## Note that ICPSR's terms forbid redistributing the data or extracts derived
## from it. That is why this repository contains this script and not the data.
## Please do not commit IHDS files here — data/raw/ is tracked, and `private/`
## is git-ignored if you need somewhere local to put them.
##
## WHY RELIGION AND NOT CASTE
##
## Caste would be the more natural variable for an Indian discrimination
## example, and it cannot be used: in the public-use file both `GROUPS` and
## `ID13` are 100% MASKED BY ICPSR — 79,956 of 80,036 households, no usable
## values at all. Caste requires the restricted-use file and a separate
## agreement. Religion is fully observed, so the book uses that.

IHDS_PATH <- "~/data/ihds/Individual.dta"   # <- edit this

suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
})

if (!file.exists(path.expand(IHDS_PATH))) {
  stop("IHDS not found at ", IHDS_PATH,
       "\nSee the header of this file for where to obtain it.")
}

## Build the analysis sample --------------------------------------------------
##
## Wave 2 only, wage earners aged 18-65 with positive earnings and observed
## education. Religion codes above 7 ("Others", "None") are dropped as they are
## too sparse to estimate.

ihds <- read_dta(path.expand(IHDS_PATH),
                 col_select = c(SURVEY, ID11, RO3, RO5, ED6, WSEARN, URBAN)) |>
  filter(
    as.numeric(SURVEY) == 2,
    !is.na(WSEARN), WSEARN > 0,
    RO5 >= 18, RO5 <= 65,
    !is.na(ED6), !is.na(ID11), ID11 <= 7
  )

wages <- data.frame(
  annual_earnings = as.numeric(ihds$WSEARN),
  education       = as.numeric(ihds$ED6),
  age             = as.numeric(ihds$RO5),
  religion        = sub(" [0-9]+$", "", as.character(as_factor(ihds$ID11))),
  sex             = ifelse(as.numeric(ihds$RO3) == 2, "Female", "Male"),
  residence       = ifelse(as.numeric(ihds$URBAN) == 1, "Urban", "Rural"),
  stringsAsFactors = FALSE
)
wages$religion <- relevel(factor(wages$religion), ref = "Hindu")

cat("IHDS-II wage earners aged 18-65:", nrow(wages), "\n\n")

## The same model the book fits to the synthetic data ------------------------

fit <- lm(log(annual_earnings) ~ religion + sex + education + age + residence,
          data = wages)
print(summary(fit))

## The calibration targets, printed so they can be checked -------------------

cat("\n--- values R/make-wages-synthetic.R is calibrated to ---\n")
cat("religion shares:\n"); print(round(prop.table(table(wages$religion)), 4))
cat("\nfemale share :", round(mean(wages$sex == "Female"), 4),
    "  urban share:", round(mean(wages$residence == "Urban"), 4), "\n")
cat("education    : mean", round(mean(wages$education), 3),
    " sd", round(sd(wages$education), 3), "\n")
cat("age          : mean", round(mean(wages$age), 2),
    " sd", round(sd(wages$age), 2), "\n")
cat("residual sd  :", round(sigma(fit), 4),
    "  R-squared:", round(summary(fit)$r.squared, 4), "\n")
