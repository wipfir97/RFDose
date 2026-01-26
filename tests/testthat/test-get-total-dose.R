test_that("get_total_dose returns a named list", {
  vars <- list(
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
    gaming_duration = 600)


  result <- get_total_dose(vars)

  expect_type(result, "list")
  expect_named(result)
})
