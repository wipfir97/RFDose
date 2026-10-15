# Parameter sets of the stochastic dose calculation ###########################

params <- load_params()
dists  <- load_distributions()
specs  <- list_distributions(dists)
sar    <- list_sar(params)
means  <- vapply(specs, function(spec) get_param(params, spec$key), numeric(1))
types  <- vapply(specs, function(spec) spec$distribution, character(1))
groups <- vapply(specs, function(spec) {
  if (is.null(spec$group)) NA_character_ else spec$group
}, character(1))

set.seed(11)
draws <- simulate_params(2e4, params = params, distributions = dists)

## Structure ==================================================================
test_that("simulate_params returns one column per drawn parameter and SAR value", {
  expect_true(is.matrix(draws))
  expect_equal(dim(draws), c(2e4, length(specs) + nrow(sar)))
  expect_equal(colnames(draws), c(names(specs), sar$name))
  expect_false(anyNA(draws))
})

test_that("simulate_params is reproducible with set.seed", {
  set.seed(12)
  first <- simulate_params(5, params = params, distributions = dists)
  set.seed(12)

  expect_identical(simulate_params(5, params = params, distributions = dists), first)
})

test_that("simulate_params stops for invalid n and sar_sd", {
  expect_error(simulate_params(0, params = params, distributions = dists), "n must")
  expect_error(simulate_params(2.5, params = params, distributions = dists), "n must")
  expect_error(simulate_params(2, params = params, distributions = dists, sar_sd = -0.1), "sar_sd")
  expect_error(simulate_params(2, params = params, distributions = dists, sar_sd = NA), "sar_sd")
})

test_that("simulate_params names the parameter that is missing", {
  without <- params
  without$devices$dect$dect_pwr <- NULL

  expect_error(simulate_params(2, params = without, distributions = dists),
               "devices > dect > dect_pwr")
})

## Values =====================================================================
test_that("the draws have the parameter and SAR values as means", {
  # within 5 standard errors of the mean of the draws
  expected <- c(means, stats::setNames(sar$value, sar$name))
  z <- (colMeans(draws) - expected) / (apply(draws, 2, sd) / sqrt(nrow(draws)))

  expect_equal(names(z)[abs(z) > 5], character(0))
})

test_that("the draws stay within the bounds of their distributions", {
  positive  <- draws[, c(names(specs)[types %in% c("lognormal", "trunc_lognormal")], sar$name)]
  unit      <- draws[, names(specs)[types %in% c("beta", "dirichlet")]]
  truncated <- names(specs)[types == "trunc_lognormal"]
  lower     <- vapply(specs[truncated], function(spec) spec$min, numeric(1))
  upper     <- vapply(specs[truncated], function(spec) spec$max, numeric(1))

  expect_true(all(positive > 0))
  expect_true(all(unit >= 0 & unit <= 1))
  expect_true(all(t(draws[, truncated]) >= lower & t(draws[, truncated]) <= upper))
})

test_that("the spread stays relative to the mean, also with other parameter values", {
  # e.g. another parameter file: three times the means of the lognormal parameters
  lognormal <- names(specs)[types == "lognormal"]
  tripled   <- set_params(params, 3 * means[lognormal])
  sd_rel    <- vapply(specs[lognormal], function(spec) spec$sd_rel, numeric(1))
  set.seed(15)
  drawn     <- simulate_params(2e4, params = tripled, distributions = dists, sar_sd = 0)[, lognormal]

  expect_equal(colMeans(drawn), 3 * means[lognormal], tolerance = 0.01)
  expect_equal(apply(drawn, 2, stats::sd) / (3 * means[lognormal]), sd_rel, tolerance = 0.05)
})

test_that("the proportions of each Dirichlet group sum to 1 in every draw", {
  for (group in unique(groups[!is.na(groups)])) {
    members <- names(groups)[groups %in% group]

    expect_equal(rowSums(draws[, members]), rep(1, nrow(draws)), tolerance = 1e-12,
                 label = group)
    # the check of the dose calculation passes too
    for (i in 1:100) {
      expect_silent(check_proportions(draws[i, members]))
    }
  }
})

## SAR values =================================================================
test_that("SAR values of the same simulation are drawn together", {
  simulation <- paste(sar$tissue, sprintf("%.17g", sar$value))
  shared     <- unique(simulation[duplicated(simulation)])

  expect_gt(length(shared), 0)
  for (s in shared) {
    columns <- sar$name[simulation == s]
    for (column in columns[-1]) {
      expect_identical(draws[, column], draws[, columns[1]], label = column)
    }
  }
  # different simulations are drawn independently
  first <- sar$name[match(unique(simulation), simulation)]
  ratio <- t(t(draws[, first]) / sar$value[match(unique(simulation), simulation)])
  correlation <- stats::cor(ratio)
  expect_lt(max(abs(correlation[upper.tri(correlation)])), 0.05)
})

test_that("SAR values have a standard deviation of sar_sd times their value", {
  simulation <- paste(sar$tissue, sprintf("%.17g", sar$value))
  first      <- match(unique(simulation), simulation)
  ratio      <- t(t(draws[, sar$name[first]]) / sar$value[first])

  expect_equal(unname(apply(ratio, 2, sd)), rep(0.25, length(first)), tolerance = 0.05)
})

test_that("SAR values of 0 are not drawn and stay 0", {
  zero <- setdiff(grep("[.](brain|body)[.]", names(unlist(params)), value = TRUE), sar$name)
  drawn <- set_params(params, draws[1, ])

  expect_gt(length(zero), 0)
  expect_false(any(zero %in% colnames(draws)))
  expect_true(all(unlist(drawn)[zero] == 0))
})

test_that("without SAR spread, only the parameters are drawn, with the same draws", {
  set.seed(14)
  without <- simulate_params(5, params = params, distributions = dists, sar_sd = 0)
  set.seed(14)
  with    <- simulate_params(5, params = params, distributions = dists)

  expect_equal(colnames(without), names(specs))
  expect_identical(without, with[, names(specs)])
})

## Parameter sets =============================================================
test_that("set_params sets the drawn values and keeps all others", {
  drawn <- set_params(params, draws[1, ])
  other <- setdiff(names(unlist(params)), colnames(draws))

  expect_equal(vapply(specs, function(spec) get_param(drawn, spec$key), numeric(1)),
               draws[1, names(specs)])
  expect_equal(unlist(drawn)[sar$name], draws[1, sar$name])
  expect_identical(unlist(drawn)[other], unlist(params)[other])
})

test_that("simulate_params draws the SAR values of every SAR file", {
  sar_files <- list.files(system.file("extdata", package = "RFDose"),
                          pattern = "^sar_.*\\.yaml$", full.names = TRUE)
  set.seed(13)
  base <- simulate_params(3, params = params, distributions = dists)
  for (sar_file in sar_files) {
    sar_params <- load_params(sar_path = sar_file)
    file_sar   <- list_sar(sar_params)
    set.seed(13)
    sar_draws  <- simulate_params(3, params = sar_params, distributions = dists)

    # the other parameters do not depend on the SAR file
    expect_identical(sar_draws[, names(specs)], base[, names(specs)], label = basename(sar_file))
    expect_equal(colnames(sar_draws), c(names(specs), file_sar$name))
    expect_true(all(is.finite(sar_draws[, file_sar$name]) & sar_draws[, file_sar$name] > 0))
  }
})
