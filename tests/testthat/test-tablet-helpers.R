# tablet_msar =================================================================
cases_tablet_msar <- list(
  list(
    input = list(
      tissue      = "brain",
      dur_low     = 313,
      dur_lowmed  = 458,
      dur_medhigh = 612,
      dur_high    = 0
    ),
    output = 0.0056911
  ),
  list(
    input = list(
      tissue      = "body",
      dur_low     = 313,
      dur_lowmed  = 458,
      dur_medhigh = 612,
      dur_high    = 0
    ),
    output = 0.005471607
  )
)

test_that("tablet_msar matches reference values", {
  for (case in cases_tablet_msar) {
    result <- do.call(tablet_msar, case$input)
    expect_equal(result, case$output, tolerance = 1e-5)
  }
})

# tablet_pwr ==================================================================
cases_tablet_pwr <- list(
  list(
    input = list(
      band        = "2",
      dur_low     = 313,
      dur_lowmed  = 458,
      dur_medhigh = 612,
      dur_high    = 0
    ),
    output = 7.02
  ),
  list(
    input = list(
      band        = "5",
      dur_low     = 313,
      dur_lowmed  = 458,
      dur_medhigh = 612,
      dur_high    = 0
    ),
    output = 8.41
  )
)

test_that("tablet_pwr matches reference values", {
  for (case in cases_tablet_pwr) {
    result <- do.call(tablet_pwr, case$input)
    expect_equal(result, case$output, tolerance = 1e-3)
  }
})

# tablet_sar ==================================================================
cases_tablet_sar <- list(
  list(
    input = list(
      tissue = "brain",
      band   = "2"
    ),
    output = 0.001119
  ),
  list(
    input = list(
      tissue = "brain",
      band   = "5"
    ),
    output = 0.000320
  ),
  list(
    input = list(
      tissue = "body",
      band   = "2"
    ),
    output = 0.000863
  ),
  list(
    input = list(
      tissue = "body",
      band   = "5"
    ),
    output = 0.000554
  )
)

test_that("tablet_sar matches reference values", {
  for (case in cases_tablet_sar) {
    result <- do.call(tablet_sar, case$input)
    expect_equal(result, case$output, tolerance = 1e-3)
  }
})
