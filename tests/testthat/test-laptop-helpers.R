# laptop_msar =================================================================
cases_laptop_msar <- list(
  list(
    input = list(
      tissue      = "brain",
      dur_low     = 1069,
      dur_lowmed  = 1168,
      dur_medhigh = 1715,
      dur_high    = 0
    ),
    output = 0.0002242
  ),
  list(
    input = list(
      tissue      = "body",
      dur_low     = 1069,
      dur_lowmed  = 1168,
      dur_medhigh = 1715,
      dur_high    = 0
    ),
    output = 0.032084349
  )
)

test_that("laptop_msar matches reference values", {
  for (case in cases_laptop_msar) {
    result <- do.call(laptop_msar, case$input)
    expect_equal(result, case$output, tolerance = 1e-2)
  }
})

# laptop_pwr ==================================================================
cases_laptop_pwr <- list(
  list(
    input = list(
      band        = "2",
      dur_low     = 1069,
      dur_lowmed  = 1168,
      dur_medhigh = 1715,
      dur_high    = 0
    ),
    output = 8.60
  ),
  list(
    input = list(
      band        = "5",
      dur_low     = 1069,
      dur_lowmed  = 1168,
      dur_medhigh = 1715,
      dur_high    = 0
    ),
    output = 10.30
  )
)

test_that("laptop_pwr matches reference values", {
  for (case in cases_laptop_pwr) {
    result <- do.call(laptop_pwr, case$input)
    expect_equal(result, case$output, tolerance = 1e-2)
  }
})

# laptop_sar ==================================================================
cases_laptop_sar <- list(
  list(
    input = list(
      tissue = "brain",
      band   = "2"
    ),
    output = 0.0000381756
  ),
  list(
    input = list(
      tissue = "brain",
      band   = "5"
    ),
    output = 0.0000078166
  ),
  list(
    input = list(
      tissue = "body",
      band   = "2"
    ),
    output = 0.0039684076
  ),
  list(
    input = list(
      tissue = "body",
      band   = "5"
    ),
    output = 0.0028418154
  )
)

test_that("laptop_sar matches reference values", {
  for (case in cases_laptop_sar) {
    result <- do.call(laptop_sar, case$input)
    expect_equal(result, case$output, tolerance = 1e-3)
  }
})


