# =============================================================================
#' Calculate RF-EMF Dose from Tablet Use
#'
#' Calculates the tissue-specific RF-EMF dose from tablet use.
#'
#' @details
#'
#' The tablet RF-EMF dose is calculated as:
#'
#' \deqn{Dose_{tablet} = mSAR_{tablet}*duration_{tablet}}
#'
#' Where:
#'
#' * \eqn{Dose_{tablet}} is the dose from tablet use
#' * \eqn{mSAR_{tablet}} is the momentary SAR value in mJ/kg
#' * \eqn{duration_{tablet}} is the duration of tablet use
#'
#' We distinguish between 4 types of activities:
#'
#' 1. Low output power: sending e-mails, browsing the internet, scrolling and
#'    chatting on social media, sending text messages
#' 2. Low to medium output power: online gaming, streaming music, sending voice
#'    messages
#' 3. Medium to high output power: watching videos, uploading pictures or
#'    videos, making video calls
#' 4. High output power: uploading large files
#'
#' @param tissue Tissue for which to calculate dose (default: "brain" or "body")
#' @param dur_low Duration (in seconds per day) of low output power activities on tablet
#' @param dur_lowmed Duration (in seconds per day) of low-medium output power activities on tablet
#' @param dur_medhigh Duration (in seconds per day) of medium-high output power activities on tablet
#' @param dur_high Duration (in seconds per day) of high output power activities on tablet
#' @param params Parameter list (optional). If not specified, calculations use
#' default parameters.
#'
#' @returns Tissue-specific RF-EMF dose from tablet use in mJ/kg/day
#'
#' @examples
#' tablet_dose(
#'   tissue      = "brain",
#'   dur_low     = 0,
#'   dur_lowmed  = 681,
#'   dur_medhigh = 0,
#'   dur_high    = 0)
#'
#' @export
#' @seealso [tablet_msar()]
tablet_dose <- function(
    tissue,
    dur_low,
    dur_lowmed,
    dur_medhigh,
    dur_high,
    params = load_params()) {

  # Check input ===============================================================
  check_duration(c(dur_low, dur_lowmed, dur_medhigh, dur_high))

  # Calculate total duration ==================================================
  duration <- sum(
    dur_low,
    dur_lowmed,
    dur_medhigh,
    dur_high)

  # Calculate mSAR ============================================================
  msar <- tablet_msar(
    tissue        = tissue,
    dur_low       = dur_low,
    dur_lowmed    = dur_lowmed,
    dur_medhigh   = dur_medhigh,
    dur_high      = dur_high,
    params        = params
  )

  # Calculate dose ============================================================
  dose <- msar * duration

  return(dose)
}

# =============================================================================
#' Calculate mSAR from Tablet Use
#'
#' Calculates the tissue-specific momentary SAR (mSAR) from tablet use.
#'
#' @details
#'
#' The mSAR is calculated as:
#'
#' \deqn{mSAR_{tablet} = nSAR_{tablet}*outputpower_{tablet}}
#'
#' Where:
#'
#' * \eqn{mSAR_{tablet}} is the mSAR from tablet use
#' * \eqn{nSAR_{tablet}} is the normalised SAR value in mJ/kg
#' * \eqn{outputpower_{tablet}} is the duration of tablet use
#'
#'
#' We distinguish between 4 types of activities:
#'
#' 1. Low output power: sending e-mails, browsing the internet, scrolling and
#'    chatting on social media, sending text messages
#' 2. Low to medium output power: online gaming, streaming music, sending voice
#'    messages
#' 3. Medium to high output power: watching videos, uploading pictures or
#'    videos, making video calls
#' 4. High output power: uploading large files
#'
#' @param tissue Tissue for which to calculate mSAR (default: "brain" or "body")
#' @param dur_low Duration (in seconds per day) of low output power activities on tablet
#' @param dur_lowmed Duration (in seconds per day) of low-medium output power activities on tablet
#' @param dur_medhigh Duration (in seconds per day) of medium-high output power activities on tablet
#' @param dur_high Duration (in seconds per day) of high output power activities on tablet
#' @param params Parameter list (optional). If not specified, calculations use
#' default parameters.
#'
#' @returns Tissue-specific mSAR from tablet use in mW/kg
#'
#' @examples
#' tablet_msar(
#'   tissue      = "brain",
#'   dur_low     = 0,
#'   dur_lowmed  = 1230,
#'   dur_medhigh = 0,
#'   dur_high    = 0)
#'
#' @export
#' @seealso [tablet_pwr()], [tablet_sar()]
tablet_msar <- function(
    tissue,
    dur_low,
    dur_lowmed,
    dur_medhigh,
    dur_high,
    params = load_params()) {
  ## List frequency bands
  bands <- c("2", "5") # 2.4 GHz, 5.0 GHz

  msar <- sum(
    vapply(
      bands,
      \(band) {

        prop <- params$global[[paste0("wifi_", band, "_prop")]]

        ## Calculate power
        pwr <- tablet_pwr(
          band          = band,
          dur_low       = dur_low,
          dur_lowmed    = dur_lowmed,
          dur_medhigh   = dur_medhigh,
          dur_high      = dur_high,
          params        = params)

        ## Calculate SAR
        sar <- tablet_sar(
          tissue        = tissue,
          band          = band,
          params        = params)

        prop*sar*pwr
      },
      numeric(1)
    )
  )
  return(msar)
}

