###############################################################################
# Calculate total RF-EMF dose (for brain and body) from mobile calling


###############################################################################
# Total mobile call dose ======================================================
#' Calculate RF-EMF dose from mobile calling (mobile phone and Bluethooth)
#'
#' Includes all sources: RF-EMF from phone itself, for Bluetooth connection to
#' headphones, and from headphones themselves
#'
#' @details
#' The mobile call RF-EMF dose is calculated as:
#' \deqn{Dose_{mobilecall} = Dose_{phone} + Dose_{phoneBluetooth} + Dose_{headphonesBluetooth}}
#'
#' Where:
#'
#' * \eqn{Dose_{mobilecall}} is the total dose from all mobile call activities
#' * \eqn{Dose_{phone}} is the dose from the mobile phone (no Bluetooth)
#' * \eqn{Dose_{phoneBluetooth}} is the dose from Bluetooth by the phone
#' * \eqn{Dose_{headphonesBluetooth}} is the dose from Bluetooth by the Bluetooth headphones
#'
#'
#' @param duration Duration of mobile phone call in seconds per day
#' @param ear_prop Proportion of time mobile phone is held against ear during call
#' @param headp_prop Proportion of time Bluetooth headphones are used during mobile call while phone is NOT held against ear
#' @param urbanicity Urbanicity of home / workplace
#' @param use_5g TRUE if participant uses 5G services on mobile phone, FALSE if not
#' @param travel_time Time spent commuting in seconds per day
#' @param headp_ear_num If particpant uses 1 or 2 Bluetooth headphones during mobile call
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
get_mobilecall_dose <- function(
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
    params = NULL) {
  # Load parameters if not provided ===========================================
  if (is.null(params)) {
    params <- load_params("params.yaml")}

  # Extract parameters ========================================================
  ## Extract shared (non-tissue specific) parameters for mobile calling -------
  call_params  <- load_device_params(params, "call")
  ## Extract brain-specific parameters (SAR values) for mobile calling --------
  brain_params <- load_tissue_params(params, "call", "brain")
  ## Extract body-specific parameters (SAR values) for mobile calling ---------
  body_params  <- load_tissue_params(params, "call", "body")

  # Derive additional input values ============================================
  ## Derive speaker mode use proportion ---------------------------------------
  speaker_prop <- (1-ear_prop)*(1-headp_prop)
  ## Update headp prop to scale by total mobile call duration -----------------
  headp_prop   <-(1-ear_prop)*headp_prop

  # Check input values for validity ===========================================
  check_proportions(proportions = c(ear_prop, speaker_prop, headp_prop))
  check_duration(duration       = duration)
  recode_urbanicity(urbanicity  = urbanicity)

  # Calculate doses from different sources ====================================
  ## Calculate dose from phone (no bluetooth contribution) --------------------
  ### Brain
  phone_dose_brain <- get_mobilecall_phone_dose(duration      = duration,
                                                ear_prop      = ear_prop,
                                                speaker_prop  = speaker_prop,
                                                headp_prop    = headp_prop,
                                                urbanicity    = urbanicity,
                                                use_5g        = use_5g,
                                                travel_time   = travel_time,
                                                wifi_prop_home = wifi_prop_home,
                                                wifi_prop_work = wifi_prop_work,
                                                wifi_prop_travel = wifi_prop_travel,
                                                params        = call_params,
                                                tissue_params = brain_params)

  ### Body
  phone_dose_body <- get_mobilecall_phone_dose(duration      = duration,
                                               ear_prop      = ear_prop,
                                               speaker_prop  = speaker_prop,
                                               headp_prop    = headp_prop,
                                               urbanicity    = urbanicity,
                                               use_5g        = use_5g,
                                               travel_time   = travel_time,
                                               wifi_prop_home = wifi_prop_home,
                                               wifi_prop_work = wifi_prop_work,
                                               wifi_prop_travel = wifi_prop_travel,
                                               params        = call_params,
                                               tissue_params = body_params)

  ## Calculate dose from phone (bluetooth contribution) -----------------------
  ### scaled with headphone use proportion!
  ### Brain
  phone_bt_dose_brain <- get_mobilecall_bt_phone_dose(duration = duration,
                                                      headp_prop = headp_prop,
                                                      params = call_params,
                                                      tissue_params = brain_params)
  ### Body
  phone_bt_dose_body  <- get_mobilecall_bt_phone_dose(duration = duration,
                                                      headp_prop    = headp_prop,
                                                      params        = call_params,
                                                      tissue_params = body_params)
  ## Calculate dose from bluetooth headphones ---------------------------------
  ### scaled with headphone use proportion!
  headp_bt_dose_brain <- headp_prop*get_mobilecall_bt_headp_dose(duration      = duration,
                                                                 headp_prop    = headp_prop,
                                                                 headp_ear_num = headp_ear_num,
                                                                 params        = call_params,
                                                                 tissue_params = brain_params)
  headp_bt_dose_body  <- headp_prop*get_mobilecall_bt_headp_dose(duration      = duration,
                                                                 headp_prop    = headp_prop,
                                                                 headp_ear_num = headp_ear_num,
                                                                 params        = call_params,
                                                                 tissue_params = body_params)

  # Add doses from different sources and return result ========================
  brain_dose <- sum(phone_dose_brain,
                    phone_bt_dose_brain,
                    headp_bt_dose_brain)
  body_dose  <- sum(phone_dose_body,
                    phone_bt_dose_body,
                    headp_bt_dose_body)
  output_list <- list("brain_call_dose" = brain_dose,
                      "body_call_dose"  = body_dose)
  return(output_list)
}

