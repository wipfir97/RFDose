# farfield_dose ===============================================================
test_that("farfield_dose errors if required argument is missing", {
  expect_error(
    farfield_dose(
      tissue      = "brain",
      country     = "CH",
      travel_time = 1800),
    "urbanicity"
  )
})

test_that("farfield_dose errors if input values are incorrect type", {
  expect_error(
    farfield_dose(
      tissue      = "brain",
      country     = 5,
      urbanicity  = "suburban",
      travel_time = 1800)
  )
  expect_error(
    farfield_dose(
      tissue      = "brain",
      country     = "CH",
      urbanicity  = 7,
      travel_time = 1800)
  )
  expect_error(
    farfield_dose(
      tissue      = "brain",
      country     = "CH",
      urbanicity  = "suburban",
      travel_time = "1800"),
    "numeric"
  )
})

test_that("farfield_dose errors if unknown country code is used", {
  expect_error(
    farfield_dose(
      tissue      = "body",
      country     = "XY",
      urbanicity  = "suburban",
      travel_time = 1800)
  )
})

test_that("farfield_dose errors if invalid urbanicity input is used", {
  expect_error(
    farfield_dose(
      tissue      = "brain",
      country     = "AT",
      urbanicity  = "forest",
      travel_time = 1800)
  )
})

test_that("farfield_dose errors if nonsensical travel_time is used", {
  expect_error(
    farfield_dose(
      tissue      = "body",
      country     = "CH",
      urbanicity  = "rural",
      travel_time = -1800)
  )
})

test_that("farfield_dose errors if invalid tissue is used", {
  expect_error(
    farfield_dose(
      tissue      = "test",
      country     = "CH",
      urbanicity  = "rural",
      travel_time = 1800)
  )
})

cases_farfield_dose <- list(
  list(
    input = list(
      tissue      = "brain",
      country     = "Other",
      urbanicity  = "suburban",
      travel_time = 1850
    ),
    output = 162.5784
    ),
  list(
    input = list(
      tissue      = "body",
      country     = "Other",
      urbanicity  = "suburban",
      travel_time = 1850
    ),
    output = 136.0205
  )
)

test_that("farfield_dose matches reference values", {
  for (case in cases_farfield_dose) {
    result <- do.call(farfield_dose, case$input)
    expect_equal(result, case$output, tolerance = 1e-3)
  }
})




