
# wifi_msar ===================================================================
cases_wifi_msar <- list(
  list(
    input = list(
      tissue           = "brain",
      travel_time      = 1850,
      wifi_prop_travel = 0.31
    ),
    output = 0.00001692
  ),
  list(
    input = list(
      tissue           = "body",
      travel_time      = 1850,
      wifi_prop_travel = 0.31
    ),
    output = 0.00006839
  )
)

test_that("wifi_msar matches reference values", {
  for (case in cases_wifi_msar) {
    result <- do.call(wifi_msar, case$input)
    expect_equal(result, case$output, tolerance = 1e-3)
  }
})

# wifi_pwr ====================================================================
cases_wifi_pwr <- list(
  list(
    input = list(
      band   = "2"
    ),
    output = 0.018
  ),
  list(
    input = list(
      band   = "5"
    ),
    output = 0.013
  )
)

test_that("wifi_pwr matches reference values", {
  for (case in cases_wifi_pwr) {
    result <- do.call(wifi_pwr, case$input)
    expect_equal(result, case$output, tolerance = 1e-3)
  }
})

# wifi_sar ====================================================================
cases_wifi_sar <- list(
  list(
    input = list(
      tissue = "brain",
      band   = "2"
    ),
    output = 0.00133
  ),
  list(
    input = list(
      tissue = "body",
      band   = "2"
    ),
    output = 0.005295
  ),
  list(
    input = list(
      tissue = "brain",
      band   = "5"
    ),
    output = 0.000556
  ),
  list(
    input = list(
      tissue = "body",
      band   = "5"
    ),
    output = 0.002402
  )
)

test_that("wifi_sar matches reference values", {
  for (case in cases_wifi_sar) {
    result <- do.call(wifi_sar, case$input)
    expect_equal(result, case$output, tolerance = 1e-3)
  }
})
