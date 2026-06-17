test_that("mobiledata_dose errors if required argument is missing", {
  expect_error(
    mobiledata_dose(
      tissue           = "brain",
      duration_low     = 900,
      duration_lowmed  = 287,
      duration_medhigh = 186,
      duration_high    = 163,
      use_5g           = TRUE,
      wifi_prop_home   = 0.5,
      wifi_prop_work   = 0.5,
      wifi_prop_travel = 0.5,
      urbanicity       = "suburban")
  )
})

test_that("mobiledata_dose errors if required argument is NA", {
  expect_error(
    mobiledata_dose(
      tissue           = "brain",
      duration_low     = 4860,
      duration_lowmed  = 540,
      duration_medhigh = 4860,
      duration_high    = 540,
      use_5g           = TRUE,
      wifi_prop_home   = NA,
      wifi_prop_work   = 0.5,
      wifi_prop_travel = 0.5,
      urbanicity       = "suburban",
      travel_time      = 1800)
  )
})

test_that("mobiledata_dose errors if required argument is incorrect type", {
  expect_error(
    mobiledata_dose(
      tissue           = "brain",
      duration_low     = 4860,
      duration_lowmed  = 540,
      duration_medhigh = "4860",
      duration_high    = 540,
      use_5g           = TRUE,
      wifi_prop_home   = 0.5,
      wifi_prop_work   = 0.5,
      wifi_prop_travel = 0.5,
      urbanicity       = "suburban",
      travel_time      = 1800)
  )
  expect_error(
    mobiledata_dose(
      tissue           = "brain",
      duration_low     = 4860,
      duration_lowmed  = 540,
      duration_medhigh = 4860,
      duration_high    = 540,
      use_5g           = "TRUE",
      wifi_prop_home   = 0.5,
      wifi_prop_work   = 0.5,
      wifi_prop_travel = 0.5,
      urbanicity       = "suburban",
      travel_time      = 1800)
  )
  expect_error(
    mobiledata_dose(
      tissue           = "brain",
      duration_low     = 4860,
      duration_lowmed  = 540,
      duration_medhigh = 4860,
      duration_high    = 540,
      use_5g           = TRUE,
      wifi_prop_home   = 0.5,
      wifi_prop_work   = 0.5,
      wifi_prop_travel = 0.5,
      urbanicity       = 1,
      travel_time      = 1800)
  )
})

test_that("mobiledata_dose errors if required argument is invalid", {
  expect_error(
    mobiledata_dose(
      tissue           = "brain",
      duration_low     = -4860, # negative duration
      duration_lowmed  = 540,
      duration_medhigh = 4860,
      duration_high    = 540,
      use_5g           = TRUE,
      wifi_prop_home   = 0.5,
      wifi_prop_work   = 0.5,
      wifi_prop_travel = 0.5,
      urbanicity       = "suburban",
      travel_time      = 1800)
  )
  expect_error(
    mobiledata_dose(
      tissue           = "brian", # invalid tissue
      duration_low     = 4860,
      duration_lowmed  = 540,
      duration_medhigh = 4860,
      duration_high    = 540,
      use_5g           = TRUE,
      wifi_prop_home   = 0.5,
      wifi_prop_work   = 0.5,
      wifi_prop_travel = 0.5,
      urbanicity       = "suburban",
      travel_time      = 1800)
  )
  expect_error(
  mobiledata_dose(
    tissue           = "body",
    duration_low     = 4860,
    duration_lowmed  = 540,
    duration_medhigh = 4860,
    duration_high    = 540,
    use_5g           = TRUE,
    wifi_prop_home   = 0.5,
    wifi_prop_work   = 0.5,
    wifi_prop_travel = 0.5,
    urbanicity       = "my_house", # invalid urbanicity
    travel_time      = 1800)
  )
})

