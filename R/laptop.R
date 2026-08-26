# =============================================================================
#' Calculate RF-EMF Dose from Laptop Use
#'
#' Calculates the tissue-specific RF-EMF dose from laptop use.
#'
#' @details
#'
#' The laptop RF-EMF dose is calculated as:
#'
#' \deqn{Dose_{laptop} = mSAR_{laptop}*duration_{laptop}}
#'
#' Where:
#'
#' * \eqn{Dose_{laptop}} is the dose from laptop use
#' * \eqn{mSAR_{laptop}} is the momentary SAR value in mJ/kg
#' * \eqn{duration_{laptop}} is the duration of laptop use
#'
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
#' @param tissue Tissue for which to calculate dose (default: "brain" or "body")
#' @param dur_low Duration (in seconds per day) of low output power activities on laptop
#' @param dur_lowmed Duration (in seconds per day) of low-medium output power activities on laptop
#' @param dur_medhigh Duration (in seconds per day) of medium-high output power activities on laptop
#' @param dur_high Duration (in seconds per day) of high output power activities on laptop
#' @param params Parameter list (optional). If not specified, calculations use
#' default parameters.
#'
#' @returns Tissue-specific RF-EMF dose from laptop use in mJ/kg/day
#'
#' @examples
#' laptop_dose(
#'   tissue      = "brain",
#'   dur_low     = 0,
#'   dur_lowmed  = 1230,
#'   dur_medhigh = 0,
#'   dur_high    = 0)
#'
#' @export
#' @seealso [laptop_msar()]
laptop_dose <- function(
    tissue,
    dur_low,
    dur_lowmed,
    dur_medhigh,
    dur_high,
    params = load_params()) {

  # Check input ===============================================================
  check_duration(c(dur_low, dur_lowmed, dur_medhigh, dur_high))
  check_tissue(tissue, "lptp", params)

  # Calculate total duration ==================================================
  duration <- sum(
    dur_low,
    dur_lowmed,
    dur_medhigh,
    dur_high)

  # Calculate time proportions of each activity ===============================
  act_pwr_props <- act_pwr_props(
    low_dur     = dur_low,
    lowmed_dur  = dur_lowmed,
    medhigh_dur = dur_medhigh,
    high_dur    = dur_high)

  # Calculate mSAR ============================================================
  msar <- laptop_msar(
    tissue      = tissue,
    dur_low     = dur_low,
    dur_lowmed  = dur_lowmed,
    dur_medhigh = dur_medhigh,
    dur_high    = dur_high,
    params      = params
  )

  # Calculate dose ============================================================
  dose <- msar * duration
  return(dose)
}

# =============================================================================
#' Calculate mSAR from Laptop Use
#'
#' Calculates the tissue-specific momentary SAR (mSAR) from laptop use.
#'
#' @details
#'
#' The mSAR is calculated as:
#'
#' \deqn{mSAR_{laptop} = nSAR_{laptop}*outputpower_{laptop}}
#'
#' Where:
#'
#' * \eqn{mSAR_{laptop}} is the mSAR from laptop use
#' * \eqn{nSAR_{laptop}} is the normalised SAR value in mJ/kg
#' * \eqn{outputpower_{laptop}} is the duration of laptop use
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
#' @param dur_low Duration (in seconds per day) of low output power activities on laptop
#' @param dur_lowmed Duration (in seconds per day) of low-medium output power activities on laptop
#' @param dur_medhigh Duration (in seconds per day) of medium-high output power activities on laptop
#' @param dur_high Duration (in seconds per day) of high output power activities on laptop
#' @param params Parameter list (optional). If not specified, calculations use
#' default parameters.
#'
#' @returns Tissue-specific mSAR from laptop use in mW/kg
#'
#' @examples
#' laptop_msar(
#'   tissue      = "brain",
#'   dur_low     = 0,
#'   dur_lowmed  = 1230,
#'   dur_medhigh = 0,
#'   dur_high    = 0)
#'
#' @export
#' @seealso [laptop_pwr()], [laptop_sar()]
laptop_msar <- function(
    tissue,
    dur_low,
    dur_lowmed,
    dur_medhigh,
    dur_high,
    params = load_params()) {

  bands <- c("2", "5") # 2.4 GHz, 5.0 GHz

  msar <- sum(
    vapply(
      bands,
      \(band) {

        prop <- params$global[[paste0("wifi_", band, "_prop")]]

        ## Calculate power
        pwr <- laptop_pwr(
          band          = band,
          dur_low       = dur_low,
          dur_lowmed    = dur_lowmed,
          dur_medhigh   = dur_medhigh,
          dur_high      = dur_high,
          params        = params)

        ## Calculate SAR
        sar <- laptop_sar(
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
#' Calculate Laptop Output Power
#'
#' Calculates the laptop output power during use
#'
#' @details
#' The output power depends on the frequency band (2.4 GHz or 5.0 GHz) and the
#' type of activity.
#'
#' @param band WiFi frequency band ("2" for 2.4 GHz, "5" for 5.0 GHz)
#' @param dur_low Duration (in seconds per day) of low output power activities on laptop
#' @param dur_lowmed Duration (in seconds per day) of low-medium output power activities on laptop
#' @param dur_medhigh Duration (in seconds per day) of medium-high output power activities on laptop
#' @param dur_high Duration (in seconds per day) of high output power activities on laptop
#' @param params Parameter list (optional). If not specified, calculations use
#' default parameters.
#'
#' @returns Output power in mW
#'
#' @examples
#' laptop_pwr(
#'   band        = "2",
#'   dur_low     = 0,
#'   dur_lowmed  = 1230,
#'   dur_medhigh = 0,
#'   dur_high    = 0)
#'
#' @export
laptop_pwr <- function(
    band,
    dur_low,
    dur_lowmed,
    dur_medhigh,
    dur_high,
    params = load_params()) {

  # Calculate time proportions of each activity ===============================
  act_props <- act_pwr_props(
    low_dur     = dur_low,
    lowmed_dur  = dur_lowmed,
    medhigh_dur = dur_medhigh,
    high_dur    = dur_high)

  activities <- c("low", "lowmed", "medhigh", "high")

  pwr <- sum(
    vapply(
      activities,
      \(activity) {
        act_prop <- act_props[[activity]]
        dc  <- params$devices$lptp[[paste("wifi", band, activity, "dutycycle", sep = "_")]]
        pwr <- params$devices$lptp[[paste("wifi", band, "pwr", sep = "_")]]
        return(act_prop*dc*pwr)
      },
      numeric(1)
    )
  )
  return(pwr)
}

# =============================================================================
#' Calculate nSAR during Laptop Use
#'
#' Calculates tissue-specific nSAR from laptop use.
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
#' laptop_sar(
#' tissue       = "brain",
#' band         = "2")
#'
#' @export
laptop_sar <- function(
    tissue,
    band,
    params = load_params()) {

  tissue_params <- load_tissue_params(params, "lptp", tissue)
  ## Lap
  lap_prop <- params$devices$lptp$legs_prop
  sar_lap <- lap_prop*tissue_params[[paste("wifi", band, "legs_sar", sep = "_")]]
  ## Table
  tab_prop <- params$devices$lptp$tabl_prop
  sar_tab <- tab_prop*tissue_params[[paste("wifi", band, "tabl_sar", sep = "_")]]

  ## Combine and return
  return(sar_lap + sar_tab)
}
