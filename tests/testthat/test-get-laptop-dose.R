test_that("get_laptop_dose errors if required argument is missing", {
  expect_error(
    get_laptop_dose(
      dur_low = 1967,
      dur_lowtomed = 219,
      dur_medtohigh = 1967),
    "missing"
  )
})

test_that("get_laptop_dose errors if input values are incorrect type", {
  expect_error(
    get_laptop_dose(
      dur_low = 1967,
      dur_lowtomed = 219,
      dur_medtohigh = 1967,
      dur_high = "219")
  )
})


test_that("get_laptop_dose warns if nonsense input durations are used", {
  expect_warning(
    get_laptop_dose(
      dur_low = 1967,
      dur_lowtomed = -219,
      dur_medtohigh = 1967,
      dur_high = 219)
  )
  expect_warning(
    get_laptop_dose(
      dur_low = 90000,
      dur_lowtomed = 219,
      dur_medtohigh = 1967,
      dur_high = 219)
  )
})

reference_cases <- list(
  list(
    input = list(dur_low = 100, dur_lowtomed = 500, dur_medtohigh = 400, dur_high = 200),
    output = list(brain_lptp_dose = 0.82, body_lptp_dose = 34.21)
  ),
  list(
    input = list(dur_low = 0, dur_lowtomed = 0, dur_medtohigh = 0, dur_high = 0),
    output = list(brain_lptp_dose = 0, body_lptp_dose = 0)
  ),
  list(
    input = list(dur_low = 1800, dur_lowtomed = 2466, dur_medtohigh = 9876, dur_high = 222),
    output = list(brain_lptp_dose = 7.72, body_lptp_dose = 321.79)
 )
)

test_that("get_laptop_dose matches reference calculations", {
  for (case in reference_cases) {
    result <- do.call(get_laptop_dose, case$input)
    expect_equal(result, case$output, tolerance = 1e-2) # tolerance due to rounding inconsistencies
  }
})



