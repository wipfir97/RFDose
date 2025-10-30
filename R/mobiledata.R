# Calculate total RF-EMF dose (for brain and body) from mobile data

# =============================================================================
#' Calculate dose from using data on mobile phone (mobile data and WiFi)
#'
#' Calculates the total RF-EMF dose from data transfer using a mobile phone.
#' This includes mobile data (3G, 4G, 5G) and WiFi use.
#' It does NOT include RF-EMF exposure from voice calling, which is calculated separately.
#'
#' @details
#' The mobile data RF-EMF dose is calculated as:
#' \deqn{Dose_{mobiledata} = Duration_{mobiledata} \times Power_{mobiledata} \times SAR_{mobiledata}}
#'
#' Where:
#'
#' * \eqn{Duration_{mobiledata}} is the duration of mobile data use in seconds per day
#' * \eqn{Power_{mobiledata}} is the output power of the mobile phone during mobile data use in mW
#' * \eqn{SAR_{mobiledata}} is the specific absorption rate in W/kg/W
#'
#' @param duration_low ...
#' @param duration_lowmed ...
#' @param duration_medhigh ...
#' @param duration_high ...
#' @param use_5g TRUE if participant uses 5G services on mobile phone, FALSE if not
#' @param wifi_prop_home Proportion of time WiFi connection is used for data transfer AT HOME (vs mobile data)
#' @param wifi_prop_work Proportion of time WiFi connection is used for data transfer AT WORK/SCHOOL (vs mobile data)
#' @param wifi_prop_travel Proportion of time WiFi connection is used for data transfer WHILE COMMUTING (vs mobile data)
#' @param urbanicity Urbanicity of home / workplace
#' @param travel_time Time spent commuting in seconds per day
#' @param params Parameter list
#'
#' @returns List with two values:
#'
#' * "brain_data_dose" (brain RF-EMF dose from mobile data use in mJ/kg/day)
#' * "body_data_dose" (body RF-EMF dose from mobile data use in mJ/kg/day)
#'
#' @seealso [get_mobiledata_pwr()], [get_mobiledata_sar()], [get_mobilecall_dose()]
#' @export
get_mobiledata_dose <- function(duration_low,
                                duration_lowmed,
                                duration_medhigh,
                                duration_high,
                                use_5g,
                                wifi_prop_home,
                                wifi_prop_work,
                                wifi_prop_travel,
                                urbanicity,
                                travel_time,
                                params = NULL) {
  # Load parameters if not provided ===========================================
  params <- if (is.null(params)) {
    load_params("params.yaml")  # from inst/extdata
  }

  # Convert activity durations to proportions =================================
  act_pwr_props <- get_act_pwr_props(low_dur     = duration_low,
                                     lowmed_dur  = duration_lowmed,
                                     medhigh_dur = duration_medhigh,
                                     high_dur    = duration_high)
  # Calculate total use duration ==============================================
  duration  <- sum(duration_low, duration_lowmed, duration_medhigh, duration_high)

  # Extract parameters ========================================================
  ## Extract shared (non-tissue specific) parameters for mobile data ----------
  data_params  <- load_device_params(params, "data")

  ## Extract brain-specific parameters (SAR values) for mobile data -----------
  brain_params <- load_tissue_params(params, "data", "brain")

  ## Extract body-specific parameters (SAR values) for mobile data ------------
  body_params  <- load_tissue_params(params, "data", "body")

  ## Derive proportion spent at home vs work vs outdoors vs travelling --------
  loc_props <- calculate_location_proportions(travel_time = travel_time,
                                              home_prop   = data_params$home_prop,
                                              work_prop   = data_params$work_prop,
                                              outd_prop   = data_params$outd_prop)

  # Check input values for validity ===========================================
  check_duration(duration       = duration)
  check_proportions(proportions = as.vector(loc_props))
  check_proportions(proportions = as.vector(act_pwr_props))

  # Calculate total proportion of time being connected to WiFi ===============
  wifi_prop <- sum(loc_props$travel*wifi_prop_travel, # assumption: no WiFi outdoors
                   loc_props$home*wifi_prop_home,
                   loc_props$work*wifi_prop_work)


  # Calculate aggregated power ================================================
  aggr_pwr     <- get_mobiledata_pwr(wifi_prop_home   = wifi_prop_home,
                                     wifi_prop_work   = wifi_prop_work,
                                     wifi_prop_travel = wifi_prop_travel,
                                     use_5g        = use_5g,
                                     urbanicity    = urbanicity,
                                     travel_time   = travel_time,
                                     act_pwr_props = act_pwr_props,
                                     params        = data_params)

  # Calculate tissue-specific SAR =============================================
  ## Calculate aggregated brain SAR -------------------------------------------
  brain_sar    <- get_mobiledata_sar(wifi_prop     = wifi_prop,
                                     params        = data_params,
                                     tissue_params = brain_params)

  ## Calculate aggregated body SAR --------------------------------------------
  body_sar     <- get_mobiledata_sar(wifi_prop     = wifi_prop,
                                     params        = data_params,
                                     tissue_params = body_params)

  # Calculate tissue-specific dose ============================================
  ## Calculate brain dose -----------------------------------------------------
  brain_dose   <- duration*aggr_pwr*brain_sar

  ## Calculate body dose ------------------------------------------------------
  body_dose    <- duration*aggr_pwr*body_sar

  # Return output =============================================================
  output_list <- list("brain_data_dose" = brain_dose,
                      "body_data_dose"  = body_dose)

  return(output_list)
}

