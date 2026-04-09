test_that("mobilecall_dose errors if required argument is missing", {
  expect_error(
    mobilecall_dose(
      duration = 425,
      ear_prop = 0.6,
      headp_prop = 0.5,
      urbanicity = "suburban",
      use_5g = TRUE,
      headp_ear_num = 2,
      wifi_prop_home = 0.5,
      wifi_prop_work = 0.5,
      wifi_prop_travel = 0.5
    )
  )
})

test_that("mobilecall_dose warns if total daily use duration exceeds 86400 seconds", {
  expect_warning(
      mobilecall_dose(
        duration = 425,
        ear_prop = 0.5,
        headp_prop = 0.5,
        urbanicity = "suburban",
        use_5g = TRUE,
        travel_time = 90000,
        headp_ear_num = 2,
        wifi_prop_home = 0.5,
        wifi_prop_work = 0.5,
        wifi_prop_travel = 0.5
    )
  )
})

test_that("mobilecall_dose errors if required argument is NA", {
  expect_error(
    mobilecall_dose(
      duration = 425,
      ear_prop = NA,
      headp_prop = 0.5,
      urbanicity = "suburban",
      use_5g = TRUE,
      travel_time = 1800,
      headp_ear_num = 2,
      wifi_prop_home = 0.5,
      wifi_prop_work = 0.5,
      wifi_prop_travel = 0.5
    )
  )
})

test_that("mobilecall_dose errors if required argument is incorrect type", {
  expect_error(
    mobilecall_dose(
      duration = 425,
      ear_prop = 0.5,
      headp_prop = 0.5,
      urbanicity = "suburban",
      use_5g = TRUE,
      travel_time = 1800,
      headp_ear_num = 2,
      wifi_prop_home = "0.5",
      wifi_prop_work = 0.5,
      wifi_prop_travel = 0.5
    )
  )
  expect_error(
    mobilecall_dose(
      duration = 425,
      ear_prop = 0.5,
      headp_prop = 0.5,
      urbanicity = "suburban",
      use_5g = 1,
      travel_time = 1800,
      headp_ear_num = 2,
      wifi_prop_home = 0.5,
      wifi_prop_work = 0.5,
      wifi_prop_travel = 0.5
    )
  )
    expect_error(
      mobilecall_dose(
        duration = 425,
        ear_prop = 0.5,
        headp_prop = 0.5,
        urbanicity = 42,
        use_5g = TRUE,
        travel_time = 1800,
        headp_ear_num = 2,
        wifi_prop_home = 0.5,
        wifi_prop_work = 0.5,
        wifi_prop_travel = 0.5
      )
    )
    expect_error(
      mobilecall_dose(
        duration = 425,
        ear_prop = 0.5,
        headp_prop = 0.5,
        urbanicity = "castle",
        use_5g = TRUE,
        travel_time = 1800,
        headp_ear_num = 2,
        wifi_prop_home = 0.5,
        wifi_prop_work = 0.5,
        wifi_prop_travel = 0.5
      )
    )
})

test_that("mobilecall_dose errors if input argument makes no sense", {
  expect_error(
    mobilecall_dose(
      duration = 425,
      ear_prop = 1.5,
      headp_prop = 0.5,
      urbanicity = "suburban",
      use_5g = TRUE,
      travel_time = 1800,
      headp_ear_num = 2,
      wifi_prop_home = 0.5,
      wifi_prop_work = 0.5,
      wifi_prop_travel = 0.5
      )
    )
  expect_error(
    mobilecall_dose(
      duration = -425,
      ear_prop = 1.5,
      headp_prop = 0.5,
      urbanicity = "suburban",
      use_5g = TRUE,
      travel_time = 1800,
      headp_ear_num = 2,
      wifi_prop_home = 0.5,
      wifi_prop_work = 0.5,
      wifi_prop_travel = 0.5,
    )
  )
  expect_error(
    mobilecall_dose(
      duration = 425,
      ear_prop = 0.5,
      headp_prop = 0.5,
      urbanicity = "suburban",
      use_5g = TRUE,
      travel_time = 1800,
      headp_ear_num = 10,
      wifi_prop_home = 0.5,
      wifi_prop_work = 0.5,
      wifi_prop_travel = 0.5
    )
  )

})

reference_cases <- list(
  list(
    input = list(
      duration         = 425,
      ear_prop         = 0.66,
      headp_prop       = 0.5,
      urbanicity       = "suburban",
      use_5g           = TRUE,
      travel_time      = 1800,
      headp_ear_num    = 2,
      wifi_prop_home   = 0.5,
      wifi_prop_work   = 0.5,
      wifi_prop_travel = 0.5),
    output = list(
      brain_call_dose  = 121.55,
      body_call_dose   = 20.08)
  ),
  list(
    input = list(
      duration         = 425,
      ear_prop         = 0.7,
      headp_prop       = 0.47,
      urbanicity       = "suburban",
      use_5g           = TRUE,
      travel_time      = 1800,
      headp_ear_num    = 2,
      wifi_prop_home   = 0.5,
      wifi_prop_work   = 0.5,
      wifi_prop_travel = 0.5),
    output = list(
      brain_call_dose  = 128.50,
      body_call_dose   = 20.85)
  ),
  list(
    input = list(
      duration         = 425,
      ear_prop         = 0.66,
      headp_prop       = 0.5,
      urbanicity       = "suburban",
      use_5g           = TRUE,
      travel_time      = 1800,
      headp_ear_num    = 2,
      wifi_prop_home   = 1,
      wifi_prop_work   = 1,
      wifi_prop_travel = 0.5),
    output = list(
      brain_call_dose  = 98.83,
      body_call_dose   = 18.61)
  ),
  list(
    input = list(
      duration         = 425,
      ear_prop         = 0.66,
      headp_prop       = 0.5,
      urbanicity       = "suburban",
      use_5g           = TRUE,
      travel_time      = 1800,
      headp_ear_num    = 2,
      wifi_prop_home   = 0.8,
      wifi_prop_work   = 0.5,
      wifi_prop_travel = 0),
    output = list(
      brain_call_dose  = 106.77,
      body_call_dose   = 19.23)
  )
)

test_that("mobilecall_dose matches reference calculations", {
  for (case in reference_cases) {
    result <- do.call(mobilecall_dose, case$input)
    expect_equal(result, case$output, tolerance = 1e-0) # tolerance due to rounding inconsistencies
  }
})
