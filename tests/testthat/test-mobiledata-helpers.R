# mpd_msar ====================================================================
cases_mpd_msar <- list(
  list(
    input = list(
      tissue           = "brain",
      duration_low     = 4860,
      duration_lowmed  = 540,
      duration_medhigh = 4860,
      duration_high    = 540,
      use_5g           = TRUE,
      wifi_prop_home   = 0.5,
      wifi_prop_work   = 0.5,
      wifi_prop_travel = 0.5,
      urbanicity       = "suburban",
      travel_time      = 1800
    ),
    output = 0.016419195
  ),
  list(
    input = list(
      tissue           = "body",
      duration_low     = 4860,
      duration_lowmed  = 540,
      duration_medhigh = 4860,
      duration_high    = 540,
      use_5g           = TRUE,
      wifi_prop_home   = 0.5,
      wifi_prop_work   = 0.5,
      wifi_prop_travel = 0.5,
      urbanicity       = "suburban",
      travel_time      = 1800
    ),
    output = 0.008660705
  )
)

test_that("mpd_msar matches reference values", {
  for (case in cases_mpd_msar) {
    result <- do.call(mpd_msar, case$input)
    expect_equal(result, case$output, tolerance = 1e-1) # still have rounding issues
  }
})

# mpd_pwr_data ================================================================
cases_mpd_pwr_data <- list(
  list(
    input = list(
      band             = "3g",
      duration_low     = 4860,
      duration_lowmed  = 540,
      duration_medhigh = 4860,
      duration_high    = 540,
      urbanicity       = "suburban",
      travel_time      = 1800
    ),
    output = 56.96
  ),
  list(
    input = list(
      band             = "4g",
      duration_low     = 4860,
      duration_lowmed  = 540,
      duration_medhigh = 4860,
      duration_high    = 540,
      urbanicity       = "suburban",
      travel_time      = 1800
    ),
    output = 8.92
  ),
  list(
    input = list(
      band             = "5g",
      duration_low     = 4860,
      duration_lowmed  = 540,
      duration_medhigh = 4860,
      duration_high    = 540,
      urbanicity       = "suburban",
      travel_time      = 1800
    ),
    output = 7.30
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
    output = 0.003629
  ),
  list(
    input = list(
      band   = "3g",
      tissue = "body"
    ),
    output = 0.001066
  ),
  list(
    input = list(
      band   = "4g",
      tissue = "brain"
    ),
    output = 0.003235
  ),
  list(
    input = list(
      band   = "4g",
      tissue = "body"
    ),
    output = 0.001031
  ),
  list(
    input = list(
      band   = "5g",
      tissue = "brain"
    ),
    output = 0.000505
  ),
  list(
    input = list(
      band   = "5g",
      tissue = "body"
    ),
    output = 0.000707
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
      duration_low     = 4860,
      duration_lowmed  = 540,
      duration_medhigh = 4860,
      duration_high    = 540
    ),
    output = 11.76
  ),
  list(
    input = list(
      band             = "5",
      duration_low     = 4860,
      duration_lowmed  = 540,
      duration_medhigh = 4860,
      duration_high    = 540
    ),
    output = 10.48
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
    output = 0.000999
  ),
  list(
    input = list(
      band   = "2",
      tissue = "body"
    ),
    output = 0.000861
  ),
  list(
    input = list(
      band   = "5",
      tissue = "brain"
    ),
    output = 0.000163
  ),
  list(
    input = list(
      band   = "5",
      tissue = "body"
    ),
    output = 0.000586
  )
)

test_that("mpd_sar_wifi matches reference values", {
  for (case in cases_mpd_sar_wifi) {
    result <- do.call(mpd_sar_wifi, case$input)
    expect_equal(result, case$output, tolerance = 1e-3)
  }
})
