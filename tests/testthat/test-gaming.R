# gaming dose =============================================================
test_that("gaming_dose errors if required argument is NA", {
  expect_error(
    gaming_dose(
      tissue          = "brain",
      duration_gaming = NA)
  )
})

test_that("gaming_dose errors if input values are incorrect type", {
  expect_error(
    gaming_dose(
      tissue          = "brain",
      duration_gaming = "600"),
    "numeric"
  )
})

test_that("gaming_dose errors if nonsensical duration is used", {
  expect_error(
    gaming_dose(
      tissue           = "body",
      duration_gaming = -600)
  )
})

test_that("gaming_dose warns if duration > 86400 is used", {
  expect_warning(
    gaming_dose(
      tissue           = "body",
      duration_gaming = 90000)
  )
})

test_that("gaming_dose errors if invalid tissue is used", {
  expect_error(
    gaming_dose(
      tissue      = "test",
      duration_gaming = 600)
  )
})

cases_gaming_dose <- list(
  list(
    input = list(
      tissue = "brain",
      duration_gaming = 0
    ),
    output = 0
  ),
  list(
    input = list(
      tissue = "body",
      duration_gaming = 0
    ),
    output = 0
  ),
  list(
    input = list(
      tissue = "brain",
      duration_gaming = 3600
    ),
    output = 1.807350
  ),
  list(
    input = list(
      tissue = "body",
      duration_gaming = 3600
    ),
    output = 2.033755
  )
)

test_that("gaming_dose matches reference values", {
  for (case in cases_gaming_dose) {
    result <- do.call(gaming_dose, case$input)
    expect_equal(result, case$output, tolerance = 1e-3)
  }
})
