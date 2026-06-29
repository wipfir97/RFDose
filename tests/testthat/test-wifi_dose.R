test_that("get_wifi_dose errors if required argument is missing", {
  expect_error(
    get_wifi_dose(travel_time = 1800),
    "wifi_prop_travel"
  )
})

test_that("get_wifi_dose errors if travel_time and wifi_prop_travel are not numeric", {
  expect_error(
    get_wifi_dose(
      travel_time = "1800",
      wifi_prop_travel = 0.5),
    "numeric"
  )
  expect_error(
    get_wifi_dose(
      travel_time = 1800,
      wifi_prop_travel = "0.5"),
    "numeric"
  )
})

test_that("get_wifi_dose errors in case of nonsense input values", {
  expect_error(
    get_wifi_dose(
      travel_time = -1800,
      wifi_prop_travel = 0.5),
    "input"
  )
  expect_error(
    get_wifi_dose(
      travel_time = 1800,
      wifi_prop_travel = 1.5),
    "input"
  )
})

reference_cases <- list(
  list(
    input = list(travel_time = 1800, wifi_prop_travel = 0.5),
    output = list(brain_wifi_dose = 1.73, body_wifi_dose = 6.90)
  ),
  list(
    input = list(travel_time = 3600, wifi_prop_travel = 0.1),
    output = list(brain_wifi_dose = 1.73, body_wifi_dose = 6.90)
  ),
  list(
    input = list(travel_time = 0, wifi_prop_travel = 0),
    output = list(brain_wifi_dose = 1.73, body_wifi_dose = 6.90)
  ),
  list(
    input = list(travel_time = 2000, wifi_prop_travel = 0),
    output = list(brain_wifi_dose = 1.69, body_wifi_dose = 6.74)
  ),
  list(
    input = list(travel_time = 60000, wifi_prop_travel = 0),
    output = list(brain_wifi_dose = 0.42, body_wifi_dose = 1.67)
  )
)

test_that("get_wifi_dose matches reference calculations", {
  for (case in reference_cases) {
    result <- do.call(get_wifi_dose, case$input)
    expect_equal(result, case$output, tolerance = 1e-1) # tolerance due to rounding inconsistencies
  }
})
