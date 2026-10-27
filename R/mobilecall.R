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
#'
#' \deqn{Dose_{mobilecall} = Dose_{phone} + Dose_{earset} + Dose_{btphone}}
#'
#' with
#'
#' \deqn{Dose_{phone} = mSAR_{phone} \times duration}
#' \deqn{Dose_{earset} = mSAR_{earset} \times p_{headp} \times n_{ear} \times duration}
#' \deqn{Dose_{btphone} = mSAR_{btphone} \times p_{headp} \times duration}
#'
#' Where:
#'
#' * \eqn{Dose_{phone}} is the dose from the mobile phone (no Bluetooth)
#' * \eqn{Dose_{earset}} and \eqn{Dose_{btphone}} are the doses from the
#'   Bluetooth earphones and from the Bluetooth connection of the phone
#' * \eqn{mSAR_{phone}}, \eqn{mSAR_{earset}} and \eqn{mSAR_{btphone}} are the
#'   momentary SAR values in mW/kg (see [mpc_msar()], [mpc_bt_earset_msar()]
#'   and [mpc_bt_phone_msar()])
#' * \eqn{p_{headp}} is the proportion of the call with Bluetooth headphones
#'   (`headp_prop`) and \eqn{n_{ear}} the number of earphones (`headp_ear_num`)
#' * \eqn{duration} is the call duration in s/day
#'
#' The phone is in speaker mode for the rest of the call,
#' \eqn{1 - p_{ear} - p_{headp}}. The call goes over the native network for the
#' proportion \eqn{p_{native}} (parameter `native_prop`), over WiFi for
#' \eqn{p_{wifi} = (1 - p_{native}) \times (t_{home} w_{home} + t_{work} w_{work} + t_{travel} w_{travel})}
#' and over mobile data for the rest, where \eqn{t} are the shares of the day
#' at home, at work and commuting (see [location_props()]) and \eqn{w} the
#' WiFi proportions (`wifi_prop_home`, `wifi_prop_work`, `wifi_prop_travel`).
#'
#' @param tissue Tissue for which to calculate dose (default: "brain" or "body")
#' @param duration Duration of mobile phone call in seconds per day
#' @param ear_prop Proportion of call performed with phone held against ear
#' @param headp_prop Proportion of call performed with active Bluetooth connection
#' to headphones
#' @param urbanicity Urbanicity of home / workplace (rural, suburban, or urban)
#' @param use_5g TRUE if 5g services are used for calls, FALSE if not
#' @param travel_time Time spent commuting in seconds per day
#' @param headp_ear_num Number of Bluetooth earphones worn during the call (0, 1 or 2)
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
#' wifi_prop_travel = 0)
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
    params = load_params()) {
  #############################################################################
  # Derive additional input values ============================================
  ## Derive speaker mode use proportion ---------------------------------------
  speaker_prop <- 1-ear_prop-headp_prop
  ## Derive data and wifi proportion ------------------------------------------
  # TODO: double check this step and find more elegant solution
  loc_props <- location_props(
    travel_time = travel_time,
    home_prop   = params$global$home_prop,
    outd_prop   = params$global$outd_prop,
    work_prop   = params$global$work_prop)

  native_prop <- params$devices$call$native_prop

  wifi_prop <- (1-native_prop)*sum(
    loc_props$home*wifi_prop_home,
    loc_props$work*wifi_prop_work,
    loc_props$travel*wifi_prop_travel)

  data_prop <- 1-native_prop-wifi_prop


  #############################################################################
  # Input checks ==============================================================
  check_tissue(tissue, "call", params)
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
  check_proportions(c(loc_props$travel, loc_props$home, loc_props$work, loc_props$out))

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
  ## Contribution of headphones/earset
  msar_bt_earset <- mpc_bt_earset_msar(
    tissue = tissue,
    params = params
  )
  dose_bt_earset <-msar_bt_earset * headp_prop * headp_ear_num * duration

  ## Contribution of phone
  msar_bt_phone <- mpc_bt_phone_msar(
    tissue = tissue,
    params = params
  )
  dose_bt_phone <-msar_bt_phone * headp_prop * duration

  # Add doses from different sources and return result ========================
  dose <- sum(dose_phone, dose_bt_earset, dose_bt_phone)

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
#' \deqn{mSAR = p_{native} \times mSAR_{native} + p_{data} \times mSAR_{data} + p_{wifi} \times mSAR_{wifi}}
#'
#' with, for each network \eqn{n} (native, data or WiFi),
#'
#' \deqn{mSAR_{n} = \sum_{b} s_{n,b} \times nSAR_{n,b} \times P_{n,b}}
#'
#' where
#'
#' * \eqn{p_{native}}, \eqn{p_{data}}, \eqn{p_{wifi}} are the proportions of the
#'   call over the native network, mobile data or WiFi (`prop_native`,
#'   `prop_data`, `prop_wifi`)
#' * \eqn{s_{n,b}} is the share of the frequency band \eqn{b}: 2G to 5G for
#'   native calls, 3G to 5G for data calls (without 5G if `use_5g` is FALSE),
#'   2.4 and 5 GHz for WiFi calls
#' * \eqn{nSAR_{n,b}} is the normalized SAR in W/kg/W, weighted over the
#'   positions of the phone (see [mpc_sar_native()], [mpc_sar_data()],
#'   [mpc_sar_wifi()])
#' * \eqn{P_{n,b}} is the mean output power of the phone in mW, including the
#'   duty cycle (see [mpc_pwr_native()], [mpc_pwr_data()], [mpc_pwr_wifi()])
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
#' prop_wifi        = 0.1,
#' headp_prop       = 0.17,
#' ear_prop         = 0.67,
#' speaker_prop     = 0.17,
#' urbanicity       = "suburban",
#' use_5g           = TRUE,
#' travel_time      = 1800)
#'
#' @seealso [mpc_pwr_native()], [mpc_pwr_data()], [mpc_pwr_wifi()], [mpc_sar_native()], [mpc_sar_data()], [mpc_sar_wifi()]
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
    params = load_params()) {
  # Setup =====================================================================
  ## Define frequency bands for each technology -------------------------------
  native_bands <- c("2g", "3g", "4g", "5g")
  data_bands   <- c("3g", "4g", "5g")
  wifi_bands   <- c("2", "5") # 2.4 GHz and 5.0 GHz

  # Native call ===============================================================
  msar_native <- sum(
    vapply(
      native_bands,
      \(band) {
        prop <- params$devices$call[[paste0("native_", band, "_prop")]]

        pwr <- mpc_pwr_native(
          band        = band,
          urbanicity  = urbanicity,
          travel_time = travel_time,
          params      = params
        )

        sar <- mpc_sar_native(
          tissue       = tissue,
          band         = band,
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

  # Data call =================================================================
  msar_data <- sum(
    vapply(
      data_bands,
      \(band) {
        if (use_5g) {
          prop <- params$devices$call[[paste0("data_", band, "_prop")]]
        } else {
          prop <- params$devices$call[[paste0("data_", band, "_prop_no5g")]]
        }

        pwr <- mpc_pwr_data(
          band             = band,
          urbanicity       = urbanicity,
          travel_time      = travel_time,
          params           = params
        )

        sar <- mpc_sar_data(
          tissue       = tissue,
          band         = band,
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

  ## WiFi call ================================================================
  msar_wifi <- sum(
    vapply(
      wifi_bands,
      \(band) {

        prop <- params$global[[paste0("wifi_", band, "_prop")]]

        pwr <- mpc_pwr_wifi(
          band             = band,
          params           = params
        )

        sar <- mpc_sar_wifi(
          tissue       = tissue,
          band         = band,
          headp_prop   = headp_prop,
          ear_prop     = ear_prop,
          speaker_prop = speaker_prop,
          params       = params
        )

        prop*sar*pwr
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
#' Calculates the mean output power of the mobile phone during calls using the
#' native network.
#'
#' @details
#' The output power depends on the technology and on where the call is made
#' (urbanicity; indoors, outdoors or commuting):
#'
#' \deqn{P = DC \times (t_{ind} \times P_{ind} + t_{out} \times P_{out} + t_{travel} \times P_{travel})}
#'
#' where \eqn{t_{ind}}, \eqn{t_{out}} and \eqn{t_{travel}} are the shares of
#' the day at home or at work, outdoors and commuting (see [location_props()]),
#' \eqn{P_{ind}}, \eqn{P_{out}} and \eqn{P_{travel}} the output powers there in
#' mW (indoors and outdoors: for the urbanicity), and \eqn{DC} the duty cycle
#' of the technology.
#'
#' @param band Technology ("2g", "3g", "4g" or "5g") used for the call
#' @param urbanicity Urbanicity of home / workplace (rural, suburban, or urban)
#' @param travel_time Time spent commuting in seconds per day
#' @param params Parameter list (optional). If not specified, calculations use
#' default parameters.
#'
#' @returns Output power in mW, including the duty cycle
#'
#' @examples
#' mpc_pwr_native(
#' band        = "4g",
#' urbanicity  = "suburban",
#' travel_time = 1800)
#'
#' @export
mpc_pwr_native <- function(
    band,
    urbanicity,
    travel_time,
    params = load_params()) {

  # calculate location proportions
  loc_props <- location_props(
    travel_time = travel_time,
    home_prop   = params$global$home_prop,
    outd_prop   = params$global$outd_prop,
    work_prop   = params$global$work_prop)

  # define prefix for finding correct parameters
  prefix <- paste("native", band, substr(urbanicity, 0, 3), sep = "_")

  # home/work
  indoor_prop <- loc_props$home + loc_props$work
  pwr_indoor  <- indoor_prop * params$devices$call[[paste0(prefix, "_ind_pwr")]]

  # outdoors
  pwr_outdoor   <- loc_props$out * params$devices$call[[paste0(prefix, "_out_pwr")]]

  # commuting/traveling
  pwr_travel <- loc_props$travel * params$devices$call[[paste0("native_",band, "_travel_pwr")]]

  # combine, multiply with duty cycle, and return resul
  dutycycle <- params$devices$call[[paste0("native_", band, "_dutycycle")]]
  pwr_total <- sum(pwr_indoor, pwr_outdoor, pwr_travel) * dutycycle

  return(pwr_total)
}


# Mobilecall SAR by technology (nativecall) -----------------------------------
#' Calculate nSAR during Native Mobile Phone Calls
#'
#' Calculates tissue-specific nSAR from mobile phone calls using native network.
#'
#' @details
#' The normalized specific absorption rate (nSAR) depends on the tissue, the
#' technology (2G, 3G, 4G or 5G), and the position of the phone during the
#' call (against the ear, with Bluetooth headphones, in speaker mode):
#'
#' \deqn{nSAR = p_{ear} \times nSAR_{ear} + p_{headp} \times nSAR_{headp} + p_{speaker} \times nSAR_{speaker}}
#' \deqn{nSAR_{headp} = f_{face} \times nSAR_{face} + f_{pock} \times nSAR_{pock} + f_{else} \times nSAR_{else}}
#'
#' where \eqn{p} are the proportions of the call in each position (`ear_prop`,
#' `headp_prop`, `speaker_prop`), \eqn{f} the proportions of the places of the
#' phone during calls with headphones (parameters `headp_face_prop`,
#' `headp_pock_prop`, `headp_else_prop`), and the nSAR values are in W/kg/W.
#'
#' @param tissue Tissue for which to calculate nSAR (default: "brain" or "body")
#' @param band Technology ("2g", "3g", "4g" or "5g") used for the call
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
#' speaker_prop = 0.17)
#'
#' @export
mpc_sar_native <- function(
    tissue,
    band,
    headp_prop,
    ear_prop,
    speaker_prop,
    params = load_params()) {
  # define prefix for finding correct tissue parameter
  prefix <- paste0("native_", band)
  # load tissue-specific parameters (SAR values)
  tissue_params <- load_tissue_params(params, "call", tissue)
  # phone on ear
  mpc_sar_ear <- tissue_params[[paste0(prefix, "_ear_sar")]]
  # phone with headphone
  mpc_sar_headphones <- sum(
    params$devices$call$headp_face_prop * tissue_params[[paste0(prefix, "_headp_face_sar")]],
    params$devices$call$headp_pock_prop * tissue_params[[paste0(prefix, "_headp_pock_sar")]],
    params$devices$call$headp_else_prop * tissue_params[[paste0(prefix, "_headp_else_sar")]]
  )
  # phone in speaker mode
  mpc_sar_speaker <- tissue_params[[paste0(prefix, "_speaker_sar")]]

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
#' Calculates the mean output power of the mobile phone during calls using
#' mobile data.
#'
#' @details
#' The output power depends on the technology and on where the call is made
#' (urbanicity; indoors, outdoors or commuting):
#'
#' \deqn{P = DC \times (t_{ind} \times P_{ind} + t_{out} \times P_{out} + t_{travel} \times P_{travel})}
#'
#' where \eqn{t_{ind}}, \eqn{t_{out}} and \eqn{t_{travel}} are the shares of
#' the day at home or at work, outdoors and commuting (see [location_props()]),
#' \eqn{P_{ind}}, \eqn{P_{out}} and \eqn{P_{travel}} the output powers there in
#' mW (indoors and outdoors: for the urbanicity), and \eqn{DC} the duty cycle
#' of the technology.
#'
#' @param band Technology ("3g", "4g" or "5g") used for the call
#' @param urbanicity Urbanicity of home / workplace (rural, suburban, or urban)
#' @param travel_time Time spent commuting in seconds per day
#' @param params Parameter list (optional). If not specified, calculations use
#' default parameters.
#'
#' @returns Output power in mW, including the duty cycle
#'
#' @examples
#' mpc_pwr_data(
#' band        = "4g",
#' urbanicity  = "suburban",
#' travel_time = 1800)
#'
#' @export
mpc_pwr_data <- function(
    band,
    urbanicity,
    travel_time,
    params = load_params()) {

  # calculate location proportions
  loc_props <- location_props(
    travel_time = travel_time,
    home_prop   = params$global$home_prop,
    outd_prop   = params$global$outd_prop,
    work_prop   = params$global$work_prop)

  # define prefix for finding correct parameters
  prefix <- paste("data", band, substr(urbanicity, 0, 3), sep = "_")

  # home/work
  indoor_prop <- loc_props$home + loc_props$work

  pwr_indoor  <- indoor_prop * params$devices$call[[paste0(prefix, "_ind_pwr")]]

  # outdoors
  pwr_outdoor   <- loc_props$out * params$devices$call[[paste0(prefix, "_out_pwr")]]


  # commuting/traveling
  pwr_travel <- loc_props$travel * params$devices$call[[paste0("data_",band, "_travel_pwr")]]

  # combine, multiply with duty cycle, and return result
  dutycycle <- params$devices$call[[paste0("data_", band, "_dutycycle")]]


  pwr_total <- sum(pwr_indoor, pwr_outdoor, pwr_travel) * dutycycle



  return(pwr_total)
}

# Mobilecall data sar by technology -------------------------------------------
#' Calculate nSAR during Data Mobile Phone Calls
#'
#' Calculates tissue-specific nSAR from mobile phone calls using mobile data.
#'
#' @details
#' The normalized specific absorption rate (nSAR) depends on the tissue, the
#' technology (3G, 4G or 5G), and the position of the phone during the call
#' (against the ear, with Bluetooth headphones, in speaker mode):
#'
#' \deqn{nSAR = p_{ear} \times nSAR_{ear} + p_{headp} \times nSAR_{headp} + p_{speaker} \times nSAR_{speaker}}
#' \deqn{nSAR_{headp} = f_{face} \times nSAR_{face} + f_{pock} \times nSAR_{pock} + f_{else} \times nSAR_{else}}
#'
#' where \eqn{p} are the proportions of the call in each position (`ear_prop`,
#' `headp_prop`, `speaker_prop`), \eqn{f} the proportions of the places of the
#' phone during calls with headphones (parameters `headp_face_prop`,
#' `headp_pock_prop`, `headp_else_prop`), and the nSAR values are in W/kg/W.
#'
#' @param tissue Tissue for which to calculate nSAR (default: "brain" or "body")
#' @param band Technology ("3g", "4g" or "5g") used for the call
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
#' speaker_prop = 0.17)
#'
#' @export
mpc_sar_data <- function(
    tissue,
    band,
    headp_prop,
    ear_prop,
    speaker_prop,
    params = load_params()) {
  # define prefix for finding correct tissue parameter
  prefix <- paste0("data_", band)
  # load tissue-specific parameters (SAR values)
  tissue_params <- load_tissue_params(params, "call", tissue)
  # phone on ear
  mpc_sar_ear <- tissue_params[[paste0(prefix, "_ear_sar")]]
  # phone with headphone
  mpc_sar_headphones <- sum(
    params$devices$call$headp_face_prop * tissue_params[[paste0(prefix, "_headp_face_sar")]],
    params$devices$call$headp_pock_prop * tissue_params[[paste0(prefix, "_headp_pock_sar")]],
    params$devices$call$headp_else_prop * tissue_params[[paste0(prefix, "_headp_else_sar")]]
  )
  # phone in speaker mode
  mpc_sar_speaker <- tissue_params[[paste0(prefix, "_speaker_sar")]]


  mpc_sar <- sum(
    ear_prop * mpc_sar_ear,
    headp_prop * mpc_sar_headphones,
    speaker_prop * mpc_sar_speaker
  )

  return(mpc_sar)
}

# Mobilecall output power (WiFi call) -----------------------------------------
#' Calculate Mobile Phone Output Power during WiFi Mobile Phone Calls
#'
#' Calculates the mean output power of the mobile phone during calls using WiFi
#' connection.
#'
#' @details
#' The output power depends on the frequency band (2.4 GHz or 5.0 GHz):
#'
#' \deqn{P = DC \times P_{wifi}}
#'
#' where \eqn{P_{wifi}} is the output power of the band in mW and \eqn{DC} its
#' duty cycle.
#'
#' @param band Frequency band ("2" for 2.4 GHz, "5" for 5.0 GHz) used for the call
#' @param params Parameter list (optional). If not specified, calculations use
#' default parameters.
#'
#' @returns Output power in mW, including the duty cycle
#'
#' @examples
#' mpc_pwr_wifi(
#' band  = "5")
#'
#' @export
mpc_pwr_wifi <- function(
    band,
    params = load_params()) {

  # define prefix for finding correct parameters
  prefix <- paste("wifi", band, sep = "_")

  # get power
  pwr <- params$devices$call[[paste0("wifi_", band, "_pwr")]]

  # get duty cycle
  dutycycle <- params$devices$call[[paste0("wifi_", band, "_dutycycle")]]

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
#' frequency band (2.4 GHz or 5.0 GHz), and the position of the phone during
#' the call (against the ear, with Bluetooth headphones, in speaker mode):
#'
#' \deqn{nSAR = p_{ear} \times nSAR_{ear} + p_{headp} \times nSAR_{headp} + p_{speaker} \times nSAR_{speaker}}
#' \deqn{nSAR_{headp} = f_{face} \times nSAR_{face} + f_{pock} \times nSAR_{pock} + f_{else} \times nSAR_{else}}
#'
#' where \eqn{p} are the proportions of the call in each position (`ear_prop`,
#' `headp_prop`, `speaker_prop`), \eqn{f} the proportions of the places of the
#' phone during calls with headphones (parameters `headp_face_prop`,
#' `headp_pock_prop`, `headp_else_prop`), and the nSAR values are in W/kg/W.
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
#' speaker_prop = 0.17)
#'
#' @export
mpc_sar_wifi <- function(
    tissue,
    band,
    headp_prop,
    ear_prop,
    speaker_prop,
    params = load_params()) {
  # define prefix for finding correct tissue parameter
  prefix <- paste0("wifi_", band)
  # load tissue-specific parameters (SAR values)
  tissue_params <- load_tissue_params(params, "call", tissue)
  # phone on ear
  mpc_sar_ear <- tissue_params[[paste0(prefix, "_ear_sar")]]
  # phone with headphone
  mpc_sar_headphones <- sum(
    params$devices$call$headp_face_prop * tissue_params[[paste0(prefix, "_headp_face_sar")]],
    params$devices$call$headp_pock_prop * tissue_params[[paste0(prefix, "_headp_pock_sar")]],
    params$devices$call$headp_else_prop * tissue_params[[paste0(prefix, "_headp_else_sar")]]
  )
  # phone in speaker mode
  mpc_sar_speaker <- tissue_params[[paste0(prefix, "_speaker_sar")]]


  mpc_sar <- sum(
    ear_prop * mpc_sar_ear,
    headp_prop * mpc_sar_headphones,
    speaker_prop * mpc_sar_speaker
  )

  return(mpc_sar)
}

###############################################################################
# Contributions from Bluetooth headphones =====================================
#' Calculate mobile call mSAR for Bluetooth headphones (headphones only)
#'
#' Calculates the mSAR for mobile calling using Bluetooth headphones
#' (headphone/earset only; the contribution of the mobile phone is calculated
#' separately).
#'
#' @details
#' The mSAR of one earphone is calculated as
#'
#' \deqn{mSAR_{earset} = nSAR_{earset} \times P_{bt}}
#'
#' where \eqn{nSAR_{earset}} is the normalized SAR of the earphone in W/kg/W
#' and \eqn{P_{bt}} the Bluetooth output power in mW. [mobilecall_dose()]
#' multiplies it by the number of earphones.
#'
#' @param tissue Tissue for which to calculate mSAR (default: "brain" or "body")
#' @param params Parameter list (optional). If not specified, calculations use
#' default parameters.
#'
#' @returns mSAR from Bluetooth calls (one earphone only) in mW/kg
#'
#' @seealso [mpc_bt_phone_msar()]
#'
#' @examples
#' mpc_bt_earset_msar(
#'   tissue = "brain"
#' )
#'
#' @export
mpc_bt_earset_msar <- function(
    tissue,
    params = load_params()) {
  # Load tissue params ========================================================
  tissue_params <- load_tissue_params(params, "call", tissue)

  # Output power ==============================================================
  pwr <- params$devices$call$bt_pwr

  # nSAR ======================================================================
  sar <- tissue_params$bt_headp_sar

  # Calculate mSAR and return result
  msar <- pwr*sar
  return(msar)
}

#' Calculate mobile call mSAR for Bluetooth headphones (phone only)
#'
#' Calculates the mSAR for mobile calling using Bluetooth headphones
#' (Bluetooth connection of the phone only; the contribution of the
#' headphones/earset is calculated separately).
#'
#' @details
#' The mSAR is calculated as
#'
#' \deqn{mSAR_{btphone} = P_{bt} \times (f_{face} \times nSAR_{face} + f_{pock} \times nSAR_{pock} + f_{else} \times nSAR_{else})}
#'
#' where \eqn{P_{bt}} is the Bluetooth output power in mW, \eqn{f} the
#' proportions of the places of the phone during calls with headphones
#' (parameters `headp_face_prop`, `headp_pock_prop`, `headp_else_prop`) and
#' the nSAR values are in W/kg/W.
#'
#' @param tissue Tissue for which to calculate mSAR (default: "brain" or "body")
#' @param params Parameter list (optional). If not specified, calculations use
#' default parameters.
#'
#' @returns mSAR from Bluetooth calls (phone contribution only) in mW/kg
#'
#' @seealso [mpc_bt_earset_msar()]
#'
#' @examples
#' mpc_bt_phone_msar(
#' tissue = "brain"
#' )
#'
#' @export
mpc_bt_phone_msar <- function(
    tissue,
    params = load_params()) {
  # Load tissue params ========================================================
  tissue_params <- load_tissue_params(params, "call", tissue)

  # Output power ==============================================================
  pwr <- params$devices$call$bt_pwr

  # nSAR ======================================================================
  sar_face <- params$devices$call$headp_face_prop * tissue_params$bt_phone_face_sar
  sar_pock <- params$devices$call$headp_pock_prop * tissue_params$bt_phone_pock_sar
  sar_else <- params$devices$call$headp_else_prop * tissue_params$bt_phone_else_sar
  sar <- sum(sar_face, sar_pock, sar_else)

  # Calculate mSAR and return result ==========================================
  msar <- pwr*sar
  return(msar)
}
