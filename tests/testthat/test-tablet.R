# tablet_dose =================================================================
test_that("tablet_dose errors if required argument is missing", {
  expect_error(
    tablet_dose(
      tissue      = "brain",
      dur_low     = 0,
      dur_lowmed  = 1230,
      dur_high    = 0)
  )
  expect_error(
    tablet_dose(
      dur_low     = 0,
      dur_lowmed  = 1230,
      dur_medhigh = 0,
      dur_high    = 0)
  )
})

test_that("tablet_dose errors if required argument is NA", {
  expect_error(
    tablet_dose(
      tissue      = "brain",
      dur_low     = 0,
      dur_lowmed  = NA,
      dur_medhigh = 0,
      dur_high    = 0)
  )
  expect_error(
    tablet_dose(
      tissue      = NA,
      dur_low     = 0,
      dur_lowmed  = 1230,
      dur_medhigh = 0,
      dur_high    = 0)
  )
})

test_that("tablet_dose errors if input argument is incorrect type", {
  expect_error(
    tablet_dose(
      tissue      = "brain",
      dur_low     = 0,
      dur_lowmed  = "1230",
      dur_medhigh = 0,
      dur_high    = 0)
  )
  expect_error(
    tablet_dose(
      tissue      = 42,
      dur_low     = 0,
      dur_lowmed  = 1230,
      dur_medhigh = 0,
      dur_high    = 0)
  )
})

test_that("tablet_dose errors if input argument is not valid", {
  expect_error(
    tablet_dose(
      tissue      = "brain",
      dur_low     = 0,
      dur_lowmed  = -1230,
      dur_medhigh = 0,
      dur_high    = 0)
  )
  expect_error(
    tablet_dose(
      tissue      = "popsicle",
      dur_low     = 0,
      dur_lowmed  = 1230,
      dur_medhigh = 0,
      dur_high    = 0)
  )
})

test_that("tablet_dose warns if sum of durations exceeds 86400 seconds", {
  expect_warning(
    tablet_dose(
      tissue      = "brain",
      dur_low     = 30000,
      dur_lowmed  = 30000,
      dur_medhigh = 30000,
      dur_high    = 30000)
  )
})

cases_tablet_dose <- list(
  list(
    input = list(
      tissue      = "brain",
      dur_low     = 728,
      dur_lowmed  = 81,
      dur_medhigh = 728,
      dur_high    = 81
    ),
    output = 12.19
  ),
  list(
    input = list(
      tissue      = "body",
      dur_low     = 728,
      dur_lowmed  = 81,
      dur_medhigh = 728,
      dur_high    = 81
    ),
    output = 13.68
  )
)

test_that("tablet_dose matches reference values", {
  for (case in cases_tablet_dose) {
    result <- do.call(tablet_dose, case$input)
    expect_equal(result, case$output, tolerance = 1e-2)
  }
})