# Total mobile call dose from phone (no bluetooth) ============================
## Dose -----------------------------------------------------------------------
#' Calculate RF-EMF dose from mobile phone (no Bluetooth)
#'
#' Calculates the total RF-EMF dose from mobile calling from the mobile phone
#' (No Bluetooth)
#'
#' @details
#' The mobile call RF-EMF dose (no Bluetooth) is calculated as:
#' \deqn{Dose = Duration \times SAR \times Power}
#'
#' Where:
#'
#' * \eqn{Duration} is the duration of mobile phone call in seconds per day
#' * \eqn{SAR} is the specific absorption rate in W/kg/W
#' * \eqn{Power} is the output power of the mobile phone during mobile calling mW
#'
#' @param duration Duration of mobile phone call in seconds per day
#' @param ear_prop Proportion of time mobile phone is held against ear during call
#' @param speaker_prop Proportion of time speaker mode is used during mobile call while phone is NOT held against ear
#' @param headp_prop Proportion of time Bluetooth headphones are used during mobile call while phone is NOT held against ear
#' @param urbanicity Urbanicity of home / workplace
#' @param use_5g TRUE if participant uses 5G services on mobile phone, FALSE if not
#' @param travel_time Time spent commuting in seconds per day
#' @param wifi_prop_home ...
#' @param wifi_prop_work ...
#' @param wifi_prop_travel ...
#' @param params Parameter list
#' @param tissue_params Tissue-specific parameter list
#'
#' @returns RF-EMF dose in mJ/kg/day
#'
#' @seealso [get_mobilecall_phone_pwr()], [get_mobilecall_phone_sar()]
get_mobilecall_phone_dose <- function(
    duration,
    ear_prop,
    speaker_prop,
    headp_prop,
    urbanicity,
    use_5g,
    travel_time,
    wifi_prop_home,
    wifi_prop_work,
    wifi_prop_travel,
    params,
    tissue_params) {

  # Calculate power ===========================================================
  pwr <- get_mobilecall_phone_pwr(
    urbanicity       = urbanicity,
    use_5g           = use_5g,
    travel_time      = travel_time,
    wifi_prop_home   = wifi_prop_home,
    wifi_prop_work   = wifi_prop_work,
    wifi_prop_travel = wifi_prop_travel,
    params           = params)
  # Calculate SAR =============================================================
  sar <- get_mobilecall_phone_sar(
    ear_prop         = ear_prop,
    speaker_prop     = speaker_prop,
    headp_prop       = headp_prop,
    travel_time      = travel_time,
    wifi_prop_home   = wifi_prop_home,
    wifi_prop_work   = wifi_prop_work,
    wifi_prop_travel = wifi_prop_travel,
    params           = params,
    tissue_params    = tissue_params)

  # Calculate dose and return results =========================================
  dose <- duration*sar*pwr
  return(dose)
}
## Power ----------------------------------------------------------------------
#' Calculate output power from mobile phone during mobile call (no Bluetooth)
#'
#' Calculates the output power of the mobile phone during mobile calls in mW (No Bluetooth)
#'
#' @details
#' The mobile phone output power during mobile calling (no Bluetooth) is calculated as:
#' \deqn{Power = Prop_{WiFi} \times Power_{WiFi} + Prop_{Data} \times Power_{Data} + Prop_{Native} \times Power_{Native}}
#'
#' Where:
#'
#' * \eqn{Prop_{WiFi}}, \eqn{Prop_{Data}}, \eqn{Prop_{Native}} are the proportion of time mobile calls are done using WiFi, mobile data, or native network, respectively.
#' * \eqn{Power_{WiFi}}, \eqn{Prop_{Data}}, \eqn{Prop_{Native}} are the output power (mW) of the mobile phone using WiFi, mobile data, or native phone calls, respectively.
#'
#'
#' @param urbanicity Urbanicity of home / workplace
#' @param use_5g TRUE if participant uses 5G services on mobile phone, FALSE if not
#' @param travel_time Time spent commuting in seconds per day
#' @param wifi_prop_home ...
#' @param wifi_prop_work ...
#' @param wifi_prop_travel ...
#' @param params Parameter list
#'
#' @returns Mobile phone output power during mobile calling (no Bluetooth) in mW
#'
#' @seealso [get_mobilecall_phone_wifi_pwr()], [get_mobilecall_phone_data_pwr()], [get_mobilecall_phone_native_pwr()]
get_mobilecall_phone_pwr <- function(urbanicity,
                                     use_5g,
                                     travel_time,
                                     wifi_prop_home,
                                     wifi_prop_work,
                                     wifi_prop_travel,
                                     params) {
  # Calculate location proportions ============================================
  loc_props <- calculate_location_proportions(travel_time = travel_time,
                                              home_prop   = params$home_prop,
                                              outd_prop   = params$outd_prop,
                                              work_prop   = params$work_prop)

  # Calculate output power from WiFi ==========================================
  wifi_pwr <- get_mobilecall_phone_wifi_pwr(wifi_2_prop = params$wifi_2_prop,
                                            wifi_5_prop = params$wifi_5_prop,
                                            wifi_2_pwr  = params$wifi_2_pwr,
                                            wifi_5_pwr  = params$wifi_5_pwr,
                                            wifi_2_duty_cycle = params$wifi_2_duty_cycle,
                                            wifi_5_duty_cycle = params$wifi_5_duty_cycle)

  # Calculate output power from mobile data ===================================
  data_pwr <- get_mobilecall_phone_data_pwr(urbanicity  = urbanicity,
                                            use_5g      = use_5g,
                                            travel_time = travel_time,
                                            params      = params)

  # Calculate output power from native calling ================================
  native_pwr <- get_mobilecall_phone_native_pwr(urbanicity  = urbanicity,
                                                travel_time = travel_time,
                                                params      = params)

  # Calculate technology use proportion =======================================
  ## Assume that proportion of native calls is fixed and NO WiFi outdoors
  ## Data vs WiFi proportion depends on wifi_prop input variables
  wifi_prop <- (1-params$native_prop)*sum(loc_props$home*wifi_prop_home,
                                          loc_props$work*wifi_prop_work,
                                          loc_props$travel*wifi_prop_travel)
  data_prop <- 1-params$native_prop-wifi_prop


  ## Scale by technology use proportion and return output
  pwr <- sum(wifi_prop*wifi_pwr,
             data_prop*data_pwr,
             params$native_prop*native_pwr)

  return(pwr)
}

