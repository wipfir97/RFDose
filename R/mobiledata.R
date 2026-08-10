###############################################################################
# Calculate RF-EMF dose (for brain and body) from mobile data


###############################################################################
# Total mobile data dose ======================================================
#' Calculation of RF-EMF Dose from Mobile Phone Data Use
#'
#' The mobile data RF-EMF dose is calculated as:
#' \deqn{Dose_{data} = mSAR_{data}*duration_{data}}
#'
#' Where:
#'
#' * \eqn{Dose_{data}} is the dose from mobile data use
#' * \eqn{mSAR_{data}} is the momentary SAR value in mJ/kg
#' * \eqn{duration_{data}} is the duration of mobile data use
#'
#' @details
#'
#' We distinguish between 4 types of mobile data use:
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
#' @param duration_low Duration (in seconds per day) of low output power activities
#' @param duration_lowmed Duration (in seconds per day) of low-medium output power activities
#' @param duration_medhigh Duration (in seconds per day) of medium-high output power activities
#' @param duration_high Duration (in seconds per day) of high output power activities
#' @param use_5g TRUE if 5G services are used for data transfer, FALSE if not
#' @param wifi_prop_home Proportion of time connected to WiFi (vs mobile data)
#' at home
#' @param wifi_prop_work Proportion of time connected to WiFi (vs mobile data)
#' at school / work
#' @param wifi_prop_travel Proportion of time connected to WiFi (vs mobile data)
#' while commuting
#' @param travel_time Time spent commuting in seconds per day
#' @param params Parameter list (optional). If not specified, calculations use
#' default parameters.
#'
#' @returns Tissue-specific RF-EMF dose from data use in mJ/kg/day
#'
#' @examples
#' mobiledata_dose(
#' tissue           = "brain",
#' duration_low     = 4860,
#' duration_lowmed  = 540,
#' duration_medhigh = 4860,
#' duration_high    = 540,
#' use_5g           = FALSE,
#' wifi_prop_home   = 0.5,
#' wifi_prop_work   = 0.5,
#' wifi_prop_travel = 0.5,
#' travel_time      = 1800,
#' params           = load_params())
#'
#' @seealso [mpd_msar()]
#' @export
mobiledata_dose <- function(
    tissue,
    duration_low,
    duration_lowmed,
    duration_medhigh,
    duration_high,
    use_5g,
    wifi_prop_home,
    wifi_prop_work,
    wifi_prop_travel,
    travel_time,
    simulation,
    params = load_params(version = simulation)) {
  # Check input ===============================================================
  # check_tissue(tissue, "data", params)
  check_duration(c(duration_low, duration_lowmed, duration_medhigh, duration_high))
  check_boolean_not_na(use_5g)
  check_proportions(wifi_prop_home)
  check_proportions(wifi_prop_work)
  check_proportions(wifi_prop_travel)
  check_duration(travel_time)

  # Calculate mSAR ============================================================
  msar <- mpd_msar(
    tissue           = tissue,
    duration_low     = duration_low,
    duration_lowmed  = duration_lowmed,
    duration_medhigh = duration_medhigh,
    duration_high    = duration_high,
    use_5g           = use_5g,
    wifi_prop_home   = wifi_prop_home,
    wifi_prop_work   = wifi_prop_work,
    wifi_prop_travel = wifi_prop_travel,
    travel_time      = travel_time,
    params           = params
  )

  # Calculate total use duration ==============================================
  duration <- sum(
    duration_low,
    duration_lowmed,
    duration_medhigh,
    duration_high)

  # Calculate dose ============================================================
  dose <- duration*msar/1000# mW -> W
  # Return result =============================================================
  return(dose)
}