# =============================================================================
#' Calculate mobile data aggregated output power
#'
#' Calculates the output power of the mobile phone during mobile data use in mW
#'
#' @details
#' The mobile phone output power during mobile data use is calculated as:
#' \deqn{Power = Prop_{WiFi} \times Power_{WiFi} + Prop_{Data} \times Power_{Data}}
#'
#' Where:
#'
#' * \eqn{Prop_{WiFi}}, \eqn{Prop_{Data}} are the proportion of time mobile calls are done using WiFi and mobile data, respectively.
#' * \eqn{Power_{WiFi}}, \eqn{Prop_{Data}} are the output power (mW) of the mobile phone using WiFi and mobile data respectively.
#'
#' @param wifi_prop_home ...
#' @param wifi_prop_work ...
#' @param wifi_prop_travel ...
#' @param use_5g TRUE if participant uses 5G services on mobile phone, FALSE if not
#' @param urbanicity Urbanicity of home / workplace
#' @param travel_time Time spent commuting in seconds per day
#' @param act_pwr_props List with proportion of time spent in low vs low-mid vs mid-high vs high output power activities
#' @param params parameter list
#'
#' @returns Mobile phone output power during mobile data use in mW
#'
#' @seealso [get_mpd_wifi_pwr()], [get_mpd_data_pwr()]
get_mobiledata_pwr <- function(wifi_prop_home,
                               wifi_prop_work,
                               wifi_prop_travel,
                               use_5g, #new
                               act_pwr_props, #new
                               travel_time, #new
                               urbanicity, #new
                               params) {
  # Get power from data
  data_pwr <- get_mpd_data_pwr(use_5g        = use_5g,
                               urbanicity    = urbanicity,
                               travel_time   = travel_time,
                               act_pwr_props = act_pwr_props,
                               params = params)

  # Get power from wifi
  wifi_pwr <- get_mpd_wifi_pwr(act_pwr_props = act_pwr_props,
                               travel_time   = travel_time,
                               params        = params)

  pwr_home <- sum(wifi_prop_home*wifi_pwr$home,
                  (1-wifi_prop_home)*data_pwr$home)

  pwr_work <- sum(wifi_prop_work*wifi_pwr$work,
                  (1-wifi_prop_work)*data_pwr$work)

  pwr_outd <- data_pwr$outdoor

  pwr_trav <- sum(wifi_prop_travel*wifi_pwr$travel,
                  (1-wifi_prop_travel)*data_pwr$travel)

  aggr_pwr <- sum(pwr_home,
                  pwr_work,
                  pwr_outd,
                  pwr_trav)

  return(aggr_pwr)
}