### Wifi ----
#' Calculate mobile phone output power from WiFi mobile calling (no Bluetooth)
#'
#' Calculates the output power of the mobile phone during WiFi mobile calls in mW (No Bluetooth)
#'
#' @details
#' The mobile phone output power during WiFi mobile calling (no Bluetooth) is calculated as:
#' \deqn{Power_{WiFi} = Prop_{2.4GHz} \times Power_{2.4GHz} \times DutyCycle_{2.4GHz} + Prop_{5.0GHz} \times Power_{5.0GHz} \times DutyCycle_{5.0GHz}}
#'
#' Where:
#'
#' * \eqn{Prop_{2.4GHz}}, \eqn{Prop_{5.0GHz}} are the proportion of 2.4GHz and 5.0GHz WiFi, respectively
#' * \eqn{Power_{2.4GHz}}, \eqn{Power_{5.0GHz}} are the output power of 2.4GHz and 5.0GHz WiFi calls from the mobile phone (no Bluetooth), respectively
#' * \eqn{DutyCycle_{2.4GHz}}, \eqn{DutyCycle_{5.0GHz}} are the duty cycle of 2.4GHz and 5.0GHz WiFi, respectively
#'
#' @param wifi_2_prop Proportion of 2.4GHz WiFi
#' @param wifi_5_prop Proportion of 5.0GHz WiFi
#' @param wifi_2_pwr 2.4GHz WiFi Call Power
#' @param wifi_5_pwr 5.0GHz WiFi Call Power
#' @param wifi_2_duty_cycle 2.4GHz WiFi Duty Cycle
#' @param wifi_5_duty_cycle 5.0GHz WiFi Duty Cycle
#'
#' @returns Mobile phone output power during WiFi mobile calling (no Bluetooth) in mW
get_mobilecall_phone_wifi_pwr <- function(wifi_2_prop,
                                          wifi_5_prop,
                                          wifi_2_pwr,
                                          wifi_5_pwr,
                                          wifi_2_duty_cycle,
                                          wifi_5_duty_cycle) {
  # 2.4 GHz
  pwr_2 <- wifi_2_pwr*wifi_2_duty_cycle
  # 5.0 GHz
  pwr_5 <- wifi_5_pwr*wifi_5_duty_cycle
  # Scale with 2.4/5.0 GHz proportion and return result
  pwr <- sum(pwr_2*wifi_2_prop,
             pwr_5*wifi_5_prop)
  return(pwr)
}

###############################################################################
### Data ======================================================================
#' Calculate mobile phone output power from data mobile calling (no Bluetooth)
#'
#' Calculates the output power of the mobile phone during data (3G, 4G, 5G) mobile calls in mW (No Bluetooth)
#'
#' @details
#' The mobile phone output power during data mobile calling (no Bluetooth) is calculated as:
#' \deqn{Power_{Data} = Prop_{3G} \times Power_{3G} + Prop_{4G} \times Power_{4G} + Prop_{5G} \times Power_{5G}}
#'
#' Where:
#'
#' * \eqn{Prop_{3G}}, \eqn{Prop_{4G}}, \eqn{Prop_{5G}} are the proportion of 3G, 4G and 5G during mobile calls, respectively
#' * \eqn{Power_{3G}}, \eqn{Power_{4G}}, \eqn{Power_{5G}} are the output power of the mobile phone using 3G, 4G and 5G during mobile calls, respectively
#'
#'
#' @param urbanicity Urbanicity of home / workplace
#' @param use_5g TRUE if participant uses 5G services on mobile phone, FALSE if not
#' @param travel_time Time spent commuting in seconds per day
#' @param params Parameter list
#'
#' @returns Mobile phone output power during data (3G, 4G, 5G) mobile calling (no Bluetooth) in mW
get_mobilecall_phone_data_pwr <- function(urbanicity,
                                          use_5g,
                                          travel_time,
                                          params) {

  # Recode urbanicity to binary format ========================================
  urb_list     <- recode_urbanicity(urbanicity  = urbanicity)

  # Get prop of time spent at home vs work vs outdoors based on travel time ===
  loc_props <- calculate_location_proportions(travel_time = travel_time,
                                              home_prop   = params$home_prop,
                                              outd_prop   = params$outd_prop,
                                              work_prop   = params$work_prop)

  # Calculate output power for each frequency band ============================
  pwr_3g <- calculate_mpc_data_power_by_band("3g", loc_props, urb_list, params)
  pwr_4g <- calculate_mpc_data_power_by_band("4g", loc_props, urb_list, params)
  pwr_5g <- calculate_mpc_data_power_by_band("5g", loc_props, urb_list, params)

  # Scale by frequency band use proportion and return result ==================
  total_pwr <- scale_power_by_use5g(use_5g, pwr_3g, pwr_4g, pwr_5g, params)
  return(total_pwr)
}

