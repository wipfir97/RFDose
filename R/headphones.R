#' @export
headphones_dose <- function(
    tissue,
    duration_headphones,
    params = load_params()) {
  # From ear set ==============================================================
  dose_headphones <- headphones_earset_dose(
    tissue              = tissue,
    duration_headphones = duration_headphones,
    params              = params
  )

  # From phone (bluetooth connection to watch) ================================
  dose_phone <- headphones_phone_dose(
    tissue              = tissue,
    duration_headphones = duration_headphones,
    params              = params
  )

  return(sum(dose_headphones, dose_phone))
}

headphones_earset_dose <- function(
    tissue,
    duration_headphones,
    params = load_params()) {
  tissue_params <- load_tissue_params_old(params, "headphones", tissue)
  pwr <- params$devices$headphones[["headp_pwr"]]
  sar <- tissue_params[["headp_sar"]]
  dose <- pwr*sar*duration_headphones*2 # times 2: assumption 2 headphones
  return(dose)
}

headphones_phone_dose <- function(
    tissue,
    duration_headphones,
    params = load_params()) {
  tissue_params <- load_tissue_params_old(params, "headphones", tissue)
  pwr <- params$devices$headphones[["headp_phone_pwr"]]
  sar <- tissue_params[["headp_phone_sar"]]
  dose <- pwr*sar*duration_headphones
  return(dose)
}
