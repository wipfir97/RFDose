#' @export
vr_dose <- function(
    tissue,
    duration_vr,
    params = load_params()) {
  # Check input
  ## TODO input check

  # Load tissue params
  tissue_params <- load_tissue_params_old(params, "vr", tissue)

  # Output power
  pwr_2 <- params$devices$vr[["vr_2_pwr"]] * params$devices$vr[["vr_2_dutycycle"]]
  pwr_5 <- params$devices$vr[["vr_5_pwr"]] * params$devices$vr[["vr_5_dutycycle"]]

  # SAR
  sar_2 <- tissue_params[["vr_2_sar"]]
  sar_5 <- tissue_params[["vr_5_sar"]]

  # mSAR
  msar <- sum(
    params$global$wifi_2_prop*pwr_2*sar_2,
    params$global$wifi_5_prop*pwr_5*sar_5
  )

  # dose
  dose <- msar*duration_vr*params$devices$vr[["vr_online_prop"]]

  return(dose)
}
