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
      travel_time      = 1800,
      wifi_prop_travel = 0.5),
    output = 1.30295088
  ),
  list(
    input = list(
      tissue           = "body",
      travel_time      = 1800,
      wifi_prop_travel = 0.5),
    output = 5.426242418
  )
)

test_that("wifi_dose matches reference calculations", {
  for (case in reference_cases) {
    result <- do.call(wifi_dose, case$input)
    expect_equal(result, case$output, tolerance = 1e-2) # tolerance due to rounding inconsistencies
  }
})

# wifi_msar ===================================================================
cases_wifi_msar <- list(
  list(
    input = list(
      tissue           = "brain",
      travel_time      = 1800,
      wifi_prop_travel = 0.5
    ),
    output = 1.64514E-05
  ),
  list(
    input = list(
      tissue           = "body",
      travel_time      = 1800,
      wifi_prop_travel = 0.5
    ),
    output = 6.85132E-05
  )
)

test_that("wifi_msar matches reference values", {
  for (case in cases_wifi_msar) {
    result <- do.call(wifi_msar, case$input)
    expect_equal(result, case$output, tolerance = 1e-2)
  }
})

# wifi_pwr ====================================================================
cases_wifi_pwr <- list(
  list(
    input = list(
      band   = "2"
    ),
    output = 0.018
  ),
  list(
    input = list(
      band   = "5"
    ),
    output = 0.013
  )
)

test_that("wifi_pwr matches reference values", {
  for (case in cases_wifi_pwr) {
    result <- do.call(wifi_pwr, case$input)
    expect_equal(result, case$output, tolerance = 1e-2)
  }
})

# wifi_sar ====================================================================
cases_wifi_sar <- list(
  list(
    input = list(
      tissue = "brain",
      band   = "2"
    ),
    output = 0.00133
  ),
  list(
    input = list(
      tissue = "body",
      band   = "2"
    ),
    output = 0.005295
  ),
  list(
    input = list(
      tissue = "brain",
      band   = "5"
    ),
    output = 0.00047
  ),
  list(
    input = list(
      tissue = "body",
      band   = "5"
    ),
    output = 0.002423693
  )
)

test_that("wifi_sar matches reference values", {
  for (case in cases_wifi_sar) {
    result <- do.call(wifi_sar, case$input)
    expect_equal(result, case$output, tolerance = 1e-2)
  }
})

