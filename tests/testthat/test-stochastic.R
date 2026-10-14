# Stochastic dose calculation #################################################

params  <- load_params()
dists   <- load_distributions()
specs   <- list_distributions(dists)
means   <- vapply(specs, function(spec) get_param(params, spec$key), numeric(1))
input   <- make_test_input()
sample  <- as.list(input)
summary_cols <- c("row", "dose", "deterministic", "mean", "sd", "q2.5", "q50", "q97.5")

# Distribution file with the same parameters, but without spread
degenerate_file <- function() {
  no_spread <- rapply(dists, function(x) x, how = "replace")
  for (spec in specs) {
    shape <- switch(spec$distribution,
      lognormal       = list(sd = 0),
      trunc_lognormal = list(sd = 0),
      beta            = list(alpha = Inf),
      dirichlet       = list(a0 = Inf))
    no_spread[[spec$key]] <- utils::modifyList(no_spread[[spec$key]], shape)
  }
  file <- tempfile(fileext = ".yaml")
  yaml::write_yaml(no_spread, file)
  file
}

## Means ======================================================================
test_that("parameter sets with the parameter values give the deterministic doses", {
  draws <- matrix(means, nrow = 3, ncol = length(means), byrow = TRUE,
                  dimnames = list(NULL, names(means)))
  for (tissue in c("brain", "body")) {
    deterministic <- total_dose(sample, tissue = tissue, params = params)
    doses         <- stochastic_doses(list(sample), tissue = tissue, params = params, draws = draws)

    for (d in 1:3) {
      expect_equal(doses[1, d, ], deterministic, tolerance = 1e-12,
                   label = paste(tissue, "draw", d))
    }
  }
})

test_that("distributions without spread give the deterministic doses", {
  file <- degenerate_file()
  for (tissue in c("brain", "body")) {
    result <- calculate_emf_doses_stochastic(input, tissue = tissue, n = 3, distributions = file,
                                             sar_sd = 0)

    expect_equal(result$mean, result$deterministic, tolerance = 1e-12, label = tissue)
    expect_equal(result$q2.5, result$deterministic, tolerance = 1e-12, label = tissue)
    expect_equal(result$q97.5, result$deterministic, tolerance = 1e-12, label = tissue)
    expect_true(all(result$sd < 1e-10 * result$deterministic + 1e-300))
  }
})

test_that("the deterministic doses are those of calculate_emf_doses", {
  set.seed(21)
  for (tissue in c("brain", "body")) {
    result <- calculate_emf_doses_stochastic(example_data, tissue = tissue, n = 2)
    det    <- calculate_emf_doses(example_data, tissue = tissue)

    for (source in dose_cols) {
      expect_equal(result$deterministic[result$dose == source], det[[source]],
                   tolerance = 1e-12, label = paste(tissue, source))
    }
  }
})

## Result =====================================================================
test_that("calculate_emf_doses_stochastic summarises every row and dose", {
  set.seed(22)
  result <- calculate_emf_doses_stochastic(example_data, tissue = "brain", n = 20,
                                           keep_draws = TRUE)
  summary <- result$summary

  expect_equal(names(summary), summary_cols)
  expect_equal(nrow(summary), nrow(example_data) * (length(dose_cols) + 1))
  expect_equal(summary$dose[summary$row == 1], c(dose_cols, "total_dose"))
  expect_equal(dim(result$doses), c(nrow(example_data), 20, length(dose_cols)))
  expect_equal(dim(result$params), c(20, length(specs) + nrow(list_sar(params))))

  # summary of the doses of every draw
  for (row in seq_len(nrow(example_data))) {
    doses <- result$doses[row, , ]
    rows  <- summary[summary$row == row, ]
    expect_equal(rows$mean, unname(c(colMeans(doses), mean(rowSums(doses)))))
    expect_equal(rows$q50, unname(c(apply(doses, 2, stats::median), stats::median(rowSums(doses)))))
    expect_equal(rows$deterministic[rows$dose == "total_dose"],
                 sum(rows$deterministic[rows$dose != "total_dose"]))
  }
})

test_that("calculate_emf_doses_stochastic names the quantiles by probs", {
  set.seed(23)
  result <- calculate_emf_doses_stochastic(input, tissue = "brain", n = 5, probs = c(0.05, 0.95))

  expect_equal(names(result), c("row", "dose", "deterministic", "mean", "sd", "q5", "q95"))
  expect_true(all(result$q5 <= result$q95))
  expect_error(calculate_emf_doses_stochastic(input, tissue = "brain", n = 5, probs = 1.5),
               "probs")
})

