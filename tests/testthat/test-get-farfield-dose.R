test_that("get_farfield_dose errors if required argument is missing", {
  expect_error(
    get_farfield_dose(
      country = "CH",
      travel_time = 1800),
    "urbanicity"
  )
})

test_that("get_farfield_dose errors if input values are incorrect type", {
  expect_error(
    get_farfield_dose(
      country = 5,
      urbanicity = "suburban",
      travel_time = 1800)
  )
  expect_error(
    get_farfield_dose(
      country = "CH",
      urbanicity = 7,
      travel_time = 1800)
  )
  expect_error(
    get_farfield_dose(
      country = "CH",
      urbanicity = "suburban",
      travel_time = "1800"),
    "numeric"
  )
})

test_that("get_farfield_dose errors if unknown country code is used", {
  expect_error(
    get_farfield_dose(
      country = "XY",
      urbanicity = "suburban",
      travel_time = 1800)
  )
})

test_that("get_farfield_dose errors if invalid urbanicity input is used", {
  expect_error(
    get_farfield_dose(
      country = "AT",
      urbanicity = "forest",
      travel_time = 1800)
  )
})

test_that("get_farfield_dose errors if nonsensical travel_time is used", {
  expect_error(
    get_farfield_dose(
      country = "CH",
      urbanicity = "rural",
      travel_time = -1800)
  )
})

reference_cases <- list(
  list(
    input = list(country = "Other", urbanicity = "suburban", travel_time = 1800),
    output = list(brain_farf_dose = 160.93, body_farf_dose = 137.74)
  ),
  list(
    input = list(country = "Other", urbanicity = "suburban", travel_time = 900),
    output = list(brain_farf_dose = 159.03, body_farf_dose = 136.12)
  ),
  list(
    input = list(country = "Other", urbanicity = "suburban", travel_time = 0),
    output = list(brain_farf_dose = 157.14, body_farf_dose = 134.49)
  ),
  list(
    input = list(country = "Other", urbanicity = "suburban", travel_time = 60000),
    output = list(brain_farf_dose = 283.53, body_farf_dose = 242.68)
  ),
  list(
    input = list(country = "Other", urbanicity = "urban", travel_time = 1800),
    output = list(brain_farf_dose = 264.48, body_farf_dose = 226.37)
  ),
  list(
    input = list(country = "CH", urbanicity = "suburban", travel_time = 1800),
    output = list(brain_farf_dose = 55.20, body_farf_dose = 47.24)
  ),
  list(
    input = list(country = "CH", urbanicity = "urban", travel_time = 60000),
    output = list(brain_farf_dose = 125.17, body_farf_dose = 107.13)
  ),
  list(
    input = list(country = "CH", urbanicity = "rural", travel_time = 1800),
    output = list(brain_farf_dose = 38.09, body_farf_dose = 32.60)
  ),
  list(
    input = list(country = "IT", urbanicity = "suburban", travel_time = 1800),
    output = list(brain_farf_dose = 109.54, body_farf_dose = 93.76)
  ),
  list(
    input = list(country = "IT", urbanicity = "suburban", travel_time = 900),
    output = list(brain_farf_dose = 109.11, body_farf_dose = 93.39)
  ),
  list(
    input = list(country = "FR", urbanicity = "suburban", travel_time = 900),
    output = list(brain_farf_dose = 377.94, body_farf_dose = 323.48)
  ),
  list(
    input = list(country = "FR", urbanicity = "urban", travel_time = 60000),
    output = list(brain_farf_dose = 693.28, body_farf_dose = 593.37)
  ),
  list(
    input = list(country = "FR", urbanicity = "urban", travel_time = 0),
    output = list(brain_farf_dose = 720.64, body_farf_dose = 616.79)
  )
)

test_that("get_farfield_dose matches reference calculations", {
  for (case in reference_cases) {
    result <- do.call(get_farfield_dose, case$input)
    expect_equal(result, case$output, tolerance = 1e-1) # tolerance due to rounding inconsistencies
  }
})




