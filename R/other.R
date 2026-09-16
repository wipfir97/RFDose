# this we can leave the same
#' @export
other_dose_wrapper <- function(
    tissue,
    duration_hotspot,
    duration_smartwatch,
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
  # Sum by tissue and return result
  # NOTE: gaming and vr have moved out of this wrapper. They are stochastic now,
  # they need the simulated parameter list, and they are divided by 1000 because
  # they read the dummy-resolved sar table. The sources left here still read the
  # old table and correctly omit the /1000.
  dose <- sum(
    dose_smartwatch,
    dose_headphones,
    dose_hotspot
  )

  return(dose)
}
