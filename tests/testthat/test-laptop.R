# The stochastic laptop implementation reads the nested lptp structure that only
# params_stochastic.yaml and params_template.yaml carry, and it resolves the
# simulation dummy from global$input_stoch$sex/age. The legacy params.yaml has
# neither, so every case that is meant to reach the calculation passes the
# template explicitly. The cases that are meant to error on input validation
# still call without params -- check_duration() fires before params is touched.
template_params <- load_params(version = "_template")

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
      dur_high    = 30000,
      params      = template_params)
  )
})

# Reference values recomputed for the stochastic implementation at the template
# point values (dummy Duke, lap 200 mm / desk 450 mm, lap share 0.2, distance
# correction on). They replace the values of the deterministic version, which
# read dedicated ETAIN legs/tabl constants and did not divide the dose by 1000.
# The durations are corrected from 218 to 219 to match defaultvariables.yaml.
cases_laptop_dose <- list(
  list(
    input = list(
      tissue      = "brain",
      dur_low     = 1967,
      dur_lowmed  = 219,
      dur_medhigh = 1967,
      dur_high    = 219,
      params      = template_params
    ),
    output = 1.708018
  ),
  list(
    input = list(
      tissue      = "body",
      dur_low     = 1967,
      dur_lowmed  = 219,
      dur_medhigh = 1967,
      dur_high    = 219,
      params      = template_params
    ),
    output = 28.17316
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
      dur_lowmed  = 219,
      dur_medhigh = 1967,
      dur_high    = 219,
      params      = template_params
    ),
    output = 0.3906719
  ),
  list(
    input = list(
      tissue      = "body",
      dur_low     = 1967,
      dur_lowmed  = 219,
      dur_medhigh = 1967,
      dur_high    = 219,
      params      = template_params
    ),
    output = 6.443997
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
      freq        = "2400",
      dur_low     = 1967,
      dur_lowmed  = 219,
      dur_medhigh = 1967,
      dur_high    = 219,
      params      = template_params
    ),
    output = 11.79966
  ),
  list(
    input = list(
      freq        = "5000",
      dur_low     = 1967,
      dur_lowmed  = 219,
      dur_medhigh = 1967,
      dur_high    = 219,
      params      = template_params
    ),
    output = 10.48563
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
      freq   = "2400",
      params = template_params
    ),
    output = 0.05640707
  ),
  list(
    input = list(
      tissue = "brain",
      freq   = "5000",
      params = template_params
    ),
    output = 0.001052045
  ),
  list(
    input = list(
      tissue = "body",
      freq   = "2400",
      params = template_params
    ),
    output = 0.6858173
  ),
  list(
    input = list(
      tissue = "body",
      freq   = "5000",
      params = template_params
    ),
    output = 0.39746
  )
)

test_that("laptop_sar matches reference values", {
  for (case in cases_laptop_sar) {
    result <- do.call(laptop_sar, case$input)
    expect_equal(result, case$output, tolerance = 1e-2)
  }
})


