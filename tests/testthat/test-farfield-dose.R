# farfield_dose ===============================================================
test_that("farfield_dose errors if required argument is missing", {
  expect_error(
    farfield_dose(
      country = "CH",
      travel_time = 1800),
    "urbanicity"
  )
})

test_that("farfield_dose errors if input values are incorrect type", {
  expect_error(
    farfield_dose(
      country = 5,
      urbanicity = "suburban",
      travel_time = 1800)
  )
  expect_error(
    farfield_dose(
      country = "CH",
      urbanicity = 7,
      travel_time = 1800)
  )
  expect_error(
    farfield_dose(
      country = "CH",
      urbanicity = "suburban",
      travel_time = "1800"),
    "numeric"
  )
})

test_that("farfield_dose errors if unknown country code is used", {
  expect_error(
    farfield_dose(
      country = "XY",
      urbanicity = "suburban",
      travel_time = 1800)
  )
})

test_that("farfield_dose errors if invalid urbanicity input is used", {
  expect_error(
    farfield_dose(
      country = "AT",
      urbanicity = "forest",
      travel_time = 1800)
  )
})

test_that("farfield_dose errors if nonsensical travel_time is used", {
  expect_error(
    farfield_dose(
      country = "CH",
      urbanicity = "rural",
      travel_time = -1800)
  )
})

cases_farfield_dose <- list(
  list(
    input = list(
      tissue      = "brain",
      country     = "Other",
      urbanicity  = "suburban",
      travel_time = 1800
    ),
    output = 160.9282589
    ),
  list(
    input = list(
      tissue      = "body",
      country     = "Other",
      urbanicity  = "suburban",
      travel_time = 1800
    ),
    output = 137.7382324
  )
)

test_that("farfield_dose matches reference values", {
  for (case in cases_farfield_dose) {
    result <- do.call(farfield_dose, case$input)
    expect_equal(result, case$output, tolerance = 1e-2)
  }
})

# Farfield_msar ===============================================================
cases_farfield_msar <- list(
  list(
    input = list(
      tissue      = "body",
      country     = "Other",
      urbanicity  = "suburban",
      travel_time = 1800
    ),
    output = 0.001594193
  ),
  list(
    input = list(
      tissue      = "brain",
      country     = "Other",
      urbanicity  = "suburban",
      travel_time = 1800
    ),
    output = 0.001862596
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
      travel_time = 1800
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
    output = 0.005439141
  ),
  list(
    input = list(
      tissue = "body"
    ),
    output = 0.004655352
  )
)

test_that("farfield_sar matches reference values", {
  for (case in cases_farfield_sar) {
    result <- do.call(farfield_sar, case$input)
    expect_equal(result, case$output, tolerance = 1e-2)
  }
})


