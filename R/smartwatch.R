# =============================================================================
#' Calculate RF-EMF Dose from Smart Watch
#'
#' Calculates the tissue-specific RF-EMF dose from smart-watch use
#'
#' @details
#'
#' The RF-EMF dose from smart-watch use is calculated as:
#'
#' \deqn{Dose_{smartwatch} = Dose_{watch} + Dose_{phone}}
#'
#' Where:
#'
#' * \eqn{Dose_{watch}} is the dose contribution from the smart-watch itself
#' * \eqn{Dose_{phone}} is the dose contribution from the phone connection to the smart-watch
#'
#' @param tissue Tissue for which to calculate dose (default: "brain" or "body")
#' @param duration_smartwatch duration of time smartwatch was worn in s/day
#' @param params Parameter list (optional). If not specified, calculations use
#' default parameters.
#'
#' @returns Tissue-specific RF-EMF dose from smart-watch use in mJ/kg/day
#'
#' @examples
#' smartwatch_dose(
#'   tissue              = "body",
#'   duration_smartwatch = 6000)
#'
#' @seealso [smartwatch_watch_dose(), smartwatch_phone_dose()]
#'
#' @export
smartwatch_dose <- function(
    tissue,
    duration_smartwatch,
    params = load_params()) {

  # From watch ================================================================
  dose_watch <- smartwatch_watch_dose(
    tissue              = tissue,
    duration_smartwatch = duration_smartwatch,
    params              = params
  )

  # From phone (bluetooth connection to watch) ================================
  dose_phone <- smartwatch_phone_dose(
    tissue              = tissue,
    duration_smartwatch = duration_smartwatch,
    params              = params
  )

  return(sum(dose_watch, dose_phone))
}

# =============================================================================
#' Calculate RF-EMF Dose from Smart Watch (watch contribution only)
#'
#' Calculates the tissue-specific RF-EMF dose from smart-watch use (watch
#' contribution only).
#'
#' @details
#'
#' The RF-EMF dose from smart-watch use (watch contribution) is calculated as:
#'
#' \deqn{Dose_{watch} = mSAR_{watch} * duration_{watch}}
#'
#' Where:
#'
#' * \eqn{mSAR_{watch}} is the momentary SAR
#' * \eqn{duration_{watch}} is the use duration
#'
#' @param tissue Tissue for which to calculate dose (default: "brain" or "body")
#' @param duration_smartwatch duration of time smart-watch was worn in s/day
#' @param params Parameter list (optional). If not specified, calculations use
#' default parameters.
#'
#' @returns Tissue-specific RF-EMF dose from smart-watch use (watch contribution only) in mJ/kg/day
#'
#' @examples
#' smartwatch_watch_dose(
#'   tissue              = "body",
#'   duration_smartwatch = 6000)
#'
#' @export
smartwatch_watch_dose <- function(
    tissue,
    duration_smartwatch,
    params = load_params()) {
  # Check input ===============================================================
  check_tissue(tissue, "smartwatch", params)
  check_duration(duration_smartwatch)

  # Load tissue-specific dose =================================================
  tissue_params <- load_tissue_params(params, "smartwatch", tissue)

  # Calculate active and passive use duration =================================
  file_dur    <- (duration_smartwatch*120)/86400
  active_dur  <- file_dur/2
  passive_dur <- duration_smartwatch-(file_dur/2)
  mode_dur <- list(
    active  = active_dur,
    passive = passive_dur
    )
  modes <- c("active", "passive")

  dose <- sum(
    vapply(
      modes,
      \(mode) {
        pwr <- params$devices$smartwatch[[paste("watch_pwr", mode, sep = "_")]]
        sar <- tissue_params[["watch_sar"]]
        dur <- mode_dur[[mode]]
        return(pwr*sar*dur)
      },
      numeric(1)
    )
  )
  return(dose)
}

# =============================================================================
#' Calculate RF-EMF Dose from Smart Watch (phone contribution only)
#'
#' Calculates the tissue-specific RF-EMF dose from smart-watch use (phone
#' contribution only).
#'
#' @details
#'
#' The RF-EMF dose from smart-watch use (phone contribution) is calculated as:
#'
#' \deqn{Dose_{phone} = mSAR_{phone} * duration_{phone}}
#'
#' Where:
#'
#' * \eqn{mSAR_{phone}} is the momentary SAR
#' * \eqn{duration_{phone}} is the use duration
#'
#' @param tissue Tissue for which to calculate dose (default: "brain" or "body")
#' @param duration_smartwatch duration of time smart-watch was worn in s/day
#' @param params Parameter list (optional). If not specified, calculations use
#' default parameters.
#'
#' @returns Tissue-specific RF-EMF dose from smart-watch use (phone contribution only) in mJ/kg/day
#'
#' @examples
#' smartwatch_phone_dose(
#'   tissue              = "body",
#'   duration_smartwatch = 6000)
#'
#' @export
smartwatch_phone_dose <- function(
    tissue,
    duration_smartwatch,
    params = load_params()) {
  # Check input ===============================================================
  check_tissue(tissue, "smartwatch", params)
  check_duration(duration_smartwatch)

  # Load tissue specific parameters ===========================================
  tissue_params <- load_tissue_params(params, "smartwatch", tissue)

  # Output power ==============================================================
  pwr <- params$devices$smartwatch[["watch_phone_pwr"]]

  # SAR =======================================================================
  sar <- tissue_params[["watch_phone_sar"]]

  # Dose ======================================================================
  dose <- pwr*sar*duration_smartwatch
  return(dose)
}
