# Loading parameter functions #################################################

## load_params ================================================================
library(yaml)

test_that("load_params returns a list when using the default path to yaml file", {
  result <- load_params()
  expect_type(result, "list")
})

test_that("load_params loads default yaml file without error", {
  expect_no_error(load_params())
})

test_that("load_params errors when file does not exist", {
  fake_path <- file.path(tempdir(), "hello_i_do_not_exist.yaml")
  expect_error(load_params(fake_path))
})

test_that("load_params returns NULL path behavior consistent with explicit default path", {
  default_result  <- load_params()
  explicit_result <- load_params(system.file("extdata", "params.yaml", package = "RFDose"))

  expect_equal(default_result, explicit_result)
})

## load_tissue_params =========================================================
make_test_params <- function() {
  list(
    devices = list(
      deviceA = list(
        power = 2,
        brain = list(
          sar1 = 1.5,
          sar2 = 0.4),
        body = list(
          sar1 = 2,
          sar2 = 0.8)
      ),
      deviceB = list(
        power = 2,
        brain = list(
          sar1 = 1.5,
          sar2 = 0.4),
        body = list(
          sar1 = 2)
      )
    )
  )
}

test_that("load_tissue_params extracts correct values for valid device and tissue", {
  params <- make_test_params()
  result <- load_tissue_params(params, "deviceA", "brain")

  expect_type(result, "list")
  expect_equal(result$sar1, 1.5)
  expect_equal(result$sar2, 0.4)
})

test_that("load_tissue_params picks the correct device when multiple exist", {
  params <- make_test_params()
  result <- load_tissue_params(params, "deviceB", "body")

  expect_equal(result$sar1, 2)
  expect_null(result$sar2)
})

test_that("load_tissue_params errors on invalid device_type", {
  params <- make_test_params()

  expect_error(
    load_tissue_params(params, "device_inexistent", "body"),
    "Invalid device type"
  )
})

test_that("load_tissue_params calls check_tissue and propagates the error", {
  params <- make_test_params()

  expect_error(
    load_tissue_params(params, "deviceA", "invalid_tissue"),
    "Invalid tissue."
  )
})


# Checking functions ##########################################################
## check_proportions ==========================================================
test_that("check_proportions returns invisible TRUE on valid single input", {
  result <- withVisible(check_proportions(0.5))
  expect_true(result$value)
  expect_false(result$visible)
})

test_that("check_proportions rejects invalid proportion input", {
  tol <- .Machine$double.eps^0.5
  expect_error(check_proportions(1 + tol * 2), "not between 0 and 1")
  expect_error(check_proportions(NULL))
  expect_error(check_proportions(c(-1, 1.5)))
})

test_that("check_proportions warns if input does not add to 1", {
  tol <- .Machine$double.eps^0.5
  expect_warning(check_proportions(c(0.4, 0.5)), "do not sum to 1")
})

## check_duration =============================================================
test_that("check_duration returns invisible TRUE on valid single input", {
  result <- withVisible(check_duration(0.5))
  expect_true(result$value)
  expect_false(result$visible)
})

test_that("check_duration rejects invalid duration input", {
  tol <- .Machine$double.eps^0.5
  expect_error(check_duration(0 - tol * 2), "negative")
  expect_error(check_duration(NULL))
  expect_error(check_duration(c(1, 2, NA)))
  expect_error(check_duration(c(-5, 5)))
})

test_that("check_duration warns if input duration exceepts 86400 seconds", {
  expect_warning(check_duration(c(20000, 40000, 60000)))
  expect_warning(check_duration(100000))
})

## check_numeric_not_na  =======================================================
test_that("check_numeric_not_na returns invisible TRUE on valid single input", {
  result <- withVisible(check_numeric_not_na(0.5))
  expect_true(result$value)
  expect_false(result$visible)
})

test_that("check_numeric_not_na errors for invalid input", {
  expect_error(check_numeric_not_na(NA))
  expect_error(check_numeric_not_na("hello"))
  expect_error(check_numeric_not_na(NA_real_))
  expect_error(check_numeric_not_na(c(1, 2)))
})

## check_character_not_na =====================================================
test_that("check_character_not_na returns invisible TRUE on valid single input", {
  result <- withVisible(check_character_not_na("hello"))
  expect_true(result$value)
  expect_false(result$visible)
})

