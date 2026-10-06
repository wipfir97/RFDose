test_that("calculate_emf_doses works with valid input", {
  input <- tibble::tibble(
    use_5g               = TRUE,
    travel_time          = 1800,
    urbanicity           = "suburban",
    country              = "Other",
    headp_ear_num        = 2,
    mpc_duration         = 425,
    mpc_ear_prop         = 0.25,
    mpc_headp_prop       = 0.5,
    mpd_wifi_prop_home   = 0.5,
    mpd_wifi_prop_travel = 0.5,
    mpd_wifi_prop_work   = 0.5,
    mpd_dur_low          = 4860,
    mpd_dur_lowtomed     = 540,
    mpd_dur_medtohigh    = 4860,
    mpd_dur_high         = 540,
    dect_duration        = 205,
    dect_ear_prop        = 0.9,
    lptp_dur_low         = 1967,
    lptp_dur_lowtomed    = 219,
    lptp_dur_medtohigh   = 1967,
    lptp_dur_high        = 219,
    tblt_dur_low         = 728,
    tblt_dur_lowtomed    = 81,
    tblt_dur_medtohigh   = 728,
    tblt_dur_high        = 81,
    hotspot_duration     = 0,
    smartwatch_duration  = 0,
    tracker_duration     = 0,
    vr_duration          = 0,
    headphone_duration   = 0,
    gaming_duration      = 600
  )

  result <- calculate_emf_doses(input, tissue = "brain")

  expect_s3_class(result, "data.frame")
  expect_true(nrow(result) == 1)
  }
)

test_that("calculate_emf_doses works adds output columns", {
  input <- tibble::tibble(
    use_5g               = TRUE,
    travel_time          = 1800,
    urbanicity           = "suburban",
    country              = "Other",
    headp_ear_num        = 2,
    mpc_duration         = 425,
    mpc_ear_prop         = 0.25,
    mpc_headp_prop       = 0.5,
    mpd_wifi_prop_home   = 0.5,
    mpd_wifi_prop_travel = 0.5,
    mpd_wifi_prop_work   = 0.5,
    mpd_dur_low          = 4860,
    mpd_dur_lowtomed     = 540,
    mpd_dur_medtohigh    = 4860,
    mpd_dur_high         = 540,
    dect_duration        = 205,
    dect_ear_prop        = 0.9,
    lptp_dur_low         = 1967,
    lptp_dur_lowtomed    = 219,
    lptp_dur_medtohigh   = 1967,
    lptp_dur_high        = 219,
    tblt_dur_low         = 728,
    tblt_dur_lowtomed    = 81,
    tblt_dur_medtohigh   = 728,
    tblt_dur_high        = 81,
    hotspot_duration     = 0,
    smartwatch_duration  = 0,
    tracker_duration     = 0,
    vr_duration          = 0,
    headphone_duration   = 0,
    gaming_duration      = 600
  )

  result <- calculate_emf_doses(input, tissue = "body")

  expect_true(all(
    c("call_dose",
      "data_dose",
      "dect_dose",
      "farf_dose",
      "wifi_dose",
      "lptp_dose",
      "tblt_dose",
      "other_dose") %in% names(result)
  ))
  }
)

test_that("calculate_emf_doses replaces missing values", {
  input <- tibble::tibble(
    use_5g               = TRUE,
    travel_time          = 1800,
    urbanicity           = "suburban",
    country              = "Other",
    headp_ear_num        = 2,
    mpc_duration         = 425,
    mpc_ear_prop         = 0.25,
    mpc_headp_prop       = 0.5,
    mpd_wifi_prop_home   = 0.5,
    mpd_wifi_prop_travel = NA,
    mpd_wifi_prop_work   = 0.5,
    mpd_dur_low          = 4860,
    mpd_dur_lowtomed     = 540,
    mpd_dur_medtohigh    = 4860,
    mpd_dur_high         = 540,
    dect_duration        = 205,
    dect_ear_prop        = 0.9,
    lptp_dur_low         = NA,
    lptp_dur_lowtomed    = 219,
    lptp_dur_medtohigh   = 1967,
    lptp_dur_high        = 219,
    tblt_dur_low         = 728,
    tblt_dur_lowtomed    = 81,
    tblt_dur_medtohigh   = 728,
    tblt_dur_high        = 81,
    hotspot_duration     = 0,
    smartwatch_duration  = NA,
    tracker_duration     = 0,
    vr_duration          = 0,
    headphone_duration   = 0,
    gaming_duration      = 600
  )

  result <- suppressWarnings(
    calculate_emf_doses(input, tissue = "brain")
  )

  expect_false(anyNA(result))

})

