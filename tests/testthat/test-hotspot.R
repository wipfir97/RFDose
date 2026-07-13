# hotspot dose =============================================================
test_that("hotspot_dose errors if required argument is NA", {
  expect_error(
    hotspot_dose(
      tissue           = "brain",
      duration_hotspot = NA)
  )
})

test_that("hotspot_dose errors if input values are incorrect type", {
  expect_error(
    hotspot_dose(
      tissue           = "brain",
      duration_hotspot = "600"),
    "numeric"
  )
})

test_that("hotspot_dose errors if nonsensical duration is used", {
  expect_error(
    hotspot_dose(
      tissue           = "body",
      duration_hotspot = -600)
  )
})

test_that("hotspot_dose warns if duration > 86400 is used", {
  expect_warning(
    hotspot_dose(
      tissue           = "body",
      duration_hotspot = 90000)
  )
})

test_that("hotspot_dose errors if invalid tissue is used", {
  expect_error(
    hotspot_dose(
      tissue      = "test",
      duration_hotspot = 600)
  )
})

cases_hotspot_dose <- list(
  list(
    input = list(
      tissue = "brain",
      duration_hotspot = 3600
    ),
    output = 11.4
  ),
  list(
    input = list(
      tissue = "body",
      duration_hotspot = 3600
    ),
    output = 125.61
  )
)

test_that("hotspot_dose matches reference values", {
  for (case in cases_hotspot_dose) {
    result <- do.call(hotspot_dose, case$input)
    expect_equal(result, case$output, tolerance = 1e-2)
  }
})
