#' @export
headphones_dose <- function(
    duration_headphones,
    params = load_params()) {
  # From ear set ==============================================================
  ## Brain
  dose_brain_headphones <- headphones_earset_dose(
    tissue              = "brain",
    duration_headphones = duration_headphones,
    params              = params
  )
  ## Body
  dose_body_headphones <- headphones_earset_dose(
    tissue              = "body",
    duration_headphones = duration_headphones,
    params              = params
  )

  # From phone (bluetooth connection to watch) ================================
  ## Brain
  dose_brain_phone <- headphones_phone_dose(
    tissue              = "brain",
    duration_headphones = duration_headphones,
    params              = params
  )
  ## Body
  dose_body_phone <- headphones_phone_dose(
    tissue              = "body",
    duration_headphones = duration_headphones,
    params              = params
  )

  return(
    list(
      headphones_brain_dose = sum(dose_brain_headphones, dose_brain_phone),
      headphones_body_dose  = sum(dose_body_headphones, dose_body_phone)
    )
  )
}

headphones_earset_dose <- function(
    tissue,
    duration_headphones,
    params = load_params()) {
  tissue_params <- load_tissue_params(params, "headphones", tissue)
  pwr <- params$devices$headphones[["headp_pwr"]]
  sar <- tissue_params[["headp_sar"]]
  dose <- pwr*sar*duration_headphones*2 # times 2: assumption 2 headphones
  return(dose)
}

headphones_phone_dose <- function(
    tissue,
    duration_headphones,
    params = load_params()) {
  tissue_params <- load_tissue_params(params, "headphones", tissue)
  pwr <- params$devices$headphones[["headp_phone_pwr"]]
  sar <- tissue_params[["headp_phone_sar"]]
  dose <- pwr*sar*duration_headphones
  return(dose)
}