test_that("calculate_emf_doses warns on high missingness", {
  input <- tibble::tibble(
    use_5g               = TRUE,
    travel_time          = 1800,
    urbanicity           = "suburban",
    country              = "Other",
    headp_ear_num        = 2,
    mpc_duration         = 425,
    mpc_ear_prop         = 0.25,
    mpc_headp_prop       = 0.5,
    mpd_wifi_prop_home   = 0.5,
    mpd_wifi_prop_travel = NA,
    mpd_wifi_prop_work   = 0.5,
    mpd_dur_low          = 4860,
    mpd_dur_lowtomed     = 540,
    mpd_dur_medtohigh    = 4860,
    mpd_dur_high         = 540,
    dect_duration        = 205,
    dect_ear_prop        = 0.9,
    lptp_dur_low         = NA,
    lptp_dur_lowtomed    = 219,
    lptp_dur_medtohigh   = 1967,
    lptp_dur_high        = 219,
    tblt_dur_low         = 728,
    tblt_dur_lowtomed    = 81,
    tblt_dur_medtohigh   = 728,
    tblt_dur_high        = 81,
    hotspot_duration     = 0,
    smartwatch_duration  = NA,
    tracker_duration     = 0,
    vr_duration          = 0,
    headphone_duration   = 0,
    gaming_duration      = 600
  )

  expect_warning(
    calculate_emf_doses(input, tissue = "brain"),
    "missing")
})

## sar_file ===================================================================
make_sar_test_input <- function() {
  tibble::tibble(
    use_5g               = TRUE,
    travel_time          = 1800,
    urbanicity           = "suburban",
    country              = "Other",
    headp_ear_num        = 2,
    mpc_duration         = 425,
    mpc_ear_prop         = 0.25,
    mpc_headp_prop       = 0.5,
    mpd_wifi_prop_home   = 0.5,
    mpd_wifi_prop_travel = 0.5,
    mpd_wifi_prop_work   = 0.5,
    mpd_dur_low          = 4860,
    mpd_dur_lowtomed     = 540,
    mpd_dur_medtohigh    = 4860,
    mpd_dur_high         = 540,
    dect_duration        = 205,
    dect_ear_prop        = 0.9,
    lptp_dur_low         = 1967,
    lptp_dur_lowtomed    = 219,
    lptp_dur_medtohigh   = 1967,
    lptp_dur_high        = 219,
    tblt_dur_low         = 728,
    tblt_dur_lowtomed    = 81,
    tblt_dur_medtohigh   = 728,
    tblt_dur_high        = 81,
    hotspot_duration     = 300,
    smartwatch_duration  = 3600,
    tracker_duration     = 0,
    vr_duration          = 600,
    headphone_duration   = 1800,
    gaming_duration      = 600
  )
}

dose_cols <- c("call_dose", "data_dose", "dect_dose", "farf_dose",
               "wifi_dose", "lptp_dose", "tblt_dose", "other_dose")

test_that("calculate_emf_doses uses default SAR values when sar_file is NULL", {
  input    <- make_sar_test_input()
  sar_file <- system.file("extdata", "sar_etain.yaml", package = "RFDose")

  expect_equal(
    calculate_emf_doses(input, tissue = "brain"),
    calculate_emf_doses(input, tissue = "brain", sar_file = sar_file))
})

test_that("calculate_emf_doses works with a parameter file without SAR values", {
  input       <- make_sar_test_input()
  params_file <- system.file("extdata", "params_nosar.yaml", package = "RFDose")

  expect_equal(
    calculate_emf_doses(input, tissue = "brain"),
    calculate_emf_doses(input, tissue = "brain", params = params_file))
})

test_that("calculate_emf_doses applies SAR values from sar_file", {
  input <- make_sar_test_input()
  # Double every SAR value: doses are linear in SAR, so they must double too
  sar <- yaml::read_yaml(system.file("extdata", "sar_etain.yaml", package = "RFDose"))
  sar <- rapply(sar, function(x) 2 * x, how = "replace")
  sar_file <- tempfile(fileext = ".yaml")
  yaml::write_yaml(sar, sar_file, precision = 15)

  for (tissue in c("brain", "body")) {
    default <- calculate_emf_doses(input, tissue = tissue)
    doubled <- calculate_emf_doses(input, tissue = tissue, sar_file = sar_file)

    expect_true(all(default[dose_cols] > 0))
    expect_equal(doubled[dose_cols], 2 * default[dose_cols])
  }
})

