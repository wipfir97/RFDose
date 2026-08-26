# Farfield_msar ===============================================================
cases_farfield_msar <- list(
  list(
    input = list(
      tissue      = "brain",
      country     = "Other",
      urbanicity  = "suburban",
      travel_time = 0
    ),
    output = 0.001836153

  ),
  list(
    input = list(
      tissue      = "body",
      country     = "Other",
      urbanicity  = "suburban",
      travel_time = 0
    ),
    output = 0.001536210

  )
)

test_that("farfield_msar matches reference values", {
  for (case in cases_farfield_msar) {
    result <- do.call(farfield_msar, case$input)
    expect_equal(result, case$output, tolerance = 1e-6)
  }
})

# farfield_pwr ================================================================
cases_farfield_pwr <- list(
    list(
    input = list(
      country     = "Other",
      urbanicity  = "urban",
      travel_time = 1850
    ),
    output = 0.5629115
  ), 
    list(
    input = list(
      country     = "Other",
      urbanicity  = "rural",
      travel_time = 0
    ),
    output = 0.1102724
  ), 
    list(
    input = list(
      country     = "Other",
      urbanicity  = "suburban",
      travel_time = 0
    ),
    output = 0.3343740


  )
)

test_that("farfield_pwr matches reference values", {
  for (case in cases_farfield_pwr) {
    result <- do.call(farfield_pwr, case$input)
    expect_equal(result, case$output, tolerance = 1e-5)
  }
})

# farfield_sar ================================================================
cases_farfield_sar <- list(
  list(
    input = list(
      tissue = "brain"
    ),
    output = 0.005491315
  ),
  list(
    input = list(
      tissue = "body"
    ),
    output = 0.004594286
  )
)

test_that("farfield_sar matches reference values", {
  for (case in cases_farfield_sar) {
    result <- do.call(farfield_sar, case$input)
    expect_equal(result, case$output, tolerance = 1e-6)
  }
})
