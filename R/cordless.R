# Calculate total RF-EMF dose (for brain and body) from cordless calls

# here we have to add positions and distances, and change sar to freq of dect (from hameds simulations)

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
  dose <- msar * duration/1000 # mW->W

  return(dose)
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
    params) {
  pwr <- params$devices$dect$pwr$dect_pwr * params$devices$dect$dutycycle$dect_dutycycle
  return(pwr)
}

dect_sar <- function(
    tissue,
    ear_prop,
    params) {

  ## ear

  #find name of simulation dummy
  dummy <- determine_dummy(params$global$input_stoch$sex,
                           params$global$input_stoch$age)
  # define prefix for finding correct tissue parameter
  prefix <- paste0(dummy,"_",tissue,"_1800_")
  # load tissue-specific parameters (SAR values)

  tissue_params <- load_tissue_params(params, "call", tissue,dummy)
  ear_position <- c("cheek1","cheek2","cheek3",
                    "tilt1","tilt2","tilt3")


  dect_ear_sar <- sum(
    vapply(
      ear_position,
      \(positions) {
        ear_sar <- paste0(prefix,positions,"_sar")
        ear_props <- paste0(positions,"_prop")
        return(tissue_params[[ear_sar]]*params$device$call$phone_positions[[ear_props]])
      },
      numeric(1)
    )
  )
  #adjust distance with distance law (in mm).
  if (params$global$dist_correction) {
    dect_ear_sar <- dist_law(sar = dect_ear_sar,
                            dist = params$devices$dect$dect_distance$dect_distance_ear,
                            dist_ref = 8,# because eye simulations ware at 8 mm
                            delta = 6)
  }

  ear_sar <- ear_prop * dect_ear_sar


  ## speaker
  frontal_position <- c("front_of_eyes_center_vertical","front_of_eyes_center_horizontal",
                        "front_of_eyes_left_vertical","front_of_eyes_left_horizontal",
                        "front_of_eyes_right_vertical","front_of_eyes_right_horizontal",
                        "front_of_eyes_down_vertical","front_of_eyes_down_horizontal")
  dect_speaker_sar <-  sum(
      vapply(
        frontal_position,
        \(positions) {
          frontal_sar <- paste0(prefix,positions,"_sar")
          frontal_prop <- paste0(positions,"_prop")
          return(tissue_params[[frontal_sar]]*params$device$call$phone_positions[[frontal_prop]])
        },
        numeric(1)
      )
    )
  if (params$global$dist_correction) {
    # adjust distance with distance law (in mm).
    dect_speaker_sar <- dist_law(sar = dect_speaker_sar,
                                dist = params$devices$dect$dect_distance$dect_distance_speaker,
                                dist_ref = 200,
                                delta = 6)
  }
  speaker_sar <- (1-ear_prop) * dect_speaker_sar
  ## total sar
  sar <- ear_sar + speaker_sar
  return(sar)
}

