## panel-ladder.R -------------------------------------------------------------
##
## The estimation ladder for a household panel, in base R:
##
##   (1) OLS
##   (2) OLS + household controls
##   (3) OLS + household controls + household fixed effects
##   (4) OLS + household controls + household fixed effects + time trend
##   (5) the same as (4), with standard errors clustered by household
##
## Every column is reported with BOTH the usual and the clustered standard
## error, so the effect of clustering is visible at each step; column (5) is the
## specification you would put in a paper.
##
## USING IT ON IHDS
##
## IHDS cannot be redistributed (ICPSR terms), so this repository holds the code
## and not the data. Build a long data frame with one row per household per
## wave -- columns: a household id, a wave number (1, 2, ...), the outcome, the
## variable of interest and the household controls -- and call
##
##   panel_ladder(d, id = "hhid", wave = "wave", y = "lcons", x = "lincome",
##                controls = c("hhsize", "hh_educ", "urban"))
##
## Controls that never change within a household (e.g. `urban` for households
## that do not move) are absorbed by the household effects in columns (3)-(5);
## the function lists them rather than silently dropping them.
##
## Run this file with `Rscript R/panel-ladder.R` for a demonstration on a
## SIMULATED panel (not IHDS) whose true effect is known.

cluster_vcov <- function(X, u, cluster) {
  G <- length(unique(cluster))
  bread <- solve(crossprod(X))
  meat  <- crossprod(rowsum(X * u, cluster))
  G / (G - 1) * bread %*% meat %*% bread
}

# OLS on (possibly demeaned) data, returning the coefficient on `x` with the
# usual and the clustered standard error. `df_lost` is the number of
# parameters absorbed by demeaning (one per household for fixed effects).
fit_one <- function(d, y, regs, id, df_lost = 0, demean = FALSE, intercept = TRUE) {
  Y <- d[[y]]; X <- as.matrix(d[, regs, drop = FALSE])
  if (demean) {
    Y <- Y - ave(Y, d[[id]])
    X <- apply(X, 2, function(v) v - ave(v, d[[id]]))
    # a regressor that is constant within households is now all zeros
    keep <- apply(X, 2, function(v) any(abs(v) > 1e-10))
  } else keep <- rep(TRUE, ncol(X))
  dropped <- colnames(X)[!keep]
  X <- X[, keep, drop = FALSE]
  if (intercept && !demean) X <- cbind(`(Intercept)` = 1, X)
  n <- nrow(X); k <- ncol(X)
  b <- solve(crossprod(X), crossprod(X, Y))[, 1]
  u <- Y - X %*% b
  s2 <- sum(u^2) / (n - k - df_lost)
  V_usual <- s2 * solve(crossprod(X))
  V_clust <- cluster_vcov(X, as.numeric(u), d[[id]])
  ss_tot <- sum((Y - mean(Y))^2)
  list(b = b, se_usual = sqrt(diag(V_usual)), se_clust = sqrt(diag(V_clust)),
       n = n, dropped = dropped,
       r2 = 1 - sum(u^2) / ss_tot)
}

panel_ladder <- function(d, id, wave, y, x, controls = character(0)) {
  d <- d[complete.cases(d[, c(id, wave, y, x, controls)]), ]
  d <- d[order(d[[id]], d[[wave]]), ]

  # Fixed effects use only households seen more than once.
  seen <- table(d[[id]])
  multi <- d[d[[id]] %in% names(seen)[seen > 1], ]
  N_all <- length(seen); N_multi <- length(unique(multi[[id]]))
  d$trend <- d[[wave]] - min(d[[wave]]); multi$trend <- multi[[wave]] - min(multi[[wave]])

  specs <- list(
    `(1) OLS`                     = list(data = d,     regs = x,                          fe = FALSE),
    `(2) + controls`              = list(data = d,     regs = c(x, controls),             fe = FALSE),
    `(3) + household FE`          = list(data = multi, regs = c(x, controls),             fe = TRUE),
    `(4) + time trend`            = list(data = multi, regs = c(x, controls, "trend"),    fe = TRUE),
    `(5) = (4), clustered`        = list(data = multi, regs = c(x, controls, "trend"),    fe = TRUE))

  fits <- lapply(specs, function(s) {
    G <- length(unique(s$data[[id]]))
    fit_one(s$data, y, s$regs, id, df_lost = if (s$fe) G else 0, demean = s$fe)
  })

  tab <- do.call(rbind, lapply(names(fits), function(nm) {
    f <- fits[[nm]]
    is5 <- grepl("clustered", nm)
    data.frame(model = nm,
               estimate = unname(f$b[x]),
               se_usual = unname(f$se_usual[x]),
               se_cluster = unname(f$se_clust[x]),
               shown_se = unname(if (is5) f$se_clust[x] else f$se_usual[x]),
               households = if (specs[[nm]]$fe) length(unique(specs[[nm]]$data[[id]]))
                            else length(unique(d[[id]])),
               observations = f$n, r2 = f$r2)
  }))
  rownames(tab) <- NULL

  list(table = tab, fits = fits,
       absorbed_by_FE = fits[["(3) + household FE"]]$dropped,
       households_seen_once = N_all - N_multi)
}

## Demonstration on SIMULATED data (NOT IHDS) ----------------------------------
if (sys.nframe() == 0) {
  set.seed(1)
  N <- 3000; waves <- 2
  a      <- rnorm(N, sd = 0.6)                       # unobserved household effect
  urban  <- rbinom(N, 1, 0.4)                        # constant within household
  d <- data.frame(hhid = rep(1:N, each = waves), wave = rep(1:waves, N))
  d$urban  <- urban[d$hhid]
  d$hhsize <- pmax(1, round(4.5 + rnorm(N * waves, sd = 1.4) - 0.5 * (d$wave - 1)))
  d$lincome <- 9 + 0.5 * a[d$hhid] + 0.15 * (d$wave - 1) + rnorm(N * waves, sd = 0.5)
  d$lcons   <- 4 + 0.40 * d$lincome - 0.05 * d$hhsize + 0.10 * d$urban +
               a[d$hhid] + 0.05 * (d$wave - 1) + rnorm(N * waves, sd = 0.3)
  res <- panel_ladder(d, "hhid", "wave", "lcons", "lincome", c("hhsize", "urban"))
  cat("SIMULATED panel; true effect of lincome = 0.40\n\n")
  print(transform(res$table[, c("model", "estimate", "se_usual", "se_cluster",
                                "households", "observations")],
                  estimate = round(estimate, 3), se_usual = round(se_usual, 4),
                  se_cluster = round(se_cluster, 4)), row.names = FALSE)
  cat("\nAbsorbed by household FE:", res$absorbed_by_FE, "\n")
}