test_that("calculate_emf_doses_stochastic is reproducible with set.seed", {
  set.seed(24)
  first <- calculate_emf_doses_stochastic(input, tissue = "body", n = 5)
  set.seed(24)

  expect_identical(calculate_emf_doses_stochastic(input, tissue = "body", n = 5), first)
})

test_that("drawing the SAR values widens the doses", {
  for (tissue in c("brain", "body")) {
    set.seed(30)
    without <- calculate_emf_doses_stochastic(input, tissue = tissue, n = 300, sar_sd = 0)
    set.seed(30)
    with    <- calculate_emf_doses_stochastic(input, tissue = tissue, n = 300)

    expect_equal(with$deterministic, without$deterministic)
    expect_true(all(with$sd > without$sd), label = tissue)
  }
})

test_that("the doses of a row do not depend on the other rows", {
  set.seed(25)
  all_rows <- calculate_emf_doses_stochastic(example_data, tissue = "brain", n = 5)
  set.seed(25)
  one_row  <- calculate_emf_doses_stochastic(example_data[2, ], tissue = "brain", n = 5)

  expect_equal(all_rows[all_rows$row == 2, -1], one_row[, -1], ignore_attr = TRUE)
})

## Physical properties in every draw ==========================================
test_that("doses of every draw are finite and non-negative, with every SAR file", {
  sar_files <- list.files(system.file("extdata", package = "RFDose"),
                          pattern = "^sar_.*\\.yaml$", full.names = TRUE)
  for (sar_file in sar_files) {
    for (tissue in c("brain", "body")) {
      set.seed(26)
      result <- calculate_emf_doses_stochastic(example_data, tissue = tissue, n = 20,
                                               sar_file = sar_file, keep_draws = TRUE)

      expect_true(all(is.finite(result$doses) & result$doses >= 0),
                  label = paste(basename(sar_file), tissue))
    }
  }
})

test_that("the physical properties of the doses hold in every draw", {
  device_durations <- list(
    call_dose  = "mpc_duration",
    data_dose  = c("mpd_dur_low", "mpd_dur_lowtomed", "mpd_dur_medtohigh", "mpd_dur_high"),
    dect_dose  = "dect_duration",
    lptp_dose  = c("lptp_dur_low", "lptp_dur_lowtomed", "lptp_dur_medtohigh", "lptp_dur_high"),
    tblt_dose  = c("tblt_dur_low", "tblt_dur_lowtomed", "tblt_dur_medtohigh", "tblt_dur_high"),
    other_dose = c("hotspot_duration", "smartwatch_duration", "vr_duration",
                   "headphone_duration", "gaming_duration"))
  device_cols      <- names(device_durations)
  environment_cols <- setdiff(dose_cols, device_cols)

  no_use <- sample
  no_use[unlist(device_durations)] <- 0
  doubled <- lapply(device_cols, function(device) {
    x <- sample
    x[device_durations[[device]]] <- lapply(sample[device_durations[[device]]], `*`, 2)
    x
  })

  set.seed(27)
  draws <- simulate_params(10, params = params, distributions = dists)
  for (tissue in c("brain", "body")) {
    doses <- stochastic_doses(c(list(sample, no_use), doubled), tissue = tissue,
                              params = params, draws = draws)
    for (d in 1:10) {
      base <- doses[1, d, ]
      # zero use: no dose from devices, unchanged far-field and WiFi doses
      expect_equal(doses[2, d, device_cols], 0 * base[device_cols])
      expect_equal(doses[2, d, environment_cols], base[environment_cols])
      # double the durations of one device: its dose doubles, the others do not change
      for (k in seq_along(device_cols)) {
        expected <- base
        expected[device_cols[k]] <- 2 * base[device_cols[k]]
        expect_equal(doses[2 + k, d, ], expected, label = paste(tissue, device_cols[k], "draw", d))
      }
    }
  }
})

## Errors and warnings ========================================================
test_that("an error in a draw names the row and the draw", {
  # travel time just below the time at home, which some draws of home_prop fall below
  far <- input
  far$travel_time <- 0.69 * 86400
  set.seed(28)

  expect_error(calculate_emf_doses_stochastic(far, tissue = "brain", n = 200),
               "Row 1, draw [0-9]+: Calculation not defined")
})

test_that("warnings about the input are raised once, not for every draw", {
  long <- input
  long$mpc_duration <- 90000
  raised <- character(0)
  set.seed(29)
  withCallingHandlers(
    calculate_emf_doses_stochastic(long, tissue = "brain", n = 10),
    warning = function(w) {
      raised <<- c(raised, conditionMessage(w))
      invokeRestart("muffleWarning")
    })

  expect_gt(length(raised), 0)
  expect_equal(raised, unique(raised))
  expect_false(any(grepl("draws)", raised, fixed = TRUE)))
})
