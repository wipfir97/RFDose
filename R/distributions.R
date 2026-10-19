# =============================================================================
#' Load parameter distributions
#'
#' Loads the distributions of the parameters that are drawn in the stochastic
#' dose calculation and returns them as a nested list, with the structure of
#' the parameter list.
#'
#' @details Each drawn parameter has a distribution and the values that set
#' its shape:
#' * `lognormal`: `sd_rel` (standard deviation relative to the mean)
#' * `trunc_lognormal`: `sd_rel`, `min`, `max` (lognormal truncated to
#'   `min`-`max`)
#' * `beta`: `alpha` (a0 = alpha/mean)
#' * `dirichlet`: `a0` and `group`. The parameters of a group are drawn
#'   together and sum to 1.
#'
#' The mean of each distribution is the value of the parameter in the
#' parameter list (see [RFDose::load_params()]). Parameters without a
#' distribution are not drawn. The default distributions
#' (`params_distributions.yaml`) are generated from the same Excel file as the
#' default parameters.
#'
#' @param path Path of a distribution file (must be a YAML file). If null, the
#' default distributions are loaded.
#' @returns Nested list of distributions.
#'
#' @export
#' @seealso [RFDose::simulate_params()]
load_distributions <- function(path = NULL) {
  if (is.null(path)) {
    path <- system.file("extdata", "params_distributions.yaml", package = "RFDose")
  }
  yaml::read_yaml(path)
}

# =============================================================================
#' List parameter distributions
#'
#' Turns the nested list of distributions into a flat list, with one element
#' per drawn parameter.
#'
#' @param distributions Nested list of distributions, as returned by
#' [RFDose::load_distributions()]
#'
#' @returns List named by the path of each parameter in the parameter list
#' (sections separated by "."). Each element is the distribution of the
#' parameter, with its path as character vector (`key`).
list_distributions <- function(distributions) {
  specs <- list()
  walk  <- function(x, key) {
    if (!is.list(x)) {
      stop("No distribution for ", paste(key, collapse = " > "), ".")
    }
    if (!is.null(x[["distribution"]])) {
      if (any(grepl(".", key, fixed = TRUE))) {
        stop("Parameter ", paste(key, collapse = " > "), ": names must not contain \".\".")
      }
      specs[[paste(key, collapse = ".")]] <<- c(list(key = key), x)
    } else {
      for (name in names(x)) walk(x[[name]], c(key, name))
    }
  }
  walk(distributions, character(0))
  specs
}

# =============================================================================
#' Get a parameter value
#'
#' @param params Parameter list, as returned by [RFDose::load_params()]
#' @param key Path of the parameter in the parameter list (character vector)
#'
#' @returns Value of the parameter. Side effect of stopping calculation if the
#' parameter is not a single number.
get_param <- function(params, key) {
  value <- params
  for (k in key) {
    if (!is.list(value) || !(k %in% names(value))) {
      stop("Parameter ", paste(key, collapse = " > "), " not found.")
    }
    value <- value[[k]]
  }
  if (!is.numeric(value) || length(value) != 1 || is.na(value)) {
    stop("Parameter ", paste(key, collapse = " > "), " is not a single number.")
  }
  value
}

# =============================================================================
#' Set parameter values
#'
#' Replaces the values of some parameters, e.g. by one draw of
#' [RFDose::simulate_params()].
#'
#' @param params Parameter list, as returned by [RFDose::load_params()]
#' @param values Numeric vector of new values
#' @param keys List with the path of each parameter of `values` (character
#' vectors). By default, the names of `values`, with sections separated by ".".
#'
#' @returns Parameter list with the new values.
set_params <- function(params, values, keys = strsplit(names(values), ".", fixed = TRUE)) {
  for (i in seq_along(values)) {
    params[[keys[[i]]]] <- values[[i]]
  }
  params
}

