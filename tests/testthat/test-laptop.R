# laptop_dose =================================================================
test_that("laptop_dose errors if required argument is missing", {
  expect_error(
    laptop_dose(
      tissue      = "brain",
      dur_low     = 0,
      dur_lowmed  = 1230,
      dur_high    = 0)
  )
})

test_that("laptop_dose errors if required argument is NA", {
  expect_error(
    laptop_dose(
      tissue      = "brain",
      dur_low     = NA,
      dur_lowmed  = 1230,
      dur_medhigh = 0,
      dur_high    = 0)
  )
  expect_error(
    laptop_dose(
      tissue      = NA,
      dur_low     = 0,
      dur_lowmed  = 1230,
      dur_medhigh = 0,
      dur_high    = 0)
  )
})

test_that("laptop_dose errors if input argument is incorrect type", {
  expect_error(
    laptop_dose(
      tissue      = "brain",
      dur_low     = "0",
      dur_lowmed  = 1230,
      dur_medhigh = 0,
      dur_high    = 0)
  )
  expect_error(
    laptop_dose(
      tissue      = 7,
      dur_low     = 0,
      dur_lowmed  = 1230,
      dur_medhigh = 0,
      dur_high    = 0)
  )
})

test_that("laptop_dose errors if input argument is not valid", {
  expect_error(
    laptop_dose(
      tissue      = "brain",
      dur_low     = -25,
      dur_lowmed  = 1230,
      dur_medhigh = 0,
      dur_high    = 0)
  )
  expect_error(
    laptop_dose(
      tissue      = "icecream",
      dur_low     = 0,
      dur_lowmed  = 1230,
      dur_medhigh = 0,
      dur_high    = 0)
  )
})

test_that("laptop_dose warns if sum of durations exceeds 86400 seconds", {
  expect_warning(
    laptop_dose(
      tissue      = "brain",
      dur_low     = 40000,
      dur_lowmed  = 40000,
      dur_medhigh = 40000,
      dur_high    = 40000)
  )
})

cases_laptop_dose <- list(
  list(
    input = list(
      tissue      = "brain",
      dur_low     = 1069,
      dur_lowmed  = 1168,
      dur_medhigh = 1715,
      dur_high    = 0
    ),
    output = 0.71
  ),
  list(
    input = list(
      tissue      = "body",
      dur_low     = 1069,
      dur_lowmed  = 1168,
      dur_medhigh = 1715,
      dur_high    = 0
    ),
    output = 101.38
  )
)

test_that("laptop_dose matches reference values", {
  for (case in cases_laptop_dose) {
    result <- do.call(laptop_dose, case$input)
    expect_equal(result, case$output, tolerance = 1e-2)
  }
})