test_that("check_character_not_na errors for invalid input", {
  expect_error(check_character_not_na(NA))
  expect_error(check_character_not_na(5))
  expect_error(check_character_not_na(NA_character_))
  expect_error(check_character_not_na(c("hello", "there")))
})

## check_boolean_not_na =======================================================
test_that("check_boolean_not_na returns invisible TRUE on valid single input", {
  result <- withVisible(check_boolean_not_na(TRUE))
  expect_true(result$value)
  expect_false(result$visible)
})

test_that("check_boolean_not_na errors for invalid input", {
  expect_error(check_boolean_not_na(NA))
  expect_error(check_boolean_not_na(5))
  expect_error(check_boolean_not_na(NA_real_))
  expect_error(check_boolean_not_na(c(TRUE, FALSE)))
})

## check_urbanicity ===========================================================
test_that("check_urbanicity returns invisible TRUE on valid single input", {
  result <- withVisible(check_urbanicity("suburban"))
  expect_true(result$value)
  expect_false(result$visible)
})

test_that("check_urbanicity errors for invalid input", {
  expect_error(check_urbanicity(NA))
  expect_error(check_urbanicity(5))
  expect_error(check_urbanicity(NA_character_))
  expect_error(check_urbanicity(NULL))
  expect_error(check_urbanicity("hello"))
  expect_error(check_urbanicity(c("urban", "urban")))
})

## check_tissue ===============================================================
test_that("check_tissue returns invisible TRUE on valid single input", {
  result <- withVisible(check_tissue("brain", "call", load_params()))
  expect_true(result$value)
  expect_false(result$visible)
})

test_that("check_tissue errors for invalid input", {
  expect_error(check_tissue(NA, "call", load_params()))
  expect_error(check_tissue("body", "inexistent_device", load_params()))
  expect_error(check_tissue("inexistend_tissue", "data", load_params()))
  expect_error(check_tissue("brain", 1, load_params()))
})

## check_country ==============================================================
test_that("check_country returns invisible TRUE on valid single input", {
  result <- withVisible(check_country("ES"))
  expect_true(result$value)
  expect_false(result$visible)
})

test_that("check_country errors for invalid input", {
  expect_error(check_country(NA))
  expect_error(check_country("DE"))
  expect_error(check_country(c("AT", "CH")))
})

## check_headp_num ========================================================
test_that("check_headp_num returns invisible TRUE on valid single input", {
  result <- withVisible(check_headp_num(2))
  expect_true(result$value)
  expect_false(result$visible)
})

test_that("check_headp_num errors for invalid input", {
  expect_error(check_headp_num(NA))
  expect_error(check_headp_num(3))
  expect_error(check_headp_num(0.5))
  expect_error(check_headp_num(c(1, 2)))
})


# Filling missing values ######################################################
test_that("fill_missing_variables fills NA values in an existing column", {
  data <- data.frame(age = c(25, NA, 30), stringsAsFactors = FALSE)
  result <- fill_missing_variables(data, defaults = list(age = 0))

  expect_equal(result$data$age, c(25, 0, 30))
  expect_equal(result$replaced$age, 1)
})

test_that("fill_missing_variables fills an entirely missing column with the default for every row", {
  data <- data.frame(age = c(25, 30, 40))
  result <- fill_missing_variables(data, defaults = list(height = 170))

  expect_equal(result$data$height, rep(170, 3))
  expect_equal(result$replaced$height, 3)
})

test_that("fill_missing_variables treats empty strings as missing for character columns", {
  data <- data.frame(city = c("Basel", "", "Zurich"), stringsAsFactors = FALSE)
  result <- fill_missing_variables(data, defaults = list(city = "Unknown"))

  expect_equal(result$data$city, c("Basel", "Unknown", "Zurich"))
  expect_equal(result$replaced$city, 1)
})

test_that("fill_missing_variables does not modify columns outside of `defaults`", {
  data <- data.frame(
    age  = c(25, NA, 30),
    note = c("fine", "", "ok"),
    stringsAsFactors = FALSE
  )
  result <- fill_missing_variables(data, defaults = list(age = 0))
  expect_equal(result$data$note, c("fine", "", "ok"))
})

