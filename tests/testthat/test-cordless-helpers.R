# DECT mSAR ===================================================================
cases_dect_msar <- list(
  list(
    input = list(
      tissue   = "brain",
      ear_prop = 0.346
    ),
    output = 0.181396065
  ),
  list(
    input = list(
      tissue   = "body",
      ear_prop = 0.346
    ),
    output = 0.052029622
  )
)

test_that("dect_msar matches reference values", {
  for (case in cases_dect_msar) {
    result <- do.call(dect_msar, case$input)
    expect_equal(result, case$output, tolerance = 1e-3)
  }
})

# DECT power ==================================================================
test_that("dect_pwr matches reference values", {
    output <- 10
    result <- dect_pwr()
    expect_equal(result, output, tolerance = 1e-2)
})

# DECT nSAR ===================================================================
cases_dect_sar <- list(
  list(
    input = list(
      tissue   = "brain",
      ear_prop = 0.35
    ),
    output = 0.018139607
  ),
  list(
    input = list(
      tissue   = "body",
      ear_prop = 0.35
    ),
    output = 0.005202962
  )
)

test_that("dect_sar matches reference values", {
  for (case in cases_dect_sar) {
    result <- do.call(dect_sar, case$input)
    expect_equal(result, case$output, tolerance = 1e-2)
  }
})