#' Calculate data call power by environment and tech ---------------------------
#'
#' @param band ...
#' @param urb_list ...
#' @param params ...
calculate_mpc_data_power_by_env <- function(band,
                                            urb_list,
                                            params) {
  prefix <- paste0("data_", band, "_")
  # Indoors (home + work) =====================================================
  indoor <- sum(
    params[[paste0(prefix, "sub_indo_pwr")]] * urb_list$home_suburb,
    params[[paste0(prefix, "urb_indo_pwr")]] * urb_list$home_urban,
    params[[paste0(prefix, "rur_indo_pwr")]] * urb_list$home_rural
  )

  # Outdoors ==================================================================
  outdoor <- sum(
    params[[paste0(prefix, "sub_outd_pwr")]] * urb_list$home_suburb,
    params[[paste0(prefix, "urb_outd_pwr")]] * urb_list$home_urban,
    params[[paste0(prefix, "rur_outd_pwr")]] * urb_list$home_rural
  )

  # Traveling =================================================================
  travel <- params[[paste0(prefix, "travel_pwr")]]

  # Output list ===============================================================
  result <- list(indoor = indoor, outdoor = outdoor, travel = travel)
  return(result)
}

#' Calculate data call power by band -------------------------------------------
#'
#' @param band ...
#' @param loc_props ...
#' @param urb_list ...
#' @param params ...
calculate_mpc_data_power_by_band <- function(band,
                                             loc_props,
                                             urb_list,
                                             params) {
  # Calculate power for different environments ================================
  pwr_by_env <- calculate_mpc_data_power_by_env(band, urb_list, params)

  # Get duty cycle from parameter list ========================================
  dutycycle <- params[[paste0("data_", band, "_dutycycle")]]

  # Scale power by location proportions and duty cycle ========================
  total <- sum(
    (loc_props$home + loc_props$work) * pwr_by_env$indoor,
    loc_props$outd * pwr_by_env$outdoor,
    loc_props$travel * pwr_by_env$travel
  ) * dutycycle

  return(total)
}

#' Scale band power by 5G use TRUE/FALSE ---------------------------------------
#'
#' @param use_5g ...
#' @param pwr_3g ...
#' @param pwr_4g ...
#' @param pwr_5g ...
#' @param params ...
scale_power_by_use5g <- function(use_5g,
                                 pwr_3g,
                                 pwr_4g,
                                 pwr_5g,
                                 params) {
  if (use_5g) {
    scaled_pwr <- c(
      pwr_3g * params$tech_3g_prop,
      pwr_4g * params$tech_4g_prop,
      pwr_5g * params$tech_5g_prop
    )
  } else {
    scaled_pwr <- c(
      pwr_3g * params$tech_3g_prop_5gno,
      pwr_4g * params$tech_4g_prop_5gno,
      pwr_5g * params$tech_5g_prop_5gno
    )
  }
  return(scaled_pwr)
}

###############################################################################
### Native ----
#' Calculate mobile phone output power from native mobile calling (no Bluetooth)
#'
#' Calculates the output power of the mobile phone during native mobile calls in mW (No Bluetooth)
#'
#' @details
#' The mobile phone output power during native mobile calling (no Bluetooth) is calculated as:
#' \deqn{Power_{Data} = Prop_{2G} \times Power_{2G} + Prop_{3G} \times Power_{3G} + Prop_{4G} \times Power_{4G} + Prop_{5G} \times Power_{5G}}
#'
#' Where:
#'
#' * \eqn{Prop_{2G}}, \eqn{Prop_{3G}}, \eqn{Prop_{4G}}, \eqn{Prop_{5G}} are the proportion of 2G, 3G, 4G and 5G during native mobile calls, respectively
#' * \eqn{Power_{2G}}, \eqn{Power_{3G}}, \eqn{Power_{4G}}, \eqn{Power_{5G}} are the output power of the mobile phone using 2G, 3G, 4G and 5G during native mobile calls, respectively
#'
#' @param urbanicity Urbanicity of home / workplace
#' @param travel_time Time spent commuting in seconds per day
#' @param params Parameter list
#'
#' @returns Mobile phone output power during native mobile calling (no Bluetooth) in mW
get_mobilecall_phone_native_pwr <- function(urbanicity,
                                            travel_time,
                                            params) {
  # Recode urbanicity to binary format ========================================
  urb_list     <- recode_urbanicity(urbanicity  = urbanicity)

  # Get prop of time spent at home vs work vs outdoors based on travel time ===
  loc_props <- calculate_location_proportions(travel_time = travel_time,
                                              home_prop   = params$home_prop,
                                              outd_prop   = params$outd_prop,
                                              work_prop   = params$work_prop)

  pwr_2g <- calculate_mpc_native_power_by_band("2g", loc_props, urb_list, params)
  pwr_3g <- calculate_mpc_native_power_by_band("3g", loc_props, urb_list, params)
  pwr_4g <- calculate_mpc_native_power_by_band("4g", loc_props, urb_list, params)
  pwr_5g <- calculate_mpc_native_power_by_band("5g", loc_props, urb_list, params)

  pwr <- sum(pwr_2g*params$native_2g_prop,
             pwr_3g*params$native_3g_prop,
             pwr_4g*params$native_4g_prop,
             pwr_5g*params$native_5g_prop)

  return(pwr)
}

