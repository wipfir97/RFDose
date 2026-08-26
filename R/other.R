# =============================================================================
#' Calculate RF-EMF Dose from Other Sources
#'
#' Wrapper function that calculates total dose from additional devices and
#' activities, as used in the GOLIAT consortium study dose calculation.
#'
#' @details
#'
#' The RF-EMF dose from other sources takes into account 5 additional sources:
#'
#' 1. Hotspot (smartphone)
#' 2. Smart watch
#' 3. Virtual reality (VR) headset
#' 4. Bluetooth headphones
#' 5. Portable gaming consoles
#'
#' The dose is calculated as
#'
#' \deqn{Dose_{other} = Dose_{hotspot} + Dose_{smartwatch} + Dose_{vr} + Dose_{headphones} + Dose_{gaming}}
#'
#' The dose from each source is calculated from the corresponding dose functions.
#'
#' @param tissue Tissue for which to calculate dose (default: "brain" or "body")
#' @param duration_hotspot Duration of time hotspot was active in s/day
#' @param duration_smartwatch Duration of time smartwatch was used in s/day
#' @param duration_vr Duration of time VR headset was used in s/day
#' @param duration_headphones Duration of time Bluetooth headphones were used in s/day
#' @param duration_gaming Duration of gaming with portable console in s/day
#' @param params Parameter list (optional). If not specified, calculations use
#' default parameters.
#'
#' @returns Tissue-specific RF-EMF dose from other sources in mJ/kg/day
#'
#' @examples
#' other_dose_wrapper(
#'   tissue              = "brain",
#'   duration_hotspot    = 600,
#'   duration_smartwatch = 86400,
#'   duration_vr         = 0,
#'   duration_headphones = 8280,
#'   duration_gaming     = 3600)
#'
#' @seealso [hotspot_dose()], [smartwatch_dose()], [vr_dose()], [headphones_dose()], [gaming_dose()]
#'
#' @export
other_dose_wrapper <- function(
    tissue,
    duration_hotspot,
    duration_smartwatch,
    duration_vr,
    duration_headphones,
    duration_gaming,
    params = load_params()) {
  # Calculate doses from different sources
  ## Smartwatch
  dose_smartwatch <- smartwatch_dose(
    tissue              = tissue,
    duration_smartwatch = duration_smartwatch,
    params              = params)
  ## Bluetooth headphones
  dose_headphones <- headphones_dose(
    tissue              = tissue,
    duration_headphones = duration_headphones,
    params              = params)
  ## Hotspot
  dose_hotspot    <- hotspot_dose(
    tissue           = tissue,
    duration_hotspot = duration_hotspot,
    params           = params)
  ## VR headset
  dose_vr         <- vr_dose(
    tissue      = tissue,
    duration_vr = duration_vr,
    params      = params)
  ## Gaming console
  dose_gaming     <- gaming_dose(
    tissue          = tissue,
    duration_gaming = duration_gaming,
    params          = params)

  # Sum by tissue and return result
  dose <- sum(
    dose_smartwatch,
    dose_headphones,
    dose_hotspot,
    dose_vr,
    dose_gaming
  )

  return(dose)
}
