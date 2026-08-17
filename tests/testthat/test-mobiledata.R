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
      duration_low     = 3989.318141,
      duration_lowmed  = 4916.971705,
      duration_medhigh = 5650.714779,
      duration_high    = 0,
      use_5g           = TRUE,
      wifi_prop_home   = 0.7378683,
      wifi_prop_work   = 0.4892182,
      wifi_prop_travel = 0.3071721,
      urbanicity       = "suburban",
      travel_time      = 1850
    ),
    output = 146.94667
  ),
  list(
    input = list(
      tissue           = "body",
      duration_low     = 3989,
      duration_lowmed  = 4917,
      duration_medhigh = 5651,
      duration_high    = 0,
      use_5g           = TRUE,
      wifi_prop_home   = 0.7378683,
      wifi_prop_work   = 0.4892182,
      wifi_prop_travel = 0.3071721,
      urbanicity       = "suburban",
      travel_time      = 1800
    ),
    output = 78.68703
  ), 

  list(
    input = list(
      tissue           = "body",
      duration_low     = 0,
      duration_lowmed  = 0,
      duration_medhigh = 0,
      duration_high    = 0,
      use_5g           = TRUE,
      wifi_prop_home   = 0.7378683,
      wifi_prop_work   = 0.4892182,
      wifi_prop_travel = 0.3071721,
      urbanicity       = "suburban",
      travel_time      = 1800
    ),
    output = 0
  ), 

  list(
    input = list(
      tissue           = "body",
      duration_low     = 0,
      duration_lowmed  = 0,
      duration_medhigh = 0,
      duration_high    = 80000,
      use_5g           = TRUE,
      wifi_prop_home   = 0.7378683,
      wifi_prop_work   = 0.4892182,
      wifi_prop_travel = 0.3071721,
      urbanicity       = "suburban",
      travel_time      = 1800
    ),
    output = 4800.352339

  ), 

  list(
    input = list(
      tissue           = "brain",
      duration_low     = 0,
      duration_lowmed  = 0,
      duration_medhigh = 0,
      duration_high    = 80000,
      use_5g           = TRUE,
      wifi_prop_home   = 0.7378683,
      wifi_prop_work   = 0.4892182,
      wifi_prop_travel = 0.3071721,
      urbanicity       = "suburban",
      travel_time      = 1800
    ),
    output = 8922.30527
  )
)

test_that("mobiledata_dose matches reference values", {
  for (case in cases_mobiledata_dose) {
    result <- do.call(mobiledata_dose, case$input)
    expect_equal(result, case$output, tolerance = 1e-3) # still have rounding issues
  }
})