# =============================================================================
#' Draw parameter sets
#'
#' Draws parameter sets for the stochastic dose calculation: each drawn
#' parameter from its distribution, around its value in the parameter list.
#'
#' @details The parameters of a Dirichlet group are drawn together, so that
#' they sum to 1 in every draw.
#'
#' The SAR values are drawn too, from a lognormal distribution around their
#' value in the parameter list, with standard deviation `sar_sd` times the
#' value. SAR values with the same value for the same tissue come from the same
#' simulation and are drawn together; SAR values of 0 stay 0.
#'
#' The SAR values are drawn after the other parameters, so the draws of the
#' other parameters do not depend on `sar_sd`. Use [set.seed()] before for
#' reproducible draws.
#'
#' @param n Number of parameter sets
#' @param params Parameter list, as returned by [RFDose::load_params()]. Its
#' values are the means of the distributions.
#' @param distributions Nested list of distributions, as returned by
#' [RFDose::load_distributions()]
#' @param sar_sd Standard deviation of the SAR values, relative to their value.
#' With 0, the SAR values are not drawn.
#'
#' @returns Matrix with one row per parameter set and one column per drawn
#' parameter and SAR value, named by its path in the parameter list (sections
#' separated by "."). Parameters that are not drawn keep their value in `params`.
#'
#' @export
#' @seealso [RFDose::load_distributions()]
simulate_params <- function(
    n,
    params        = load_params(),
    distributions = load_distributions(),
    sar_sd        = 0.25) {
  if (length(n) != 1 || !is.numeric(n) || is.na(n) || n < 1 || n != round(n)) {
    stop("n must be a positive whole number.")
  }
  if (length(sar_sd) != 1 || !is.numeric(sar_sd) || !is.finite(sar_sd) || sar_sd < 0) {
    stop("sar_sd must be a single number, 0 or more.")
  }
  specs <- list_distributions(distributions)
  means <- vapply(specs, function(spec) get_param(params, spec$key), numeric(1))
  draws <- matrix(NA_real_, nrow = n, ncol = length(specs),
                  dimnames = list(NULL, names(specs)))

  # Single parameters ---------------------------------------------------------
  for (name in names(specs)) {
    spec <- specs[[name]]
    draws[, name] <- tryCatch(
      switch(spec$distribution,
        lognormal       = r_lognormal(n, means[[name]], spec$sd_rel * means[[name]]),
        trunc_lognormal = r_trunc_lognormal(n, means[[name]], spec$sd_rel * means[[name]],
                                            spec$min, spec$max),
        beta            = r_beta(n, means[[name]], spec$alpha),
        dirichlet       = NA_real_, # drawn below, with its group
        stop("unknown distribution '", spec$distribution, "'")),
      error = function(e) {
        stop("Parameter ", paste(spec$key, collapse = " > "), ": ", conditionMessage(e),
             call. = FALSE)
      })
  }

  # Dirichlet groups ----------------------------------------------------------
  groups <- vapply(specs, function(spec) {
    if (identical(spec$distribution, "dirichlet")) as.character(spec$group) else NA_character_
  }, character(1))
  for (group in unique(groups[!is.na(groups)])) {
    members <- names(groups)[groups %in% group]
    a0      <- unique(vapply(specs[members], function(spec) as.numeric(spec$a0), numeric(1)))
    if (length(a0) != 1) {
      stop("Group ", group, " has different values of a0.")
    }
    draws[, members] <- tryCatch(
      r_dirichlet(n, means[members], a0),
      error = function(e) stop("Group ", group, ": ", conditionMessage(e), call. = FALSE))
  }

  # SAR values ----------------------------------------------------------------
  # One factor (mean 1) per simulation, i.e. per value and tissue
  if (sar_sd > 0) {
    sar         <- list_sar(params)
    simulation  <- paste(sar$tissue, sprintf("%.17g", sar$value))
    simulations <- unique(simulation)
    factors     <- matrix(vapply(simulations, function(s) r_lognormal(n, mean = 1, sd = sar_sd),
                                 numeric(n)),
                          nrow = n)
    sar_draws   <- factors[, match(simulation, simulations), drop = FALSE] *
      matrix(sar$value, nrow = n, ncol = nrow(sar), byrow = TRUE)
    colnames(sar_draws) <- sar$name
    draws <- cbind(draws, sar_draws)
  }

  draws
}

