# vr dose =============================================================
test_that("vr_dose errors if required argument is NA", {
  expect_error(
    vr_dose(
      tissue      = "brain",
      duration_vr = NA)
  )
})

test_that("vr_dose errors if input values are incorrect type", {
  expect_error(
    vr_dose(
      tissue      = "brain",
      duration_vr = "600"),
    "numeric"
  )
})

test_that("vr_dose errors if nonsensical duration is used", {
  expect_error(
    vr_dose(
      tissue      = "body",
      duration_vr = -600)
  )
})

test_that("vr_dose warns if duration > 86400 is used", {
  expect_warning(
    vr_dose(
      tissue      = "body",
      duration_vr = 90000)
  )
})

test_that("vr_dose errors if invalid tissue is used", {
  expect_error(
    vr_dose(
      tissue      = "test",
      duration_vr = 600)
  )
})

cases_vr_dose <- list(
  list(
    input = list(
      tissue = "brain",
      duration_vr = 600
    ),
    output = 65.485124
  ),
  list(
    input = list(
      tissue = "body",
      duration_vr = 600
    ),
    output = 32.872966
  ),
  list(
    input = list(
      tissue = "brain",
      duration_vr = 0
    ),
    output = 0
  ),
  list(
    input = list(
      tissue = "body",
      duration_vr = 0
    ),
    output = 0
  )
)

test_that("vr_dose matches reference values", {
  for (case in cases_vr_dose) {
    result <- do.call(vr_dose, case$input)
    expect_equal(result, case$output, tolerance = 1e-3)
  }
})
