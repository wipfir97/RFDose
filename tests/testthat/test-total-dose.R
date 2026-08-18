test_that("total_dose returns a numeric value", {
  vars <- list(
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


  result <- total_dose(vars, tissue = "brain")

  expect_type(result, "double")
})

test_that("total_dose fails on missing numbers", {
  vars <- list(
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
    dect_duration        = NA,
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

  expect_error(
    total_dose(vars, tissue = "body"),
    "missing")
})

cases_total_dose <- list(
  list(input = list(
    sample = list(
        urbanicity = "suburban",
        use_5g = TRUE,
        travel_time = 1850,
        headp_ear_num = 2,    
        country              = "Other",
        mpc_duration         = 1533.35,
        mpc_ear_prop         = 0.447769,
        mpc_headp_prop       = 0.229485,
        mpd_wifi_prop_home   =  0.7378683,
        mpd_wifi_prop_travel = 0.3071721,
        mpd_wifi_prop_work   = 0.4892182,
        mpd_dur_low          = 0,
        mpd_dur_lowtomed     = 0,
        mpd_dur_medtohigh    = 0,
        mpd_dur_high         = 0,
        dect_duration        = 0,
        dect_ear_prop        = 0,
        lptp_dur_low         = 0,
        lptp_dur_lowtomed    = 0,
       lptp_dur_medtohigh   = 0,
       lptp_dur_high        = 0,
       tblt_dur_low         = 0,
       tblt_dur_lowtomed    = 0,
        tblt_dur_medtohigh   = 0,
        tblt_dur_high        = 0,
       hotspot_duration     = 0,
       smartwatch_duration  = 0,
        tracker_duration     = 0,
       vr_duration          = 0,
       headphone_duration   = 0,
       gaming_duration      = 0
      ),        
    tissue = "brain"
    ), 
  output = c(call_dose = 322.77, 
    data_dose = 0,
    dect_dose = 0,
    farf_dose = 162.5783,
    wifi_dose = 2.405355686,
    lptp_dose = 0,
    tblt_dose = 0,
    other_dose = 0
   )
  )
)


test_that("total_dose matches reference values", {
 for (case in cases_total_dose) {
    print(case)
    result <- do.call(total_dose, case$input)
    expect_equal(result, case$output, tolerance = 1e-3) 
  }
})
