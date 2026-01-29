test_that("get_other_dose errors if required argument is missing", {
  expect_error(
    get_other_dose(
      duration_hotspot = 0,
      duration_smartwatch = 0,
      duration_tracker = 0,
      duration_vr = 0,
      duration_headphones = 0),
    "duration_gaming"
  )
})

test_that("get_other_dose errors if input is not numeric", {
  expect_error(
    get_other_dose(
      duration_hotspot = 0,
      duration_smartwatch = 0,
      duration_tracker = 0,
      duration_vr = 0,
      duration_headphones = 0,
      duration_gaming = "600"),
    "numeric"
  )
})

test_that("get_other_dose errors in case of nonsense input values", {
  expect_error(
    get_other_dose(
      duration_hotspot = 0,
      duration_smartwatch = 0,
      duration_tracker = -600,
      duration_vr = 0,
      duration_headphones = 0,
      duration_gaming = 600)
  )
  expect_error(
    get_other_dose(
      duration_hotspot = 0,
      duration_smartwatch = 0,
      duration_tracker = 0,
      duration_vr = 90000,
      duration_headphones = 0,
      duration_gaming = 600)
  )
})

reference_cases <- list(
  list(
    input = list(duration_hotspot = 8400,
                 duration_smartwatch = 8400,
                 duration_tracker = 8400,
                 duration_vr = 8400,
                 duration_headphones = 8400,
                 duration_gaming = 600),
    output = list(brain_othe_dose = 68.22,
                  body_othe_dose = 480.51)
  ),
  list(
    input = list(duration_hotspot = 25000,
                 duration_smartwatch = 25000,
                 duration_tracker = 25000,
                 duration_vr = 25000,
                 duration_headphones = 25000,
                 duration_gaming = 600),
    output = list(brain_othe_dose = 200.45,
                  body_othe_dose = 1410.89)
  ),
  list(
    input = list(duration_hotspot = 0,
                 duration_smartwatch = 0,
                 duration_tracker = 0,
                 duration_vr = 0,
                 duration_headphones = 0,
                 duration_gaming = 0),
    output = list(brain_othe_dose = 0,
                  body_othe_dose = 0)
  ),
  list(
    input = list(duration_hotspot = 1800,
                 duration_smartwatch = 86400,
                 duration_tracker = 10800,
                 duration_vr = 3600,
                 duration_headphones = 3600,
                 duration_gaming = 600),
    output = list(brain_othe_dose = 27.04,
                  body_othe_dose = 178.94)
  )
)

test_that("get_other_dose matches reference calculations", {
  for (case in reference_cases) {
    result <- do.call(get_other_dose, case$input)
    expect_equal(result, case$output, tolerance = 1e-1) # tolerance due to rounding inconsistencies
  }
})

