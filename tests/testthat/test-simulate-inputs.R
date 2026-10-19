# Input draws of the stochastic dose calculation ##############################

specs <- load_input_distributions()
types <- vapply(specs, function(spec) spec$distribution, character(1))
data  <- prepare_dose_data(as.data.frame(dplyr::bind_rows(make_test_input(), example_data)))
n     <- 2e4

set.seed(41)
draws <- simulate_inputs(n, data, specs)

## Structure ==================================================================
test_that("simulate_inputs returns a matrix row x draw for every drawn input", {
  expect_equal(names(draws), names(specs))
  for (name in names(draws)) {
    expect_equal(dim(draws[[name]]), c(nrow(data), n), label = name)
    expect_false(anyNA(draws[[name]]), label = name)
  }
  expect_type(draws$urbanicity, "character")
})

test_that("simulate_inputs is reproducible with set.seed", {
  set.seed(42)
  first <- simulate_inputs(5, data, specs)
  set.seed(42)

  expect_identical(simulate_inputs(5, data, specs), first)
})

test_that("simulate_inputs stops for invalid n and missing inputs", {
  expect_error(simulate_inputs(0, data, specs), "n must")
  expect_error(simulate_inputs(5, data[, setdiff(names(data), "travel_time")], specs), "travel_time")
})

test_that("the draws of a row do not depend on the other rows", {
  set.seed(43)
  all_rows <- simulate_inputs(20, data, specs)
  set.seed(43)
  one_row  <- simulate_inputs(20, data[3, ], specs)

  for (name in names(specs)) {
    expect_identical(all_rows[[name]][3, , drop = FALSE], one_row[[name]], label = name)
  }
})

## Values =====================================================================
test_that("lognormal inputs keep their value as mean, with a relative sd of sd_rel", {
  for (name in names(specs)[types %in% c("lognormal", "trunc_lognormal")]) {
    x     <- draws[[name]]
    value <- as.numeric(data[[name]])
    upper <- if (is.null(specs[[name]]$max)) Inf else specs[[name]]$max
    drawn <- value > 0 & value < upper

    expect_gt(sum(drawn), 0)
    expect_equal(rowMeans(x)[drawn], value[drawn], tolerance = 0.01, label = name)
    expect_equal(apply(x, 1, stats::sd)[drawn] / value[drawn], rep(specs[[name]]$sd_rel, sum(drawn)),
                 tolerance = 0.05, label = name)
    # durations of 0, and values at a bound, stay
    expect_true(all(x[!drawn, , drop = FALSE] == value[!drawn]), label = name)
  }
})

test_that("durations just below 24 h are drawn just below 24 h, with their value as mean", {
  near <- data[1, ]
  near$smartwatch_duration <- 86000
  near$headphone_duration  <- 86399
  set.seed(44)
  x <- simulate_inputs(2000, near, specs)

  for (name in c("smartwatch_duration", "headphone_duration")) {
    expect_true(all(x[[name]] > 0 & x[[name]] <= 86400), label = name)
    expect_equal(mean(x[[name]]), near[[name]], tolerance = 1e-3, label = name)
  }
})

test_that("beta inputs keep their value as mean and stay between 0 and 1", {
  for (name in names(specs)[types == "beta"]) {
    x     <- draws[[name]]
    value <- as.numeric(data[[name]])
    z     <- (rowMeans(x) - value) / (apply(x, 1, stats::sd) / sqrt(n))
    z[!is.finite(z)] <- 0

    expect_true(all(x >= 0 & x <= 1), label = name)
    expect_true(all(abs(z) < 5), label = name)
  }
})

test_that("the call modes are drawn together with their rest, the speaker mode", {
  ear   <- draws$mpc_ear_prop
  headp <- draws$mpc_headp_prop

  expect_true(all(ear >= 0 & headp >= 0 & ear + headp <= 1 + 1e-12))
  expect_equal(rowMeans(ear), data$mpc_ear_prop, tolerance = 0.01)
  expect_equal(rowMeans(headp), data$mpc_headp_prop, tolerance = 0.01)
  expect_equal(rowMeans(1 - ear - headp), 1 - data$mpc_ear_prop - data$mpc_headp_prop,
               tolerance = 0.01)
})

test_that("urbanicity is drawn with the probabilities of the given value", {
  values <- names(specs$urbanicity$probs)
  for (i in seq_len(nrow(data))) {
    given  <- data$urbanicity[i]
    shares <- as.numeric(table(factor(draws$urbanicity[i, ], values))) / n
    probs  <- unname(unlist(specs$urbanicity$probs[[given]]))

    expect_true(all(abs(shares - probs) < 0.015), label = given)
  }
})

test_that("inputs without a distribution are not drawn", {
  expect_false(any(c("country", "use_5g", "headp_ear_num") %in% names(draws)))
})

## Quantile functions =========================================================
test_that("q_category draws the value of the interval of p", {
  probs <- list(urban = list(urban = 0.8, suburban = 0.1, rural = 0.1))

  expect_equal(q_category(c(0.5, 0.8, 0.85, 0.95), "urban", probs),
               c("urban", "urban", "suburban", "rural"))
  expect_error(q_category(0.5, "town", probs), "town")
})

test_that("q_shares draws shares with their rest; shares of 0 stay 0", {
  set.seed(44)
  p      <- matrix(stats::runif(3000), ncol = 3)
  shares <- q_shares(p, c(0.6, 0), a0 = 100)

  expect_equal(dim(shares), c(1000, 2))
  expect_equal(shares[, 2], rep(0, 1000))
  expect_equal(mean(shares[, 1]), 0.6, tolerance = 0.01)
  expect_equal(q_shares(p[1:2, ], c(0.3, 0.2), a0 = Inf), matrix(c(0.3, 0.2), 2, 2, byrow = TRUE))
  expect_error(q_shares(p, c(0.7, 0.4), a0 = 100), "more than 1")
})