# -----------------------------------------------------------------------------
#' Calculate mobile phone aggregated output power from mobile data (3G, 4G, 5G) use
#'
#' Calculates mobile phone aggregated output power from mobile data (3G, 4G, 5G) use
#'
#' @details
#' The mobile phone output power from mobile data use is calculated as:
#' \deqn{Power = Prop_{3G} \times Power_{3G} + Prop_{4G} \times Power_{4G} + Prop_{5G} \times Power_{5G}}
#'
#' Where:
#'
#' * \eqn{Prop_{3G}}, \eqn{Prop_{4G}}, \eqn{Prop_{5G}} are the proportions of 3G, 4G and 5G
#' * \eqn{Power_{3G}}, \eqn{Power_{4G}}, \eqn{Power_{5G}} are the output powers of 3G, 4G and 5G (to be refined further)
#'
#' @param use_5g TRUE if participant uses 5G, FALSE otherwise
#' @param urbanicity Urbanicity of home/work environment
#' @param act_pwr_props List with proportion of time spent in low vs low-mid vs mid-high vs high output power activities
#' @param travel_time Time spent commuting in seconds per day
#' @param params Device-specific parameter list
#'
#' @returns Output power from mobile data (3G, 4G, 5G) use on mobile phone in mW
get_mpd_data_pwr <- function(use_5g,
                             urbanicity,
                             act_pwr_props,
                             travel_time,
                             params) {
  # Recode urbanicity =========================================================
  urb_list     <- recode_urbanicity(urbanicity  = urbanicity)

  # Recode location proportions ===============================================
  loc_props <- calculate_location_proportions(travel_time = travel_time,
                                              home_prop   = params$home_prop,
                                              outd_prop   = params$outd_prop,
                                              work_prop   = params$work_prop)

  # Calculate output power from different technologies ========================
  pwr_3g <- calculate_total_power_for_tech("3g", act_pwr_props, urb_list,
                                           loc_props, params)
  pwr_4g <- calculate_total_power_for_tech("4g", act_pwr_props, urb_list,
                                           loc_props, params)
  pwr_5g <- calculate_total_power_for_tech("5g", act_pwr_props, urb_list,
                                           loc_props, params)

  # Calculate technology use proportions ======================================
  props <- calculate_data_tech_proportions(use_5g = use_5g, params = params)

  # Scale by tech props and sum for each environment ==========================
  result <- list(
    home    = sum(props$prop_3g * pwr_3g$home, props$prop_4g * pwr_4g$home, props$prop_5g * pwr_5g$home),
    work    = sum(props$prop_3g * pwr_3g$work, props$prop_4g * pwr_4g$work, props$prop_5g * pwr_5g$work),
    outdoor = sum(props$prop_3g * pwr_3g$outdoor, props$prop_4g * pwr_4g$outdoor, props$prop_5g * pwr_5g$outdoor),
    travel  = sum(props$prop_3g * pwr_3g$travel, props$prop_4g * pwr_4g$travel, props$prop_5g * pwr_5g$travel)
  )

  return(result)
}
# -----------------------------------------------------------------------------
#' Calculate weighted duty cycle
#'
#' @param act_pwr_props ...
#' @param tech "3g", "4g", or "5g"
#' @param params ...
#' @returns weighted duty cycle
calculate_weighted_duty_cycle <- function(act_pwr_props,
                                          tech,
                                          params) {
  low <- sum(
    act_pwr_props$low_prop * params[[paste0("data_", tech, "_low_ind_dutycycle")]],
    act_pwr_props$lowmed_prop * params[[paste0("data_", tech, "_lowmed_ind_dutycycle")]]
  )

  high <- sum(
    act_pwr_props$medhigh_prop * params[[paste0("data_", tech, "_medhigh_ind_dutycycle")]],
    act_pwr_props$high_prop    * params[[paste0("data_", tech, "_high_ind_dutycycle")]]
  )

  return(list(low = low, high = high))
}