#' Calculate native power by environment and band ------------------------------
#'
#' @param band ...
#' @param urb_list ...
#' @param params ...
calculate_mpc_native_power_by_env <- function(band,
                                              urb_list,
                                              params) {
  prefix <- paste0("native_", band, "_")

  # Indoors (home + work) =====================================================
  indoor <- sum(
    params[[paste0(prefix, "sub_indo_pwr")]] * urb_list$home_suburb,
    params[[paste0(prefix, "urb_indo_pwr")]] * urb_list$home_urban,
    params[[paste0(prefix, "rur_indo_pwr")]] * urb_list$home_rural
  )

  # Outdoors ==================================================================
  outdoor <- sum(
    params[[paste0(prefix, "sub_outd_pwr")]] * urb_list$home_suburb,
    params[[paste0(prefix, "urb_outd_pwr")]] * urb_list$home_urban,
    params[[paste0(prefix, "rur_outd_pwr")]] * urb_list$home_rural
  )

  # Traveling =================================================================
  travel <- params[[paste0(prefix, "travel_pwr")]]

  # Output list ===============================================================
  result <- list(indoor = indoor, outdoor = outdoor, travel = travel)
  return(result)
}

#' Calculate native power by band ----------------------------------------------
#'
#' @param band ...
#' @param loc_props ...
#' @param urb_list ...
#' @param params ...
calculate_mpc_native_power_by_band <- function(band,
                                               loc_props,
                                               urb_list,
                                               params) {
  # Calculate power for different environments ================================
  pwr_by_env <- calculate_mpc_native_power_by_env(band, urb_list, params)

  # Get duty cycle from parameter list ========================================
  dutycycle <- params[[paste0("native_", band, "_dutycycle")]]

  # Scale power by location proportions and duty cycle ========================
  total <- sum(
    (loc_props$home + loc_props$work) * pwr_by_env$indoor,
    loc_props$outd * pwr_by_env$outdoor,
    loc_props$travel * pwr_by_env$travel
  ) * dutycycle

  return(total)
}

## SAR ------------------------------------------------------------------------
#' Calculate SAR from mobile calling (no Bluetooth)
#'
#' Calculates the tissue-specific absorption rate (SAR) for calling with a mobile phone (no Bluetooth).
#'
#'
#' @details The SAR from mobile calling (no Bluetooth) is calculated as:
#' \deqn{SAR = Prop_{WiFi} \times SAR_{WiFi} + Prop_{Data} \times SAR_{Data} + Prop_{Native} \times SAR_{Native}}
#'
#' Where:
#'
#' * \eqn{Prop_{WiFi}}, \eqn{Prop_{Data}}, \eqn{Prop_{Native}} are the proportion of WiFi, mobile data, and native network used during mobile calls, respectively
#' * \eqn{SAR_{WiFi}}, \eqn{SAR_{Data}}, \eqn{SAR_{Native}} are the SAR values for WiFi, mobile data, and native network used during mobile calls, respectively
#'
#' @param ear_prop Proportion of time mobile phone is held against ear during call
#' @param speaker_prop Proportion of time speaker mode is used during mobile call while phone is NOT held against ear
#' @param headp_prop Proportion of time Bluetooth headphones are used during mobile call while phone is NOT held against ear
#' @param wifi_prop_home ...
#' @param wifi_prop_work ...
#' @param wifi_prop_travel ...
#' @param travel_time ...
#' @param params Parameter list
#' @param tissue_params SAR values
#'
#' @returns SAR from mobile calling (no Bluetooth) in W/kg/W
#'
#' @seealso [get_mobilecall_phone_wifi_sar()], [get_mobilecall_phone_data_sar()], [get_mobilecall_phone_native_sar()]
get_mobilecall_phone_sar <- function(ear_prop,
                                     headp_prop,
                                     speaker_prop,
                                     wifi_prop_home,
                                     wifi_prop_work,
                                     wifi_prop_travel,
                                     travel_time,
                                     params,
                                     tissue_params) {
  # Calculate location proportions ============================================
  loc_props <- calculate_location_proportions(travel_time = travel_time,
                                              home_prop   = params$home_prop,
                                              outd_prop   = params$outd_prop,
                                              work_prop   = params$work_prop)
  # Calculate SAR from WiFi ===================================================
  wifi_sar   <- get_mobilecall_phone_wifi_sar(ear_prop      = ear_prop,
                                              headp_prop    = headp_prop,
                                              speaker_prop  = speaker_prop,
                                              params        = params,
                                              tissue_params = tissue_params)

  # Calculate SAR from Data (3G, 4G, 5G) ======================================
  data_sar   <- get_mobilecall_phone_data_sar(ear_prop      = ear_prop,
                                              headp_prop    = headp_prop,
                                              speaker_prop  = speaker_prop,
                                              params        = params,
                                              tissue_params = tissue_params)

  # Calculate SAR from Native =================================================
  native_sar <- get_mobilecall_phone_native_sar(ear_prop      = ear_prop,
                                                headp_prop    = headp_prop,
                                                speaker_prop  = speaker_prop,
                                                params        = params,
                                                tissue_params = tissue_params)


  # Calculate technology use proportion =======================================
  ## Assume that proportion of native calls is fixed and NO WiFi outdoors
  ## Data vs WiFi proportion depends on wifi_prop input variables
  wifi_prop <- (1-params$native_prop)*sum(loc_props$home*wifi_prop_home,
                                          loc_props$work*wifi_prop_work,
                                          loc_props$travel*wifi_prop_travel)
  data_prop <- 1-params$native_prop-wifi_prop

  # Scale by technology use proportion and return output
  sar <- sum(wifi_prop*wifi_sar,
             data_prop*data_sar,
             params$native_prop*native_sar)

  return(sar)
}


