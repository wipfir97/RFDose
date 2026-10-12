# SAR files (inst/extdata/sar_*.yaml) #########################################

sar_files  <- list.files(system.file("extdata", package = "RFDose"),
                         pattern = "^sar_.*\\.yaml$", full.names = TRUE)
etain_file <- system.file("extdata", "sar_etain.yaml", package = "RFDose")
phantoms   <- c("duke", "ella", "eartha", "thelonious")

goliat_file <- function(name) {
  system.file("extdata", paste0("sar_goliat_", name, ".yaml"), package = "RFDose")
}

# SAR values of a SAR file as a named vector ("device.tissue.name")
# (SAR values are the only nested lists within a device)
sar_values <- function(file) {
  devices <- yaml::read_yaml(file)$devices
  unlist(lapply(devices, function(device) device[vapply(device, is.list, logical(1))]))
}

# Device parameters of a SAR file that are not SAR values (placement proportions)
device_params <- function(file) {
  devices <- yaml::read_yaml(file)$devices
  lapply(devices, function(device) device[!vapply(device, is.list, logical(1))])
}

## Structure and values =======================================================
test_that("all SAR files are found", {
  expected <- c("sar_etain.yaml", basename(goliat_file(c("average", phantoms))))
  expect_true(all(expected %in% basename(sar_files)))
})

for (sar_file in sar_files) {
  name <- basename(sar_file)

  test_that(paste(name, "has brain and body SAR values for every device"), {
    devices <- yaml::read_yaml(sar_file)$devices
    params  <- yaml::read_yaml(system.file("extdata", "params.yaml", package = "RFDose"))
    has_tissues <- vapply(devices, function(device) all(c("brain", "body") %in% names(device)),
                          logical(1))

    expect_setequal(names(devices), names(params$devices))
    expect_equal(names(devices)[!has_tissues], character(0))
  })

  test_that(paste(name, "has the same SAR values as sar_etain.yaml"), {
    expect_setequal(names(sar_values(sar_file)), names(sar_values(etain_file)))
  })

  test_that(paste(name, "has finite, non-negative SAR values"), {
    values <- sar_values(sar_file)

    expect_true(is.numeric(values))
    expect_equal(names(values)[!(is.finite(values) & values >= 0)], character(0))
  })

  test_that(paste(name, "has placement proportions that sum to 1"), {
    params <- device_params(sar_file)
    for (device in names(params)) {
      props <- unlist(params[[device]][grepl("_prop$", names(params[[device]]))])
      if (length(props) > 0) {
        # tolerance: ETAIN uses 0.333 for each of its three call placements
        expect_equal(sum(props), 1, tolerance = 0.01, label = paste(device, "proportions"))
      }
    }
  })
}

## GOLIAT phantoms ============================================================
test_that("GOLIAT average SAR values are the mean of the four phantoms", {
  average <- sar_values(goliat_file("average"))
  values  <- lapply(phantoms, function(phantom) sar_values(goliat_file(phantom))[names(average)])

  expect_equal(average, Reduce(`+`, values) / length(phantoms))
})

test_that("GOLIAT phantoms use the same placement proportions as the average", {
  average <- device_params(goliat_file("average"))
  for (phantom in phantoms) {
    expect_equal(device_params(goliat_file(phantom)), average, label = phantom)
  }
})

## Dose calculation ===========================================================
for (sar_file in sar_files) {
  test_that(paste("calculate_emf_doses gives finite, non-negative doses with", basename(sar_file)), {
    for (tissue in c("brain", "body")) {
      result <- calculate_emf_doses(example_data, tissue = tissue, sar_file = sar_file)
      doses  <- unlist(result[dose_cols])

      expect_equal(nrow(result), nrow(example_data))
      expect_equal(names(doses)[!(is.finite(doses) & doses >= 0)], character(0),
                   label = paste(tissue, "doses that are not finite and >= 0"))
    }
  })
}