# -----------------------------------------------------------------------------
#' Calculate power by environment
#'
#' @param duty_cycle ...
#' @param urb_list ...
#' @param loc_props ...
#' @param tech ...
#' @param env ...
#' @param params ...
#' @returns weighted duty cycle
calculate_power_by_env <- function(duty_cycle,
                                   urb_list,
                                   loc_props,
                                   tech,
                                   env,
                                   params) {
  suffix <- switch(env,
                   home    = "ind_pwr",
                   work    = "ind_pwr",
                   outdoor = "out_pwr",
                   travel  = "travel_pwr"
  )

  # For indoor/outdoor
  if (env != "travel") {
    low <- duty_cycle$low  * sum(
      params[[paste0("data_", tech, "_suburb_", suffix)]] * urb_list$home_suburb,
      params[[paste0("data_", tech, "_urb_", suffix)]]    * urb_list$home_urban,
      params[[paste0("data_", tech, "_rural_", suffix)]]  * urb_list$home_rural
    )
    high <- duty_cycle$high * sum(
      params[[paste0("data_", tech, "_suburb_", suffix)]] * urb_list$home_suburb,
      params[[paste0("data_", tech, "_urb_", suffix)]]    * urb_list$home_urban,
      params[[paste0("data_", tech, "_rural_", suffix)]]  * urb_list$home_rural
    )
  } else {
    low  <- duty_cycle$low  * params[[paste0("data_", tech, "_travel_pwr")]]
    high <- duty_cycle$high * params[[paste0("data_", tech, "_travel_pwr")]]
  }

  prop <- loc_props[[ifelse(env == "outdoor", "outd", env)]]
  return(sum(low, high) * prop)
}

# -----------------------------------------------------------------------------
#' Calculate total power by data technology
#'
#' @param tech ...
#' @param act_pwr_props ...
#' @param urb_list ...
#' @param loc_props ...
#' @param params ...
calculate_total_power_for_tech <- function(tech,
                                           act_pwr_props,
                                           urb_list,
                                           loc_props,
                                           params) {

  duty <- calculate_weighted_duty_cycle(act_pwr_props, tech, params)

  return(list(
    home    = calculate_power_by_env(duty, urb_list, loc_props, tech, "home", params),
    work    = calculate_power_by_env(duty, urb_list, loc_props, tech, "work", params),
    outdoor = calculate_power_by_env(duty, urb_list, loc_props, tech, "outdoor", params),
    travel  = calculate_power_by_env(duty, urb_list, loc_props, tech, "travel", params)
    )
  )
}