###############################################################################
### Wifi ======================================================================
# TODO: add explanation about different phone locations in documentation
#' Calculate SAR from WiFi mobile calling (no Bluetooth)
#'
#' Calculates the tissue-specific absorption rate (SAR) for calling with a mobile phone (no Bluetooth) using WiFi.
#'
#' @details The SAR from mobile calling using WiFi is calculated as:
#' \deqn{SAR_{WiFi} = Prop_{2.4GHz} \times SAR_{2.4GHz} + Prop_{5.0GHz} \times SAR_{5.0GHz}}
#'
#' Where:
#'
#' * \eqn{Prop_{2.4GHz}}, \eqn{Prop_{5.0GHz}} are the proportion of 2.4GHz and 5.0GHz WiFi, respectively
#' * \eqn{SAR_{2.4GHz}}, \eqn{SAR_{5.0GHz}} are the SAR values from 2.4GHz and 5.0GHz WiFi calls from the mobile phone (no Bluetooth), respectively
#'
#' @param ear_prop Proportion of time mobile phone is held against ear during call
#' @param speaker_prop Proportion of time speaker mode is used during mobile call while phone is NOT held against ear
#' @param headp_prop Proportion of time Bluetooth headphones are used during mobile call while phone is NOT held against ear
#' @param params Parameter list
#' @param tissue_params Tissue parameter list
#'
#' @returns SAR value from mobile phone during WiFi calls in W/kg/W
get_mobilecall_phone_wifi_sar <- function(ear_prop,
                                          headp_prop,
                                          speaker_prop,
                                          params,
                                          tissue_params) {
  # 2.4 GHz ===================================================================
  wifi_2 <- calculate_wifi_band_total_sar(
    band          = "2",
    ear_prop      = ear_prop,
    headp_prop    = headp_prop,
    speaker_prop  = speaker_prop,
    params        = params,
    tissue_params = tissue_params
  )

  # 5.0 GHz ===================================================================
  wifi_5 <- calculate_wifi_band_total_sar(
    band          = "5",
    ear_prop      = ear_prop,
    headp_prop    = headp_prop,
    speaker_prop  = speaker_prop,
    params        = params,
    tissue_params = tissue_params
  )

  # Combine both bands weighted by usage proportion ===========================
  sar <- params$wifi_2_prop * wifi_2 + params$wifi_5_prop * wifi_5
  return(sar)
}

# WiFi SAR per frequency band -------------------------------------------------
#' Calculate the SAR from WiFi for a specific frequency band (2.4 GHz or 5.0 GHz)
#'
#' @param band frequency band ("2" for 2.4GHz, "5" for 5.0GHz)
#' @param ear_prop ...
#' @param headp_prop ...
#' @param speaker_prop ...
#' @param params ...
#' @param tissue_params ...
calculate_wifi_band_total_sar <- function(band,
                                          ear_prop,
                                          headp_prop,
                                          speaker_prop,
                                          params,
                                          tissue_params) {

  # Calculate SAR for each phone position =====================================
  ear_sar      <- tissue_params[[paste0("wifi_", band, "_ear_sar")]]
  headp_sar    <- calculate_wifi_band_headphone_sar(band, params, tissue_params)
  speaker_sar  <- tissue_params[[paste0("wifi_", band, "_speaker_sar")]]

  # Scale by proportion of each phone position and return result ==============
  sar <- ear_prop * ear_sar + headp_prop * headp_sar + speaker_prop * speaker_sar
  return(sar)
}

# WiFi SAR for headphone per frequency band and phone position ----------------
#' Calculate WiFi SAR from phone while used with headphones for a specific frequency band and phone position
#'
#' @param band frequency band ("2" for 2.4GHz, "5" for 5.0GHz)
#' @param params ...
#' @param tissue_params ...
calculate_wifi_band_headphone_sar <- function(band,
                                              params,
                                              tissue_params) {
  prefix <- paste0("wifi_", band, "_headp_")

  sar <- sum(
    params$headp_face_prop * tissue_params[[paste0(prefix, "face_sar")]],
    params$headp_pock_prop * tissue_params[[paste0(prefix, "pock_sar")]],
    params$headp_else_prop * tissue_params[[paste0(prefix, "else_sar")]]
  )
  return(sar)
}