test_that("fill_missing_variables warns when missing proportion exceeds threshold", {
  data <- data.frame(age = c(NA, NA, NA, 40))  # 75% missing
  expect_warning(
    fill_missing_variables(data, defaults = list(age = 0), warn_threshold = 0.1),
    "75.0% missing"
  )
})

test_that("fill_missing_variables warns when an entirely missing column is filled", {
  data <- data.frame(age = c(25, 30, 40))
  expect_warning(
    fill_missing_variables(data, defaults = list(height = 170)),
    "entirely missing"
  )
})

test_that("fill_missing_variables handles a data frame with zero rows without error", {
  data <- data.frame(age = numeric(0))
  expect_no_error(
    result <- fill_missing_variables(data, defaults = list(age = 0))
  )
  expect_equal(nrow(result$data), 0)
  expect_equal(result$replaced$age, 0)
})

test_that("fill_missing_variables errors clearly when default is not a valid factor level", {
  data <- data.frame(grp = factor(c("a", NA, "b")))
  expect_error(
    fill_missing_variables(data, defaults = list(grp = "c")),  # "c" not in levels("a","b")
    "not among its existing factor levels"
  )
})

test_that("fill_missing_variables fills factor column correctly when default is a valid level", {
  data <- data.frame(grp = factor(c("a", NA, "b"), levels = c("a", "b", "unknown")))
  result <- fill_missing_variables(data, defaults = list(grp = "unknown"))

  expect_equal(as.character(result$data$grp), c("a", "unknown", "b"))
})

test_that("fill_missing_variables errors when data is not a data frame", {
  expect_error(fill_missing_variables(list(age = c(1, NA)), defaults = list(age = 0)))
})

test_that("fill_missing_variables errors when defaults is not a named list", {
  data <- data.frame(age = c(25, NA))
  expect_error(fill_missing_variables(data, defaults = list(0)))       # unnamed
  expect_error(fill_missing_variables(data, defaults = c(age = 0)))    # not a list
})

test_that("fill_missing_variables errors when warn_threshold is out of range", {
  data <- data.frame(age = c(25, NA))
  expect_error(fill_missing_variables(data, defaults = list(age = 0), warn_threshold = 1.5))
  expect_error(fill_missing_variables(data, defaults = list(age = 0), warn_threshold = -0.1))
})

test_that("fill_missing_variables preserves numeric column type after filling", {
  data <- data.frame(age = c(25, NA, 30))
  result <- fill_missing_variables(data, defaults = list(age = 0))
  expect_type(result$data$age, "double")
})

test_that("fill_missing_variables handles multiple variables in one call", {
  data <- data.frame(
    age  = c(25, NA, 30),
    city = c("Basel", "", "Zurich"),
    stringsAsFactors = FALSE
  )
  result <- fill_missing_variables(
    data,
    defaults = list(age = 0, city = "Unknown", country = "CH")  # country entirely missing
  )

  expect_equal(result$data$age, c(25, 0, 30))
  expect_equal(result$data$city, c("Basel", "Unknown", "Zurich"))
  expect_equal(result$data$country, rep("CH", 3))
  expect_equal(result$replaced, list(age = 1, city = 1, country = 3))
})

# Calculating proportions #####################################################
## Location proportions =======================================================
test_that("location_props computes correct proportions for typical valid input", {
  result <- location_props(
    travel_time = 1800,
    home_prop   = 0.6,
    work_prop   = 0.3,
    outd_prop   = 0.1
  )

  expect_equal(result$travel, 1800 / 86400)
  expect_equal(result$home, 0.6 - 1800 / 86400)
  expect_equal(result$work, 0.3)
  expect_equal(result$out, 0.1)
})


test_that("location_props returns a named list with expected keys", {
  result <- location_props(3600, 0.6, 0.3, 0.1)
  expect_named(result, c("travel", "home", "work", "out"))
})

test_that("location_props output proportions sum to 1 when input proportions sum to 1", {
  result <- location_props(3600, 0.6, 0.3, 0.1)
  expect_equal(sum(unlist(result)), 1, tolerance = 1e-9)
})

test_that("location_props handles zero travel time correctly", {
  result <- location_props(0, 0.6, 0.3, 0.1)
  expect_equal(result$travel, 0)
  expect_equal(result$home, 0.6)
})

