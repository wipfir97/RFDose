# Calculate total RF-EMF dose (for brain and body) from a laptop over WiFi,
# in two positions: on the user's lap and on a table.

# There is no laptop-specific sar simulation in GOLIAT. Both positions use the
# mean of the eight belly positions as a proxy, differing only in the distance
# they are rescaled to.
#
# WHY belly FOR BOTH, and not front_of_eyes for the table case:
#   - The WiFi antennas of a laptop sit in the screen bezel, roughly 185 mm above
#     the base plate. In both positions that puts the source in front of the
#     torso at about sternum height, with a nearly horizontal path to the body.
#     front_of_eyes assumes a source at eye level directly in front of the face,
#     which is not a laptop.
#   - Using front_of_eyes for the table case raises the brain dose by a factor of
#     23 over the deterministic model with no physical justification.
#
# WHAT IS DELIBERATELY NOT MODELLED: a laptop is used seated, while the GOLIAT
# phantoms are standing. Accounting for that would need a separate vertical
# offset for the simulation and for the scenario, which no other source does and
# which the documentation of the simulation geometry does not support. The brain
# therefore uses the same height/2 hypotenuse as mobiledata and gaming.
# See doc/laptop_stochastification.md.

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
#'   dur_high    = 0,
#'   params      = load_params(version = "_template"))
#'
#' @export
#' @import yaml
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

  # Calculate total duration ==================================================
  duration <- sum(
    dur_low,
    dur_lowmed,
    dur_medhigh,
    dur_high)

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
  dose <- msar * duration / 1000 # mW->W

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
#' * \eqn{outputpower_{laptop}} is the output power during laptop use
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
#'   dur_high    = 0,
#'   params      = load_params(version = "_template"))
#'
#' @export
#' @seealso [laptop_pwr(), laptop_sar()]
laptop_msar <- function(
    tissue,
    dur_low,
    dur_lowmed,
    dur_medhigh,
    dur_high,
    params = load_params()) {

  freqs <- c("2400", "5000") # 2.4 GHz and 5.0 GHz

  msar <- sum(
    vapply(
      freqs,
      \(freq) {

        ## Frequency band proportion
        prop <- params$global$wifi_probs[[paste0("wifi_", freq, "_prop")]]

        ## Calculate output power
        pwr <- laptop_pwr(
          freq        = freq,
          dur_low     = dur_low,
          dur_lowmed  = dur_lowmed,
          dur_medhigh = dur_medhigh,
          dur_high    = dur_high,
          params      = params)

        ## Calculate SAR
        sar <- laptop_sar(
          tissue = tissue,
          freq   = freq,
          params = params)

        ## Calculate mSAR of this band and return
        return(prop*pwr*sar)
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
#' type of activity. The nominal power is the same for every activity; what the
#' activity changes is the duty cycle, i.e. the share of the time the radio is
#' actually transmitting.
#'
#' @param freq WiFi frequency band in MHz ("2400" or "5000")
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
#'   freq        = "2400",
#'   dur_low     = 0,
#'   dur_lowmed  = 1230,
#'   dur_medhigh = 0,
#'   dur_high    = 0,
#'   params      = load_params(version = "_template"))
#'
#' @export
laptop_pwr <- function(
    freq,
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

  # Calculate power ===========================================================
  pwr <- sum(
    vapply(
      activities,
      \(activity) {
        act_prop <- act_props[[activity]]
        dc <- params$devices$lptp$dutycycle[[
          paste("lptp", freq, activity, "dutycycle", sep = "_")]]
        pwr <- params$devices$lptp$pwr[[
          paste("lptp", freq, "pwr", sep = "_")]]
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
#' The normalized specific absorption rate (nSAR) depends on the tissue, the
#' frequency band and the position of the device. Both positions take the
#' unweighted mean of the eight belly positions of the simulation dummy and
#' rescale it from the 200 mm at which those were simulated to the position's
#' own distance; the two results are then mixed by the lap/table share.
#'
#' For the body the distance is the horizontal antenna-to-torso distance. For
#' the brain it is the hypotenuse of that distance and half the body height,
#' because the device sits at torso level while the head is above it — the same
#' construction as in `mobiledata.R` and `gaming.R`.
#'
#' @param tissue Tissue for which to calculate nSAR (default: "brain" or "body")
#' @param freq WiFi frequency band in MHz ("2400" or "5000")
#' @param params Parameter list (optional). If not specified, calculations use
#' default parameters.
#'
#' @returns nSAR in W/kg/W
#'
#' @examples
#' laptop_sar(
#' tissue       = "brain",
#' freq         = "2400",
#' params       = load_params(version = "_template"))
#'
#' @export
laptop_sar <- function(
    tissue,
    freq,
    params = load_params()) {

  belly_position <- c("belly_center_vertical","belly_center_horizontal",
                      "belly_left_vertical","belly_left_horizontal",
                      "belly_right_vertical","belly_right_horizontal",
                      "belly_up_vertical","belly_up_horizontal")

  #find name of simulation dummy
  dummy <- determine_dummy(params$global$input_stoch$sex,
                           params$global$input_stoch$age)
  # define prefix for finding correct tissue parameter
  prefix <- paste0(dummy,"_",tissue,"_", freq,"_")
  # load tissue-specific parameters (SAR values)
  tissue_params <- load_tissue_params(params, "call", tissue,dummy) # here we still use call because at the moment all sar values are stored in call

  # no laptop-specific simulation exists, so we take the unweighted mean over the
  # belly positions instead of weighting them with the position proportions,
  # which describe how a phone is held rather than where a laptop sits
  sar_belly <- mean(
    vapply(
      belly_position,
      \(positions) {
        belly_sar <- paste0(prefix,positions,"_sar")
        return(tissue_params[[belly_sar]])
      },
      numeric(1)
    )
  )

  # tripwire: a dummy whose sar table has not been filled in would silently give a
  # dose of zero, which is indistinguishable from "this person does not use a laptop"
  if (sar_belly == 0) {
    warning("No SAR values for dummy ", dummy, " (", tissue, ", ", freq,
            " MHz). Laptop dose will be 0.")
  }

  # mix the two positions
  lap_prop  <- params$global$input_stoch$lptp_position$lptp_lap_prop
  dist_lap  <- params$devices$lptp$lptp_distance$lptp_dist_lap
  dist_desk <- params$devices$lptp$lptp_distance$lptp_dist_desk

  if (params$global$dist_correction) {
    #adjust distance with distance law (in mm), reference is 200 because GOLIAT
    #simulated the belly positions at 20 cm
    if (tissue == "body") {
      sar_lap  <- dist_law(sar = sar_belly, dist = dist_lap,
                           dist_ref = 200, delta = 6)
      sar_desk <- dist_law(sar = sar_belly, dist = dist_desk,
                           dist_ref = 200, delta = 6)
    } else if (tissue == "brain") {
      #the laptop sits at torso level, so it is further from the head than from
      #the body. Same geometry as for the phone at belly height.
      dummy_chest_height <- params$devices$call[[dummy]]$height/2

      sar_lap  <- dist_law(sar = sar_belly,
                           dist = sqrt(dummy_chest_height^2 + dist_lap^2),
                           dist_ref = sqrt(dummy_chest_height^2 + 200^2),
                           delta = 6)
      sar_desk <- dist_law(sar = sar_belly,
                           dist = sqrt(dummy_chest_height^2 + dist_desk^2),
                           dist_ref = sqrt(dummy_chest_height^2 + 200^2),
                           delta = 6)
    }
  } else {
    sar_lap <- sar_desk <- sar_belly
  }

  return(lap_prop*sar_lap + (1-lap_prop)*sar_desk)
}
