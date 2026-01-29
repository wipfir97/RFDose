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


