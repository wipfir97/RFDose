# =============================================================================
#' Calculate RF-EMF Dose from online gaming (console)
#'
#' Calculates the tissue-specific RF-EMF dose from online gaming
#'
#' @details
#'
#' The RF-EMF dose from online gaming is calculated as:
#'
#' \deqn{Dose_{gaming} = mSAR_{gaming} * duration_{gaming}}
#'
#' Where:
#'
#' * \eqn{mSAR_{gaming}} is the mSAR of gaming
#' * \eqn{Dduration_{gaming}} is the duration of gaming with portable console in s/day
#'
#' @param tissue Tissue for which to calculate dose (default: "brain" or "body")
#' @param duration_gaming duration of gaming with portable console in s/day
#' @param params Parameter list (optional). If not specified, calculations use
#' default parameters.
#'
#' @returns Tissue-specific RF-EMF dose from gaming in mJ/kg/day
#'
#' @examples
#' gaming_dose(
#'   tissue          = "body",
#'   duration_gaming = 600)
#'
#' @export
gaming_dose <- function(
    tissue,
    duration_gaming,
    params = load_params()) {
  # Check input
  # Input check
  check_tissue(tissue, "gaming", params)
  check_duration(duration_gaming)

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
  ) * params$devices$gaming[["gaming_online_prop"]]

  # dose
  dose <- msar*duration_gaming

  return(dose)
}
