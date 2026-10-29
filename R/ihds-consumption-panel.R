## ihds-consumption-panel.R ---------------------------------------------------
##
## Two candidate designs for the same household panel, IHDS-I (2004-05) and
## IHDS-II (2011-12), each estimated with the ladder in R/panel-ladder.R:
##
##   (1) OLS   (2) + controls   (3) + household FE   (4) + time trend
##   (5) = (4) with standard errors clustered by household
##
##   Design A, "nrega": log consumption on days of NREGA work (rural households)
##   Design B, "mpc":   log consumption on log household income
##
## The IHDS microdata cannot be redistributed (ICPSR terms), so this script
## holds the code and not the data. Put your files under private/ or anywhere
## else and edit the CONFIG block below.
##
## !! The variable names in CONFIG are written from memory of the IHDS household
## !! files and have NOT been checked against your copy. The script stops and
## !! lists any name it cannot find. Check them against the ICPSR codebooks
## !! (IHDS-I: ICPSR 22626; IHDS-II: ICPSR 36151) before trusting any output.
##
## DESIGN A -- WHAT IT CAN AND CANNOT SHOW
##
## NREGA began in 2006, so in 2004-05 every household had zero NREGA days. With
## household fixed effects the coefficient compares each household's CHANGE in
## consumption with its own change in NREGA days. With two waves a linear time
## trend is the same as a wave dummy, so column (4) compares households that
## worked more days with those that worked fewer, net of the common change
## between waves: a difference-in-differences with a continuous treatment. It
## needs households with many and few days to have shared a consumption trend
## absent NREGA, which is not guaranteed -- districts and households select
## into the scheme.
##
## DESIGN B -- WHAT IT CAN AND CANNOT SHOW
##
## Income varies a lot within households, so fixed effects has plenty to work
## with, but the coefficient is a consumption RESPONSE to income, not a causal
## marginal propensity to consume: income and consumption are measured in the
## same survey (correlated reporting error), income is measured with error
## (which fixed effects makes worse), and shocks move both. Both variables are
## in current rupees, so the time trend absorbs inflation.

source("R/panel-ladder.R")

suppressPackageStartupMessages({ library(haven); library(dplyr) })

## CONFIG -- edit ---------------------------------------------------------------
cfg <- list(
  wave1_file = "private/ihds/IHDS1_Household.dta",
  wave2_file = "private/ihds/IHDS2_Household.dta",

  # Household identifiers. IHDS-II adds HHSPLITID for households that split.
  id_vars       = c("STATEID", "DISTID", "PSUID", "HHID"),
  split_var     = "HHSPLITID",     # wave 2 only; NULL if absent
  keep_original_only = TRUE,       # drop split-off households (HHSPLITID != 0)

  # Outcome: monthly consumption per capita (rupees)
  consumption   = "COPC",

  # Household income in the last year (rupees), present in both waves
  income        = "INCOME",

  # Design A variable of interest: days of NREGA work in the last year
  nrega_days_w2 = "NREGDAYS",      # wave 2 only; set to 0 in wave 1 (pre-NREGA)

  # Household controls present in BOTH waves (name in each wave file)
  controls = c(hhsize = "NPERSONS", urban = "URBAN")
)

## Build the panel -----------------------------------------------------------------
read_wave <- function(path, vars) {
  d <- read_dta(path.expand(path))
  missing <- setdiff(vars, names(d))
  if (length(missing))
    stop("Not found in ", path, ": ", paste(missing, collapse = ", "),
         "\nEdit CONFIG at the top of this script.")
  d[, vars]
}

ctrl_vars <- unname(cfg$controls)
w1 <- read_wave(cfg$wave1_file, c(cfg$id_vars, cfg$consumption, cfg$income, ctrl_vars))
w2 <- read_wave(cfg$wave2_file, c(cfg$id_vars, cfg$split_var, cfg$consumption,
                                  cfg$income, cfg$nrega_days_w2, ctrl_vars))

if (!is.null(cfg$split_var) && cfg$keep_original_only)
  w2 <- w2[as.numeric(w2[[cfg$split_var]]) == 0, ]

stack <- function(d, wave, nrega) {
  out <- data.frame(
    hhid = do.call(paste, c(lapply(cfg$id_vars, function(v) as.numeric(d[[v]])), sep = "-")),
    wave = wave,
    cons = as.numeric(d[[cfg$consumption]]),
    income = as.numeric(d[[cfg$income]]),
    nrega_days = nrega)
  for (nm in names(cfg$controls)) out[[nm]] <- as.numeric(d[[cfg$controls[[nm]]]])
  out
}

panel <- rbind(
  stack(w1, 1, rep(0, nrow(w1))),                        # pre-NREGA: zero days
  stack(w2, 2, as.numeric(w2[[cfg$nrega_days_w2]])))
panel$nrega_days[is.na(panel$nrega_days) & panel$wave == 2] <- 0   # no NREGA work

panel <- panel[!is.na(panel$cons) & panel$cons > 0, ]
panel$lcons <- log(panel$cons)
panel$nrega_10days <- panel$nrega_days / 10    # coefficient = effect of 10 more days
panel$lincome <- ifelse(!is.na(panel$income) & panel$income > 0, log(panel$income), NA)

cat("Households in the panel (seen in both waves):",
    sum(table(panel$hhid) == 2), "of", length(unique(panel$hhid)), "\n")
cat("Share of wave-2 households with any NREGA work:",
    round(mean(panel$nrega_days[panel$wave == 2] > 0), 3), "\n\n")

## Run one design ---------------------------------------------------------------------
run_design <- function(d, x, label, controls) {
  # A control with no variation in this sample (e.g. `urban` among rural
  # households) would make OLS singular, so drop it and say so.
  varies <- vapply(controls, function(v) var(d[[v]], na.rm = TRUE) > 0, logical(1))
  if (any(!varies)) cat("(dropped constant controls:", paste(controls[!varies], collapse = ", "), ")\n")
  res <- panel_ladder(d, id = "hhid", wave = "wave", y = "lcons", x = x,
                      controls = controls[varies])
  out <- res$table[, c("model", "estimate", "se_usual", "se_cluster",
                       "households", "observations")]
  out[, 2:4] <- round(out[, 2:4], 4)
  cat("==== ", label, " ====\n", sep = "")
  print(out, row.names = FALSE)
  cat("Absorbed by household FE:", paste(res$absorbed_by_FE, collapse = ", "),
      "| households seen once:", res$households_seen_once, "\n\n")
  invisible(res)
}

ctrl <- names(cfg$controls)

## Design A: rural households only (NREGA is a rural scheme). `urban` is taken
## from wave 2; adjust if your coding differs.
rural_ids <- panel$hhid[panel$wave == 2 & panel$urban == 0]
run_design(panel[panel$hhid %in% rural_ids, ], "nrega_10days",
           "A. log consumption on NREGA days (per 10 days), rural households", ctrl)

## Design B: all households
run_design(panel, "lincome", "B. log consumption on log household income", ctrl)
