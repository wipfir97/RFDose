# wifi dose ===================================================================
test_that("wifi_dose errors if required argument is missing", {
  expect_error(
    wifi_dose(
      tissue      = "body",
      travel_time = 1800),
    "wifi_prop_travel"
  )
})

test_that("wifi_dose errors if travel_time and wifi_prop_travel are not numeric", {
  expect_error(
    wifi_dose(
      tissue           = "brain",
      travel_time      = "1800",
      wifi_prop_travel = 0.5),
    "numeric"
  )
  expect_error(
    wifi_dose(
      tissue           = "body",
      travel_time      = 1800,
      wifi_prop_travel = "0.5"),
    "numeric"
  )
})

test_that("wifi_dose errors in case of nonsense input values", {
  expect_error(
    wifi_dose(
      tissue           = "body",
      travel_time      = -1800,
      wifi_prop_travel = 0.5)
  )
  expect_error(
    wifi_dose(
      tissue           = "body",
      travel_time      = 1800,
      wifi_prop_travel = 1.5)
  )
})

reference_cases <- list(
  list(
    input = list(
      tissue           = "brain",
      travel_time      = 1850.0,
      wifi_prop_travel = 0.5),
    output = 1.340218995
  ),
  list(
    input = list(
      tissue           = "body",
      travel_time      = 1850.0,
      wifi_prop_travel = 0.5),
    output = 5.416770347
  )
)

test_that("wifi_dose matches reference calculations", {
  for (case in reference_cases) {
    result <- do.call(wifi_dose, case$input)
    expect_equal(result, case$output, tolerance = 1e-3) # tolerance due to rounding inconsistencies
  }
})


