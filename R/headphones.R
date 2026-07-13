# =============================================================================
#' Calculate RF-EMF Dose from Bluetooth Headphones
#'
#' Calculates the tissue-specific RF-EMF dose from bluetooth headphones (calls excluded)
#'
#' @details
#'
#' The RF-EMF dose from Bluetooth headphone use is calculated as:
#'
#' \deqn{Dose_{headphones} = Dose_{earset} + Dose_{phone}}
#'
#' Where:
#'
#' * \eqn{Dose_{earset}} is the dose contribution from the headphones themselves
#' * \eqn{Dose_{phone}} is the dose contribution from the phone connection to the headphones
#'
#' @param tissue Tissue for which to calculate dose (default: "brain" or "body")
#' @param duration_smartwatch duration of time Bluetooth headphones were used in s/day
#' @param params Parameter list (optional). If not specified, calculations use
#' default parameters.
#'
#' @returns Tissue-specific RF-EMF dose from Bluetooth headphone use in mJ/kg/day
#'
#' @examples
#' headphones_dose(
#'   tissue              = "body",
#'   duration_headphones = 6000)
#'
#' @seealso [headphones_earset_dose(), headphones_phone_dose()]
#'
#' @export
headphones_dose <- function(
    tissue,
    duration_headphones,
    params = load_params()) {
  # Check input ===============================================================
  check_tissue(tissue, "headphones", params)
  check_duration(duration_headphones)

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

# =============================================================================
#' Calculate RF-EMF Dose from Smart Watch (earset contribution only)
#'
#' Calculates the tissue-specific RF-EMF dose from Bluetooth headphone use (earset
#' contribution only).
#'
#' @details
#'
#' The RF-EMF dose from Bluetooth headphone use (earset
#' contribution) is calculated as:
#'
#' \deqn{Dose_{earset} = mSAR_{earset} * duration_{earset}}
#'
#' Where:
#'
#' * \eqn{mSAR_{earset}} is the momentary SAR for the headphone connection
#' * \eqn{duration_{earset}} is the use duration in s/day
#'
#' @param tissue Tissue for which to calculate dose (default: "brain" or "body")
#' @param duration_smartwatch duration of time Bluetooth headphones were worn in s/day
#' @param params Parameter list (optional). If not specified, calculations use
#' default parameters.
#'
#' @returns Tissue-specific RF-EMF dose from Bluetooth headphone use (earset contribution only) in mJ/kg/day
#'
#' @examples
#' headphones_earset_dose(
#'   tissue              = "body",
#'   duration_headphones = 6000)
#'
#'   @export
headphones_earset_dose <- function(
    tissue,
    duration_headphones,
    params = load_params()) {
  # Check input ===============================================================
  check_tissue(tissue, "headphones", params)
  check_duration(duration_headphones)

  # Load tissue params ========================================================
  tissue_params <- load_tissue_params(params, "headphones", tissue)

  # Calculate dose ============================================================
  pwr <- params$devices$headphones[["headp_pwr"]]
  sar <- tissue_params[["headp_sar"]]
  dose <- pwr*sar*duration_headphones*2 # times 2: assumption 2 headphones
  return(dose)
}

# =============================================================================
#' Calculate RF-EMF Dose from Smart Watch (phone contribution only)
#'
#' Calculates the tissue-specific RF-EMF dose from Bluetooth headphone use (phone
#' contribution only).
#'
#' @details
#'
#' The RF-EMF dose from Bluetooth headphone use (phone
#' contribution) is calculated as:
#'
#' \deqn{Dose_{phone} = mSAR_{phone} * duration_{phone}}
#'
#' Where:
#'
#' * \eqn{mSAR_{phone}} is the momentary SAR for the headphone connection
#' * \eqn{duration_{phone}} is the use duration in s/day
#'
#' @param tissue Tissue for which to calculate dose (default: "brain" or "body")
#' @param duration_smartwatch duration of time Bluetooth headphones were worn in s/day
#' @param params Parameter list (optional). If not specified, calculations use
#' default parameters.
#'
#' @returns Tissue-specific RF-EMF dose from Bluetooth headphone use (phone contribution only) in mJ/kg/day
#'
#' @examples
#' headphones_phone_dose(
#'   tissue              = "body",
#'   duration_headphones = 6000)
#'
#'   @export
headphones_phone_dose <- function(
    tissue,
    duration_headphones,
    params = load_params()) {
  # Check input ===============================================================
  check_tissue(tissue, "headphones", params)
  check_duration(duration_headphones)

  # Load tissue params ========================================================
  tissue_params <- load_tissue_params(params, "headphones", tissue)

  # Calculate dose ============================================================
  pwr <- params$devices$headphones[["headp_phone_pwr"]]
  sar <- tissue_params[["headp_phone_sar"]]
  dose <- pwr*sar*duration_headphones
  return(dose)
}
