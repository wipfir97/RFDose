vr_dose <- function(
    duration_vr,
    params = load_params()) {
  # Check input
  ## TODO input check

  # Load tissue params
  brain_params <- load_tissue_params(params, "vr", "brain")
  body_params  <- load_tissue_params(params, "vr", "body")

  # Output power
  pwr_2 <- params$devices$vr[["vr_2_pwr"]] * params$devices$vr[["vr_2_dutycycle"]]
  pwr_5 <- params$devices$vr[["vr_5_pwr"]] * params$devices$vr[["vr_5_dutycycle"]]

  # SAR
  ## Brain
  sar_brain_2 <- brain_params[["vr_2_sar"]]
  sar_brain_5 <- brain_params[["vr_5_sar"]]
  ## Body
  sar_body_2 <- body_params[["vr_2_sar"]]
  sar_body_5 <- body_params[["vr_5_sar"]]

  # mSAR
  msar_brain <- sum(
    params$global$wifi_2_prop*pwr_2*sar_brain_2,
    params$global$wifi_5_prop*pwr_5*sar_brain_5
  )
  msar_body <- sum(
    params$global$wifi_2_prop*pwr_2*sar_body_2,
    params$global$wifi_5_prop*pwr_5*sar_body_5
  )
  # dose
  dose_brain <- msar_brain*duration_vr*params$devices$vr[["vr_online_prop"]]
  dose_body  <- msar_body*duration_vr*params$devices$vr[["vr_online_prop"]]

  return(list(
    vr_brain_dose = dose_brain,
    vr_body_dose  = dose_body
    )
  )
}
