###############################################################################
# Calculate total RF-EMF dose (for brain and body) from mobile calling
# TODO: once functions are checked, remove redundancy by combining similar functions

###############################################################################
# Total mobile call dose ======================================================
#' Calculate RF-EMF dose from mobile calling (mobile phone and Bluethooth)
#'
#' Includes all sources: RF-EMF from phone itself, for Bluetooth connection to
#' headphones, and from headphones themselves
#'
#' @details
#' The mobile call RF-EMF dose is calculated as:
#' \deqn{Dose_{mobilecall} = Dose_{phone} + Dose_{phoneBluetooth} +
#' Dose_{headphonesBluetooth}}
#'
#' Where:
#'
#' * \eqn{Dose_{mobilecall}} is the total dose from all mobile call activities
#' * \eqn{Dose_{phone}} is the dose from the mobile phone (no Bluetooth)
#' * \eqn{Dose_{phoneBluetooth}} is the dose from Bluetooth by the phone
#' * \eqn{Dose_{headphonesBluetooth}} is the dose from Bluetooth by the
#' Bluetooth headphones
#'
#'
#' @param duration Duration of mobile phone call in seconds per day
#' @param ear_prop Proportion of time mobile phone is held against ear
#' during call
#' @param headp_prop Proportion of time Bluetooth headphones are used during
#' mobile call
#' @param urbanicity Urbanicity of home / workplace
#' @param use_5g TRUE if participant uses 5G services on mobile phone,
#' FALSE if not
#' @param travel_time Time spent commuting in seconds per day
#' @param headp_ear_num If particpant uses 1 or 2 Bluetooth headphones
#' during mobile call
#' @param wifi_prop_home ...
#' @param wifi_prop_work ...
#' @param wifi_prop_travel ...
#' @param params Parameter list
#'
#' @returns List with two values:
#'
#' * "brain_call_dose" (brain RF-EMF dose from mobile calls in mJ/kg/day)
#' * "body_call_dose" (body RF-EMF dose from mobile calls in mJ/kg/day)
#'
#' @seealso [get_mobilecall_phone_dose()], [get_mobilecall_bt_phone_dose()], [get_mobilecall_bt_headp_dose()]
#' @export
mobilecall_dose <- function(
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

  # Input checks ==============================================================
  ## TODO: add input checks

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

  # Calculate dose for mobile phone (no bluetooth) ============================
  ## Brain --------------------------------------------------------------------
  msar_phone_brain <- mobilecall_msar(
    tissue       = "brain",
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

  dose_phone_brain <- msar_phone_brain * duration

  ## Body ---------------------------------------------------------------------
  msar_phone_body <- mobilecall_msar(
    tissue       = "body",
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

  dose_phone_body <- msar_phone_body * duration

  # Calculate dose for bluetooth headphones ===================================
  ## Brain --------------------------------------------------------------------
  msar_bt_brain <- mobilecall_bt_msar(tissue = "brain", params = params)
  dose_bt_brain <- msar_bt_brain * headp_prop * headp_ear_num
  ## Body ---------------------------------------------------------------------
  msar_bt_body  <- mobilecall_bt_msar(tissue = "body", params = params)
  dose_bt_body  <- msar_bt_body * headp_prop * headp_ear_num

  # Add doses from different sources and return result ========================
  ## Brain --------------------------------------------------------------------
  brain_dose <- sum(dose_phone_brain, dose_bt_brain)
  ## Body ---------------------------------------------------------------------
  body_dose  <- sum(dose_phone_body, dose_bt_body)

  ## Save as list and return --------------------------------------------------
  output_list <- list(
    "brain_call_dose" = brain_dose,
    "body_call_dose"  = body_dose)

  return(output_list)
}

###############################################################################
# Mobilecall mSAR =============================================================
#' Calculate momentary SAR (mSAR) from mobile calling -------------------------
#'
#'
#' @export
mobilecall_msar <- function(
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

  # Native call
  msar_native <- prop_native * mpc_msar_native(
    tissue       = tissue,
    headp_prop   = headp_prop,
    ear_prop     = ear_prop,
    speaker_prop = speaker_prop,
    urbanicity   = urbanicity,
    travel_time  = travel_time,
    params       = params
  )
  # Data call
  msar_data   <- prop_data * mpc_msar_data(
    tissue       = tissue,
    headp_prop   = headp_prop,
    ear_prop     = ear_prop,
    speaker_prop = speaker_prop,
    urbanicity   = urbanicity,
    use_5g       = use_5g,
    travel_time  = travel_time,
    params       = params
  )
  # Wifi call
  msar_wifi   <- prop_wifi * mpc_msar_wifi(
    tissue       = tissue,
    headp_prop   = headp_prop,
    ear_prop     = ear_prop,
    speaker_prop = speaker_prop,
    params       = params
  )
  print(paste(prop_native, prop_data, prop_wifi))
  print(paste(msar_native, msar_data, msar_wifi))
  # Combine and return result
  total_msar <- sum(
    msar_native,
    msar_data,
    msar_wifi)

  return(total_msar)
}

# Mobilecall mSAR for native calls ============================================
# Mobilecall mSAR (native call) -----------------------------------------------
mpc_msar_native <- function(
    tissue,
    headp_prop,
    ear_prop,
    speaker_prop,
    urbanicity,
    travel_time,
    params = load_params()) {

  # define technologies
  techs <- c("2g", "3g", "4g", "5g")

  # apply to all technologies
  msar_native <- setNames(
    lapply(techs, function(tech) {


      prop <- params$devices$call[[paste0("native_", tech, "_prop")]]

      prop * mpc_msar_native_bytech(
        tissue       = tissue,
        tech         = tech,
        headp_prop   = headp_prop,
        ear_prop     = ear_prop,
        speaker_prop = speaker_prop,
        urbanicity   = urbanicity,
        travel_time  = travel_time,
        params       = params
      )
    }),
    techs
  )


  # sum and return
  total_msar_native <- sum(unlist(msar_native))

  return(total_msar_native)
}


# Mobilecall mSAR (nativecall) by technology (2G, 3G, 4G, 5G) -----------------
mpc_msar_native_bytech <- function(
    tissue,
    tech,
    headp_prop,
    ear_prop,
    speaker_prop,
    urbanicity,
    travel_time,
    params = load_params()) {
  # output power
  mpc_pwr_native <- mpc_pwr_native(
    tech          = tech,
    urbanicity    = urbanicity,
    travel_time   = travel_time,
    params        = params)
  # sar
  mpc_sar_native <- mpc_sar_native(
    tissue        = tissue,
    tech          = tech,
    headp_prop    = headp_prop,
    ear_prop      = ear_prop,
    speaker_prop  = speaker_prop,
    params        = params)

  # calculate msar (output power * sar) and return result
  msar_bytech <- mpc_pwr_native * mpc_sar_native

  return(msar_bytech)
}

# Mobilecall output power (nativecall) by technology (2G, 3G, 4G, 5G) ---------
mpc_pwr_native <- function(
    tech,
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
  prefix <- paste("native", tech, substr(urbanicity, 0, 3), sep = "_")

  # home/work
  indoor_prop <- loc_props$home + loc_props$work
  pwr_indoor  <- indoor_prop * params$devices$call[[paste0(prefix, "_ind_pwr")]]

  # outdoors
  pwr_outdoor   <- loc_props$out * params$devices$call[[paste0(prefix, "_out_pwr")]]

  # commuting/traveling
  pwr_travel <- loc_props$travel * params$devices$call[[paste0("native_",tech, "travel_pwr")]]

  # combine, multiply with duty cycle, and return resul
  dutycycle <- params$devices$call[[paste0("native_", tech, "_dutycycle")]]
  pwr_total <- sum(pwr_indoor, pwr_outdoor, pwr_travel) * dutycycle

  return(pwr_total)
}


# Mobilecall SAR by technology (nativecall) -----------------------------------
mpc_sar_native <- function(
    tissue,
    tech,
    headp_prop,
    ear_prop,
    speaker_prop,
    params = load_params()) {
  # define prefix for finding correct tissue parameter
  prefix <- paste0("native_", tech)
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


# Mobilecall mSAR (data call) =================================================
mpc_msar_data <- function(
    tissue,
    headp_prop,
    ear_prop,
    speaker_prop,
    urbanicity,
    use_5g,
    travel_time,
    params = load_params()) {

  # define technologies
  techs <- c("2g", "3g", "4g", "5g")

  # define function to get correct proportion parameter
  get_data_prop <- function(params, tech, use_5g) {
    if (use_5g) {
      params$devices$call[[paste0("data_", tech, "_prop")]]
    } else {
      params$devices$call[[paste0("data_", tech, "_prop_no5g")]]
    }
  }
  # apply to all tachnologies
  msar_data <- setNames(
    lapply(techs, function(tech) {

      prop <- get_data_prop(params, tech, use_5g)

      prop * mpc_msar_data_bytech(
        tissue       = tissue,
        tech         = tech,
        headp_prop   = headp_prop,
        ear_prop     = ear_prop,
        speaker_prop = speaker_prop,
        urbanicity   = urbanicity,
        travel_time  = travel_time,
        params       = params
      )
    }),
    techs
  )

  # sum and return
  total_msar_data <- sum(unlist(msar_data)
  )
  return(total_msar_data)
}

# Mobilecall data msar by technology ------------------------------------------
mpc_msar_data_bytech <- function(
    tissue,
    tech,
    headp_prop,
    ear_prop,
    speaker_prop,
    urbanicity,
    travel_time,
    params = load_params()) {
  # output power
  mpc_pwr_data <- mpc_pwr_data(
    tech          = tech,
    urbanicity    = urbanicity,
    travel_time   = travel_time,
    params        = params)
  # sar
  mpc_sar_data <- mpc_sar_data(
    tissue        = tissue,
    tech          = tech,
    headp_prop    = headp_prop,
    ear_prop      = ear_prop,
    speaker_prop  = speaker_prop,
    params        = params)

  # calculate msar (output power * sar) and return result
  msar_bytech <- mpc_pwr_data * mpc_sar_data

  return(msar_bytech)
}

# Mobilecall data output power by technology ----------------------------------
mpc_pwr_data <- function(
    tech,
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
  prefix <- paste("data", tech, substr(urbanicity, 0, 3), sep = "_")

  # home/work
  indoor_prop <- loc_props$home + loc_props$work

  pwr_indoor  <- indoor_prop * params$devices$call[[paste0(prefix, "_ind_pwr")]]

  # outdoors
  pwr_outdoor   <- loc_props$out * params$devices$call[[paste0(prefix, "_out_pwr")]]


  # commuting/traveling
  pwr_travel <- loc_props$travel * params$devices$call[[paste0("data_",tech, "travel_pwr")]]

  # combine, multiply with duty cycle, and return resul
  dutycycle <- params$devices$call[[paste0("data_", tech, "_dutycycle")]]

  pwr_total <- sum(pwr_indoor, pwr_outdoor, pwr_travel) * dutycycle

  return(pwr_total)
}

# Mobilecall data sar by technology -------------------------------------------
mpc_sar_data <- function(
    tissue,
    tech,
    headp_prop,
    ear_prop,
    speaker_prop,
    params = load_params()) {
  # define prefix for finding correct tissue parameter
  prefix <- paste0("data_", tech)
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


# Mobilecall mSAR (wifi call) =================================================
mpc_msar_wifi <- function(
    tissue,
    headp_prop,
    ear_prop,
    speaker_prop,
    params = load_params()) {
  # define technologies
  techs <- c("2", "5")

  # define function to get correct proportion parameter
  get_wifi_prop <- function(params, tech) {
    params$global[[paste0("wifi_", tech, "_prop")]]
  }
  # apply to all tachnologies
  msar_wifi <- setNames(
    lapply(techs, function(tech) {

      prop <- get_wifi_prop(params, tech)

      prop * mpc_msar_wifi_bytech(
        tissue       = tissue,
        tech         = tech,
        headp_prop   = headp_prop,
        ear_prop     = ear_prop,
        speaker_prop = speaker_prop,
        params       = params
      )
    }),
    techs
  )

  # sum and return
  total_msar_wifi <- sum(unlist(msar_wifi)
  )
  return(total_msar_wifi)
}

# Mobilecall mSAR by technology (WiFi call) -----------------------------------
mpc_msar_wifi_bytech <- function(
    tissue,
    tech,
    headp_prop,
    ear_prop,
    speaker_prop,
    params = load_params()) {
  # output power
  mpc_pwr_wifi <- mpc_pwr_wifi(
    tech          = tech,
    params        = params)
  # sar
  mpc_sar_wifi <- mpc_sar_wifi(
    tissue        = tissue,
    tech          = tech,
    headp_prop    = headp_prop,
    ear_prop      = ear_prop,
    speaker_prop  = speaker_prop,
    params        = params)

  # calculate msar (output power * sar) and return result
  msar_wifi_bytech <- mpc_pwr_wifi * mpc_sar_wifi

  return(msar_wifi_bytech)
}

# Mobilecall output power (WiFi call) -----------------------------------------
mpc_pwr_wifi <- function(
    tech,
    params = load_params()) {

  # define prefix for finding correct parameters
  prefix <- paste("wifi", tech, sep = "_")

  # get power
  pwr <- params$devices$call[[paste0("wifi_", tech, "_pwr")]]

  # get duty cycle
  dutycycle <- params$devices$call[[paste0("wifi_", tech, "_dutycycle")]]

  # multiply and return
  pwr_total <- pwr * dutycycle

  return(pwr_total)
}

# Mobilecall sar (WiFi call) --------------------------------------------------
mpc_sar_wifi <- function(
    tissue,
    tech,
    headp_prop,
    ear_prop,
    speaker_prop,
    params = load_params()) {
  # define prefix for finding correct tissue parameter
  prefix <- paste0("wifi_", tech)
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
# Contributions from bluetooth heapdhones =====================================
mobilecall_bt_msar <- function(
    tissue,
    params = load_params()) {

  # from bluetooth headphones
  pwr_bt <- mobilecall_bt_pwr(params = params)
  sar_bt <- mobilecall_bt_sar(tissue = tissue, params = params)
  msar_bt <- pwr_bt * sar_bt

  # from phone
  pwr_p  <- mobilecall_bt_phone_pwr(params = params)
  sar_p  <- mobilecall_bt_phone_sar(tissue = tissue, params = params)
  msar_bt_phone <- pwr_p * sar_p

  return(msar_bt + msar_bt_phone)
}

mobilecall_bt_pwr <- function(
    params = load_params()) {
  pwr <- params$devices$call$bt_pwr
  return(pwr)
}

mobilecall_bt_sar <- function(
    tissue,
    params = load_params()) {
  tissue_params <- load_tissue_params(params, "call", tissue)
  sar <- tissue_params$bt_headp_sar
  return(sar)
}

mobilecall_bt_phone_pwr <- function(
    params = load_params()) {
  pwr <- params$devices$call$bt_pwr
  return(pwr)
}

mobilecall_bt_phone_sar <- function(
    tissue,
    params = load_params()) {
  tissue_params <- load_tissue_params(params, "call", tissue)
  sar_face <- params$devices$call$headp_face_prop * tissue_params$bt_phone_face_sar
  sar_pock <- params$devices$call$headp_pock_prop * tissue_params$bt_phone_pock_sar
  sar_else <- params$devices$call$headp_else_prop * tissue_params$bt_phone_else_sar
  return(sar_face + sar_pock + sar_else)
}




