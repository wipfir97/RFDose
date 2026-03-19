test_that("get_tablet_dose errors if required argument is missing", {
  expect_error(
    get_tablet_dose(
      dur_low = 728,
      dur_lowtomed = 81,
      dur_medtohigh = 728),
    "missing"
  )
})

test_that("get_tablet_dose errors if input values are incorrect type", {
  expect_error(
    get_tablet_dose(
      dur_low = 728,
      dur_lowtomed = 81,
      dur_medtohigh = 728,
      dur_high = "81")
  )
})

test_that("get_tablet_dose errors if nonsense input durations are used", {
  expect_error(
    get_tablet_dose(
      dur_low = 728,
      dur_lowtomed = -81,
      dur_medtohigh = 728,
      dur_high = 81)
  )
})

test_that("get_tablet_dose warns if use duration exceeds 86400s per day", {
  expect_warning(
    get_tablet_dose(
      dur_low = 90000,
      dur_lowtomed = 81,
      dur_medtohigh = 728,
      dur_high = 81)
  )
})

reference_cases <- list(
  list(
    input = list(dur_low = 100, dur_lowtomed = 500, dur_medtohigh = 400, dur_high = 200),
    output = list(brain_tblt_dose = 12.74, body_tblt_dose = 14.65)
  ),
  list(
    input = list(dur_low = 0, dur_lowtomed = 0, dur_medtohigh = 0, dur_high = 0),
    output = list(brain_tblt_dose = 0, body_tblt_dose = 0)
  ),
  list(
    input = list(dur_low = 1800, dur_lowtomed = 2466, dur_medtohigh = 9876, dur_high = 222),
    output = list(brain_tblt_dose = 119.87, body_tblt_dose = 137.86)
  )
)

test_that("get_tablet_dose matches reference calculations", {
  for (case in reference_cases) {
    result <- do.call(get_tablet_dose, case$input)
    expect_equal(result, case$output, tolerance = 1e-2) # tolerance due to rounding inconsistencies
  }
})
