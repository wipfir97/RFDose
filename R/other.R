#' @export
other_dose_wrapper <- function(
    duration_hotspot,
    duration_smartwatch,
    duration_vr,
    duration_headphones,
    duration_gaming,
    params = load_params()) {
  # Calculate doses from different sources
  dose_smartwatch <- smartwatch_dose(duration_smartwatch, params = params)
  dose_headphones <- headphones_dose(duration_headphones, params = params)
  dose_hotspot    <- hotspot_dose(duration_hotspot,       params = params)
  dose_vr         <- vr_dose(duration_vr,                 params = params)
  dose_gaming     <- gaming_dose(duration_gaming,         params = params)
  # Sum by tissue and return result
  ## Brain
  dose_brain <- sum(
    dose_smartwatch$smartwatch_brain_dose,
    dose_headphones$headphones_brain_dose,
    dose_hotspot$hotspot_brain_dose,
    dose_vr$vr_brain_dose,
    dose_gaming$gaming_brain_dose
  )
  ## Body
  dose_body <- sum(
    dose_smartwatch$smartwatch_body_dose,
    dose_headphones$headphones_body_dose,
    dose_hotspot$hotspot_body_dose,
    dose_vr$vr_body_dose,
    dose_gaming$gaming_body_dose
  )
  return(
    list(
      other_brain_dose = dose_brain,
      other_body_dose  = dose_body
    )
  )
}
