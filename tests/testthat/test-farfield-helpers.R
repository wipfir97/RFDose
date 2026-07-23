# Farfield_msar ===============================================================
cases_farfield_msar <- list(
  list(
    input = list(
      tissue      = "brain",
      country     = "Other",
      urbanicity  = "suburban",
      travel_time = 1850
    ),
    output = 0.001881694
  ),
  list(
    input = list(
      tissue      = "body",
      country     = "Other",
      urbanicity  = "suburban",
      travel_time = 1850
    ),
    output = 0.001574312
  )
)

test_that("farfield_msar matches reference values", {
  for (case in cases_farfield_msar) {
    result <- do.call(farfield_msar, case$input)
    expect_equal(result, case$output, tolerance = 1e-2)
  }
})

# farfield_pwr ================================================================
cases_farfield_pwr <- list(
  list(
    input = list(
      country     = "Other",
      urbanicity  = "suburban",
      travel_time = 1850
    ),
    output = 0.34
  )
)

test_that("farfield_pwr matches reference values", {
  for (case in cases_farfield_pwr) {
    result <- do.call(farfield_pwr, case$input)
    expect_equal(result, case$output, tolerance = 1e-2)
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
    expect_equal(result, case$output, tolerance = 1e-2)
  }
})
