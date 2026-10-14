# Distributions of the stochastic dose calculation ############################

## Lognormal ==================================================================
test_that("r_lognormal has the given mean and sd", {
  set.seed(1)
  x <- r_lognormal(1e5, mean = 2, sd = 0.6)

  expect_length(x, 1e5)
  expect_true(all(x > 0))
  expect_equal(mean(x), 2, tolerance = 0.01)
  expect_equal(sd(x), 0.6, tolerance = 0.03)
})

test_that("r_lognormal follows the lognormal distribution", {
  set.seed(2)
  x     <- r_lognormal(2000, mean = 2, sd = 0.6)
  sdlog <- sqrt(log(1 + 0.3^2))

  expect_gt(stats::ks.test(x, "plnorm", log(2) - sdlog^2 / 2, sdlog)$p.value, 0.01)
})

test_that("r_lognormal gives the mean if mean or sd is 0", {
  expect_equal(r_lognormal(3, mean = 2, sd = 0), c(2, 2, 2))
  expect_equal(r_lognormal(3, mean = 0, sd = 1), c(0, 0, 0))
})

test_that("r_lognormal stops for invalid values", {
  expect_error(r_lognormal(3, mean = -1, sd = 1), "mean")
  expect_error(r_lognormal(3, mean = 1, sd = NA), "sd")
  expect_error(r_lognormal(3, mean = c(1, 2), sd = 1), "mean")
})

## Truncated lognormal ========================================================
test_that("trunc_lognormal_mean is the mean of the truncated distribution", {
  cases <- list(c(5, 0.3, 0, 200), c(5.2, 0.3, 100, 180), c(1, 0.5, 2, Inf), c(0, 1, 0.5, 3))
  for (case in cases) {
    meanlog <- case[1]; sdlog <- case[2]; lower <- case[3]; upper <- case[4]
    mass     <- stats::plnorm(upper, meanlog, sdlog) - stats::plnorm(lower, meanlog, sdlog)
    integral <- stats::integrate(function(x) x * stats::dlnorm(x, meanlog, sdlog),
                                 lower, upper, rel.tol = 1e-10)$value

    expect_equal(trunc_lognormal_mean(meanlog, sdlog, lower, upper), integral / mass,
                 tolerance = 1e-8, label = paste(case, collapse = " "))
  }
})

test_that("trunc_lognormal_meanlog gives the mean after truncation", {
  cases <- list(c(178.1, 0.29, 0.001, 200), c(250, 0.1, 0, 300), c(10, 0.5, 9.5, 20),
                c(3, 0.3, 0, Inf), c(0.05, 1, 0.04, 0.06))
  for (case in cases) {
    mean <- case[1]; sdlog <- case[2]; lower <- case[3]; upper <- case[4]
    meanlog <- trunc_lognormal_meanlog(mean, sdlog, lower, upper)

    expect_equal(trunc_lognormal_mean(meanlog, sdlog, lower, upper), mean,
                 tolerance = 1e-10, label = paste(case, collapse = " "))
  }
})

test_that("r_trunc_lognormal keeps the mean and the bounds", {
  # mean close to max: truncation alone would move the mean down by about 15 %
  set.seed(3)
  x <- r_trunc_lognormal(1e5, mean = 178.1, sd = 53.43, min = 0.001, max = 200)

  expect_true(all(x >= 0.001 & x <= 200))
  expect_equal(mean(x), 178.1, tolerance = 0.002)
  expect_lt(sd(x), 53.43)
})

test_that("r_trunc_lognormal keeps the mean with min above the median", {
  set.seed(4)
  x <- r_trunc_lognormal(1e5, mean = 10, sd = 5, min = 9.5, max = 20)

  expect_true(all(x >= 9.5 & x <= 20))
  expect_equal(mean(x), 10, tolerance = 0.002)
})

test_that("r_trunc_lognormal follows the truncated distribution", {
  set.seed(5)
  x       <- r_trunc_lognormal(2000, mean = 178.1, sd = 53.43, min = 0.001, max = 200)
  sdlog   <- sqrt(log(1 + (53.43 / 178.1)^2))
  meanlog <- trunc_lognormal_meanlog(178.1, sdlog, 0.001, 200)
  p       <- stats::plnorm(c(0.001, 200), meanlog, sdlog)
  cdf     <- function(q) (stats::plnorm(q, meanlog, sdlog) - p[1]) / (p[2] - p[1])

  expect_gt(stats::ks.test(x, cdf)$p.value, 0.01)
})

