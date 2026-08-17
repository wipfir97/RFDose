test_that("mobilecall errors if required argument is missing", {
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
        tissue = "brain",
        duration = 90000,
        ear_prop = 0.5,
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

test_that("mobilecall_dose errors if required argument is NA", {
  expect_error(
    mobilecall_dose(
      tissue = "brain",
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
      tissue = "brain",
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
      tissue = "brain",
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
        tissue = "brain",
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
        tissue = "brain",
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
      tissue = "brain",
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
      tissue = "brain",
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
      tissue = "brain",
      duration = 1533,
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

test_that("mobilecall_dose errors warns if sum of durations is over 86400", {
  expect_warning(
    mobilecall_dose(
      tissue = "brain",
      duration = 90000,
      ear_prop = 0.5,
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

cases_mobilecall_dose <- list(
  list(
    input = list(
      tissue = "brain",
      duration = 1533.35,
      ear_prop = 0.447769,
      headp_prop = 0.229485,
      urbanicity = "suburban",
      use_5g = TRUE,
      travel_time = 1850,
      headp_ear_num = 2,
      wifi_prop_home = 0.7378683,
      wifi_prop_work = 0.4892182,
      wifi_prop_travel = 0.3071721
    ),
    output = 322.77
  ),
  list(
    input = list(
      tissue = "body",
      duration = 1533.35,
      ear_prop = 0.447769,
      headp_prop = 0.229485,
      urbanicity = "suburban",
      use_5g = TRUE,
      travel_time = 1850,
      headp_ear_num = 2,
      wifi_prop_home = 0.7378683,
      wifi_prop_work = 0.4892182      ,
      wifi_prop_travel = 0.3071721
    ),
    output = 66.65
  ), 
list(
    input = list(
      tissue = "brain",
      duration = 10000,
      ear_prop = 0.447769,
      headp_prop = 0.229485,
      urbanicity = "suburban",
      use_5g = TRUE,
      travel_time = 1850,
      headp_ear_num = 2,
      wifi_prop_home = 0.7378683,
      wifi_prop_work = 0.4892182,
      wifi_prop_travel = 0.3071721
    ),
    output = 2105.019106


  ),
  list(
    input = list(
      tissue = "body",
      duration = 10000,
      ear_prop = 0.447769,
      headp_prop = 0.229485,
      urbanicity = "suburban",
      use_5g = TRUE,
      travel_time = 1850.05,
      headp_ear_num = 2,
      wifi_prop_home = 0.7378683,
      wifi_prop_work = 0.4892182      ,
      wifi_prop_travel = 0.3071721
    ),
    output = 434.650509
  ),
  list(
    input = list(
      tissue = "body",
      duration = 0,
      ear_prop = 0.447769,
      headp_prop = 0.229485,
      urbanicity = "suburban",
      use_5g = TRUE,
      travel_time = 1850.05,
      headp_ear_num = 2,
      wifi_prop_home = 0.7378683,
      wifi_prop_work = 0.4892182      ,
      wifi_prop_travel = 0.3071721
    ),
    output = 0
  )
)

test_that("mobilecall_dose matches reference values", {
  for (case in cases_mobilecall_dose) {
    result <- do.call(mobilecall_dose, case$input)
    expect_equal(result, case$output, tolerance = 1e-2) # still have rounding issues
  }
})

