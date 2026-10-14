# =============================================================================
#' Load input distributions
#'
#' Loads the distributions of the input variables that are drawn in the
#' stochastic dose calculation.
#'
#' @details Each input is drawn around its value: the value given in the input
#' data, or else its default value. Its distribution only gives the shape:
#' * `trunc_lognormal`: `sd_rel` (standard deviation relative to the value),
#'   `min`, `max` (lognormal truncated to `min`-`max`)
#' * `lognormal`: `sd_rel`
#' * `beta`: `alpha` (a0 = alpha/value)
#' * `dirichlet`: `a0` and `group`. The inputs of a group are shares of a whole
#'   and are drawn together with its rest (e.g. the speaker mode of calls).
#' * `categorical`: `probs`, the probability of each value, for each given value
#'
#' Inputs without a distribution are not drawn. The default input distributions
#' (`input_distributions.yaml`) are generated from the same Excel file as the
#' default values.
#'
#' @param path Path of an input distribution file (must be a YAML file). If
#' null, the default input distributions are loaded.
#' @returns Named list of input distributions.
#'
#' @export
#' @seealso [RFDose::simulate_inputs()]
load_input_distributions <- function(path = NULL) {
  if (is.null(path)) {
    path <- system.file("extdata", "input_distributions.yaml", package = "RFDose")
  }
  yaml::read_yaml(path)
}

# =============================================================================
#' Draw input values
#'
#' Draws the input values of each row for the stochastic dose calculation, each
#' around its value in the input data.
#'
#' @details All rows are drawn with the same random numbers, each transformed
#' by the distribution around its own value, so the draws of a row do not
#' depend on the other rows. Durations of 0 stay 0, and so do values at the
#' bounds of a truncated distribution. The inputs of a Dirichlet group are
#' drawn together with the rest of their whole, so they sum to 1 at most. Use
#' [set.seed()] before for reproducible draws.
#'
#' @param n Number of draws
#' @param data Data frame of inputs without missing values (see
#' [RFDose::calculate_emf_doses()])
#' @param input_distributions Named list of input distributions, as returned by
#' [RFDose::load_input_distributions()]
#'
#' @returns Named list with one element per drawn input: a matrix with one row
#' per row of `data` and one column per draw.
#'
#' @export
#' @seealso [RFDose::load_input_distributions()]
simulate_inputs <- function(
    n,
    data,
    input_distributions = load_input_distributions()) {
  if (length(n) != 1 || !is.numeric(n) || is.na(n) || n < 1 || n != round(n)) {
    stop("n must be a positive whole number.")
  }
  specs <- input_distributions
  if (!all(names(specs) %in% names(data))) {
    stop("Input(s) missing in the data: ",
         paste(setdiff(names(specs), names(data)), collapse = ", "))
  }
  groups <- vapply(specs, function(spec) {
    if (identical(spec$distribution, "dirichlet")) as.character(spec$group) else NA_character_
  }, character(1))

  # Random numbers: one column per input, and per share of a Dirichlet group
  # plus one for its rest. The same for every row.
  columns <- list()
  for (name in names(specs)) {
    key   <- if (is.na(groups[[name]])) name else paste0("group:", groups[[name]])
    width <- if (is.na(groups[[name]])) 1 else sum(groups %in% groups[[name]]) + 1
    if (is.null(columns[[key]])) {
      columns[[key]] <- length(unlist(columns)) + seq_len(width)
    }
  }
  random <- matrix(stats::runif(n * length(unlist(columns))), nrow = n)

  # Draws of each row, as a matrix row x draw
  rows    <- seq_len(nrow(data))
  by_rows <- function(draw, type = numeric(n)) {
    matrix(vapply(rows, draw, type), nrow = length(rows), ncol = n, byrow = TRUE)
  }
  draws <- list()
  for (name in names(specs)) {
    spec   <- specs[[name]]
    values <- data[[name]]
    p      <- if (is.na(groups[[name]])) random[, columns[[name]]] else NULL
    draws[[name]] <- tryCatch(
      switch(spec$distribution,
        lognormal       = ,
        trunc_lognormal = by_rows(function(i) q_around(p, as.numeric(values[[i]]), spec)),
        beta            = by_rows(function(i) q_beta(p, as.numeric(values[[i]]), spec$alpha)),
        categorical     = by_rows(function(i) q_category(p, values[[i]], spec$probs), character(n)),
        dirichlet       = NULL, # drawn below, with its group
        stop("unknown distribution '", spec$distribution, "'")),
      error = function(e) stop("Input ", name, ": ", conditionMessage(e), call. = FALSE))
  }

  # Dirichlet groups: shares of a whole and their rest
  for (group in unique(groups[!is.na(groups)])) {
    members <- names(groups)[groups %in% group]
    a0      <- unique(vapply(specs[members], function(spec) as.numeric(spec$a0), numeric(1)))
    if (length(a0) != 1) {
      stop("Group ", group, " has different values of a0.")
    }
    p      <- random[, columns[[paste0("group:", group)]], drop = FALSE]
    shares <- lapply(rows, function(i) {
      values <- vapply(members, function(member) as.numeric(data[[member]][[i]]), numeric(1))
      tryCatch(
        q_shares(p, values, a0),
        error = function(e) stop("Group ", group, ", row ", i, ": ", conditionMessage(e), call. = FALSE))
    })
    for (j in seq_along(members)) {
      draws[[members[j]]] <- by_rows(function(i) shares[[i]][, j])
    }
  }

  draws[names(specs)]
}

