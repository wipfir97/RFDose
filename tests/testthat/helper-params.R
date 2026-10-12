# The reference values of the dose tests were computed with the ETAIN SAR values
# (and the ETAIN placement proportions of params.yaml), so these tests use
# the ETAIN parameters instead of the default (GOLIAT) ones.
etain_params <- load_params(
  sar_path = system.file("extdata", "sar_etain.yaml", package = "RFDose"))

# Dose columns added by calculate_emf_doses()
dose_cols <- c("call_dose", "data_dose", "dect_dose", "farf_dose",
               "wifi_dose", "lptp_dose", "tblt_dose", "other_dose")

# One input row with non-zero use of every device
make_test_input <- function() {
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
    vr_duration          = 600,
    headphone_duration   = 1800,
    gaming_duration      = 600
  )
}
