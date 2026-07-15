###############################################################################
# Calculate RF-EMF dose (for brain and body) from mobile calling


###############################################################################
# Total mobile call dose ======================================================
#' Calculation of RF-EMF Dose from Mobile Phone Calls
#'
#' Includes RF-EMF exposure from phone itself, for Bluetooth connection to
#' headphones, and from headphones themselves
#'
#' @details
#' The mobile call RF-EMF dose is calculated as:
#' \deqn{Dose_{mobilecall} = Dose_{phone} + Dose_{bluetooth}}
#'
#' Where:
#'
#' * \eqn{Dose_{mobilecall}} is the total dose from all mobile call activities
#' * \eqn{Dose_{phone}} is the dose from the mobile phone (no Bluetooth)
#' * \eqn{Dose_{bluetooth}} is the dose from using Bluetooth headphones
#' during the call.
#'
#'
#' For each source (phone and bluetooth), the dose is calculated as:
#'
#' \deqn{mSAR * duration}
#'
#' Where:
#'
#' * \eqn{mSAR} is the momentary SAR value in mJ/kg
#' * \eqn{duration} is the call duration in seconds
#'
#' @param tissue Tissue for which to calculate dose (default: "brain" or "body")
#' @param duration Duration of mobile phone call in seconds per day
#' @param ear_prop Proportion of call performed with phone held against ear
#' @param headp_prop Proportion of call performed with active Bluetooth connection
#' to headphones
#' @param urbanicity Urbanicity of home / workplace (rural, suburban, or urban)
#' @param use_5g TRUE if 5g services are used for calls, FALSE if not
#' @param travel_time Time spent commuting in seconds per day
#' @param headp_ear_num Number of Bluetooth headphones used during call
#' @param wifi_prop_home Proportion of time connected to WiFi (vs mobile data)
#' at home
#' @param wifi_prop_work Proportion of time connected to WiFi (vs mobile data)
#' at school / work
#' @param wifi_prop_travel Proportion of time connected to WiFi (vs mobile data)
#' while commuting
#' @param params Parameter list (optional). If not specified, calculations use
#' default parameters.
#'
#' @returns Tissue-specific RF-EMF dose in mJ/kg/day
#'
#' @examples
#' mobilecall_dose(
#' tissue           = "brain",
#' duration         = 400,
#' ear_prop         = 0.67,
#' headp_prop       = 0.17,
#' urbanicity       = "suburban",
#' use_5g           = TRUE,
#' travel_time      = 1800,
#' headp_ear_num    = 2,
#' wifi_prop_home   = 1,
#' wifi_prop_work   = 0.8,
#' wifi_prop_travel = 0,
#' params           = load_params(version = "_template"))
#'
#' @seealso [mpc_msar()]
#' @export
mobilecall_dose <- function(
    tissue,
    duration,
    ear_prop,
    headp_prop,
    urbanicity,
    use_5g,
    travel_time,
    headp_ear_num,
    wifi_prop_home,
    wifi_prop_work,
    wifi_prop_travel,
    simulation,
    params = load_params(version = simulation)) {
  #############################################################################

  ## Derive other input vars---------------------------------------------------
  speaker_prop <- 1- ear_prop - headp_prop

  ## Derive data and wifi proportion ------------------------------------------

  native_prop <- params$devices$call$call_type$native_prop

  wifi_prop <- (1-native_prop)*sum(
    params$global$environment_prop$home*wifi_prop_home,
    params$global$environment_prop$work_prop*wifi_prop_work,
    params$global$environment_prop$travel_prop*wifi_prop_travel)

  data_prop <- 1-native_prop-wifi_prop

  #############################################################################
  # Input checks ==============================================================

  #find name of simulation dummy
  dummy <- determine_dummy(params$global$input_stoch$sex,
                           params$global$input_stoch$age)
  check_tissue(tissue, "call", params,dummy)
  check_duration(duration)
  check_proportions(c(ear_prop, headp_prop, speaker_prop))
  check_urbanicity(urbanicity)
  check_boolean_not_na(use_5g)
  check_duration(travel_time)
  check_headp_num(headp_ear_num)
  check_proportions(wifi_prop_home)
  check_proportions(wifi_prop_work)
  check_proportions(wifi_prop_travel)
  check_proportions(c(native_prop, wifi_prop, data_prop))
  check_proportions(c(params$global$environment_prop$travel_prop,
                      params$global$environment_prop$home_prop,
                      params$global$environment_prop$work_prop,
                      params$global$environment_prop$outd_prop))

  # Calculate dose for mobile phone (no bluetooth) ============================
  msar_phone <- mpc_msar(
    tissue       = tissue,
    prop_native  = native_prop,
    prop_data    = data_prop,
    prop_wifi    = wifi_prop,
    headp_prop   = headp_prop,
    ear_prop     = ear_prop,
    speaker_prop = speaker_prop,
    urbanicity   = urbanicity,
    use_5g       = use_5g,
    travel_time  = travel_time,
    params       = params)

  dose_phone <- msar_phone * duration


  # Calculate dose for bluetooth headphones ===================================
  ## Brain --------------------------------------------------------------------
  msar_bt <- mpc_bt_msar(
    tissue = tissue,
    params = params)
  dose_bt <- msar_bt * headp_prop * headp_ear_num

  # Add doses from different sources and return result ========================
  dose <- sum(dose_phone, dose_bt)

  return(dose)
}

