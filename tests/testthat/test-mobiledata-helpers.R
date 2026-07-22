# mpd_msar ====================================================================
cases_mpd_msar <- list(
  list(
    input = list(
      tissue           = "brain",
      duration_low     = 3989,
      duration_lowmed  = 4917,
      duration_medhigh = 5651,
      duration_high    = 0,
      use_5g           = TRUE,
      wifi_prop_home   = 0.74,
      wifi_prop_work   = 0.49,
      wifi_prop_travel = 0.31,
      urbanicity       = "suburban",
      travel_time      = 1850
    ),
    output = 0.010986358
  ),
  list(
    input = list(
      tissue           = "body",
      duration_low     = 3989,
      duration_lowmed  = 4917,
      duration_medhigh = 5651,
      duration_high    = 0,
      use_5g           = TRUE,
      wifi_prop_home   = 0.74,
      wifi_prop_work   = 0.49,
      wifi_prop_travel = 0.31,
      urbanicity       = "suburban",
      travel_time      = 1850
    ),
    output = 0.006212321
  )
)

test_that("mpd_msar matches reference values", {
  for (case in cases_mpd_msar) {
    result <- do.call(mpd_msar, case$input)
    expect_equal(result, case$output, tolerance = 1e-2) # still have rounding issues
  }
})

# mpd_pwr_data ================================================================
cases_mpd_pwr_data <- list(
  list(
    input = list(
      band             = "3g",
      duration_low     = 3989,
      duration_lowmed  = 4917,
      duration_medhigh = 5651,
      duration_high    = 0,
      urbanicity       = "suburban",
      travel_time      = 1850
    ),
    output = 57.21
  ),
  list(
    input = list(
      band             = "4g",
      duration_low     = 3989,
      duration_lowmed  = 4917,
      duration_medhigh = 5651,
      duration_high    = 0,
      urbanicity       = "suburban",
      travel_time      = 1850
    ),
    output = 5.58
  ),
  list(
    input = list(
      band             = "5g",
      duration_low     = 3989,
      duration_lowmed  = 4917,
      duration_medhigh = 5651,
      duration_high    = 0,
      urbanicity       = "suburban",
      travel_time      = 1850
    ),
    output = 4.93
  )
)

test_that("mpd_pwr_data matches reference values", {
  for (case in cases_mpd_pwr_data) {
    result <- do.call(mpd_pwr_data, case$input)
    expect_equal(result, case$output, tolerance = 1e-2)
  }
})

# mpd_sar_data ================================================================
cases_mpd_sar_data <- list(
  list(
    input = list(
      band   = "3g",
      tissue = "brain"
    ),
    output = 0.003828
  ),
  list(
    input = list(
      band   = "3g",
      tissue = "body"
    ),
    output = 0.001062
  ),
  list(
    input = list(
      band   = "4g",
      tissue = "brain"
    ),
    output = 0.003599
  ),
  list(
    input = list(
      band   = "4g",
      tissue = "body"
    ),
    output = 0.001036
  ),
  list(
    input = list(
      band   = "5g",
      tissue = "brain"
    ),
    output = 0.000671
  ),
  list(
    input = list(
      band   = "5g",
      tissue = "body"
    ),
    output = 0.000726
  )
)

test_that("mpd_sar_data matches reference values", {
  for (case in cases_mpd_sar_data) {
    result <- do.call(mpd_sar_data, case$input)
    expect_equal(result, case$output, tolerance = 1e-3)
  }
})

# mpd_pwr_wifi ================================================================
cases_mpd_pwr_wifi <- list(
  list(
    input = list(
      band             = "2",
      duration_low     = 3989,
      duration_lowmed  = 4917,
      duration_medhigh = 5651,
      duration_high    = 0
    ),
    output = 7.90
  ),
  list(
    input = list(
      band             = "5",
      duration_low     = 3989,
      duration_lowmed  = 4917,
      duration_medhigh = 5651,
      duration_high    = 0
    ),
    output = 10.17
  )
)

test_that("mpd_pwr_wifi matches reference values", {
  for (case in cases_mpd_pwr_wifi) {
    result <- do.call(mpd_pwr_wifi, case$input)
    expect_equal(result, case$output, tolerance = 1e-2)
  }
})

# mpc_sar_wifi ================================================================
cases_mpd_sar_wifi <- list(
  list(
    input = list(
      band   = "2",
      tissue = "brain"
    ),
    output = 0.001119
  ),
  list(
    input = list(
      band   = "2",
      tissue = "body"
    ),
    output = 0.000863
  ),
  list(
    input = list(
      band   = "5",
      tissue = "brain"
    ),
    output = 0.000320
  ),
  list(
    input = list(
      band   = "5",
      tissue = "body"
    ),
    output = 0.000554
  )
)

test_that("mpd_sar_wifi matches reference values", {
  for (case in cases_mpd_sar_wifi) {
    result <- do.call(mpd_sar_wifi, case$input)
    expect_equal(result, case$output, tolerance = 1e-3)
  }
})
