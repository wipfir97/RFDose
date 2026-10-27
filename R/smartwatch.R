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
#' @seealso [smartwatch_watch_dose()], [smartwatch_phone_dose()]
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
#' \deqn{Dose_{watch} = nSAR_{watch} \times (P_{active} \times t_{active} + P_{passive} \times t_{passive})}
#'
#' Where:
#'
#' * \eqn{nSAR_{watch}} is the normalized SAR of the watch in W/kg/W
#' * \eqn{P_{active}} and \eqn{P_{passive}} are the output powers of the watch
#'   in mW when transmitting actively and passively
#' * \eqn{t_{active}} and \eqn{t_{passive}} are the times of active and passive
#'   transmission in s/day
#'
#' While worn, the smart-watch transfers data for `watch_transfer_dur` seconds
#' per day of wearing. During the share `watch_transfer_active_prop` of this
#' time it transmits actively, the rest of the time passively (parameters of
#' the device `smartwatch`):
#'
#' \deqn{t_{active} = duration \times T_{transfer} / 86400 \times f_{active}}
#' \deqn{t_{passive} = duration - t_{active}}
#'
#' with \eqn{duration} the time the watch is worn in s/day, \eqn{T_{transfer}}
#' the transfer time (`watch_transfer_dur`) in s per day of wearing and
#' \eqn{f_{active}} the active share (`watch_transfer_active_prop`).
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
  ## Data transfer while the smartwatch is worn: part of it is active
  ## transmission, the rest of the time counts as passive
  file_dur    <- duration_smartwatch * params$devices$smartwatch$watch_transfer_dur / 86400
  active_dur  <- file_dur * params$devices$smartwatch$watch_transfer_active_prop
  passive_dur <- duration_smartwatch - active_dur
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
#' \deqn{Dose_{phone} = mSAR_{phone} \times duration_{phone}}
#' \deqn{mSAR_{phone} = nSAR_{phone} \times P_{phone}}
#'
#' Where:
#'
#' * \eqn{mSAR_{phone}} is the momentary SAR in mW/kg
#' * \eqn{nSAR_{phone}} is the normalized SAR of the phone in W/kg/W
#' * \eqn{P_{phone}} is the output power of the phone's connection to the watch
#'   in mW
#' * \eqn{duration_{phone}} is the time the watch is worn in s/day
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