###############################################################################
# Calculate mSAR
#' Calculation of mSAR from Mobile Phone Data
#'
#' Calculates mSAR (momentary specifc absorption rate) from data (mobile data
#' and WiFi) use for a specific tissue
#'
#' @details
#' The mSAR is calculated as
#'
#' \deqn{mSAR = nSAR_{mobiledata} \times
#' outputpower_{mobiledata} + nSAR_{wifi} \times outputpower_{wifi}}
#'
#' where
#'
#' * \eqn{nSAR_{data}}, \eqn{nSAR_{wifi}} are the nSAR
#' (normalized specific absorption rates, in W/kg/W) from data use using
#' mobile data or WiFi networks, respectively
#' * \eqn{outputpower_{data}}, \eqn{outputpower_{wifi}} are the output powers (mW)
#' of the device (mobilephone) using mobile data or WiFi networks, respectively
#'
#' @param tissue Tissue for which to calculate mSAR (default: "brain" or "body")
#' @param duration_low Duration (in seconds per day) of low output power activities
#' @param duration_lowmed Duration (in seconds per day) of low-medium output power activities
#' @param duration_medhigh Duration (in seconds per day) of medium-high output power activities
#' @param duration_high Duration (in seconds per day) of high output power activities
#' @param use_5g TRUE if 5G services are used for data transfer, FALSE if not
#' @param wifi_prop_home Proportion of time connected to WiFi (vs mobile data)
#' at home
#' @param wifi_prop_work Proportion of time connected to WiFi (vs mobile data)
#' at school / work
#' @param wifi_prop_travel Proportion of time connected to WiFi (vs mobile data)
#' while commuting
#' @param travel_time Time spent commuting in seconds per day
#' @param params Parameter list (optional). If not specified, calculations use
#' default parameters.
#'
#' @returns Momentary SAR (mSAR) from mobile data use in mW/kg
#'
#' @examples
#' mpd_msar(
#' tissue           = "brain",
#' duration_low     = 4860,
#' duration_lowmed  = 540,
#' duration_medhigh = 4860,
#' duration_high    = 540,
#' use_5g           = FALSE,
#' wifi_prop_home   = 0.5,
#' wifi_prop_work   = 0.5,
#' wifi_prop_travel = 0.5,
#' travel_time      = 1800,
#' params           = load_params())
#'
#' @seealso [mpd_pwr_data(), mpd_pwr_wifi(), mpd_sar_data(), mpd_sar_wifi()]
#' @export
mpd_msar <- function(
    tissue,
    duration_low,
    duration_lowmed,
    duration_medhigh,
    duration_high,
    use_5g,
    wifi_prop_home,
    wifi_prop_work,
    wifi_prop_travel,
    travel_time,
    params) {

  # Setup =====================================================================
  ## Define frequency bands for each technology -------------------------------
  data_bands <- c("3g", "4g", "5g","6g")
  wifi_freqs <- c("2400", "5000") # 2.4 GHz and 5.0 GHz

  ## Calculate overall data vs wifi prop --------------------------------------
  wifi_prop_overall <- sum(
    params$global$environment_prop$home*wifi_prop_home, # assumption of no WiFi outdoors
    params$global$environment_prop$work_prop*wifi_prop_work,
    params$global$environment_prop$travel_prop*wifi_prop_travel)

  data_prop_overall <- 1-wifi_prop_overall


  # Calculate activity proportions ============================================
  act_props <- act_pwr_props(
    duration_low,
    duration_lowmed,
    duration_medhigh,
    duration_high)


  # Apply mSAR calculation to all data frequency bands ========================
  msar_data <- sum(
    vapply(
      data_bands,
      \(band) {
        if (use_5g) {
          prop <- params$devices$call$data_band_props[[paste0("data_", band, "_prop")]]
        } else {
          prop <- params$devices$call$data_band_no5g_props[[paste0("data_", band, "_prop_no5g")]]
        }

        pwr <- mpd_pwr_data(
          band             = band,
          duration_low     = duration_low,
          duration_lowmed  = duration_lowmed,
          duration_medhigh = duration_medhigh,
          duration_high    = duration_high,
          travel_time      = travel_time,
          params           = params
        )

        band_freq_names <- names(params$devices$call[[paste0(band, "_freq_props")]])
        band_freq_names <- sub("^f", "", band_freq_names)
        band_freq_names <-sub(paste0("_",band,"_prop$"), "", band_freq_names)

        sar <- sum(
          vapply(
            band_freq_names,
            \(freq) {
              freq_prop <- params$devices$call[[paste0(band, "_freq_props")]][[
                paste0("f",freq,"_",band,"_","prop")]]
              freq_sar <- mpd_sar_data(
                tissue       = tissue,
                freq         = freq,
                medhigh_prob = act_props$medhigh,
                params       = params
              )
              return(freq_prop*freq_sar)
            },
            numeric(1)
          )
        )
        return(prop*sar*pwr)
      },
      numeric(1)
    )
  )
  #print(paste0("msar_data: ", msar_data))

  # apply mSAR calculation to all WiFi frequency bands =========================
  msar_wifi <- sum(
    vapply(
      wifi_freqs,
      \(freq) {

      prop <- params$global$wifi_probs[[paste0("wifi_", freq, "_prop")]]

      pwr <- mpd_pwr_wifi(
        freq             = freq,
        duration_low     = duration_low,
        duration_lowmed  = duration_lowmed,
        duration_medhigh = duration_medhigh,
        duration_high    = duration_high,
        params           = params
      )

      sar <- mpd_sar_wifi(
        tissue       = tissue,
        freq         = freq,
        medhigh_prob = act_props$medhigh,
        params       = params
      )
      prop*sar*pwr
    },
    numeric(1)
    )
  )



  # Scale mSAR with WiFi vs data use proporion ================================
  msar <- sum(
    data_prop_overall*msar_data,
    wifi_prop_overall*msar_wifi)

  # Combine and return results ================================================
  return(msar)
}