test_that("r_trunc_lognormal is the lognormal distribution without bounds", {
  sdlog <- sqrt(log(1 + 0.3^2))

  expect_equal(trunc_lognormal_meanlog(2, sdlog, 0, Inf), log(2) - sdlog^2 / 2, tolerance = 1e-10)
})

test_that("r_trunc_lognormal gives the mean if sd is 0", {
  expect_equal(r_trunc_lognormal(3, mean = 2, sd = 0, min = 0, max = 5), c(2, 2, 2))
})

test_that("r_trunc_lognormal stops for invalid values", {
  expect_error(r_trunc_lognormal(3, mean = 6, sd = 1, min = 0, max = 5), "between min and max")
  expect_error(r_trunc_lognormal(3, mean = 0, sd = 1, min = 0, max = 5), "between min and max")
  expect_error(r_trunc_lognormal(3, mean = 2, sd = 1, min = 5, max = 5), "max")
  expect_error(r_trunc_lognormal(3, mean = 2, sd = 1, min = -1, max = 5), "min")
})

## Beta =======================================================================
test_that("r_beta has the given mean and a0 = alpha/mean", {
  set.seed(6)
  mean  <- 0.12
  alpha <- 4
  a0    <- alpha / mean
  x     <- r_beta(1e5, mean = mean, alpha = alpha)

  expect_true(all(x >= 0 & x <= 1))
  expect_equal(mean(x), mean, tolerance = 0.01)
  expect_equal(var(x), mean * (1 - mean) / (a0 + 1), tolerance = 0.03)
})

test_that("r_beta follows the beta distribution", {
  set.seed(7)
  x <- r_beta(2000, mean = 0.3, alpha = 4)

  expect_gt(stats::ks.test(x, "pbeta", 4, 4 * 0.7 / 0.3)$p.value, 0.01)
})

test_that("r_beta gives the mean if mean is 0 or 1, or alpha is infinite", {
  expect_equal(r_beta(3, mean = 0, alpha = 4), c(0, 0, 0))
  expect_equal(r_beta(3, mean = 1, alpha = 4), c(1, 1, 1))
  expect_equal(r_beta(3, mean = 0.3, alpha = Inf), c(0.3, 0.3, 0.3))
})

test_that("r_beta stops for invalid values", {
  expect_error(r_beta(3, mean = 1.2, alpha = 4), "mean")
  expect_error(r_beta(3, mean = -0.1, alpha = 4), "mean")
  expect_error(r_beta(3, mean = 0.3, alpha = 0), "alpha")
})

## Dirichlet ==================================================================
test_that("r_dirichlet draws proportions that sum to 1, with the given means", {
  set.seed(8)
  mean <- c(home = 0.7, outd = 0.1, work = 0.2)
  a0   <- 100
  x    <- r_dirichlet(1e5, mean = mean, a0 = a0)

  expect_equal(dim(x), c(1e5, 3))
  expect_equal(colnames(x), names(mean))
  expect_true(all(x >= 0 & x <= 1))
  expect_equal(rowSums(x), rep(1, 1e5), tolerance = 1e-12)
  expect_equal(colMeans(x), mean, tolerance = 0.01)
  expect_equal(apply(x, 2, var), mean * (1 - mean) / (a0 + 1), tolerance = 0.03)
})

test_that("r_dirichlet keeps proportions with mean 0 at 0", {
  set.seed(9)
  x <- r_dirichlet(100, mean = c(0, 0.0175, 0.9825), a0 = 100)

  expect_equal(x[, 1], rep(0, 100))
  expect_equal(rowSums(x), rep(1, 100), tolerance = 1e-12)
})

test_that("r_dirichlet returns a matrix also for one draw", {
  x <- r_dirichlet(1, mean = c(0.5, 0.5), a0 = 10)

  expect_equal(dim(x), c(1, 2))
})

test_that("r_dirichlet gives the means if a0 is infinite", {
  expect_equal(r_dirichlet(2, mean = c(0.25, 0.75), a0 = Inf),
               matrix(c(0.25, 0.75), nrow = 2, ncol = 2, byrow = TRUE))
})

test_that("r_dirichlet stops for invalid values", {
  expect_error(r_dirichlet(3, mean = c(0.5, 0.6), a0 = 10), "sum to 1")
  expect_error(r_dirichlet(3, mean = 1, a0 = 10), "two")
  expect_error(r_dirichlet(3, mean = c(-0.5, 1.5), a0 = 10), "mean")
  expect_error(r_dirichlet(3, mean = c(0.5, 0.5), a0 = 0), "a0")
})