###############################################################################
### Data ======================================================================
# TODO: adapt this for 5G use variable?
#' Calculate SAR from data mobile calling (no Bluetooth)
#'
#' Calculates the tissue-specific absorption rate (SAR) for calling with a mobile phone (no Bluetooth) using mobile data (3G, 4G, 5G).
#'
#' @details The SAR from mobile calling using data is calculated as:
#' \deqn{SAR_{Data} = Prop_{Ear} \times SAR_{Ear} + Prop_{Speaker} \times SAR_{Speaker} + Prop_{Headphones} \times SAR_{Headphones}}
#'
#' Where:
#'
#' * \eqn{Prop_{Ear}}, \eqn{Prop_{Speaker}}, \eqn{Prop_{Headphones}} are the proportion of time phone is held against ear, used in speaker mode, and used with headphones, respectively
#' * \eqn{SAR_{Ear}}, \eqn{SAR_{Speaker}}, \eqn{SAR_{Headphones}} are the SAR values from holding phone to ear, using it in speaker mode, and using it with headphones, respectively
#'
#' @param ear_prop Proportion of time mobile phone is held against ear during call
#' @param speaker_prop Proportion of time speaker mode is used during mobile call while phone is NOT held against ear
#' @param headp_prop Proportion of time Bluetooth headphones are used during mobile call while phone is NOT held against ear
#' @param params Parameter list
#' @param tissue_params Tissue parameter list
#'
#' @returns SAR value from mobile phone during data (3G, 4G, 5G) calls in W/kg/W
get_mobilecall_phone_data_sar <- function(ear_prop,
                                          headp_prop,
                                          speaker_prop,
                                          params,
                                          tissue_params) {
  # Calculate for each position ===============================================
  ear_sar     <- tissue_params$data_ear_sar
  headp_sar   <- calculate_data_headphone_sar(params, tissue_params)
  speaker_sar <- tissue_params$data_speaker_sar

  ## Scale by phone use mode ==================================================
  sar <- sum(ear_prop*ear_sar,
             headp_prop*headp_sar,
             speaker_prop*speaker_sar)
  return(sar)
}

# Data sar for headphone position ---------------------------------------------
#' Calculates Data SAR for headphone positin
#'
#' @param params ...
#' @param tissue_params ...
calculate_data_headphone_sar <- function(params, tissue_params) {
  sum(
    params$headp_face_prop * tissue_params$data_headp_face_sar,
    params$headp_pock_prop * tissue_params$data_headp_pock_sar,
    params$headp_else_prop * tissue_params$data_headp_else_sar
  )
}

###############################################################################
### Native ====================================================================
#' Calculate SAR from native mobile calling (no Bluetooth)
#'
#' Calculates the tissue-specific absorption rate (SAR) for calling with a mobile phone (no Bluetooth) using native network.
#'
#' @details The SAR from native mobile calling is calculated as:
#' \deqn{SAR_{Native} = Prop_{Ear} \times SAR_{Ear} + Prop_{Speaker} \times SAR_{Speaker} + Prop_{Headphones} \times SAR_{Headphones}}
#'
#' Where:
#'
#' * \eqn{Prop_{Ear}}, \eqn{Prop_{Speaker}}, \eqn{Prop_{Headphones}} are the proportion of time phone is held against ear, used in speaker mode, and used with headphones, respectively
#' * \eqn{SAR_{Ear}}, \eqn{SAR_{Speaker}}, \eqn{SAR_{Headphones}} are the SAR values from holding phone to ear, using it in speaker mode, and using it with headphones, respectively
#'
#' @param ear_prop Proportion of time mobile phone is held against ear during call
#' @param speaker_prop Proportion of time speaker mode is used during mobile call while phone is NOT held against ear
#' @param headp_prop Proportion of time Bluetooth headphones are used during mobile call while phone is NOT held against ear
#' @param params Parameter list
#' @param tissue_params Tissue parameter list
#'
#' @returns SAR value from mobile phone during native calls in W/kg/W
get_mobilecall_phone_native_sar <- function(ear_prop,
                                            headp_prop,
                                            speaker_prop,
                                            params,
                                            tissue_params) {
  ear_sar     <- tissue_params$native_ear_sar
  headp_sar   <- calculate_native_headphone_sar(params, tissue_params)
  speaker_sar <- tissue_params$native_speaker_sar

  ## Scale by phone use mode -------------------------------------------------
  sar <- sum(ear_prop*ear_sar,
             headp_prop*headp_sar,
             speaker_prop*speaker_sar)
  return(sar)
}

# Native sar for headphone position -------------------------------------------
#' Calculates Native SAR for headphone position
#'
#' @param params ...
#' @param tissue_params ...
calculate_native_headphone_sar <- function(params, tissue_params) {
  sum(
    params$headp_face_prop * tissue_params$native_headp_face_sar,
    params$headp_pock_prop * tissue_params$native_headp_pock_sar,
    params$headp_else_prop * tissue_params$native_headp_else_sar
  )
}


###############################################################################
# Total mobile call dose from phone (bluetooth) ===============================
## Dose -----------------------------------------------------------------------
#' Calculate RF-EMF dose from mobile calling using Bluetooth headphones (phone contribution)
#'
#' Calculates the RF-EMF dose from mobile calling using Bluetooth headphones (phone contribution).
#'
#' @details The dose is calculated as:
#' \deqn{Dose = Duration \times Power \times SAR}
#'
#' Where:
#'
#' * \eqn{Duration} is the duration of mobile phone call in seconds per day
#' * \eqn{SAR} is the specific absorption rate from Bluetooth in W/kg/W
#' * \eqn{Power} is the Bluetooth output power of the mobile phone during mobile calling mW
#'
#' @param duration Duration of mobile phone call in seconds per day
#' @param headp_prop Proportion of time Bluetooth headphones are used during mobile call
#' @param params Parameter list
#' @param tissue_params Tissue parameter list
#'
#' @returns Dose from mobile calling using Bluetooth headphones in mJ/kg/day (phone contribution)
#'
#' @seealso [get_mobilecall_bt_headp_dose()], [get_mobilecall_bt_phone_pwr()], [get_mobilecall_bt_phone_sar()]
get_mobilecall_bt_phone_dose <- function(duration,
                                         headp_prop,
                                         params,
                                         tissue_params) {
  # calculate power
  pwr <- get_mobilecall_bt_phone_pwr(params = params)
  # calculate sar
  sar <- get_mobilecall_bt_phone_sar(params = params,
                                     tissue_params = tissue_params)

  # calculate dose and return result
  dose <- headp_prop*duration*pwr*sar
  return(dose)
}

