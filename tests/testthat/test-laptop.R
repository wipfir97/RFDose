# laptop_dose =================================================================
test_that("laptop_dose errors if required argument is missing", {
  expect_error(
    laptop_dose(
      tissue      = "brain",
      dur_low     = 0,
      dur_lowmed  = 1230,
      dur_high    = 0)
  )
})

test_that("laptop_dose errors if required argument is NA", {
  expect_error(
    laptop_dose(
      tissue      = "brain",
      dur_low     = NA,
      dur_lowmed  = 1230,
      dur_medhigh = 0,
      dur_high    = 0)
  )
  expect_error(
    laptop_dose(
      tissue      = NA,
      dur_low     = 0,
      dur_lowmed  = 1230,
      dur_medhigh = 0,
      dur_high    = 0)
  )
})

test_that("laptop_dose errors if input argument is incorrect type", {
  expect_error(
    laptop_dose(
      tissue      = "brain",
      dur_low     = "0",
      dur_lowmed  = 1230,
      dur_medhigh = 0,
      dur_high    = 0)
  )
  expect_error(
    laptop_dose(
      tissue      = 7,
      dur_low     = 0,
      dur_lowmed  = 1230,
      dur_medhigh = 0,
      dur_high    = 0)
  )
})

test_that("laptop_dose errors if input argument is not valid", {
  expect_error(
    laptop_dose(
      tissue      = "brain",
      dur_low     = -25,
      dur_lowmed  = 1230,
      dur_medhigh = 0,
      dur_high    = 0)
  )
  expect_error(
    laptop_dose(
      tissue      = "icecream",
      dur_low     = 0,
      dur_lowmed  = 1230,
      dur_medhigh = 0,
      dur_high    = 0)
  )
})

test_that("laptop_dose warns if sum of durations exceeds 86400 seconds", {
  expect_warning(
    laptop_dose(
      tissue      = "brain",
      dur_low     = 20000,
      dur_lowmed  = 20000,
      dur_medhigh = 20000,
      dur_high    = 30000)
  )
})

cases_laptop_dose <- list(
  list(
    input = list(
      tissue      = "brain",
      dur_low     = 1967,
      dur_lowmed  = 218,
      dur_medhigh = 1967,
      dur_high    = 218
    ),
    output = 2.12
  ),
  list(
    input = list(
      tissue      = "body",
      dur_low     = 1967,
      dur_lowmed  = 218,
      dur_medhigh = 1967,
      dur_high    = 218
    ),
    output = 86.18
  )
)

test_that("laptop_dose matches reference values", {
  for (case in cases_laptop_dose) {
    result <- do.call(laptop_dose, case$input)
    expect_equal(result, case$output, tolerance = 1e-2)
  }
})

# laptop_msar =================================================================
cases_laptop_msar <- list(
  list(
    input = list(
      tissue      = "brain",
      dur_low     = 1967,
      dur_lowmed  = 218,
      dur_medhigh = 1967,
      dur_high    = 218
    ),
    output = 0.0004860
  ),
  list(
    input = list(
      tissue      = "body",
      dur_low     = 1967,
      dur_lowmed  = 218,
      dur_medhigh = 1967,
      dur_high    = 218
    ),
    output = 0.019720448
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
      dur_low     = 1967,
      dur_lowmed  = 218,
      dur_medhigh = 1967,
      dur_high    = 218
    ),
    output = 11.75
  ),
  list(
    input = list(
      band        = "5",
      dur_low     = 1967,
      dur_lowmed  = 218,
      dur_medhigh = 1967,
      dur_high    = 218
    ),
    output = 10.48
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
    output = 0.0000655
  ),
  list(
    input = list(
      tissue = "brain",
      band   = "5"
    ),
    output = 0.0000089
  ),
  list(
    input = list(
      tissue = "body",
      band   = "2"
    ),
    output = 0.0020096
  ),
  list(
    input = list(
      tissue = "body",
      band   = "5"
    ),
    output = 0.0013678
  )
)

test_that("laptop_sar matches reference values", {
  for (case in cases_laptop_sar) {
    result <- do.call(laptop_sar, case$input)
    expect_equal(result, case$output, tolerance = 1e-2)
  }
})