# Mobilecall mSAR =============================================================
#' Calculation of mSAR from Mobile Phone Calls
#'
#' Calculates mSAR (momentary specifc absorption rate) from mobile calls for
#' a specific tissue.
#'
#' @details
#' The mSAR is calculated as
#'
#' \deqn{mSAR = nSAR_{native}\times outputpower_{native} + nSAR_{data} \times
#' outputpower_{data} + nSAR_{wifi} \times outputpower_{wifi}}
#'
#' where
#'
#' * \eqn{nSAR_{native}}, \eqn{nSAR_{data}}, \eqn{nSAR_{wifi}} are the nSAR
#' (normalized specific absorption rates, in W/kg/W) from mobile phone calls using
#' native, mobile data, or WiFi networks, respectively
#' * \eqn{outputpower_{native}}, \eqn{outputpower_{data}},
#' \eqn{outputpower_{wifi}} are the output powers in mW of the device (mobile
#' phone) using native, mobile data, or WiFi networks, respectively
#'
#' @param tissue Tissue for which to calculate mSAR (default: "brain" or "body")
#' @param prop_native Proportion of mobile call using native connection
#' @param prop_data Proportion of mobile call using mobile data connection
#' @param prop_wifi Proportion of mobile call using WiFi connection
#' @param headp_prop Proportion of call performed with active Bluetooth connection
#' to headphones
#' @param ear_prop Proportion of call performed with phone held against ear
#' @param speaker_prop Proportion of call performed in speaker mode
#' @param urbanicity Urbanicity of home / workplace (rural, suburban, or urban)
#' @param use_5g TRUE if 5g services are used for calls, FALSE if not
#' @param travel_time Time spent commuting in seconds per day
#' @param params Parameter list (optional). If not specified, calculations use
#' default parameters.
#' @returns Momentary SAR (mSAR) in mW/kg
#'
#' @examples
#' mpc_msar(
#' tissue           = "body",
#' prop_native      = 0.7,
#' prop_data        = 0.2,
#' prop_wifi        = 0.1
#' headp_prop       = 0.17,
#' ear_prop         = 0.67,
#' speaker_prop     = 0.17,
#' urbanicity       = "suburban",
#' use_5g           = TRUE,
#' travel_time      = 1800,
#' params           = load_params(version = "_template"))
#'
#' @seealso [mpc_pwr_native(), mpc_pwr_data(), mpc_pwr_wifi(), mpc_sar_native(), mpc_sar_data(), mpc_sar_wifi()]
#' @export
mpc_msar <- function(
    tissue,
    prop_native,
    prop_data,
    prop_wifi,
    headp_prop,
    ear_prop,
    speaker_prop,
    urbanicity,
    use_5g,
    travel_time,
    params = load_params(version = simulation)) {
  # Setup =====================================================================
  ## Define frequency bands for each technology -------------------------------
  native_bands <- c("2g", "3g", "4g", "5g")
  data_bands   <- c("3g", "4g", "5g")
  wifi_bands   <- c("2400", "5000") # 2.4 GHz and 5.0 GHz

  # Native call ===============================================================
  msar_native <- sum(
    vapply(
      native_bands,
      \(band) {
        prop <- params$devices$call$native_band_props[[paste0("native_", band, "_prop")]]

        pwr <- mpc_pwr_native(
          band        = band,
          urbanicity  = urbanicity,
          travel_time = travel_time,
          params      = params
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
              freq_sar <- mpc_sar_native(
                tissue       = tissue,
                freq         = freq,
                headp_prop   = headp_prop,
                ear_prop     = ear_prop,
                speaker_prop = speaker_prop,
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

  # Data call =================================================================
  msar_data <- sum(
    vapply(
      data_bands,
      \(band) {
        if (use_5g) {
          prop <- params$devices$call$data_band_props[[paste0("data_", band, "_prop")]]
        } else {
          prop <- params$devices$call$data_band_no5g_props[[paste0("data_", band, "_prop_no5g")]]
        }

        pwr <- mpc_pwr_data(
          band             = band,
          urbanicity       = urbanicity,
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
              freq_sar <- mpc_sar_data(
                tissue       = tissue,
                freq         = freq,
                headp_prop   = headp_prop,
                ear_prop     = ear_prop,
                speaker_prop = speaker_prop,
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

  ## WiFi call ================================================================
  msar_wifi <- sum(
    vapply(
      wifi_bands,
      \(freq) {

        prop <- params$global$wifi_probs[[paste0("wifi_", freq, "_prop")]]

        pwr <- mpc_pwr_wifi(
          freq             = freq,
          params           = params
        )

        sar <- mpc_sar_wifi(
          tissue       = tissue,
          freq         = freq,
          headp_prop   = headp_prop,
          ear_prop     = ear_prop,
          speaker_prop = speaker_prop,
          params       = params
        )
        return(prop*sar*pwr)
      },
      numeric(1)
    )
  )
  # Scale mSAR with native vs WiFi vs data use proporion ======================
  msar <- sum(
    prop_native*msar_native,
    prop_data*msar_data,
    prop_wifi*msar_wifi)

  # Combine and return results ================================================
  return(msar)
}

# Mobilecall output power (nativecall) by technology (2G, 3g, 4g, 5g) ---------
#' Calculate Mobile Phone Output Power during Native Mobile Phone Calls
#'
#' Calculates the mobile phone output power during calls using native network.
#'
#' @details
#' The output power depends in the technology used and the location in which the
#' call is performed (urbanicity, indoors/outdoors/commuting)
#'
#'
#' @param band Technology (2G, 3g, 4g, or 5g) used for the call
#' @param urbanicity Urbanicity of home / workplace (rural, suburban, or urban)
#' @param travel_time Time spent commuting in seconds per day
#' @param params Parameter list (optional). If not specified, calculations use
#' default parameters.
#'
#' @returns Output power in mW
#'
#' @examples
#' mpc_pwr_native(
#' band        = "4g",
#' urbanicity  = "suburban",
#' travel_time = 1800,
#' params      = load_params(version = "_template"))
#'
#' @export
mpc_pwr_native <- function(
    band,
    urbanicity,
    travel_time,
    params = load_params(version = simulation)) {

  # calculate location proportions
  # loc_props <- location_props(
  #   travel_time = travel_time,
  #   home_prop   = params$global$home_prop,
  #   outd_prop   = params$global$outd_prop,
  #   work_prop   = params$global$work_prop)
  environment <- c("urb","sub","rur")
  indoor_prop <- params$global$environment_prop$home_prop + params$global$environment_prop$work_prop

  pwr_total <- sum(
    vapply(
      environment,
      \(urbanicity) {

        # define prefix for finding correct parameters
        prefix <- paste("native", band, substr(urbanicity, 0, 3), sep = "_")

        # home/work
        pwr_indoor  <- indoor_prop * params$devices$call$native_pwr[[paste0(prefix, "_ind_pwr")]]

        # outdoors
        pwr_outdoor   <- params$global$environment_prop$outd_prop * params$devices$call$native_pwr[[paste0(prefix, "_out_pwr")]]

        # commuting/traveling (same in every env)
        pwr_travel <- params$global$environment_prop$travel_prop * params$devices$call$native_pwr[[paste0("native_",band, "_travel_pwr")]]

        # combine, multiply with duty cycle, and return result (same in every env)
        dutycycle <- params$devices$call$native_dutycycle[[paste0("native_", band, "_dutycycle")]]
        pwr_loc_total <- sum(pwr_indoor, pwr_outdoor, pwr_travel) * dutycycle

        # calculate prower prop of environment
        return(pwr_loc_total*params$global$input_stoch$urbanicity[[paste0(urbanicity,"_prop")]])
      },
      numeric(1)
    )
  )

  return(pwr_total)
}


# Mobilecall SAR by technology (nativecall) -----------------------------------
#' Calculate nSAR during Native Mobile Phone Calls
#'
#' Calculates tissue-specific nSAR from mobile phone calls using native network.
#'
#' @details
#' The normalized specific absorption rate (nSAR) depends on the tissue, the
#' technology (2G, 3g, 4g or 5g), and the location of the phone during the
#' call (against ear, with Bluetooth headphones, in speaker mode)
#'
#'
#' @param tissue Tissue for which to calculate nSAR (default: "brain" or "body")
#' @param band Technology (2G, 3g, 4g, or 5g) used for the call
#' @param headp_prop Proportion of call performed with active Bluetooth connection
#' to headphones
#' @param ear_prop Proportion of call performed with phone held against ear
#' @param speaker_prop Proportion of call performed in speaker mode
#' @param params Parameter list (optional). If not specified, calculations use
#' default parameters.
#'
#' @returns nSAR in W/kg/W
#'
#' @examples
#' mpc_sar_native(
#' tissue       = "brain",
#' band         = "4g",
#' headp_prop   = 0.17,
#' ear_prop     = 0.67,
#' speaker_prop = 0.17,
#' params       = load_params(version = "_template"))
#'
#' @export
mpc_sar_native <- function(
    tissue,
    freq,
    headp_prop,
    ear_prop,
    speaker_prop,
    params) {


  ear_position <- c("cheek1","cheek2","cheek3",
                    "tilt1","tilt2","tilt3")
  frontal_position <- c("front_of_eyes_center_vertical","front_of_eyes_center_horizontal",
                       "front_of_eyes_left_vertical","front_of_eyes_left_horizontal",
                       "front_of_eyes_right_vertical","front_of_eyes_right_horizontal",
                       "front_of_eyes_down_vertical","front_of_eyes_down_horizontal")
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
  tissue_params <- load_tissue_params(params, "call", tissue,dummy)
  # phone on ear
  mpc_sar_ear <- sum(
    vapply(
      ear_position,
      \(positions) {
        ear_sar <- paste0(prefix,positions,"_sar")
        ear_props <- paste0(positions,"_prop")
        return(tissue_params[[ear_sar]]*params$device$call$phone_positions[[ear_props]]) #here also distance shift has to be added
      },
      numeric(1)
    )
  )
  # phone with headphone
  headp_sar_face <-  sum(
    vapply(
      frontal_position,
      \(positions) {
        frontal_sar <- paste0(prefix,positions,"_sar")
        frontal_prop <- paste0(positions,"_prop")
        return(tissue_params[[frontal_sar]]*params$device$call$phone_positions[[frontal_prop]]) #here also distance shift has to be added
      },
      numeric(1)
    )
  )
  headp_sar_pocket <-  sum(
    vapply(
      belly_position,
      \(positions) {
        belly_sar <- paste0(prefix,positions,"_sar")
        belly_prop <- paste0(positions,"_prop")
        return(tissue_params[[belly_sar]]*params$device$call$phone_positions[[belly_prop]]) #here also distance shift has to be added
      },
      numeric(1)
    )
  )
  headp_sar_else <- tissue_params[[paste0(dummy,"_",tissue,"_headp_else_sar")]]
  mpc_sar_headphones <- sum(
    params$devices$call$position_props$headp_face_prop * headp_sar_face,
    params$devices$call$position_props$headp_pock_prop * headp_sar_pocket,
    params$devices$call$position_props$headp_else_prop * headp_sar_else
  )
  # phone in speaker mode
  mpc_sar_speaker <-  sum(
    vapply(
      frontal_position,
      \(positions) {
        frontal_sar <- paste0(prefix,positions,"_sar")
        frontal_prop <- paste0(positions,"_prop")
        return(tissue_params[[frontal_sar]]*params$device$call$phone_positions[[frontal_prop]]) #here also distance shift has to be added
      },
      numeric(1)
    )
  )

  mpc_sar <- sum(
    ear_prop * mpc_sar_ear,
    headp_prop * mpc_sar_headphones,
    speaker_prop * mpc_sar_speaker
  )
  return(mpc_sar)
}



# Mobilecall data output power by technology ----------------------------------
#' Calculate Mobile Phone Output Power during Data Mobile Phone Calls
#'
#' Calculates the mobile phone output power during calls using mobile data.
#'
#' @details
#' The output power depends in the technology used and the location in which the
#' call is performed (urbanicity, indoors/outdoors/commuting)
#'
#'
#' @param band Technology (3g, 4g, or 5g) used for the call
#' @param urbanicity Urbanicity of home / workplace (rural, suburban, or urban)
#' @param travel_time Time spent commuting in seconds per day
#' @param params Parameter list (optional). If not specified, calculations use
#' default parameters.
#'
#' @returns Output power in mW
#'
#' @examples
#' mpc_pwr_data(
#' band        = "4g",
#' urbanicity  = "suburban",
#' travel_time = 1800,
#' params      = load_params(version = "_template"))
#'
#' @export
mpc_pwr_data <- function(
    band,
    urbanicity,
    travel_time,
    params) {


  environment <- c("urb","sub","rur")
  indoor_prop <- params$global$environment_prop$home_prop + params$global$environment_prop$work_prop

  pwr_total <- sum(
    vapply(
      environment,
      \(urbanicity) {

        # define prefix for finding correct parameters
        prefix <- paste("data", band, substr(urbanicity, 0, 3), sep = "_")

        # home/work
        pwr_indoor  <- indoor_prop * params$devices$call$data_pwr[[paste0(prefix, "_ind_pwr")]]

        # outdoors
        pwr_outdoor   <- params$global$environment_prop$outd_prop * params$devices$call$data_pwr[[paste0(prefix, "_out_pwr")]]

        # commuting/traveling (same in every env)
        pwr_travel <- params$global$environment_prop$travel_prop * params$devices$call$data_pwr[[paste0("data_",band, "_travel_pwr")]]

        # combine, multiply with duty cycle, and return result (same in every env)
        dutycycle <- params$devices$call$data_dutycycle[[paste0("data_", band, "_dutycycle")]]
        pwr_loc_total <- sum(pwr_indoor, pwr_outdoor, pwr_travel) * dutycycle

        # calculate prower prop of environment
        return(pwr_loc_total*params$global$input_stoch$urbanicity[[paste0(urbanicity,"_prop")]])
      },
      numeric(1)
    )
  )
  return(pwr_total)
}

# Mobilecall data sar by technology -------------------------------------------
#' Calculate nSAR during Data Mobile Phone Calls
#'
#' Calculates tissue-specific nSAR from mobile phone calls using mobile data.
#'
#' @details
#' The normalized specific absorption rate (nSAR) depends on the tissue, the
#' technology (2G, 3g, 4g or 5g), and the location of the phone during the
#' call (against ear, with Bluetooth headphones, in speaker mode)
#'
#'
#' @param tissue Tissue for which to calculate nSAR (default: "brain" or "body")
#' @param band Technology (2G, 3g, 4g, or 5g) used for the call
#' @param headp_prop Proportion of call performed with active Bluetooth connection
#' to headphones
#' @param ear_prop Proportion of call performed with phone held against ear
#' @param speaker_prop Proportion of call performed in speaker mode
#' @param params Parameter list (optional). If not specified, calculations use
#' default parameters.
#'
#' @returns nSAR in W/kg/W
#'
#' @examples
#' mpc_sar_data(
#' tissue       = "brain",
#' band         = "4g",
#' headp_prop   = 0.17,
#' ear_prop     = 0.67,
#' speaker_prop = 0.17,
#' params       = load_params(version = "_template"))
#'
#' @export
mpc_sar_data <- function(
    tissue,
    freq,
    headp_prop,
    ear_prop,
    speaker_prop,
    params) {


  mpc_sar <- mpc_sar_native(
    tissue,
    freq,
    headp_prop,
    ear_prop,
    speaker_prop,
    params = params)
  return(mpc_sar)
}

# Mobilecall output power (WiFi call) -----------------------------------------
#' Calculate Mobile Phone Output Power during WiFi Mobile Phone Calls
#'
#' Calculates the mobile phone output power during calls using WiFi connection.
#'
#' @details
#' The output power depends on the frequency band (2.4 GHz or 5.0 GHz)
#'
#'
#' @param band Frequency band ("2" for 2.4 GHz, "5" for 5.0 GHz) used for the call
#' @param params Parameter list (optional). If not specified, calculations use
#' default parameters.
#'
#' @returns Output power in mW
#'
#' @examples
#' mpc_pwr_wifi(
#' band        = "5",
#' params      = load_params(version = "_template"))
#'
#' @export
mpc_pwr_wifi <- function(
    freq,
    params = load_params(version = "_template")) {

  # define prefix for finding correct parameters
  prefix <- paste("wifi", freq, sep = "_")

  # get power
  pwr <- params$devices$call$data_pwr[[paste0("wifi_", freq, "_pwr")]]

  # get duty cycle
  dutycycle <- params$devices$call$wifi_dutycycle[[paste0("wifi_", freq, "_dutycycle")]]

  # multiply and return
  pwr_total <- pwr * dutycycle

  return(pwr_total)
}

# Mobilecall sar (WiFi call) --------------------------------------------------
#' Calculate nSAR during WiFi Mobile Phone Calls
#'
#' Calculates tissue-specific nSAR from mobile phone calls using WiFi connection.
#'
#' @details
#' The normalized specific absorption rate (nSAR) depends on the tissue, the
#' technology (2.4gHz or 5.0GHz), and the location of the phone during the
#' call (against ear, with Bluetooth headphones, in speaker mode)
#'
#'
#' @param tissue Tissue for which to calculate nSAR (default: "brain" or "body")
#' @param band Frequency band ("2" for 2.4 GHz, "5" for 5.0 GHz) used for the call
#' @param headp_prop Proportion of call performed with active Bluetooth connection
#' to headphones
#' @param ear_prop Proportion of call performed with phone held against ear
#' @param speaker_prop Proportion of call performed in speaker mode
#' @param params Parameter list (optional). If not specified, calculations use
#' default parameters.
#'
#' @returns nSAR in W/kg/W
#'
#' @examples
#' mpc_sar_wifi(
#' tissue       = "brain",
#' band         = "2",
#' headp_prop   = 0.17,
#' ear_prop     = 0.67,
#' speaker_prop = 0.17,
#' params       = load_params(version = "_template"))
#'
#' @export
mpc_sar_wifi <- function(
    tissue,
    freq,
    headp_prop,
    ear_prop,
    speaker_prop,
    params) {

  mpc_sar <- mpc_sar_native(
    tissue,
    freq,
    headp_prop,
    ear_prop,
    speaker_prop,
    params = params)


  return(mpc_sar)
}


###############################################################################
# Contributions from bluetooth heapdhones =====================================
#' Calculate mobile call mSAR from Bluetooth headphones
#'
#' Calculates mSAR from mobile calling using bluetooth headphones (both the
#' contribution from the headphones and the contribution of the mobile phone
#' establishing a connection to the headphones)
#'
#' @details
#' The mSAR is calculated as:
#' \deqn{mSAR_{bt} = mSAR_{bt_phone} + mSAR_{bt_headphones}}
#'
#' where the mSAR (of bt_phone and bt_headphones) is calculated as:
#'
#' \deqn{mSAR = nSAR * output_power}
#'
#' @param tissue Tissue for which to calculate mSAR (default: "brain" or "body")
#' @param params Parameter list (optional). If not specified, calculations use
#' default parameters.
#'
#' @returns mSAR from Bluetooth calls in mW/kg
#'
#' @seealso [mpc_bt_pwr(), mpc_bt_sar(), mpc_bt_phone_pwr(), mpc_bt_phone_pwr()]
#'
#' @examples
#' mpc_bt_msar(
#' tissue = "brain",
#' params = load_params(version = "_template")
#' )
#'
#' @export
mpc_bt_msar <- function(
    tissue,
    params) {

  # from bluetooth headphones
  pwr_bt <- mpc_bt_pwr(params = params)
  sar_bt <- mpc_bt_sar(tissue = tissue, params = params)
  msar_bt <- pwr_bt * sar_bt

  # from phone
  pwr_p  <- mpc_bt_phone_pwr(params = params)
  sar_p  <- mpc_bt_phone_sar(tissue = tissue, params = params)
  msar_bt_phone <- pwr_p * sar_p
  return(msar_bt + msar_bt_phone)
}

#' Calculate call output power (Bluetooth contribution only, headphones only)
#'
#' Returns the output power of Bluetooth headphones during mobile phone calls.
#'
#' @param params Parameter list (optional). If not specified, calculations use
#' default parameters.
#'
#' @returns Output power bluetooth headphones (headphones only) in mJ
mpc_bt_pwr <- function(
    params) {
  pwr <- params$devices$call$data_pwr$bt_pwr
  return(pwr)
}

#' Calculate call sar (bluetooth contribution only, headphones only)
#'
#' Returns the tissue-specific nSAR value from Bluetooth headphones during mobile
#' phone calls.
#'
#' @param tissue Tissue for which to calculate nSAR (default: "brain" or "body")
#' @param params Parameter list (optional). If not specified, calculations use
#' default parameters.
#'
#' @returns nSAR in W/kg/W
mpc_bt_sar <- function(
    tissue,
    params) {


  ear_position <- c("cheek1","cheek2","cheek3",
                    "tilt1","tilt2","tilt3")

  #find name of simulation dummy
  dummy <- determine_dummy(params$global$input_stoch$sex,
                           params$global$input_stoch$age)
  # define prefix for finding correct tissue parameter
  prefix <- paste0(dummy,"_",tissue,"_2400_")
  # load tissue-specific parameters (SAR values)
  tissue_params <- load_tissue_params(params, "call", tissue,dummy)

  # headphone on ear (prop weighted mean sar of all positions)
  bt_sar_headp <- sum(
    vapply(
      ear_position,
      \(positions) {
        ear_sar <- paste0(prefix,positions,"_sar")
        ear_props <- paste0(positions,"_prop")
        return(tissue_params[[ear_sar]]*params$device$call$phone_positions[[ear_props]]) #here also distance shift has to be added
      },
      numeric(1)
    )
  )
  return(bt_sar_headp)
}

#' Calculate call output power (bluetooth contribution only, phone only)
#'
#' Returns the output power of the mobile phone during mobile calls when connected
#' to Bluetooth headphones (Bluetooth contribution only!)
#'
#' @param params Parameter list (optional). If not specified, calculations use
#' default parameters.
#'
#' @returns Output power bluetooth headphones (phone only) in mJ
mpc_bt_phone_pwr <- function(
    params) {
  pwr <- params$devices$call$data_pwr$bt_pwr
  return(pwr)
}

#' Calculate call output power (bluetooth contribution only, headphones only)
#'
#' Returns the tissue-speficic nSAR from the mobile phones during calls when
#' connected to Bluetooth headphones (Bluetooth contribution only!)
#'
#' @param tissue Tissue for which to calculate nSAR (default: "brain" or "body")
#' @param params Parameter list (optional). If not specified, calculations use
#' default parameters.
#'
#' @returns nSAR in W/kg/W
mpc_bt_phone_sar <- function(
    tissue,
    params) {

  frontal_position <- c("front_of_eyes_center_vertical","front_of_eyes_center_horizontal",
                        "front_of_eyes_left_vertical","front_of_eyes_left_horizontal",
                        "front_of_eyes_right_vertical","front_of_eyes_right_horizontal",
                        "front_of_eyes_down_vertical","front_of_eyes_down_horizontal")
  belly_position <- c("belly_center_vertical","belly_center_horizontal",
                      "belly_left_vertical","belly_left_horizontal",
                      "belly_right_vertical","belly_right_horizontal",
                      "belly_up_vertical","belly_up_horizontal")

  #find name of simulation dummy
  dummy <- determine_dummy(params$global$input_stoch$sex,
                           params$global$input_stoch$age)
  tissue_params <- load_tissue_params(params, "call", tissue,dummy)

  # define prefix for finding correct tissue parameter
  prefix <- paste0(dummy,"_",tissue,"_2400_")

  # phone with headphone
  headp_bt_sar_face <-  sum(
    vapply(
      frontal_position,
      \(positions) {
        frontal_sar <- paste0(prefix,positions,"_sar")
        frontal_prop <- paste0(positions,"_prop")
        return(tissue_params[[frontal_sar]]*params$device$call$phone_positions[[frontal_prop]]) #here also distance shift has to be added
      },
      numeric(1)
    )
  )
  headp_bt_sar_pocket <-  sum(
    vapply(
      belly_position,
      \(positions) {
        belly_sar <- paste0(prefix,positions,"_sar")
        belly_prop <- paste0(positions,"_prop")
        return(tissue_params[[belly_sar]]*params$device$call$phone_positions[[belly_prop]]) #here also distance shift has to be added
      },
      numeric(1)
    )
  )
  headp_bt_sar_else <- tissue_params[[paste0(dummy,"_",tissue,"_headp_else_sar")]]
  mpc_sar_headphone_bt <- sum(
    params$devices$call$position_props$headp_face_prop * headp_bt_sar_face,
    params$devices$call$position_props$headp_pock_prop * headp_bt_sar_pocket,
    params$devices$call$position_props$headp_else_prop * headp_bt_sar_else
  )

  return(mpc_sar_headphone_bt)
}