## Power ----------------------------------------------------------------------
# TODO: this is a placeholder function in case future calculations are more complicated
#' Calculate output power from mobile calling using Bluetooth headphones (phone contribution)
#'
#' Calculates the output power from mobile calling using Bluetooth headphones (phone Bluetooth contribution).
#'
#' @details In this version, this function serves as a placeholder and simply fetches the corresponding parameter from the parameter list.
#'
#' @param params Parameter list
#'
#' @returns Output power from mobile phone (Bluetooth contribution) during mobile phone call in mW
get_mobilecall_bt_phone_pwr <- function(params) {
  pwr <- params$headp_phone_bt_pwr
  return(pwr)
}

## SAR ------------------------------------------------------------------------
#' Calculate SAR from mobile calling using Bluetooth headphones (phone contribution)
#'
#' Calculates the specific absorption rate from mobile calling using Bluetooth headphones (phone contribution).
#'
#' @param params Parameter list
#' @param tissue_params Tissue parameter list
#'
#' @returns SAR from mobile calling using Bluetooth headphones in W/kg/W (phone contribution)
get_mobilecall_bt_phone_sar <- function(params,
                                        tissue_params) {
  # Phone in front of face
  sar_face <- tissue_params$bt_phone_face_sar
  # Phone in pocket
  sar_pock <- tissue_params$bt_phone_pock_sar
  # Phone elsewhere
  sar_else <- tissue_params$bt_phone_else_sar

  # Scale by position and return result
  sar <- sum(params$headp_face_prop*sar_face,
             params$headp_pock_prop*sar_pock,
             params$headp_else_prop*sar_else)
  return(sar)
}


# Total mobile call dose from bluetooth headphones ============================
## Dose -----------------------------------------------------------------------
#' Calculate RF-EMF dose from mobile calling using Bluetooth headphones (headphone contribution)
#'
#' Calculates the RF-EMF dose from mobile calling using Bluetooth headphones (headphone contribution).
#'
#' @details The dose is calculated as:
#' \deqn{Dose = Duration \times Power \times SAR \times headp_prop \times headp_ear_num}
#'
#' Where:
#'
#' * \eqn{Duration} is the duration of mobile phone call in seconds per day
#' * \eqn{SAR} is the specific absorption rate from Bluetooth in W/kg/W
#' * \eqn{Power} is the Bluetooth output power of the mobile phone during mobile calling mW
#' * \eqn{headp_prop} is the proportion of time Bluetooth headphones are used during mobile calls
#' * \eqn{headp_ear_num} is the number of Bluetooth headphones (1 or 2) used during mobile calls
#'
#' @param duration Duration of mobile phone call in seconds per day
#' @param headp_prop Proportion of time Bluetooth headphones are used during mobile call
#' @param headp_ear_num If particpant uses 1 or 2 Bluetooth headphones during mobile call
#' @param params Parameter list
#' @param tissue_params Tissue parameter list
#'
#' @returns Dose from mobile calling using Bluetooth headphones in mJ/kg/day (headphone contribution)
#'
#' @seealso [get_mobilecall_bt_phone_dose()], [get_mobilecall_bt_headp_pwr()], [get_mobilecall_bt_headp_sar()]
get_mobilecall_bt_headp_dose <- function(duration,
                                         headp_prop,
                                         headp_ear_num,
                                         params,
                                         tissue_params) {
  # calculate power
  pwr <- get_mobilecall_bt_headp_pwr(params = params)
  # calculate sar
  sar <- get_mobilecall_bt_headp_sar(params = params,
                                     tissue_params = tissue_params)
  # calculate dose
  dose <- duration*pwr*sar*headp_ear_num*headp_prop
  return(dose)
}
## Power ----------------------------------------------------------------------
# TODO: this is a placeholder function in case future calculations are more complicated
#' Calculate output power from mobile calling using Bluetooth headphones (headphone contribution)
#'
#' Calculates the output power from mobile calling using Bluetooth headphones (headphone Bluetooth contribution).
#'
#' @details In this version, this function serves as a placeholder and simply fetches the corresponding parameter from the parameter list.
#'
#' @param params Parameter list
#'
#' @returns Output power from mobile phone (Bluetooth contribution) during mobile phone call in mW
get_mobilecall_bt_headp_pwr <- function(params) {
  pwr <- params$headp_phone_bt_pwr
  return(pwr)
}
## SAR ------------------------------------------------------------------------
# TODO: this is a placeholder function in case future calculations are more complicated
#' Calculate SAR from mobile calling using Bluetooth headphones (headphone contribution)
#'
#' Calculates SAR from mobile calling using Bluetooth headphones (headphone Bluetooth contribution).
#'
#' @details In this version, this function serves as a placeholder and simply fetches the corresponding parameter from the parameter list.
#'
#' @param params Parameter list
#' @param tissue_params Tissue parameter list
#'
#' @returns Output power from mobile phone (Bluetooth contribution) during mobile phone call in mW
get_mobilecall_bt_headp_sar <- function(params,
                                        tissue_params) {
  sar <- tissue_params$bt_headp_sar
  return(sar)
}
