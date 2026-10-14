# Input distribution file (inst/extdata/input_distributions.yaml) #############

defaults <- yaml::read_yaml(system.file("extdata", "defaultvariables.yaml", package = "RFDose"))
specs    <- load_input_distributions()

# Shape values of each distribution
shape_fields <- list(
  lognormal       = "sd_rel",
  trunc_lognormal = c("sd_rel", "min", "max"),
  beta            = "alpha",
  dirichlet       = c("group", "a0"),
  categorical     = "probs")

is_number <- function(x) is.numeric(x) && length(x) == 1 && is.finite(x)

## Structure ==================================================================
test_that("every drawn input is an input with a default value", {
  expect_gt(length(specs), 0)
  expect_equal(setdiff(names(specs), names(defaults)), character(0))
})

test_that("every distribution is known and has its shape values only", {
  for (name in names(specs)) {
    spec <- specs[[name]]

    expect_true(spec$distribution %in% names(shape_fields), label = name)
    expect_setequal(setdiff(names(spec), "distribution"), shape_fields[[spec$distribution]])
  }
})

## Values =====================================================================
test_that("lognormal inputs have sd_rel > 0 and bounds around their default", {
  for (name in names(specs)) {
    spec <- specs[[name]]
    if (!(spec$distribution %in% c("lognormal", "trunc_lognormal"))) next

    expect_true(is_number(spec$sd_rel) && spec$sd_rel > 0, label = name)
    if (spec$distribution == "trunc_lognormal") {
      expect_true(spec$min >= 0 && spec$min <= defaults[[name]] && defaults[[name]] < spec$max,
                  label = name)
    }
  }
})

test_that("beta inputs have alpha > 0 and a default between 0 and 1", {
  for (name in names(specs)) {
    spec <- specs[[name]]
    if (spec$distribution != "beta") next

    expect_true(is_number(spec$alpha) && spec$alpha > 0, label = name)
    expect_true(defaults[[name]] >= 0 && defaults[[name]] <= 1, label = name)
  }
})

test_that("Dirichlet groups have one a0 and defaults that sum to 1 at most", {
  dirichlet <- Filter(function(spec) spec$distribution == "dirichlet", specs)
  groups    <- vapply(dirichlet, function(spec) spec$group, character(1))

  for (group in unique(groups)) {
    members <- names(groups)[groups == group]

    expect_length(unique(vapply(dirichlet[members], function(spec) spec$a0, numeric(1))), 1)
    expect_lte(sum(unlist(defaults[members])), 1 + 1e-9)
  }
})

test_that("categorical inputs have probabilities that sum to 1 for every given value", {
  for (name in names(specs)) {
    spec <- specs[[name]]
    if (spec$distribution != "categorical") next
    values <- names(spec$probs)

    expect_true(defaults[[name]] %in% values, label = name)
    for (given in values) {
      probs <- unlist(spec$probs[[given]])
      expect_setequal(names(probs), values)
      expect_true(all(probs >= 0 & probs <= 1), label = paste(name, given))
      expect_equal(sum(probs), 1, tolerance = 1e-9, label = paste(name, given))
    }
  }
})

test_that("urbanicity is drawn among the values the dose calculation accepts", {
  for (value in names(specs$urbanicity$probs)) {
    expect_silent(check_urbanicity(value))
  }
})