# =============================================================================
#' List SAR values
#'
#' Lists the SAR values of a parameter list (the values in the tissue sections
#' of each device), except those that are 0.
#'
#' @param params Parameter list, as returned by [RFDose::load_params()]
#'
#' @returns Data frame with one row per SAR value that is not 0: its path in the
#' parameter list (`name`, sections separated by "."), its tissue and its value.
list_sar <- function(params) {
  rows <- lapply(names(params$devices), function(device) {
    tissues <- names(Filter(is.list, params$devices[[device]]))
    lapply(tissues, function(tissue) {
      values <- params$devices[[device]][[tissue]]
      if (any(grepl(".", c(device, tissue, names(values)), fixed = TRUE))) {
        stop("SAR value of ", device, " > ", tissue, ": names must not contain \".\".")
      }
      data.frame(
        name   = paste("devices", device, tissue, names(values), sep = "."),
        tissue = tissue,
        value  = vapply(values, function(value) as.numeric(value), numeric(1)),
        row.names = NULL)
    })
  })
  sar <- do.call(rbind, unlist(rows, recursive = FALSE))
  sar <- sar[sar$value != 0, ]
  rownames(sar) <- NULL
  sar
}

# =============================================================================
#' Draw from a lognormal distribution
#'
#' @param n Number of draws
#' @param mean Mean (arithmetic, not on the log scale)
#' @param sd Standard deviation (arithmetic, not on the log scale)
#'
#' @returns Vector of `n` draws. All draws are equal to `mean` if `mean` or
#' `sd` is 0.
r_lognormal <- function(n, mean, sd) {
  check_shape(mean, "mean")
  check_shape(sd, "sd")
  if (mean == 0 || sd == 0) {
    return(rep(mean, n))
  }
  sdlog   <- sqrt(log(1 + (sd / mean)^2))
  meanlog <- log(mean) - sdlog^2 / 2
  stats::rlnorm(n, meanlog = meanlog, sdlog = sdlog)
}

# =============================================================================
#' Draw from a truncated lognormal distribution
#'
#' Draws from a lognormal distribution truncated to the interval `min`-`max`,
#' which keeps the given mean.
#'
#' @details Truncation alone would move the mean, e.g. down if the mean is close
#' to `max`. The lognormal distribution before truncation is therefore shifted
#' (on the log scale), until the mean of the truncated distribution is `mean`.
#' The spread on the log scale is the one of a lognormal distribution with
#' `mean` and `sd`; truncation makes the standard deviation of the draws smaller
#' than `sd`.
#'
#' @param n Number of draws
#' @param mean Mean of the truncated distribution (between `min` and `max`)
#' @param sd Standard deviation, before truncation
#' @param min Lower bound (0 or more)
#' @param max Upper bound
#'
#' @returns Vector of `n` draws between `min` and `max`. All draws are equal to
#' `mean` if `sd` is 0.
r_trunc_lognormal <- function(n, mean, sd, min, max) {
  check_shape(mean, "mean")
  check_shape(sd, "sd")
  check_shape(min, "min")
  if (length(max) != 1 || !is.numeric(max) || is.na(max) || max <= min) {
    stop("max must be a number larger than min.")
  }
  if (sd == 0) {
    return(rep(mean, n))
  }
  if (mean <= min || mean >= max) {
    stop("mean must be between min and max.")
  }
  q_trunc_lognormal(stats::runif(n), mean, sd, min, max)
}

