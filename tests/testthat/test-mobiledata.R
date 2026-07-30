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

test_that("mobiledata_dose errors warns if sum of durations is over 86400", {
  expect_warning(
    mobiledata_dose(
      tissue           = "brain",
      duration_low     = 90000,
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
})

cases_mobiledata_dose <- list(
  list(
    input = list(
      tissue           = "brain",
      duration_low     = 3989,
      duration_lowmed  = 4917,
      duration_medhigh = 5651,
      duration_high    = 0,
      use_5g           = TRUE,
      wifi_prop_home   = 0.74,
      wifi_prop_work   = 0.49,
      wifi_prop_travel = 0.31,
      urbanicity       = "suburban",
      travel_time      = 1850
    ),
    output = 146.95
  ),
  list(
    input = list(
      tissue           = "body",
      duration_low     = 3989,
      duration_lowmed  = 4917,
      duration_medhigh = 5651,
      duration_high    = 0,
      use_5g           = TRUE,
      wifi_prop_home   = 0.74,
      wifi_prop_work   = 0.49,
      wifi_prop_travel = 0.31,
      urbanicity       = "suburban",
      travel_time      = 1850
    ),
    output = 78.69
  )
)

test_that("mobiledata_dose matches reference values", {
  for (case in cases_mobiledata_dose) {
    result <- do.call(mobiledata_dose, case$input)
    expect_equal(result, case$output, tolerance = 1e-3) # still have rounding issues
  }
})

