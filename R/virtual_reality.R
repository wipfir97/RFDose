# =============================================================================
#' Calculate RF-EMF Dose from Virtual Reality Headset
#'
#' Calculates the tissue-specific RF-EMF dose from VR headset
#'
#' @details
#'
#' The RF-EMF dose from VR headset is calculated as:
#'
#' \deqn{Dose_{vr} = mSAR_{vr} * duration_{vr}}
#'
#' Where:
#'
#' * \eqn{mSAR_{vr}} is the mSAR of virtual reality headet use
#' * \eqn{Dduration_{vr}} is the duration of VR headset use in s/day
#'
#' @param tissue Tissue for which to calculate dose (default: "brain" or "body")
#' @param duration_vr duration of time VR headset was used in s/day
#' @param params Parameter list (optional). If not specified, calculations use
#' default parameters.
#'
#' @returns Tissue-specific RF-EMF dose from VR headset use in mJ/kg/day
#'
#' @examples
#' vr_dose(
#'   tissue      = "brain",
#'   duration_vr = 600)
#'
#' @export
vr_dose <- function(
    tissue,
    duration_vr,
    params = load_params()) {
  # Check input
  check_tissue(tissue, "vr", params)
  check_duration(duration_vr)

  # Load tissue params
  tissue_params <- load_tissue_params(params, "vr", tissue)

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
