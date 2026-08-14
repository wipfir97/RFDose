# cordless_dose =================================================================
test_that("cordless_dose errors if required argument is missing", {
  expect_error(
    cordless_dose(
      tissue      = "brain",
      duration    = 600)
  )
})

test_that("cordless_dose errors if required argument is NA", {
  expect_error(
    cordless_dose(
      cordless_dose(
        tissue      = "brain",
        duration    = NA,
        ear_prop    = 0.35)
    )
  )
})

test_that("cordless_dose errors if input argument is incorrect type", {
  expect_error(
    cordless_dose(
      tissue      = "body",
      duration    = "600",
      ear_prop    = 0.35)
  )
  expect_error(
    cordless_dose(
      tissue      = "brain",
      duration    = 600,
      ear_prop    = "0.35")
  )
})

test_that("cordless_dose errors if input argument is not valid", {
  expect_error(
    cordless_dose(
      tissue      = "head",
      duration    = 600,
      ear_prop    = 0.35)
  )
  expect_error(
    cordless_dose(
      tissue      = "body",
      duration    = -600,
      ear_prop    = 0.35)
  )
  expect_error(
    cordless_dose(
      tissue      = "brain",
      duration    = 600,
      ear_prop    = 1.5)
  )
})

test_that("cordless_dose warns if duration exceeds 86400 seconds", {
  expect_warning(
    cordless_dose(
      tissue      = "brain",
      duration    = 90000,
      ear_prop    = 0.35)
  )
})

cases_cordless_dose <- list(
  list(
    input = list(
      tissue      = "brain",
      duration    = 68.8258,
      ear_prop    = 0.34601
    ),
    output = 12.4847
  ),
  list(
    input = list(
      tissue      = "body",
      duration    = 68.8258,
      ear_prop    = 0.34601
    ),
    output = 3.5810
  )
)

test_that("cordless_dose matches reference values", {
  for (case in cases_cordless_dose) {
    result <- do.call(cordless_dose, case$input)
    expect_equal(result, case$output, tolerance = 1e-3)
  }
})


