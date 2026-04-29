# Calculate total RF-EMF dose (for brain and body) from cordless calls

# =============================================================================
#' Calculate Dose from Cordless Calling
#'
#' @param duration Duration of cordless calls in seconds. >= 0 and <= 86400
#' @param ear_prop Proportion of time cordless phone is held against ear
#' during calls. >=0 and <=1.
#' @param params Parameter list.
#' @returns List with brain dose and body dose in mJ/kg/day
#' @export
#' @import yaml
cordless_dose <- function(
    duration,
    ear_prop,
    params = load_params()) {

  # Check input values ========================================================
  ## Duration
  check_duration(duration = duration)
  ## Proportion
  check_proportions(proportions = ear_prop)

  # Calculate brain and body mSAR =============================================
  ## Brain
  msar_brain <- dect_msar(
    tissue   = "brain",
    ear_prop = ear_prop,
    params   = params
  )
  ## Body
  msar_body <- dect_msar(
    tissue   = "body",
    ear_prop = ear_prop,
    params   = params
  )

  # Calculate dose and return result ==========================================
  ## Brain
  dose_brain <- msar_brain * duration
  ## Body
  dose_body  <- msar_body * duration

  return(list("brain_dect_dose" = dose_brain, "body_dect_dose"  = dose_body))
}

dect_msar <- function(
    tissue,
    ear_prop,
    params = load_params()) {
  ## Calculate output power
  pwr <- dect_pwr(
    params = params
  )
  ## Calculate SAR
  sar <- dect_sar(
    tissue = tissue,
    ear_prop = ear_prop,
    params = params
  )
  ## Calculate mSAR and return
  msar <- pwr*sar
  return(msar)
}

dect_pwr <- function(
    params = load_params()) {
  pwr <- params$devices$dect$dect_pwr * params$devices$dect$dect_dutycycle
  return(pwr)
}

dect_sar <- function(
    tissue,
    ear_prop,
    params = load_params()) {
  ## Load tissue params
  tissue_params <- load_tissue_params(params, "dect", tissue)
  ## ear
  ear_sar <- ear_prop * tissue_params$dect_ear_sar
  ## speaker
  speaker_sar <- (1-ear_prop) * tissue_params$dect_speaker_sar
  ## total sar
  sar <- ear_sar + speaker_sar
  return(sar)
}