# =============================================================================
#' Quantiles of a truncated lognormal distribution
#'
#' Quantile function of the truncated lognormal distribution of
#' [RFDose::r_trunc_lognormal()], which keeps the given mean.
#'
#' @details The probabilities are computed as logarithms, so that the quantiles
#' are also right very close to a bound (e.g. a mean just below `max`), where
#' the probabilities can be too small to be stored as numbers.
#'
#' @param p Vector of probabilities
#' @inheritParams r_trunc_lognormal
#'
#' @returns Vector of quantiles between `min` and `max`, increasing with `p`.
#' All quantiles are equal to `mean` if `sd` is 0.
q_trunc_lognormal <- function(p, mean, sd, min, max) {
  check_shape(mean, "mean")
  check_shape(sd, "sd")
  check_shape(min, "min")
  if (length(max) != 1 || !is.numeric(max) || is.na(max) || max <= min) {
    stop("max must be a number larger than min.")
  }
  if (sd == 0) {
    return(rep(mean, length(p)))
  }
  if (mean <= min || mean >= max) {
    stop("mean must be between min and max.")
  }
  sdlog   <- sqrt(log(1 + (sd / mean)^2))
  meanlog <- trunc_lognormal_meanlog(mean, sdlog, min, max)

  # Inverse of the distribution function, between its values at min and max
  # (from the upper tail if min is above the median, for precision). The
  # probabilities are taken as logarithms: close to a bound they can be too
  # small to be stored as numbers.
  if (log(min) > meanlog) {
    # log of S(min) - p * (S(min) - S(max)), with S the upper tail
    upper     <- stats::plnorm(c(min, max), meanlog, sdlog, lower.tail = FALSE, log.p = TRUE)
    target    <- upper[1] + log((1 - p) + p * exp(upper[2] - upper[1]))
    quantiles <- stats::qlnorm(target, meanlog, sdlog, lower.tail = FALSE, log.p = TRUE)
  } else {
    # log of F(min) + p * (F(max) - F(min)), with F the lower tail
    lower     <- stats::plnorm(c(min, max), meanlog, sdlog, log.p = TRUE)
    target    <- lower[2] + log(p + (1 - p) * exp(lower[1] - lower[2]))
    quantiles <- stats::qlnorm(target, meanlog, sdlog, log.p = TRUE)
  }
  quantiles[p == 0] <- min
  quantiles[p == 1] <- max
  pmin(pmax(quantiles, min), max) # against rounding at the bounds
}

# =============================================================================
#' Mean of a truncated lognormal distribution
#'
#' @param meanlog Mean on the log scale, before truncation
#' @param sdlog Standard deviation on the log scale, before truncation
#' @param min Lower bound
#' @param max Upper bound
#'
#' @returns Mean of the lognormal distribution truncated to `min`-`max`.
trunc_lognormal_mean <- function(meanlog, sdlog, min, max) {
  a <- (log(min) - meanlog) / sdlog
  b <- (log(max) - meanlog) / sdlog
  exp(meanlog + sdlog^2 / 2 +
        log_pnorm_between(a - sdlog, b - sdlog) - log_pnorm_between(a, b))
}

# =============================================================================
#' Log-scale mean of a lognormal distribution, from the mean after truncation
#'
#' @param mean Mean of the truncated distribution
#' @param sdlog Standard deviation on the log scale, before truncation
#' @param min Lower bound
#' @param max Upper bound
#'
#' @returns Mean on the log scale, before truncation, for which the lognormal
#' distribution truncated to `min`-`max` has the mean `mean`.
trunc_lognormal_meanlog <- function(mean, sdlog, min, max) {
  # The mean after truncation increases with meanlog: bracket the solution,
  # starting from the lognormal distribution without truncation
  gap   <- function(meanlog) log(trunc_lognormal_mean(meanlog, sdlog, min, max)) - log(mean)
  start <- log(mean) - sdlog^2 / 2
  lower <- upper <- start
  for (i in 1:60) {
    if (gap(lower) <= 0) break
    lower <- start - sdlog * 2^i
  }
  for (i in 1:60) {
    if (gap(upper) >= 0) break
    upper <- start + sdlog * 2^i
  }
  if (!(gap(lower) <= 0 && gap(upper) >= 0)) {
    stop("no lognormal distribution with this mean after truncation.")
  }
  if (lower == upper) {
    return(lower)
  }
  stats::uniroot(gap, c(lower, upper), tol = 1e-12)$root
}

