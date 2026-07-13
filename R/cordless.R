# =============================================================================
#' Calculate Dose from Cordless Calls
#'
#' Calculates RF-EMF dose from making calls with cordless phone (also known as
#' DECT phone).
#'
#' @details
#' The dose is calculated as
#'
#' \deqn{Dose_{DECT} = mSAR_{DECT}*duration_{DECT}}
#'
#' Where:
#'
#' * \eqn{Dose_{DECT}} is the dose from DECT/cordless phone calls
#' * \eqn{mSAR_{DECT}} is the momentary SAR value in mJ/kg
#' * \eqn{duration_{DECT}} is the duration of the calls in s/day
#'
#' @param tissue Tissue for which to calculate dose (default: "brain" or "body")
#' @param duration Duration of cordless calls in s/day.
#' @param ear_prop Proportion of time cordless phone is held against ear
#' during calls.
#' @param params Parameter list (optional). If not specified, calculations use
#' default parameters.
#'
#' @returns Tissue-specific RF-EMF dose from DECT/cordless phone calls in mJ/kg/day
#'
#' @examples
#' cordless_dose(
#'   tissue      = "brain",
#'   duration    = 600,
#'   ear_prop    = 0.9)
#'
#' @seealso [dect_msar()]
#'
#' @export
cordless_dose <- function(
    tissue,
    duration,
    ear_prop,
    params = load_params()) {

  # Check input values ========================================================
  ## Duration
  check_duration(duration = duration)
  ## Proportion
  check_proportions(proportions = ear_prop)

  # Calculate brain and body mSAR =============================================
  msar <- dect_msar(
    tissue   = tissue,
    ear_prop = ear_prop,
    params   = params
  )

  # Calculate dose and return result ==========================================
  dose <- msar * duration

  return(dose)
}

# =============================================================================
#' Calculate mSAR from Cordless Calls
#'
#' Calculates mSAR (momentary SAR) from making calls with cordless phone (also known as
#' DECT phone).
#'
#' @details
#' The mSAR is calculated as
#'
#' \deqn{mSAR_{DECT} = nSAR_{DECT}*outputpower_{DECT}}
#'
#' Where:
#'
#' * \eqn{mSAR_{DECT}} is the mSAR from DECT/cordless phone calls
#' * \eqn{nSAR_{DECT}} is the nSAR (normalized specific absorption rate) in W/kg/W
#' * \eqn{outputpower_{DECT}} is the duration of the calls in mW
#'
#' @param tissue Tissue for which to calculate dose (default: "brain" or "body")
#' @param ear_prop Proportion of time cordless phone is held against ear
#' during calls.
#' @param params Parameter list (optional). If not specified, calculations use
#' default parameters.
#'
#' @returns Tissue-specific mSAR from DECT/cordless phone calls in mW/kg
#'
#' @examples
#' dect_msar(
#'   tissue      = "brain",
#'   ear_prop    = 0.9)
#'
#' @seealso [dect_pwr(), dect_sar()]
#'
#' @export
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

# =============================================================================
#' Calculate Output Power of DECT/Cordless Phone
#'
#' Calculates the output power of DECT/cordless phone during a call.
#'
#' @param params Parameter list (optional). If not specified, calculations use
#' default parameters.
#'
#' @returns DECT/cordless phone output power in mW
#'
#' @export
dect_pwr <- function(
    params = load_params()) {
  pwr <- params$devices$dect$dect_pwr * params$devices$dect$dect_dutycycle
  return(pwr)
}

# =============================================================================
#' Calculate nSAR from Cordless Calls
#'
#' Calculates nSAR (normalized specific absorption rate) from making calls with
#' cordless phone (also known as DECT phone).
#'
#' @param tissue Tissue for which to calculate the nSAR (default: "brain" or "body")
#' @param ear_prop Proportion of time cordless phone is held against ear
#' during calls.
#' @param params Parameter list (optional). If not specified, calculations use
#' default parameters.
#'
#' @returns Tissue-specific nSAR from DECT/cordless phone calls in W/kg/W
#'
#' @examples
#' dect_sar(
#'   tissue      = "brain",
#'   ear_prop    = 0.9)
#'
#' @export
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