test_that("location_props warns when input proportions do not sum to 1", {
  expect_warning(location_props(3600, 0.5, 0.3, 0.1))  # sums to 0.9, not 1
})

test_that("location_props errors when travel_time is negative", {
  expect_error(location_props(-100, 0.6, 0.3, 0.1))
})

test_that("location_props errors when travel_time is non-numeric", {
  expect_error(location_props("3600", 0.6, 0.3, 0.1))
})

test_that("location_props errors when travel_time exceeds home_prop (physically impossible)", {
  # home_prop = 0.01 of day (~864s); travel_time = 3600s exceeds it
  expect_error(
    location_props(3600, 0.01, 0.94, 0.05),
    "not defined"
  )
})

test_that("location_props errors when any individual proportion is out of [0,1] range", {
  expect_error(location_props(3600, 1.5, -0.5, 0))
})

test_that("location_props warns if any downstream proportion is inconsistent", {
  result <- location_props(86400 * 0.6, 0.6, 0.3, 0.1)
  expect_equal(result$home, 0)  # exactly zero, not negative - should NOT error
})

test_that("location_props preserves proportional relationships regardless of travel_time", {
  # work and outdoor proportions should never change with travel_time
  result_a <- location_props(1000, 0.6, 0.3, 0.1)
  result_b <- location_props(5000, 0.6, 0.3, 0.1)
  expect_equal(result_a$work, result_b$work)
  expect_equal(result_a$out, result_b$out)
})

## Activity proportions =======================================================
test_that("act_pwr_props computes correct proportions for typical valid input", {
  result <- act_pwr_props(low_dur = 100, lowmed_dur = 100, medhigh_dur = 100, high_dur = 100)
  expect_equal(result$low, 0.25)
  expect_equal(result$lowmed, 0.25)
  expect_equal(result$medhigh, 0.25)
  expect_equal(result$high, 0.25)
})

test_that("act_pwr_props returns a named list with expected keys", {
  result <- act_pwr_props(100, 100, 100, 100)
  expect_named(result, c("low", "lowmed", "medhigh", "high"))
})

test_that("act_pwr_props preserves relative magnitude between categories", {
  result <- act_pwr_props(low_dur = 200, lowmed_dur = 100, medhigh_dur = 50, high_dur = 50)
  expect_equal(result$low, 0.5)
  expect_equal(result$lowmed, 0.25)
  expect_equal(result$medhigh, 0.125)
  expect_equal(result$high, 0.125)
})

test_that("act_pwr_props output sums to 1 for nonzero inputvalues", {
  result <- act_pwr_props(37, 812, 5, 1901)
  expect_equal(sum(unlist(result)), 1, tolerance = 1e-9)
})

test_that("act_pwr_props returns all zeros when all durations are zero", {
  result <- act_pwr_props(0, 0, 0, 0)
  expect_equal(result, list("low" = 0, "lowmed" = 0, "medhigh" = 0, "high" = 0))
})

test_that("act_pwr_props errors on negative duration", {
  expect_error(act_pwr_props(-5, 5, 0, 0), "negative")
})

test_that("act_pwr_props errors on NA input", {
  expect_error(act_pwr_props(NA, 100, 100, 100), "be NA")
})

test_that("act_pwr_props errors on non-numeric input", {
  expect_error(act_pwr_props("100", 100, 100, 100), "must be numeric")
})

test_that("act_pwr_props errors if any argument is a vector", {
  expect_error(act_pwr_props(c(100, 200), 100, 100, 100))
})

test_that("act_pwr_props warns if total duration exceeds 86400 seconds", {
  expect_warning(
    act_pwr_props(30000, 30000, 30000, 30000),
    "sum of durations exceeds"
  )
})

test_that("act_pwr_props handles one dominant category correctly", {
  result <- act_pwr_props(low_dur = 0, lowmed_dur = 0, medhigh_dur = 0, high_dur = 500)
  expect_equal(result$high, 1)
  expect_equal(result$low, 0)
  expect_equal(result$lowmed, 0)
  expect_equal(result$medhigh, 0)
})

test_that("act_pwr_props errors if a single duration alone exceeds 86400", {
  expect_warning(
    act_pwr_props(90000, 0, 0, 0),
    "exceeds 86400"
  )
})