# =============================================================================
#' Log of a standard normal probability between two values
#'
#' @param a Lower value
#' @param b Upper value
#'
#' @returns log(P(a < Z < b)) for a standard normal Z, precise also far in the
#' tails.
log_pnorm_between <- function(a, b) {
  if (a > 0) {
    # upper tail: P(Z > a) - P(Z > b)
    larger  <- stats::pnorm(a, lower.tail = FALSE, log.p = TRUE)
    smaller <- stats::pnorm(b, lower.tail = FALSE, log.p = TRUE)
  } else {
    larger  <- stats::pnorm(b, log.p = TRUE)
    smaller <- stats::pnorm(a, log.p = TRUE)
  }
  larger + log1p(-exp(smaller - larger))
}

# =============================================================================
#' Draw from a beta distribution
#'
#' @param n Number of draws
#' @param mean Mean (between 0 and 1)
#' @param alpha First shape parameter: the concentration is a0 = alpha/mean
#'
#' @returns Vector of `n` draws between 0 and 1. All draws are equal to `mean`
#' if `mean` is 0 or 1, or `alpha` is infinite.
r_beta <- function(n, mean, alpha) {
  check_shape(mean, "mean")
  check_shape(alpha, "alpha")
  if (mean > 1) {
    stop("mean must be between 0 and 1.")
  }
  if (alpha == 0) {
    stop("alpha must be larger than 0.")
  }
  if (mean == 0 || mean == 1 || is.infinite(alpha)) {
    return(rep(mean, n))
  }
  stats::rbeta(n, shape1 = alpha, shape2 = alpha * (1 - mean) / mean)
}

# =============================================================================
#' Quantiles of a beta distribution
#'
#' Quantile function of the beta distribution of [RFDose::r_beta()].
#'
#' @param p Vector of probabilities
#' @inheritParams r_beta
#'
#' @returns Vector of quantiles between 0 and 1, increasing with `p`. All
#' quantiles are equal to `mean` if `mean` is 0 or 1, or `alpha` is infinite.
q_beta <- function(p, mean, alpha) {
  check_shape(mean, "mean")
  check_shape(alpha, "alpha")
  if (mean > 1) {
    stop("mean must be between 0 and 1.")
  }
  if (alpha == 0) {
    stop("alpha must be larger than 0.")
  }
  if (mean == 0 || mean == 1 || is.infinite(alpha)) {
    return(rep(mean, length(p)))
  }
  stats::qbeta(p, shape1 = alpha, shape2 = alpha * (1 - mean) / mean)
}

# =============================================================================
#' Draw from a Dirichlet distribution
#'
#' @param n Number of draws
#' @param mean Vector of means (proportions that sum to 1)
#' @param a0 Concentration: the larger, the closer the draws are to `mean`
#'
#' @returns Matrix with one row per draw and one column per proportion; each
#' row sums to 1. Proportions with mean 0 stay 0. All rows are equal to `mean`
#' if `a0` is infinite.
r_dirichlet <- function(n, mean, a0) {
  if (length(mean) < 2) {
    stop("mean must have at least two proportions.")
  }
  for (m in mean) check_shape(m, "mean")
  check_shape(a0, "a0")
  if (abs(sum(mean) - 1) > 1e-9) {
    stop("mean must sum to 1.")
  }
  if (a0 == 0) {
    stop("a0 must be larger than 0.")
  }
  if (is.infinite(a0)) {
    draws <- matrix(mean, nrow = n, ncol = length(mean), byrow = TRUE)
  } else {
    # Proportions of independent gamma draws (shape 0 always gives 0)
    draws <- matrix(vapply(mean, function(m) stats::rgamma(n, shape = a0 * m), numeric(n)),
                    nrow = n)
    if (any(rowSums(draws) == 0)) {
      stop("draws are all 0: a0 is too small.")
    }
    draws <- draws / rowSums(draws)
  }
  colnames(draws) <- names(mean)
  draws
}

# =============================================================================
#' Check a shape value of a distribution
#'
#' @param x Value to check: a single number, 0 or more (may be infinite)
#' @param name Name of the value, for the error message
#'
#' @returns Returns invisible TRUE if the check passes. Side effect of stopping
#' calculation if it fails.
check_shape <- function(x, name) {
  if (length(x) != 1 || !is.numeric(x) || is.na(x) || x < 0) {
    stop(name, " must be a single number, 0 or more.")
  }
  invisible(TRUE)
}
