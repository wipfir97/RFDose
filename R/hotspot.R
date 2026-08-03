#' @export
hotspot_dose <- function(
    tissue,
    duration_hotspot,
    params = load_params()) {
  # Input check
  ## TODO add input checks
  # Load tissue params
  tissue_params <- load_tissue_params_old(params, "hotspot", tissue)
  # Output power
  pwr <- params$devices$hotspot[["hotspot_pwr"]]
  # SAR
  sar <- tissue_params[["hotspot_sar"]]
  # Dose
  dose <- pwr*sar*duration_hotspot

  return(dose)
}