# =============================================================================
#' Quantiles of a lognormal distribution around a value
#'
#' @param p Vector of probabilities
#' @param value Value of the input, the mean of the distribution
#' @param spec Distribution: `sd_rel`, and for a truncated distribution `min`
#' and `max`
#'
#' @returns Vector of quantiles. All quantiles are equal to `value` if it is 0
#' or at (or beyond) a bound.
q_around <- function(p, value, spec) {
  lower <- if (is.null(spec$min)) 0 else spec$min
  upper <- if (is.null(spec$max)) Inf else spec$max
  if (value == 0 || value <= lower || value >= upper) {
    return(rep(value, length(p)))
  }
  q_trunc_lognormal(p, value, spec$sd_rel * value, lower, upper)
}

# =============================================================================
#' Quantiles of a categorical distribution
#'
#' @param p Vector of probabilities
#' @param value Given value of the input
#' @param probs Probability of each value, for each given value
#'
#' @returns Vector of drawn values.
q_category <- function(p, value, probs) {
  given <- unlist(probs[[as.character(value)]])
  if (is.null(given)) {
    stop("no probabilities for the value '", value, "'.")
  }
  cumulative <- cumsum(given)
  names(given)[findInterval(p, cumulative[-length(cumulative)], left.open = TRUE) + 1]
}

# =============================================================================
#' Quantiles of shares of a whole
#'
#' Dirichlet distribution of shares and the rest of their whole, from the
#' quantiles of independent gamma distributions.
#'
#' @param p Matrix of probabilities: one row per draw, one column per share and
#' one for the rest
#' @param values Shares (their sum is 1 at most)
#' @param a0 Concentration: the larger, the closer the draws are to `values`
#'
#' @returns Matrix with one row per draw and one column per share. Shares of 0
#' stay 0.
q_shares <- function(p, values, a0) {
  for (value in values) check_shape(value, "share")
  check_shape(a0, "a0")
  rest <- 1 - sum(values)
  if (rest < -1e-9) {
    stop("shares sum to more than 1.")
  }
  shares <- c(values, max(rest, 0))
  if (is.infinite(a0)) {
    return(matrix(values, nrow = nrow(p), ncol = length(values), byrow = TRUE))
  }
  gammas <- matrix(vapply(seq_along(shares), function(j) {
    stats::qgamma(p[, j], shape = a0 * shares[j])
  }, numeric(nrow(p))), nrow = nrow(p))
  (gammas / rowSums(gammas))[, seq_along(values), drop = FALSE]
}