# =============================================================================
#' Calculate Tablet Output Power
#'
#' Calculates the tablet output power during use
#'
#' @details
#' The output power depends on the frequency band (2.4 GHz or 5.0 GHz) and the
#' type of activity.
#'
#' @param band WiFi frequency band ("2" for 2.4 GHz, "5" for 5.0 GHz)
#' @param dur_low Duration (in seconds per day) of low output power activities on tablet
#' @param dur_lowmed Duration (in seconds per day) of low-medium output power activities on tablet
#' @param dur_medhigh Duration (in seconds per day) of medium-high output power activities on tablet
#' @param dur_high Duration (in seconds per day) of high output power activities on tablet
#' @param params Parameter list (optional). If not specified, calculations use
#' default parameters.
#'
#' @returns Output power in mW
#'
#' @examples
#' tablet_pwr(
#'   band        = "5",
#'   dur_low     = 0,
#'   dur_lowmed  = 681,
#'   dur_medhigh = 0,
#'   dur_high    = 0)
#'
#' @export
tablet_pwr <- function(
    band,
    dur_low,
    dur_lowmed,
    dur_medhigh,
    dur_high,
    params = load_params()) {
  # Calculate activity proportions ============================================
  act_props <- act_pwr_props(
    dur_low,
    dur_lowmed,
    dur_medhigh,
    dur_high)

  activities <- c("low", "lowmed", "medhigh", "high")

  # Calculate power ===========================================================
  pwr <- sum(
    vapply(
      activities,
      \(activity) {
        act_prop <- act_props[[activity]]
        dc <- params$devices$tblt[[paste("wifi", band, activity, "dutycycle", sep = "_")]]
        pwr <- params$devices$tblt[[paste("wifi", band, "pwr", sep = "_")]]
        return(act_prop*dc*pwr)
      },
      numeric(1)
    )
  )
  return(pwr)
}

# =============================================================================
#' Calculate nSAR during Tablet Use
#'
#' Calculates tissue-specific nSAR from tablet use.
#'
#' @details
#' The normalized specific absorption rate (nSAR) depends on the tissue and
#' the frequency band.
#'
#' @param tissue Tissue for which to calculate nSAR (default: "brain" or "body")
#' @param band Frequency band ("2" for 2.4 GHz, "5" for 5.0 GHz)
#' @param params Parameter list (optional). If not specified, calculations use
#' default parameters.
#'
#' @returns nSAR in W/kg/W
#'
#' @examples
#' tablet_sar(
#' tissue       = "brain",
#' band         = "2")
#'
#' @export
tablet_sar <- function(
    tissue,
    band,
    params = load_params()) {
  tissue_params <- load_tissue_params(params, "tblt", tissue)
  sar <- tissue_params[[paste("tblt", band, "sar", sep ="_")]]
  return(sar)
}
