# headphones dose =============================================================
test_that("headphones_dose errors if required argument is NA", {
  expect_error(
    headphones_dose(
      tissue              = "brain",
      duration_headphones = NA)
  )
})

test_that("headphones_dose errors if input values are incorrect type", {
  expect_error(
    headphones_dose(
      tissue              = "brain",
      duration_headphones = "6000"),
    "numeric"
  )
})

test_that("headphones_dose errors if nonsensical duration is used", {
  expect_error(
    headphones_dose(
      tissue      = "body",
      duration_headphones = -6000)
  )
})

test_that("headphones_dose warns if duration > 86400 is used", {
  expect_warning(
    headphones_dose(
      tissue      = "body",
      duration_headphones = 90000)
  )
})

test_that("headphones_dose errors if invalid tissue is used", {
  expect_error(
    headphones_dose(
      tissue      = "test",
      duration_headphones = 6000)
  )
})

cases_headphones_dose <- list(
  list(
    input = list(
      tissue = "brain",
      duration_headphones = 8411.05
    ),
    output = 1.171858
  ),
  list(
    input = list(
      tissue = "body",
      duration_headphones = 8411.05
    ),
    output = 3.644465
  )
)

test_that("headphones_dose matches reference values", {
  for (case in cases_headphones_dose) {
    result <- do.call(headphones_dose, case$input)
    expect_equal(result, case$output, tolerance = 1e-3)
  }
})

# headphones earset dose =======================================================
test_that("headphones_earset_dose errors if required argument is NA", {
  expect_error(
    headphones_earset_dose(
      tissue              = "brain",
      duration_headphones = NA)
  )
})

test_that("headphones_earset_dose errors if input values are incorrect type", {
  expect_error(
    headphones_earset_dose(
      tissue              = "brain",
      duration_headphones = "6000"),
    "numeric"
  )
})

test_that("headphones_earset_dose errors if nonsensical duration is used", {
  expect_error(
    headphones_earset_dose(
      tissue      = "body",
      duration_headphones = -6000)
  )
})

test_that("headphones_earset_dose warns if duration > 84600 is used", {
  expect_warning(
    headphones_earset_dose(
      tissue      = "body",
      duration_headphones = 90000)
  )
})

test_that("headphones_earset_dose errors if invalid tissue is used", {
  expect_error(
    headphones_earset_dose(
      tissue      = "test",
      duration_headphones = 6000)
  )
})

cases_headphones_earset_dose <- list(
  list(
    input = list(
      tissue = "brain",
      duration_headphones = 8411
    ),
    output = 0.674549
  ),
  list(
    input = list(
      tissue = "body",
      duration_headphones = 8411
    ),
    output = 0.472972
  )
)

test_that("headphones_earset_dose matches reference values", {
  for (case in cases_headphones_earset_dose) {
    result <- do.call(headphones_earset_dose, case$input)
    expect_equal(result, case$output, tolerance = 1e-4)
  }
})

# headphones phone dose =======================================================
test_that("headphones_phone_dose errors if required argument is NA", {
  expect_error(
    headphones_phone_dose(
      tissue              = "brain",
      duration_headphones = NA)
  )
})

test_that("headphones_phone_dose errors if input values are incorrect type", {
  expect_error(
    headphones_phone_dose(
      tissue              = "brain",
      duration_headphones = "6000"),
    "numeric"
  )
})

test_that("headphones_phone_dose errors if nonsensical duration is used", {
  expect_error(
    headphones_phone_dose(
      tissue      = "body",
      duration_headphones = -6000)
  )
})

test_that("headphones_phone_dose warns if duration > 84600 is used", {
  expect_warning(
    headphones_phone_dose(
      tissue      = "body",
      duration_headphones = 90000)
  )
})

test_that("headphones_phone_dose errors if invalid tissue is used", {
  expect_error(
    headphones_phone_dose(
      tissue      = "test",
      duration_headphones = 6000)
  )
})

cases_headphones_phone_dose <- list(
  list(
    input = list(
      tissue = "brain",
      duration_headphones = 8411
    ),
    output = 0.497308
  ),
  list(
    input = list(
      tissue = "body",
      duration_headphones = 8411
    ),
    output = 3.171493
  ), 
  list(
    input = list(
      tissue = "body",
      duration_headphones = 0
    ),
    output = 0
  )
)

test_that("headphones_phone_dose matches reference values", {
  for (case in cases_headphones_phone_dose) {
    result <- do.call(headphones_phone_dose, case$input)
    expect_equal(result, case$output, tolerance = 1e-3)
  }
})
