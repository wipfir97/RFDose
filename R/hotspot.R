#' @export
hotspot_dose <- function(
    duration_hotspot,
    params = load_params()) {
  # Input check
  ## TODO add input checks
  # Load tissue params
  brain_params <- load_tissue_params(params, "hotspot", "brain")
  body_params  <- load_tissue_params(params, "hotspot", "body")
  # Output power
  pwr <- params$devices$hotspot[["hotspot_pwr"]]
  # SAR
  sar_brain <- brain_params[["hotspot_sar"]]
  sar_body  <- body_params[["hotspot_sar"]]
  # Dose
  dose_brain <- pwr*sar_brain*duration_hotspot
  dose_body  <- pwr*sar_body*duration_hotspot

  return(
    list(
      hotspot_brain_dose = dose_brain,
      hotspot_body_dose = dose_body
    )
  )
}
