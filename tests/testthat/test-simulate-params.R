# Parameter sets of the stochastic dose calculation ###########################

params <- load_params()
dists  <- load_distributions()
specs  <- list_distributions(dists)
means  <- vapply(specs, function(spec) get_param(params, spec$key), numeric(1))
types  <- vapply(specs, function(spec) spec$distribution, character(1))
groups <- vapply(specs, function(spec) {
  if (is.null(spec$group)) NA_character_ else spec$group
}, character(1))

set.seed(11)
draws <- simulate_params(2e4, params = params, distributions = dists)

## Structure ==================================================================
test_that("simulate_params returns one column per drawn parameter", {
  expect_true(is.matrix(draws))
  expect_equal(dim(draws), c(2e4, length(specs)))
  expect_equal(colnames(draws), names(specs))
  expect_false(anyNA(draws))
})

test_that("simulate_params is reproducible with set.seed", {
  set.seed(12)
  first <- simulate_params(5, params = params, distributions = dists)
  set.seed(12)

  expect_identical(simulate_params(5, params = params, distributions = dists), first)
})

test_that("simulate_params stops for invalid n", {
  expect_error(simulate_params(0, params = params, distributions = dists), "n must")
  expect_error(simulate_params(2.5, params = params, distributions = dists), "n must")
})

test_that("simulate_params names the parameter that is missing", {
  without <- params
  without$devices$dect$dect_pwr <- NULL

  expect_error(simulate_params(2, params = without, distributions = dists),
               "devices > dect > dect_pwr")
})

## Values =====================================================================
test_that("the draws have the parameter values as means", {
  # within 5 standard errors of the mean of the draws
  z <- (colMeans(draws) - means) / (apply(draws, 2, sd) / sqrt(nrow(draws)))

  expect_equal(names(z)[abs(z) > 5], character(0))
})

test_that("the draws stay within the bounds of their distributions", {
  positive  <- draws[, types %in% c("lognormal", "trunc_lognormal")]
  unit      <- draws[, types %in% c("beta", "dirichlet")]
  truncated <- names(specs)[types == "trunc_lognormal"]
  lower     <- vapply(specs[truncated], function(spec) spec$min, numeric(1))
  upper     <- vapply(specs[truncated], function(spec) spec$max, numeric(1))

  expect_true(all(positive > 0))
  expect_true(all(unit >= 0 & unit <= 1))
  expect_true(all(t(draws[, truncated]) >= lower & t(draws[, truncated]) <= upper))
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

## Parameter sets =============================================================
test_that("set_params sets the drawn values and keeps all others", {
  drawn <- set_params(params, draws[1, ])
  other <- setdiff(names(unlist(params)), names(specs))

  expect_equal(vapply(specs, function(spec) get_param(drawn, spec$key), numeric(1)),
               draws[1, ])
  expect_identical(unlist(drawn)[other], unlist(params)[other])
})

test_that("simulate_params uses the parameter values of every SAR file", {
  sar_files <- list.files(system.file("extdata", package = "RFDose"),
                          pattern = "^sar_.*\\.yaml$", full.names = TRUE)
  for (sar_file in sar_files) {
    sar_params <- load_params(sar_path = sar_file)
    set.seed(13)
    sar_draws  <- simulate_params(3, params = sar_params, distributions = dists)
    set.seed(13)

    expect_identical(sar_draws, simulate_params(3, params = params, distributions = dists),
                     label = basename(sar_file))
  }
})
