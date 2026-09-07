# this we can leave the same
#' @export
other_dose_wrapper <- function(
    tissue,
    duration_hotspot,
    duration_smartwatch,
    duration_vr,
    duration_headphones,
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
  # Sum by tissue and return result
  # NOTE: gaming has moved out of this wrapper. It is stochastic now, it needs the
  # simulated parameter list, and it is divided by 1000 because it reads the
  # dummy-resolved sar table. The sources left here still read the old table.
  dose <- sum(
    dose_smartwatch,
    dose_headphones,
    dose_hotspot,
    dose_vr
  )

  return(dose)
}
