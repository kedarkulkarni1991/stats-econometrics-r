## Shared setup sourced by every chapter -------------------------------------

# Several simulations fit tens of thousands of models; caching keeps a rebuild
# to seconds rather than minutes. autodep invalidates a cache when anything it
# depends on changes, so results cannot go stale silently.
knitr::opts_chunk$set(
  autodep = TRUE,
  # Figures inside callout boxes cannot float -- LaTeX raises "Not in outer par
  # mode" -- so every figure is pinned where it is written.
  fig.pos   = "H",
  out.extra = "",
  comment   = "#>",
  collapse  = FALSE,
  echo      = TRUE,
  message   = FALSE,
  warning   = FALSE,
  fig.align = "center",
  fig.width = 7,
  fig.height = 4.2,
  dpi       = 150,
  out.width = "90%",
  ## The default png device on macOS has no glyph for the rupee sign and draws
  ## a hollow box instead. In a book about the Indian economy that is not a
  ## cosmetic issue. ragg handles the full Unicode range, so every figure uses
  ## it. If ragg is missing, fall back rather than fail the build.
  dev = if (requireNamespace("ragg", quietly = TRUE)) "ragg_png" else "png"
)

options(digits = 4, scipen = 999)

## A consistent look for every figure in the book ----------------------------

book_palette <- list(
  ink    = "#1f2933",
  accent = "#2b6cb0",
  reject = "#c05621",
  soft   = "#cbd5e0",
  fill   = "#bee3f8"
)

theme_book <- function(base_size = 12) {
  ggplot2::theme_minimal(base_size = base_size) +
    ggplot2::theme(
      plot.title    = ggplot2::element_text(face = "bold", size = base_size * 1.05),
      plot.subtitle = ggplot2::element_text(colour = "grey35"),
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major = ggplot2::element_line(colour = "grey92"),
      axis.title    = ggplot2::element_text(colour = "grey25")
    )
}

## Teaching helpers -----------------------------------------------------------

#' Build a sample with an EXACTLY specified mean and standard deviation.
#'
#' Many textbook problems quote only summary statistics. This reproduces a
#' dataset consistent with them, so the R output always matches the hand
#' calculation printed alongside it.
make_sample <- function(n, mean, sd, seed = 1) {
  set.seed(seed)
  x <- stats::rnorm(n)
  x <- (x - base::mean(x)) / stats::sd(x)
  base::round(mean + sd * x, 4)
}

#' Shade the rejection region of a Z or t test.
plot_rejection <- function(stat, crit, tails = c("two", "left", "right"),
                           df = NULL, stat_label = NULL) {
  tails <- match.arg(tails)
  dfun  <- if (is.null(df)) function(x) stats::dnorm(x) else function(x) stats::dt(x, df)
  lim   <- max(4, abs(stat) * 1.15, abs(crit) * 1.15)
  grid  <- data.frame(x = seq(-lim, lim, length.out = 1000))
  grid$y <- dfun(grid$x)

  rej <- switch(
    tails,
    two   = subset(grid, x <= -abs(crit) | x >= abs(crit)),
    left  = subset(grid, x <= -abs(crit)),
    right = subset(grid, x >=  abs(crit))
  )
  rej$grp <- ifelse(rej$x < 0, "lo", "hi")

  ggplot2::ggplot(grid, ggplot2::aes(x, y)) +
    ggplot2::geom_area(fill = book_palette$soft, alpha = 0.45) +
    ggplot2::geom_area(data = rej, ggplot2::aes(group = grp),
                       fill = book_palette$reject, alpha = 0.75) +
    ggplot2::geom_line(linewidth = 0.6, colour = book_palette$ink) +
    ggplot2::geom_vline(xintercept = stat, linewidth = 0.9,
                        colour = book_palette$accent) +
    ggplot2::annotate("label", x = stat, y = max(grid$y) * 0.92,
                      label = stat_label %||% paste0("observed = ", round(stat, 3)),
                      colour = book_palette$accent, fill = "white",
                      label.size = 0.3, size = 3.6) +
    ggplot2::labs(x = if (is.null(df)) "Z" else "t", y = NULL) +
    theme_book() +
    ggplot2::theme(axis.text.y = ggplot2::element_blank())
}

`%||%` <- function(a, b) if (is.null(a)) b else a
