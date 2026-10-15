# Distribution file (inst/extdata/params_distributions.yaml) ##################

params <- yaml::read_yaml(system.file("extdata", "params.yaml", package = "RFDose"))
specs  <- list_distributions(load_distributions())

# Shape values of each distribution
shape_fields <- list(
  lognormal       = "sd_rel",
  trunc_lognormal = c("sd_rel", "min", "max"),
  beta            = "alpha",
  dirichlet       = c("group", "a0"))

is_number <- function(x) is.numeric(x) && length(x) == 1 && is.finite(x)

## Structure ==================================================================
test_that("the distribution file has distributions", {
  expect_gt(length(specs), 0)
})

test_that("every drawn parameter is a parameter of params.yaml", {
  values <- vapply(specs, function(spec) {
    value <- params[[spec$key]]
    is.numeric(value) && length(value) == 1
  }, logical(1))

  expect_equal(names(values)[!values], character(0))
})

test_that("every distribution is known and has its shape values only", {
  for (name in names(specs)) {
    spec <- specs[[name]]

    expect_true(spec$distribution %in% names(shape_fields), label = name)
    expect_setequal(setdiff(names(spec), c("key", "distribution")),
                    shape_fields[[spec$distribution]])
  }
})

## Values =====================================================================
test_that("lognormal distributions have mean > 0 and sd_rel > 0", {
  for (spec in Filter(function(spec) spec$distribution == "lognormal", specs)) {
    label <- paste(spec$key, collapse = " > ")

    expect_true(is_number(spec$sd_rel) && spec$sd_rel > 0, label = label)
    expect_gt(params[[spec$key]], 0, label = label)
  }
})

test_that("truncated lognormal distributions have sd_rel > 0 and 0 <= min < mean < max", {
  for (spec in Filter(function(spec) spec$distribution == "trunc_lognormal", specs)) {
    label <- paste(spec$key, collapse = " > ")
    mean  <- params[[spec$key]]

    expect_true(is_number(spec$sd_rel) && spec$sd_rel > 0, label = label)
    expect_true(is_number(spec$min) && is_number(spec$max), label = label)
    expect_true(spec$min >= 0 && spec$min < mean && mean < spec$max, label = label)
  }
})

test_that("beta distributions have 0 < mean < 1 and alpha > 0", {
  for (spec in Filter(function(spec) spec$distribution == "beta", specs)) {
    label <- paste(spec$key, collapse = " > ")
    mean  <- params[[spec$key]]

    expect_true(is_number(spec$alpha) && spec$alpha > 0, label = label)
    expect_true(mean > 0 && mean < 1, label = label)
  }
})

test_that("Dirichlet groups have one a0 and means that sum to 1", {
  dirichlet <- Filter(function(spec) spec$distribution == "dirichlet", specs)
  groups    <- vapply(dirichlet, function(spec) spec$group, character(1))

  for (group in unique(groups)) {
    members <- dirichlet[groups == group]
    means   <- vapply(members, function(spec) params[[spec$key]], numeric(1))
    a0      <- unique(vapply(members, function(spec) spec$a0, numeric(1)))

    expect_gte(length(members), 2, label = group)
    expect_length(a0, 1)
    expect_true(a0 > 0, label = group)
    expect_true(all(means >= 0 & means <= 1), label = group)
    expect_equal(sum(means), 1, tolerance = 1e-9, label = paste(group, "sum of means"))
  }
})

## SAR files ==================================================================
test_that("no SAR file sets a drawn parameter", {
  # The mean of a drawn parameter is its value in params.yaml for every SAR file
  sar_files <- list.files(system.file("extdata", package = "RFDose"),
                          pattern = "^sar_.*\\.yaml$", full.names = TRUE)
  for (sar_file in sar_files) {
    sar <- yaml::read_yaml(sar_file)
    set <- vapply(specs, function(spec) {
      value <- tryCatch(sar[[spec$key]], error = function(e) NULL)
      !is.null(value)
    }, logical(1))

    expect_equal(names(set)[set], character(0), label = basename(sar_file))
  }
})
