# =============================================================================
#' Calculate RF-EMF Dose from Mobile Phone Hotspot
#'
#' Calculates the tissue-specific RF-EMF dose from hotspot
#'
#' @details
#'
#' The RF-EMF dose from hotspot use is calculated as:
#'
#' \deqn{Dose_{hotspot} = mSAR_{hotspot} * duration_{hotspot}}
#'
#' Where:
#'
#' * \eqn{mSAR_{hotspot}} is the mSAR of hotspot use
#' * \eqn{Dduration_{hotspot}} is the duration of hotspot use in s/day
#'
#' @param tissue Tissue for which to calculate dose (default: "brain" or "body")
#' @param duration_hotspot duration of time hotspot was active in s/day
#' @param params Parameter list (optional). If not specified, calculations use
#' default parameters.
#'
#' @returns Tissue-specific RF-EMF dose from hotspot use in mJ/kg/day
#'
#' @examples
#' hotspot_dose(
#'   tissue           = "body",
#'   duration_hotspot = 600)
#'
#' @export
hotspot_dose <- function(
    tissue,
    duration_hotspot,
    params = load_params()) {
  # Input check
  check_tissue(tissue, "hotspot", params)
  check_duration(duration_hotspot)

  # Load tissue params
  tissue_params <- load_tissue_params(params, "hotspot", tissue)

  # Output power
  pwr <- params$devices$hotspot[["hotspot_pwr"]]

  # SAR
  sar <- tissue_params[["hotspot_sar"]]

  # Dose
  dose <- pwr*sar*duration_hotspot

  return(dose)
}