###############################################################################
# Calculate output power (data)
#' Calculate Mobile Phone Output Power during Mobile Data Use
#'
#' Calculates the mobile phone output power during mobile data use.
#'
#' @details
#' The output power depends in the technology used, the location in which the
#' mobile data network (urbanicity, indoors/outdoors/commuting), and the activity
#' the phone is used for.
#'
#' @param band Technology (3g, 4g, or 5g)
#' @param duration_low Duration (in seconds per day) of low output power activities
#' @param duration_lowmed Duration (in seconds per day) of low-medium output power activities
#' @param duration_medhigh Duration (in seconds per day) of medium-high output power activities
#' @param duration_high Duration (in seconds per day) of high output power activities
#' @param travel_time Time spent commuting in seconds per day
#' @param params Parameter list (optional). If not specified, calculations use
#' default parameters.
#'
#' @returns Output power in mW
#'
#' @examples
#' mpd_pwr_data(
#' band             = "4g",
#' duration_low     = 4860,
#' duration_lowmed  = 540,
#' duration_medhigh = 4860,
#' duration_high    = 540,
#' travel_time      = 1800,
#' params           = load_params())
#'
#' @export
mpd_pwr_data <- function(
    band,
    duration_low,
    duration_lowmed,
    duration_medhigh,
    duration_high,
    travel_time,
    params) {



  # Calculate activity proportions ============================================
  act_props <- act_pwr_props(
    duration_low,
    duration_lowmed,
    duration_medhigh,
    duration_high)


  # Calculate output power ====================================================
  ## Define which locations and activities to consider
  activities  <- c("low", "lowmed", "medhigh", "high")
  environment <- c("urb","sub","rur")
  indoor_prop <- params$global$environment_prop$home_prop + params$global$environment_prop$work_prop


  # go through environments and calculate power for every env
  pwr_total <- sum(
    vapply(
      environment,
      \(urbanicity) {
        # define prefix for finding correct parameters
        prefix <- paste("data", band, substr(urbanicity, 0, 3), sep = "_")

        #iterate through activities
        pwr_loc_total <- sum(
          vapply(
            activities,
            \(act) {
              dc <- act_props[[act]]*params$devices$data$dutycycle[[paste0("data_", band,"_",act, "_dutycycle")]]
              # home/work
              pwr_indoor  <- indoor_prop * params$devices$data$pwr[[paste0(prefix, "_ind_pwr")]]*dc

              # outdoors
              pwr_outdoor   <- params$global$environment_prop$outd_prop * params$devices$data$pwr[[paste0(prefix, "_out_pwr")]]*dc

              # commuting/traveling (same in every env)
              pwr_travel <- params$global$environment_prop$travel_prop * params$devices$data$pwr[[paste0("data_",band, "_travel_pwr")]]*dc

              # combine, multiply with duty cycle, and return result (same in every env)
              return(sum(pwr_indoor, pwr_outdoor, pwr_travel))

            },
            numeric(1)
            ))

        # calculate prower prop of environment
        return(pwr_loc_total*params$global$input_stoch$urbanicity[[paste0(urbanicity,"_prop")]])
      },
      numeric(1)
    )
  )
  return(pwr_total)
}


# Wifi ========================================================================
#' Calculate Mobile Phone Output Power during WiFi Use
#'
#' Calculates the mobile phone output power during WiFi use
#'
#' @details
#' The output power depends on the frequency band (2.4 GHz or 5.0 GHz) and the
#' type of activity.
#'
#' @param band WiFi frequency band ("2" for 2.4 GHz, "5" for 5.0 GHz)
#' @param duration_low Duration (in seconds per day) of low output power activities
#' @param duration_lowmed Duration (in seconds per day) of low-medium output power activities
#' @param duration_medhigh Duration (in seconds per day) of medium-high output power activities
#' @param duration_high Duration (in seconds per day) of high output power activities
#' @param params Parameter list (optional). If not specified, calculations use
#' default parameters.
#'
#' @returns Output power in mW
#'
#' @examples
#' mpc_pwr_wifi(
#' band             = "2",
#' duration_low     = 4860,
#' duration_lowmed  = 540,
#' duration_medhigh = 4860,
#' duration_high    = 540,
#' params           = load_params())
#'
#' @export
mpd_pwr_wifi <- function(
    freq,
    duration_low,
    duration_lowmed,
    duration_medhigh,
    duration_high,
    params) {

  # Calculate activity proportions ============================================
  act_props <- act_pwr_props(
    duration_low,
    duration_lowmed,
    duration_medhigh,
    duration_high)
  activities <- c("low", "lowmed", "medhigh", "high")

  # Define function for WiFi calculation and sum over activities ==============
  pwr <- sum(
    vapply(
      activities,
      \(activity) {
        act_prop <- act_props[[activity]]
        dc <- params$devices$data$dutycycle[[paste("wifi", freq, activity, "dutycycle", sep = "_")]]
        pwr <- params$devices$data$pwr[[paste("wifi", freq, "pwr", sep = "_")]]
        return(act_prop*dc*pwr)
      },
      numeric(1)
    )
  )
  return(pwr)
}