# -----------------------------------------------------------------------------
#' Calculate mobile phone aggregated output power from WiFi use
#'
#' Calculates mobile phone aggregated output power from WiFi use (2.4GHz, 5.0GHz)
#'
#' @details
#' The output power is calculated as:
#'
#' \deqn{Power_{WiFi} = Prop_{2.4GHz}\times Power_{2.4GHz} + Prop_{5.0GHz}\times Power_{5.0GHz}}
#'
#' Where:
#' \eqn{Prop_{2.4GHz}}, \eqn{Prop_{5.0GHz}} are the proportions of 2.4GHz vs 5.0GHz WiFi
#' \eqn{Power_{2.4GHz}}, \eqn{Power_{5.0GHz}} are the output power from 2.4GHz and 5.0GHz WiFi in mW, respectively
#'
#' @param travel_time Time spent commuting in seconds per day
#' @param act_pwr_props List with proportion of time spent in low vs low-mid vs mid-high vs high output power activities
#' @param params device-specific parameters
#'
#' @returns Output power from WiFi use on mobile phone in mW
get_mpd_wifi_pwr <- function(act_pwr_props,
                             travel_time,
                             params) {

  # Recode location proportions ===============================================
  loc_props <- calculate_location_proportions(travel_time = travel_time,
                                              home_prop   = params$home_prop,
                                              outd_prop   = params$outd_prop,
                                              work_prop   = params$work_prop)

  # 2.4 GHz ===================================================================
  ## Low output power ---------------------------------------------------------
  ### Weighted duty cycle
  wifi_2_low_dutycycle <- sum(act_pwr_props$low_prop*params$wifi_2_low_dutycycle,
                              act_pwr_props$lowmed_prop*params$wifi_2_lowmed_dutycycle)
  ### Output power
  wifi_2_low_pwr <- wifi_2_low_dutycycle * params$wifi_2_pwr

  ## High output power --------------------------------------------------------
  ### Weighted duty cycle
  wifi_2_high_dutycycle <- sum(act_pwr_props$medhigh_prop*params$wifi_2_medhigh_dutycycle,
                               act_pwr_props$high_prop*params$wifi_2_high_dutycycle)
  ### Output power
  wifi_2_high_pwr <- wifi_2_high_dutycycle * params$wifi_2_pwr

  ## High and low output power combined ---------------------------------------
  wifi_2_pwr <- wifi_2_low_pwr + wifi_2_high_pwr


  # 5.0 GHz ===================================================================
  ## Low output power ---------------------------------------------------------
  ### Weighted duty cycle
  wifi_5_low_dutycycle <- sum(act_pwr_props$low_prop*params$wifi_5_low_dutycycle,
                              act_pwr_props$lowmed_prop*params$wifi_5_lowmed_dutycycle)
  ### Output power
  wifi_5_low_pwr <- wifi_5_low_dutycycle * params$wifi_5_pwr

  ## High output power --------------------------------------------------------
  ### Weighted duty cycle
  wifi_5_high_dutycycle <- sum(act_pwr_props$medhigh_prop*params$wifi_5_medhigh_dutycycle,
                               act_pwr_props$high_prop*params$wifi_5_high_dutycycle)
  ### Output power
  wifi_5_high_pwr <- wifi_5_high_dutycycle * params$wifi_5_pwr

  ## High and low output power combined ---------------------------------------
  wifi_5_pwr <- wifi_5_low_pwr + wifi_5_high_pwr

  # 2.4 GHz and 5.0 GHz combined ==============================================
  ## Scale by 2.4GHz va 5.0 GHz proportion ------------------------------------
  wifi_pwr <- sum(params$wifi_2_prop*wifi_2_pwr,
                  params$wifi_5_prop*wifi_5_pwr)

  wifi_pwr_loc <- list("home" = wifi_pwr*loc_props$home,
                       "work" = wifi_pwr*loc_props$work,
                       "outdoor" = 0, #assumption of no WiFi use outdoors
                       "travel" = wifi_pwr*loc_props$travel)

  ## Return result ------------------------------------------------------------
  return(wifi_pwr_loc)
}


# =============================================================================
#' Calculate SAR from data use on mobile phone (mobile data and WiFi)
#'
#' Calculates specific absorption rate (SAR) from data use on mobile phone (mobile data and WiFi)
#'
#' @details
#' The SAR is calculated as follows:
#' \deqn{SAR = Prop_{WiFi}\times SAR_{WiFi} + Prop_{Data}\times SAR_{data}}
#'
#' Where:
#' \eqn{Prop_{WiFi}}, \eqn{Prop_{Data}} are the WiFi and data use proportions
#' \eqn{SAR_{WiFi}}, \eqn{SAR_{Data}} are the SAR values from WiFi and from data
#'
#' @param wifi_prop Proportion of time WiFi connection is used for data transfer (vs mobile data)
#' @param params Parameter list
#' @param tissue_params Tissue-specific parameters (SAR-values)
get_mobiledata_sar <- function(wifi_prop,
                               params,
                               tissue_params) {
  # From mobile data ==========================================================
  data_contr <- (1-wifi_prop) * tissue_params$data_face_sar

  # From WiFi =================================================================
  ## 2.4 GHz ------------------------------------------------------------------
  wifi_2     <- params$wifi_2_prop * tissue_params$wifi_2_face_sar
  ## 5.0 GHz ------------------------------------------------------------------
  wifi_5     <- params$wifi_5_prop * tissue_params$wifi_5_face_sar
  ## Total --------------------------------------------------------------------
  wifi_contr <- wifi_prop * sum(wifi_2, wifi_5)

  # Aggregated SAR ============================================================
  aggr_sar <- sum(data_contr, wifi_contr)
  return(aggr_sar)
}



