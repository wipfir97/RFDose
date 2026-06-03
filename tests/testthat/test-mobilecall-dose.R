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


# reference_cases <- list(
#   list(
#     input = list(
#       tissue           = "brain",
#       duration         = 30000,
#       ear_prop         = 0.66,
#       headp_prop       = 0.5,
#       urbanicity       = "suburban",
#       use_5g           = TRUE,
#       travel_time      = 1800,
#       headp_ear_num    = 2,
#       wifi_prop_home   = 0.5,
#       wifi_prop_work   = 0.5,
#       wifi_prop_travel = 0.5),
#     output = list(
#       brain_call_dose  = 7693.22,
#       body_call_dose   = 1176.17)
#   ),
#   list(
#     input = list(
#       duration         = 424.5,
#       ear_prop         = 0.5,
#       headp_prop       = 0.5,
#       urbanicity       = "suburban",
#       use_5g           = TRUE,
#       travel_time      = 1800,
#       headp_ear_num    = 2,
#       wifi_prop_home   = 0.5,
#       wifi_prop_work   = 0.5,
#       wifi_prop_travel = 0.5),
#     output = list(
#       brain_call_dose  = 84.75,
#       body_call_dose   = 14.86)
#   ),
#   list(
#     input = list(
#       duration         = 424.5,
#       ear_prop         = 0.66,
#       headp_prop       = 0.5,
#       urbanicity       = "suburban",
#       use_5g           = FALSE,
#       travel_time      = 1800,
#       headp_ear_num    = 2,
#       wifi_prop_home   = 0.5,
#       wifi_prop_work   = 0.5,
#       wifi_prop_travel = 0.5),
#     output = list(
#       brain_call_dose  = 112.65,
#       body_call_dose   = 16.98)
#   ),
#   list(
#     input = list(
#       duration         = 424.5,
#       ear_prop         = 0.66,
#       headp_prop       = 0.5,
#       urbanicity       = "suburban",
#       use_5g           = TRUE,
#       travel_time      = 1800,
#       headp_ear_num    = 2,
#       wifi_prop_home   = 0,
#       wifi_prop_work   = 0,
#       wifi_prop_travel = 0),
#     output = list(
#       brain_call_dose  = 115.33,
#       body_call_dose   = 16.90)
#   )
# )
#
# test_that("mobilecall_dose matches reference calculations", {
#   for (case in reference_cases) {
#     result <- do.call(mobilecall_dose, case$input)
#     expect_equal(result, case$output, tolerance = 1e-1) # tolerance due to rounding inconsistencies
#   }
# })