###############################################################################
# Calculate SAR (data) ========================================================
#' Calculate nSAR during mobile data use on mobile phone
#'
#' Calculates tissue-specific nSAR from mobile data use on mobile phone.
#'
#' @details
#' The normalized specific absorption rate (nSAR) depends on the tissue and
#' the frequency band.
#'
#'
#' @param tissue Tissue for which to calculate nSAR (default: "brain" or "body")
#' @param band Technology ("3g", "4g", or "5g")
#' @param params Parameter list (optional). If not specified, calculations use
#' default parameters.
#'
#' @returns nSAR in W/kg/W
#'
#' @examples
#' mpd_sar_data(
#' tissue       = "brain",
#' band         = "5g",
#' params       = load_params())
#'
#' @export
mpd_sar_data <- function(
    freq,
    tissue,
    medhigh_prob,
    params) {

  belly_position <- c("belly_center_vertical","belly_center_horizontal",
                      "belly_left_vertical","belly_left_horizontal",
                      "belly_right_vertical","belly_right_horizontal",
                      "belly_up_vertical","belly_up_horizontal")
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

  sar_belly <-  sum(
    vapply(
      belly_position,
      \(positions) {
        belly_sar <- paste0(prefix,positions,"_sar")
        belly_prop <- paste0(positions,"_prop")
        return(tissue_params[[belly_sar]]*params$device$call$phone_positions[[belly_prop]])
      },
      numeric(1)
    )
  )

  #distance stochastics
  if (params$global$dist_correction) {
    if (tissue == "body"){
      #distance stochastics without distance shift because mean is already 200 (in mm)
      sar_belly <- dist_law(sar = sar_belly,
                                   dist = params$devices$data$mpd_distance$mpd_dist_belly,
                                   dist_ref = 200,
                                   delta = 6)
    } else if (tissue == "brain"){
      #distance stochastics without distance shift because mean is already 200 (in mm),
      #the brain sar only increases that moch how the phone is closer to the head
      #in the pocket the phone is still quiet far away from the head.
      dummy_chest_height <- params$devices$call[[dummy]]$height/2

      sar_belly <- dist_law(sar = sar_belly,
                                   dist = sqrt(dummy_chest_height^2 + params$devices$data$mpd_distance$mpd_dist_belly^2),
                                   dist_ref = sqrt(dummy_chest_height^2+200^2),
                                   delta = 6)
    }
  }

  # when phone is held in front of the face, for example during videocall
  sar_front_of_face <-  sum(
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
    sar_front_of_face <- dist_law(sar = sar_front_of_face,
                                dist = params$devices$call$mpc_distance$mpc_dist_speaker,
                                dist_ref = 200,
                                delta = 6)
  }


  # we assume that for more or less the percentage of time, with med to high
  # data usage, the phone is held in front of face.
  #NOTE: this implementation is not completely proper, it would probably be better
  #to use front of multiply pwr_medhigh, also here. Then the sar front of face,
  #would actually only count for these power values
  return(sar_belly*(1-medhigh_prob) + sar_front_of_face*medhigh_prob)
}

# Calculate SAR (wifi) ========================================================
#' Calculate nSAR during WiFi Use on mobile phone
#'
#' Calculates tissue-specific nSAR from WiFi use on mobile phone.
#'
#' @details
#' The normalized specific absorption rate (nSAR) depends on the tissue and
#' the frequency band.
#'
#'
#' @param tissue Tissue for which to calculate nSAR (default: "brain" or "body")
#' @param band Frequency band ("2" for 2.4 GHz, "5" for 5.0 GHz)
#' @param params Parameter list (optional). If not specified, calculations use
#' default parameters.
#'
#' @returns nSAR in W/kg/W
#'
#' @examples
#' mpd_sar_wifi(
#' tissue       = "brain",
#' band         = "2",
#' params       = load_params())
#'
#' @export
mpd_sar_wifi <- function(
    freq,
    tissue,
    medhigh_prob,
    params) {

  sar_wifi <- mpd_sar_data(
    freq,
    tissue,
    medhigh_prob,
    params = params)

  return(sar_wifi)
}
