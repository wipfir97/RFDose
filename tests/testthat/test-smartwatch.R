# Smartwatch dose =============================================================
test_that("smartwatch_dose errors if required argument is NA", {
  expect_error(
    smartwatch_dose(
      tissue              = "brain",
      duration_smartwatch = NA)
  )
})

test_that("smartwatch_dose errors if input values are incorrect type", {
  expect_error(
    smartwatch_dose(
      tissue              = "brain",
      duration_smartwatch = "6000"),
    "numeric"
  )
})

test_that("smartwatch_dose errors if nonsensical duration is used", {
  expect_error(
    smartwatch_dose(
      tissue      = "body",
      duration_smartwatch = -6000)
  )
})

test_that("smartwatch_dose warns if duration > 86400 is used", {
  expect_warning(
    smartwatch_dose(
      tissue      = "body",
      duration_smartwatch = 90000)
  )
})

test_that("smartwatch_dose errors if invalid tissue is used", {
  expect_error(
    smartwatch_dose(
      tissue      = "test",
      duration_smartwatch = 6000)
  )
})

cases_smartwatch_dose <- list(
  list(
    input = list(
      tissue = "brain",
      duration_smartwatch = 86400
    ),
    output = 0.069345
  ),
  list(
    input = list(
      tissue = "body",
      duration_smartwatch = 86400
    ),
    output = 2.881490
  ),
  list(
    input = list(
      tissue = "brain",
      duration_smartwatch = 0
    ),
    output = 0
  ),
  list(
    input = list(
      tissue = "body",
      duration_smartwatch = 0
    ),
    output = 0
  )
)

test_that("smartwatch_dose matches reference values", {
  for (case in cases_smartwatch_dose) {
    result <- do.call(smartwatch_dose, c(case$input, params = list(etain_params)))
    expect_equal(result, case$output, tolerance = 1e-2)
  }
})

# Smartwatch watch dose =======================================================
test_that("smartwatch_watch_dose errors if required argument is NA", {
  expect_error(
    smartwatch_watch_dose(
      tissue              = "brain",
      duration_smartwatch = NA)
  )
})

test_that("smartwatch_watch_dose errors if input values are incorrect type", {
  expect_error(
    smartwatch_watch_dose(
      tissue              = "brain",
      duration_smartwatch = "6000"),
    "numeric"
  )
})

test_that("smartwatch_watch_dose errors if nonsensical duration is used", {
  expect_error(
    smartwatch_watch_dose(
      tissue      = "body",
      duration_smartwatch = -6000)
  )
})

test_that("smartwatch_watch_dose warns if duration > 84600 is used", {
  expect_warning(
    smartwatch_watch_dose(
      tissue      = "body",
      duration_smartwatch = 90000)
  )
})

test_that("smartwatch_watch_dose errors if invalid tissue is used", {
  expect_error(
    smartwatch_watch_dose(
      tissue      = "test",
      duration_smartwatch = 6000)
  )
})

cases_smartwatch_watch_dose <- list(
  list(
    input = list(
      tissue = "brain",
      duration_smartwatch = 86400
    ),
    output = 0.001416+0.004074
  ),
  list(
    input = list(
      tissue = "body",
      duration_smartwatch = 86400
    ),
    output = 0.638026+1.836240
  ),
  list(
    input = list(
      tissue = "brain",
      duration_smartwatch = 0
    ),
    output = 0
  ),
  list(
    input = list(
      tissue = "body",
      duration_smartwatch = 0
    ),
    output = 0
  )
)

test_that("smartwatch_watch_dose matches reference values", {
  for (case in cases_smartwatch_watch_dose) {
    result <- do.call(smartwatch_watch_dose, c(case$input, params = list(etain_params)))
    expect_equal(result, case$output, tolerance = 1e-3)
  }
})

# Smartwatch phone dose =======================================================
test_that("smartwatch_phone_dose errors if required argument is NA", {
  expect_error(
    smartwatch_phone_dose(
      tissue              = "brain",
      duration_smartwatch = NA)
  )
})

test_that("smartwatch_phone_dose errors if input values are incorrect type", {
  expect_error(
    smartwatch_phone_dose(
      tissue              = "brain",
      duration_smartwatch = "6000"),
    "numeric"
  )
})

test_that("smartwatch_phone_dose errors if nonsensical duration is used", {
  expect_error(
    smartwatch_phone_dose(
      tissue      = "body",
      duration_smartwatch = -6000)
  )
})

test_that("smartwatch_phone_dose warns if duration > 84600 is used", {
  expect_warning(
    smartwatch_phone_dose(
      tissue      = "body",
      duration_smartwatch = 90000)
  )
})

test_that("smartwatch_phone_dose errors if invalid tissue is used", {
  expect_error(
    smartwatch_phone_dose(
      tissue      = "test",
      duration_smartwatch = 6000)
  )
})

cases_smartwatch_phone_dose <- list(
  list(
    input = list(
      tissue = "brain",
      duration_smartwatch = 86400
    ),
    output = 0.063855
  ),
  list(
    input = list(
      tissue = "body",
      duration_smartwatch = 86400
    ),
    output = 0.407223
  ),
  list(
    input = list(
      tissue = "brain",
      duration_smartwatch = 0
    ),
    output = 0
  ),
  list(
    input = list(
      tissue = "body",
      duration_smartwatch = 0
    ),
    output = 0
  )
)

test_that("smartwatch_phone_dose matches reference values", {
  for (case in cases_smartwatch_phone_dose) {
    result <- do.call(smartwatch_phone_dose, c(case$input, params = list(etain_params)))
    expect_equal(result, case$output, tolerance = 1e-5)
  }
})

test_that("smartwatch_watch_dose uses the data transfer parameters", {
  params <- load_params()
  sar    <- load_tissue_params(params, "smartwatch", "body")[["watch_sar"]]
  watch  <- params$devices$smartwatch

  # without data transfer, the watch only transmits passively
  no_transfer <- params
  no_transfer$devices$smartwatch$watch_transfer_dur <- 0
  expect_equal(smartwatch_watch_dose("body", 86400, params = no_transfer),
               watch$watch_pwr_passive * sar * 86400)

  # data transfer only active: active during the whole transfer time
  all_active <- params
  all_active$devices$smartwatch$watch_transfer_active_prop <- 1
  expect_equal(smartwatch_watch_dose("body", 86400, params = all_active),
               (watch$watch_pwr_active * watch$watch_transfer_dur +
                  watch$watch_pwr_passive * (86400 - watch$watch_transfer_dur)) * sar)
})
