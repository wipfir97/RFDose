# hotspot dose =============================================================
test_that("other_dose_wrapper errors if required argument is NA", {
  expect_error(
    other_dose_wrapper(
      tissue              = "brain",
      duration_hotspot    = 3600,
      duration_smartwatch = 86400,
      duration_vr         = 0,
      duration_headphones = NA,
      duration_gaming     = 3600)
  )
})

test_that("other_dose_wrapper errors if input values are incorrect type", {
  expect_error(
    other_dose_wrapper(
      tissue              = "body",
      duration_hotspot    = 3600,
      duration_smartwatch = 86400,
      duration_vr         = 0,
      duration_headphones = 8280,
      duration_gaming     = "3600")
  )
})

test_that("other_dose_wrapper errors if nonsensical duration is used", {
  expect_error(
    other_dose_wrapper(
      tissue              = "brain",
      duration_hotspot    = 3600,
      duration_smartwatch = 86400,
      duration_vr         = 0,
      duration_headphones = -8280,
      duration_gaming     = 3600)
  )
})

test_that("other_dose_wrapper warns if duration > 86400 is used", {
  expect_warning(
    other_dose_wrapper(
      tissue              = "body",
      duration_hotspot    = 3600,
      duration_smartwatch = 90000,
      duration_vr         = 0,
      duration_headphones = 8280,
      duration_gaming     = 3600)
  )
})

test_that("other_dose_wrapper errors if invalid tissue is used", {
  expect_error(
    other_dose_wrapper(
      tissue              = "hello",
      duration_hotspot    = 3600,
      duration_smartwatch = 86400,
      duration_vr         = 0,
      duration_headphones = 8280,
      duration_gaming     = 3600)
  )
})

cases_other_dose_wrapper <- list(
  list(
    input = list(
      tissue              = "brain",
      duration_hotspot    = 3600,
      duration_smartwatch = 86400,
      duration_vr         = 0,
      duration_headphones = 8280,
      duration_gaming     = 3600
    ),
    output = 13.82
  ),
  list(
    input = list(
      tissue              = "body",
      duration_hotspot    = 3600,
      duration_smartwatch = 86400,
      duration_vr         = 0,
      duration_headphones = 8280,
      duration_gaming     = 3600
    ),
    output = 136.66
  )
)

test_that("other_dose_wrapper matches reference values", {
  for (case in cases_other_dose_wrapper) {
    result <- do.call(other_dose_wrapper, case$input)
    expect_equal(result, case$output, tolerance = 1e-2)
  }
})

