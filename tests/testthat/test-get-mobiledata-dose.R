test_that("get_mobiledata_dose errors if required argument is missing", {
  expect_error(
    get_mobiledata_dose(
      duration_low = 4860,
      duration_lowmed = 540,
      duration_medhigh = 4860,
      duration_high = 540,
      use_5g = TRUE,
      wifi_prop_home = 0.5,
      wifi_prop_work = 0.5,
      wifi_prop_travel = 0.5,
      urbanicity = "suburban"),
    "travel_time"
  )
})

test_that("get_mobiledata_dose errors if required argument is NA", {
  expect_error(
    get_mobiledata_dose(
      duration_low = 4860,
      duration_lowmed = 540,
      duration_medhigh = 4860,
      duration_high = 540,
      use_5g = TRUE,
      wifi_prop_home = NA,
      wifi_prop_work = 0.5,
      wifi_prop_travel = 0.5,
      urbanicity = "suburban",
      travel_time = 1800)
  )
})

test_that("get_mobiledata_dose errors if required argument is incorrect type", {
  expect_error(
    get_mobiledata_dose(
      duration_low = 4860,
      duration_lowmed = 540,
      duration_medhigh = "4860",
      duration_high = 540,
      use_5g = TRUE,
      wifi_prop_home = 0.5,
      wifi_prop_work = 0.5,
      wifi_prop_travel = 0.5,
      urbanicity = "suburban",
      travel_time = 1800)
  )
  expect_error(
    get_mobiledata_dose(
      duration_low = 4860,
      duration_lowmed = 540,
      duration_medhigh = 4860,
      duration_high = 540,
      use_5g = "TRUE",
      wifi_prop_home = 0.5,
      wifi_prop_work = 0.5,
      wifi_prop_travel = 0.5,
      urbanicity = "suburban",
      travel_time = 1800)
  )
  expect_error(
    get_mobiledata_dose(
      duration_low = 4860,
      duration_lowmed = 540,
      duration_medhigh = 4860,
      duration_high = 540,
      use_5g = TRUE,
      wifi_prop_home = 0.5,
      wifi_prop_work = 0.5,
      wifi_prop_travel = 0.5,
      urbanicity = 1,
      travel_time = 1800)
  )
})

test_that("get_mobiledata_dose errors if required argument is invalid", {
  expect_error(
    get_mobiledata_dose(
      duration_low = -4860,
      duration_lowmed = 540,
      duration_medhigh = 4860,
      duration_high = 540,
      use_5g = TRUE,
      wifi_prop_home = 0.5,
      wifi_prop_work = 0.5,
      wifi_prop_travel = 0.5,
      urbanicity = "suburban",
      travel_time = 1800)
  )
  expect_error(
    get_mobiledata_dose(
      duration_low = 4860,
      duration_lowmed = 540,
      duration_medhigh = 4860,
      duration_high = 540,
      use_5g = TRUE,
      wifi_prop_home = 2,
      wifi_prop_work = 0.5,
      wifi_prop_travel = 0.5,
      urbanicity = "suburban",
      travel_time = 1800)
  )
})

reference_cases <- list(
  list(
    input = list(
      duration_low = 4860,
      duration_lowmed = 540,
      duration_medhigh = 4860,
      duration_high = 540,
      use_5g = TRUE,
      wifi_prop_home = 0.5,
      wifi_prop_work = 0.5,
      wifi_prop_travel = 0.5,
      urbanicity = "suburban",
      travel_time = 1800),
    output = list(
      brain_data_dose  = 279.78,
      body_data_dose   = 131.18)
  ),
  list(
    input = list(
      duration_low = 1260,
      duration_lowmed = 540,
      duration_medhigh = 900,
      duration_high = 900,
      use_5g = TRUE,
      wifi_prop_home = 0.5,
      wifi_prop_work = 0.5,
      wifi_prop_travel = 0.5,
      urbanicity = "suburban",
      travel_time = 1800),
    output = list(
      brain_data_dose  = 156.06,
      body_data_dose   = 73.17)
  ),
  list(
    input = list(
      duration_low = 3240,
      duration_lowmed = 360,
      duration_medhigh = 0,
      duration_high = 0,
      use_5g = TRUE,
      wifi_prop_home = 0.5,
      wifi_prop_work = 0.5,
      wifi_prop_travel = 0.5,
      urbanicity = "suburban",
      travel_time = 1800),
    output = list(
      brain_data_dose  = 31.63,
      body_data_dose   = 14.83)
  ),
  list(
    input = list(
      duration_low = 0,
      duration_lowmed = 0,
      duration_medhigh = 3240,
      duration_high = 360,
      use_5g = TRUE,
      wifi_prop_home = 0.5,
      wifi_prop_work = 0.5,
      wifi_prop_travel = 0.5,
      urbanicity = "suburban",
      travel_time = 1800),
    output = list(
      brain_data_dose  = 154.88,
      body_data_dose   = 72.62)
  )
)

test_that("get_mobiledata_dose matches reference calculations", {
  for (case in reference_cases) {
    result <- do.call(get_mobiledata_dose, case$input)
    expect_equal(result, case$output, tolerance = 1e-0) # we currently give some tolerance due to rounding inconsistencies
  }
})
