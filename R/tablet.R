# Calculate total RF-EMF dose (for brain and body) from a tablet over WiFi

# There is no tablet-specific sar simulation. We use the mean of the eight
# front_of_eyes positions as a proxy and rescale it from their 200 mm reference
# distance to the stochastic viewing distance.
#
# WHY front_of_eyes AND ONLY front_of_eyes:
#   - A tablet is held up to be looked at, so the front-of-face geometry applies
#     to every activity. Unlike mobile data, which mixes belly and front-of-face
#     depending on what the user is doing, a tablet is not carried in a pocket.
#   - The deterministic model made the same choice: its tblt_*_sar values are the
#     wifi_*_headp_face_sar values, i.e. a phone held in front of the face. The
#     lap and table scenarios belong to laptop, not here.
#   - The rescaling is short and outward (20 cm simulated -> 30 cm modelled), so
#     it is the mildest application of the distance law anywhere in the model.
#
# The eight positions are averaged unweighted rather than weighted with
# phone_positions: those weights describe how a phone is held (60 % centred and
# portrait), which is not how a tablet is held. The choice is nearly immaterial
# either way -- weighting changes the mean by at most 11 %.
# See doc/tablet_stochastification.md.

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
#'   dur_high    = 0,
#'   params      = load_params(version = "_template"))
#'
#' @export
#' @import yaml
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
  dose <- msar * duration / 1000 # mW->W

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
#'   dur_high    = 0,
#'   params      = load_params(version = "_template"))
#'
#' @export
#' @seealso [tablet_pwr(), tablet_sar()]
tablet_msar <- function(
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
        pwr <- tablet_pwr(
          freq          = freq,
          dur_low       = dur_low,
          dur_lowmed    = dur_lowmed,
          dur_medhigh   = dur_medhigh,
          dur_high      = dur_high,
          params        = params)

        ## Calculate SAR
        sar <- tablet_sar(
          tissue        = tissue,
          freq          = freq,
          params        = params)

        ## Calculate mSAR of this band and return
        return(prop*pwr*sar)
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
#' type of activity. The nominal power is the same for every activity; what the
#' activity changes is the duty cycle, i.e. the share of the time the radio is
#' actually transmitting.
#'
#' @param freq WiFi frequency band in MHz ("2400" or "5000")
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
#'   freq        = "5000",
#'   dur_low     = 0,
#'   dur_lowmed  = 681,
#'   dur_medhigh = 0,
#'   dur_high    = 0,
#'   params      = load_params(version = "_template"))
#'
#' @export
tablet_pwr <- function(
    freq,
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
        dc <- params$devices$tblt$dutycycle[[
          paste("tblt", freq, activity, "dutycycle", sep = "_")]]
        pwr <- params$devices$tblt$pwr[[
          paste("tblt", freq, "pwr", sep = "_")]]
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
#' the frequency band. It is the unweighted mean of the eight front_of_eyes
#' positions of the simulation dummy, rescaled from the 200 mm at which they
#' were simulated to the drawn viewing distance. Brain and body use the same
#' rescaling: the tablet sits in front of the face, so moving it further away
#' increases the separation to the head and to the torso alike.
#'
#' @param tissue Tissue for which to calculate nSAR (default: "brain" or "body")
#' @param freq WiFi frequency band in MHz ("2400" or "5000")
#' @param params Parameter list (optional). If not specified, calculations use
#' default parameters.
#'
#' @returns nSAR in W/kg/W
#'
#' @examples
#' tablet_sar(
#' tissue       = "brain",
#' freq         = "2400",
#' params       = load_params(version = "_template"))
#'
#' @export
tablet_sar <- function(
    tissue,
    freq,
    params = load_params()) {

  frontal_position <- c("front_of_eyes_center_vertical","front_of_eyes_center_horizontal",
                        "front_of_eyes_left_vertical","front_of_eyes_left_horizontal",
                        "front_of_eyes_right_vertical","front_of_eyes_right_horizontal",
                        "front_of_eyes_down_vertical","front_of_eyes_down_horizontal")

  #find name of simulation dummy
  dummy <- determine_dummy(params$global$input_stoch$sex,
                           params$global$input_stoch$age)
  # define prefix for finding correct tissue parameter
  prefix <- paste0(dummy,"_",tissue,"_", freq,"_")
  # load tissue-specific parameters (SAR values)
  tissue_params <- load_tissue_params(params, "call", tissue,dummy) # here we still use call because at the moment all sar values are stored in call

  # no tablet-specific simulation exists, so we take the unweighted mean over the
  # front_of_eyes positions instead of weighting them with the position
  # proportions, which describe how a phone is held rather than a tablet
  sar_front_of_face <- mean(
    vapply(
      frontal_position,
      \(positions) {
        frontal_sar <- paste0(prefix,positions,"_sar")
        return(tissue_params[[frontal_sar]])
      },
      numeric(1)
    )
  )

  # tripwire: a dummy whose sar table has not been filled in would silently give a
  # dose of zero, which is indistinguishable from "this person does not use a tablet"
  if (sar_front_of_face == 0) {
    warning("No SAR values for dummy ", dummy, " (", tissue, ", ", freq,
            " MHz). Tablet dose will be 0.")
  }

  #distance stochastics
  if (params$global$dist_correction) {
    #adjust distance with distance law (in mm), reference is 200 because GOLIAT
    #simulated the front_of_eyes positions at 20 cm
    sar_front_of_face <- dist_law(sar = sar_front_of_face,
                                  dist = params$devices$tblt$tblt_distance$tblt_dist_device,
                                  dist_ref = 200,
                                  delta = 6)
  }
  return(sar_front_of_face)
}
