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

test_that("get_farfield_dose warns if nonsensical travel_time is used", {
  expect_warning(
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
  )
)

test_that("get_farfield_dose matches reference calculations", {
  for (case in reference_cases) {
    result <- do.call(get_farfield_dose, case$input)
    expect_equal(result, case$output, tolerance = 1e-2) # tolerance due to rounding inconsistencies
  }
})




