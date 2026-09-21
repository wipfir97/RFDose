# The stochastic tablet implementation reads the nested tblt structure that only
# params_stochastic.yaml and params_template.yaml carry, and it resolves the
# simulation dummy from global$input_stoch$sex/age. The legacy params.yaml has
# neither, so every case that is meant to reach the calculation passes the
# template explicitly. The cases that are meant to error on input validation
# still call without params -- check_duration() fires before params is touched.
template_params <- load_params(version = "_template")

# tablet_dose =================================================================
test_that("tablet_dose errors if required argument is missing", {
  expect_error(
    tablet_dose(
      tissue      = "brain",
      dur_low     = 0,
      dur_lowmed  = 1230,
      dur_high    = 0)
  )
  expect_error(
    tablet_dose(
      dur_low     = 0,
      dur_lowmed  = 1230,
      dur_medhigh = 0,
      dur_high    = 0)
  )
})

test_that("tablet_dose errors if required argument is NA", {
  expect_error(
    tablet_dose(
      tissue      = "brain",
      dur_low     = 0,
      dur_lowmed  = NA,
      dur_medhigh = 0,
      dur_high    = 0)
  )
  expect_error(
    tablet_dose(
      tissue      = NA,
      dur_low     = 0,
      dur_lowmed  = 1230,
      dur_medhigh = 0,
      dur_high    = 0)
  )
})

test_that("tablet_dose errors if input argument is incorrect type", {
  expect_error(
    tablet_dose(
      tissue      = "brain",
      dur_low     = 0,
      dur_lowmed  = "1230",
      dur_medhigh = 0,
      dur_high    = 0)
  )
  expect_error(
    tablet_dose(
      tissue      = 42,
      dur_low     = 0,
      dur_lowmed  = 1230,
      dur_medhigh = 0,
      dur_high    = 0)
  )
})

test_that("tablet_dose errors if input argument is not valid", {
  expect_error(
    tablet_dose(
      tissue      = "brain",
      dur_low     = 0,
      dur_lowmed  = -1230,
      dur_medhigh = 0,
      dur_high    = 0)
  )
  expect_error(
    tablet_dose(
      tissue      = "popsicle",
      dur_low     = 0,
      dur_lowmed  = 1230,
      dur_medhigh = 0,
      dur_high    = 0)
  )
})

test_that("tablet_dose warns if sum of durations exceeds 86400 seconds", {
  expect_warning(
    tablet_dose(
      tissue      = "brain",
      dur_low     = 30000,
      dur_lowmed  = 30000,
      dur_medhigh = 30000,
      dur_high    = 30000,
      params      = template_params)
  )
})

# Reference values recomputed for the stochastic implementation at the template
# point values (dummy Duke, viewing distance 300 mm, distance correction on).
# They replace the values of the deterministic version, which read a single
# tblt_*_sar constant per band instead of the front_of_eyes positions and did
# not divide the dose by 1000.
cases_tablet_dose <- list(
  list(
    input = list(
      tissue      = "brain",
      dur_low     = 728,
      dur_lowmed  = 81,
      dur_medhigh = 728,
      dur_high    = 81,
      params      = template_params
    ),
    output = 5.919812
  ),
  list(
    input = list(
      tissue      = "body",
      dur_low     = 728,
      dur_lowmed  = 81,
      dur_medhigh = 728,
      dur_high    = 81,
      params      = template_params
    ),
    output = 8.141920
  )
)

test_that("tablet_dose matches reference values", {
  for (case in cases_tablet_dose) {
    result <- do.call(tablet_dose, case$input)
    expect_equal(result, case$output, tolerance = 1e-2)
  }
})

# tablet_msar =================================================================
cases_tablet_msar <- list(
  list(
    input = list(
      tissue      = "brain",
      dur_low     = 728,
      dur_lowmed  = 81,
      dur_medhigh = 728,
      dur_high    = 81,
      params      = template_params
    ),
    output = 3.658722
  ),
  list(
    input = list(
      tissue      = "body",
      dur_low     = 728,
      dur_lowmed  = 81,
      dur_medhigh = 728,
      dur_high    = 81,
      params      = template_params
    ),
    output = 5.032089
  )
)

test_that("tablet_msar matches reference values", {
  for (case in cases_tablet_msar) {
    result <- do.call(tablet_msar, case$input)
    expect_equal(result, case$output, tolerance = 1e-2)
  }
})

# tablet_pwr ==================================================================
cases_tablet_pwr <- list(
  list(
    input = list(
      freq        = "2400",
      dur_low     = 728,
      dur_lowmed  = 81,
      dur_medhigh = 728,
      dur_high    = 81,
      params      = template_params
    ),
    output = 11.79815
  ),
  list(
    input = list(
      freq        = "5000",
      dur_low     = 728,
      dur_lowmed  = 81,
      dur_medhigh = 728,
      dur_high    = 81,
      params      = template_params
    ),
    output = 10.48502
  )
)

test_that("tablet_pwr matches reference values", {
  for (case in cases_tablet_pwr) {
    result <- do.call(tablet_pwr, case$input)
    expect_equal(result, case$output, tolerance = 1e-2)
  }
})

# tablet_sar ==================================================================
cases_tablet_sar <- list(
  list(
    input = list(
      tissue = "brain",
      freq   = "2400",
      params = template_params
    ),
    output = 0.4973535
  ),
  list(
    input = list(
      tissue = "brain",
      freq   = "5000",
      params = template_params
    ),
    output = 0.05798965
  ),
  list(
    input = list(
      tissue = "body",
      freq   = "2400",
      params = template_params
    ),
    output = 0.5367537
  ),
  list(
    input = list(
      tissue = "body",
      freq   = "5000",
      params = template_params
    ),
    output = 0.3086316
  )
)

test_that("tablet_sar matches reference values", {
  for (case in cases_tablet_sar) {
    result <- do.call(tablet_sar, case$input)
    expect_equal(result, case$output, tolerance = 1e-2)
  }
})

