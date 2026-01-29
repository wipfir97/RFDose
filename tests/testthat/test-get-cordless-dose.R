test_that("get_cordless_dose errors if required argument is missing", {
  expect_error(
    get_cordless_dose(duration = 204),
    "ear_proportion"
  )
})

test_that("get_cordless_dose errors if duration and ear_proportion are not numeric", {
  expect_error(
    get_cordless_dose(duration = "204",
                      ear_proportion = 0.9),
    "numeric"
  )
  expect_error(
    get_cordless_dose(duration = 204,
                      ear_proportion = "0.9"),
    "numeric"
  )
})

test_that("get_cordless_dose errors in case of nonsense input values", {
  expect_error(
    get_cordless_dose(duration = -204,
                      ear_proportion = 0.9)
  )
  expect_error(
    get_cordless_dose(duration = 204,
                      ear_proportion = 1.5)
  )
})

reference_cases <- list(
  list(
    input = list(duration = 180, ear_proportion = 0.9),
    output = list(brain_dect_dose = 57.05, body_dect_dose = 11.76)
  ),
  list(
    input = list(duration = 60, ear_proportion = 0.5),
    output = list(brain_dect_dose = 11.26, body_dect_dose = 2.74)
  ),
  list(
    input = list(duration = 180, ear_proportion = 0),
    output = list(brain_dect_dose = 4.69, body_dect_dose = 3.81)
  ),
  list(
    input = list(duration = 0, ear_proportion = 0.9),
    output = list(brain_dect_dose = 0, body_dect_dose = 0)
  ),
  list(
    input = list(duration = 180, ear_proportion = 1),
    output = list(brain_dect_dose = 62.87, body_dect_dose = 12.65)
  )
)

test_that("get_cordless_dose matches reference calculations", {
  for (case in reference_cases) {
    result <- do.call(get_cordless_dose, case$input)
    expect_equal(result, case$output, tolerance = 1e-3) # tolerance due to rounding inconsistencies
  }
})


