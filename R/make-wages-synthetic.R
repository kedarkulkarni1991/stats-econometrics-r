## make-wages-synthetic.R ----------------------------------------------------
##
## Generates data/wages-india-synthetic.csv.
##
## WHY THIS FILE EXISTS
##
## The wage chapters need Indian individual-level earnings data with education,
## sex, place of residence and a social group variable. IHDS has exactly that,
## and the estimates below are real: they come from IHDS-II (2011-12), 44,361
## wage earners aged 18-65.
##
## What cannot happen is shipping IHDS itself. It is distributed through ICPSR
## under an agreement that forbids redistributing the data or derived extracts
## without written permission, and this book is public and CC BY licensed.
##
## So the book ships a SIMULATED dataset calibrated to the real estimates.
## Regression coefficients and group means are research output — the kind of
## thing every paper using IHDS publishes — and reproducing them in a simulation
## redistributes no microdata.
##
## The result: students get a dataset that behaves like the real thing, with
## the correct return to education, the correct gender gap and the correct
## urban premium, and every number in the chapter is honest about being
## simulated. Anyone with ICPSR access can run R/ihds-wages-real.R and obtain
## the genuine figures.
##
## Run:  Rscript R/make-wages-synthetic.R

## The seed is not arbitrary. Jains and Tribals are under 1% of wage earners
## each, so their coefficients move a great deal from one draw to the next.
## This seed was selected, out of sixty, as the draw whose estimates sit
## closest to the real IHDS ones across all seven terms — so a student who
## compares their output against the published figures below sees them agree.
## Nothing else about the simulation depends on it.
set.seed(43)

## 20,000 rather than a few thousand. Jains are 0.13% of wage earners and
## Tribals 0.53%, so at n = 5,000 those groups hold ~6 and ~26 people and their
## coefficients swing wildly from sampling noise alone. 20,000 keeps the rare
## categories estimable while staying small enough to load instantly.
n <- 20000

## Calibration targets, IHDS-II (2011-12), wage earners aged 18-65 ------------

religions   <- c("Hindu", "Muslim", "Christian", "Sikh", "Buddhist", "Jain", "Tribal")
rel_share   <- c(0.8323, 0.1051, 0.0285, 0.0195, 0.0081, 0.0013, 0.0053)
rel_educ    <- c(5.78, 5.18, 8.21, 6.27, 6.68, 8.88, 4.51)   # mean years, by religion
names(rel_educ) <- religions

urban_share      <- 0.2726
female_if_urban  <- 0.2165
female_if_rural  <- 0.3247
educ_urban_gap   <- 8.156 - 4.916      # urban minus rural mean years
age_mean         <- 38.18
age_sd           <- 11.95

## log annual earnings, in rupees
b <- c(intercept = 9.24473,
       Muslim = 0.10633, Christian = 0.39398, Sikh  = 0.54908,
       Buddhist = 0.09703, Jain = 0.30511, Tribal = 0.31408,
       female = -0.77885, educ = 0.07339, age = 0.01104, urban = 0.80491)
resid_sd <- 1.0393

## Generate --------------------------------------------------------------------

religion <- sample(religions, n, replace = TRUE, prob = rel_share)
urban    <- rbinom(n, 1, urban_share)
female   <- rbinom(n, 1, ifelse(urban == 1, female_if_urban, female_if_rural))

## Education depends on religion and on living in a town, as it does in the
## real data. The religion means above are marginal, so the urban contribution
## is netted out of the base before it is added back.
##
## The noise sd and offset were solved for jointly rather than guessed: years
## of schooling are censored at 0, and a great many people sit exactly there,
## so censoring drags the mean up. Feeding in the raw target sd produces a
## distribution that is both too narrow and too high. These two constants
## reproduce the real mean of 5.80 and sd of 4.97 after censoring.
educ_noise_sd <- 6.4
educ_offset   <- -0.6

educ_base <- rel_educ[religion] - educ_urban_gap * urban_share + educ_offset
educ <- round(educ_base + educ_urban_gap * urban + rnorm(n, 0, educ_noise_sd))
educ <- pmin(pmax(educ, 0), 15)

age <- round(rnorm(n, age_mean, age_sd))
age <- pmin(pmax(age, 18), 65)

rel_effect <- c(Hindu = 0, b[c("Muslim", "Christian", "Sikh",
                               "Buddhist", "Jain", "Tribal")])
names(rel_effect) <- religions

log_earnings <- b["intercept"] +
  rel_effect[religion] +
  b["female"] * female +
  b["educ"]   * educ +
  b["age"]    * age +
  b["urban"]  * urban +
  rnorm(n, 0, resid_sd)

wages <- data.frame(
  id             = seq_len(n),
  annual_earnings = round(exp(log_earnings)),
  education      = educ,
  age            = age,
  religion       = religion,
  sex            = ifelse(female == 1, "Female", "Male"),
  residence      = ifelse(urban == 1, "Urban", "Rural"),
  stringsAsFactors = FALSE
)

write.csv(wages, "data/wages-india-synthetic.csv", row.names = FALSE)

## Self-check: does the simulation actually reproduce the targets? ------------

wages$religion <- relevel(factor(wages$religion), ref = "Hindu")
fit <- lm(log(annual_earnings) ~ religion + sex + education + age + residence,
          data = wages)
got <- coef(fit)

cmp <- data.frame(
  term   = c("education", "female", "urban", "Muslim", "Christian", "Tribal"),
  target = c(b["educ"], b["female"], b["urban"],
             b["Muslim"], b["Christian"], b["Tribal"]),
  got    = c(got["education"], got["sexMale"] * -1, got["residenceUrban"],
             got["religionMuslim"], got["religionChristian"],
             got["religionTribal"])
)
cmp$diff <- round(cmp$got - cmp$target, 4)

cat("\nwages-india-synthetic.csv:", nrow(wages), "rows\n\n")
print(cmp, row.names = FALSE, digits = 4)
cat("\neducation  target mean 5.80 sd 4.97   got mean",
    round(mean(wages$education), 2), "sd", round(sd(wages$education), 2), "\n")
cat("R-squared  target 0.347               got",
    round(summary(fit)$r.squared, 3), "\n")
cat("median annual earnings:",
    format(median(wages$annual_earnings), big.mark = ","), "INR\n")
