test_that("calculate_emf_doses works with valid input", {
  input <- tibble::tibble(
    use_5g = TRUE,
    travel_time = 1800,
    urbanicity = "suburban",
    country = "Other",
    headp_ear_num = 2,
    mpc_duration = 425,
    mpc_ear_prop = 0.66,
    mpc_headp_prop = 0.5,
    mpd_wifi_prop_home = 0.5,
    mpd_wifi_prop_travel = 0.5,
    mpd_wifi_prop_work = 0.5,
    mpd_dur_low = 4860,
    mpd_dur_lowtomed = 540,
    mpd_dur_medtohigh = 4860,
    mpd_dur_high = 540,
    dect_duration = 205,
    dect_ear_prop = 0.9,
    lptp_dur_low = 1967,
    lptp_dur_lowtomed = 219,
    lptp_dur_medtohigh = 1967,
    lptp_dur_high = 219,
    tblt_dur_low = 728,
    tblt_dur_lowtomed = 81,
    tblt_dur_medtohigh = 728,
    tblt_dur_high = 81,
    hotspot_duration = 0,
    smartwatch_duration = 0,
    tracker_duration = 0,
    vr_duration = 0,
    headphone_duration = 0,
    gaming_duration = 600
  )

  result <- calculate_emf_doses(input)

  expect_s3_class(result, "data.frame")
  expect_true(nrow(result) == 1)
  }
)

test_that("calculate_emf_doses works adds output columns", {
  input <- tibble::tibble(
    use_5g = TRUE,
    travel_time = 1800,
    urbanicity = "suburban",
    country = "Other",
    headp_ear_num = 2,
    mpc_duration = 425,
    mpc_ear_prop = 0.66,
    mpc_headp_prop = 0.5,
    mpd_wifi_prop_home = 0.5,
    mpd_wifi_prop_travel = 0.5,
    mpd_wifi_prop_work = 0.5,
    mpd_dur_low = 4860,
    mpd_dur_lowtomed = 540,
    mpd_dur_medtohigh = 4860,
    mpd_dur_high = 540,
    dect_duration = 205,
    dect_ear_prop = 0.9,
    lptp_dur_low = 1967,
    lptp_dur_lowtomed = 219,
    lptp_dur_medtohigh = 1967,
    lptp_dur_high = 219,
    tblt_dur_low = 728,
    tblt_dur_lowtomed = 81,
    tblt_dur_medtohigh = 728,
    tblt_dur_high = 81,
    hotspot_duration = 0,
    smartwatch_duration = 0,
    tracker_duration = 0,
    vr_duration = 0,
    headphone_duration = 0,
    gaming_duration = 600
  )

  result <- calculate_emf_doses(input)

  expect_true(all(
    c("brain_dect_dose", "body_dect_dose",
      "brain_call_dose", "body_call_dose",
      "brain_data_dose", "body_data_dose",
      "brain_wifi_dose", "body_wifi_dose",
      "brain_farf_dose", "body_farf_dose",
      "brain_lptp_dose", "body_lptp_dose",
      "brain_tblt_dose", "body_tblt_dose",
      "brain_othe_dose", "body_othe_dose",
      "brain_total_dose", "body_total_dose") %in% names(result)
  ))
  }
)

test_that("calculate_emf_doses replaces missing values", {
  input <- tibble::tibble(
    use_5g = TRUE,
    travel_time = NA_real_,
    urbanicity = "suburban",
    country = "Other",
    headp_ear_num = 2,
    mpc_duration = NA_real_,
    mpc_ear_prop = 0.66,
    mpc_headp_prop = 0.5,
    mpd_wifi_prop_home = 0.5,
    mpd_wifi_prop_travel = 0.5,
    mpd_wifi_prop_work = 0.5,
    mpd_dur_low = 4860,
    mpd_dur_lowtomed = 540,
    mpd_dur_medtohigh = 4860,
    mpd_dur_high = 540,
    dect_duration = 205,
    dect_ear_prop = 0.9,
    lptp_dur_low = 1967,
    lptp_dur_lowtomed = 219,
    lptp_dur_medtohigh = NA_real_,
    lptp_dur_high = 219,
    tblt_dur_low = 728,
    tblt_dur_lowtomed = 81,
    tblt_dur_medtohigh = 728,
    tblt_dur_high = 81,
    hotspot_duration = 0,
    smartwatch_duration = 0,
    tracker_duration = 0,
    vr_duration = 0,
    headphone_duration = 0,
    gaming_duration = 600
  )

  result <- suppressWarnings(
    calculate_emf_doses(input)
  )

  expect_false(anyNA(result))

})

test_that("calculate_emf_doses warns on high missingness", {
  input <- tibble::tibble(
    use_5g = TRUE,
    travel_time = 1800,
    urbanicity = "suburban",
    country = "Other",
    headp_ear_num = 2,
    mpc_duration = 425,
    mpc_ear_prop = 0.66,
    mpc_headp_prop = 0.5,
    mpd_wifi_prop_home = 0.5,
    mpd_wifi_prop_travel = 0.5,
    mpd_wifi_prop_work = 0.5,
    mpd_dur_low = 4860,
    mpd_dur_lowtomed = 540,
    mpd_dur_medtohigh = 4860,
    mpd_dur_high = 540,
    dect_duration = 205,
    dect_ear_prop = 0.9,
    lptp_dur_low = 1967,
    lptp_dur_lowtomed = 219,
    lptp_dur_medtohigh = NA_real_,
    lptp_dur_high = 219,
    tblt_dur_low = 728,
    tblt_dur_lowtomed = 81,
    tblt_dur_medtohigh = 728,
    tblt_dur_high = 81,
    hotspot_duration = 0,
    smartwatch_duration = 0,
    tracker_duration = 0,
    vr_duration = 0,
    headphone_duration = 0,
    gaming_duration = 600
  )

  expect_warning(
    calculate_emf_doses(input),
    "missing")
})

