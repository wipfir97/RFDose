#' @export
gaming_dose <- function(
    tissue,
    duration_gaming,
    params = load_params()) {
  # Check input
  ## TODO input check

  # Load tissue params
  tissue_params <- load_tissue_params(params, "gaming", tissue)

  # Output power
  pwr_2 <- params$devices$gaming[["gaming_2_pwr"]] * params$devices$gaming[["gaming_2_dutycycle"]]
  pwr_5 <- params$devices$gaming[["gaming_5_pwr"]] * params$devices$gaming[["gaming_5_dutycycle"]]

  # SAR
  ## Brain
  sar_2 <- tissue_params[["gaming_2_sar"]]
  sar_5 <- tissue_params[["gaming_5_sar"]]

  # mSAR
  msar <- sum(
    params$global$wifi_2_prop*pwr_2*sar_2,
    params$global$wifi_5_prop*pwr_5*sar_5
  )

  # dose
  dose <- msar*duration_gaming*params$devices$gaming[["gaming_online_prop"]]

  return(dose)
}
