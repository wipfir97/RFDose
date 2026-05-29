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
