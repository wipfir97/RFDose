# Calculate total RF-EMF dose (for brain and body) from mobile data

# =============================================================================
#' Calculate Dose from mobile data
#'
#' @param duration Duration of mobile data transfer in seconds
#' @param use_5g If participant uses 5G or not
#' @param wifi_prop Proportion of time WiFi connection is used for data
#' transfer (vs mobile data)
#' @param urbanicity urbanicity
#' @param act_pwr_props activity power proportions
#' @param travel_time travel time
#' @param high_pwr_prop Proportion of time spent on high data transfer activities
#' @param params Parameter list
#' @returns List with brain dose and body dose in mJ/kg/day
#' @export
get_mobiledata_dose <- function(duration,
                                use_5g,
                                wifi_prop,
                                urbanicity,
                                act_pwr_props,
                                travel_time,
                                high_pwr_prop,
                                params) {
  # Extract parameters ========================================================
  ## Extract shared (non-tissue specific) parameters for mobile data ----------
  data_params  <- load_device_params(params, "data")

  ## Extract brain-specific parameters (SAR values) for mobile data -----------
  brain_params <- load_tissue_params(params, "data", "brain")

  ## Extract body-specific parameters (SAR values) for mobile data ------------
  body_params  <- load_tissue_params(params, "data", "body")

  ## Derive phone wifi/data proportions ---------------------------------------
  data_prop    <- 1 - wifi_prop

  ## Derive proportion spent at home vs work vs outdoors vs travelling --------
  loc_props <- calculate_location_proportions(travel_time = travel_time,
                                              home_prop   = params$home_prop,
                                              work_prop   = params$work_prop,
                                              outd_prop   = params$outd_prop)

  print(loc_props)
  print(act_pwr_props)
  # Check input values for validity ===========================================
  check_proportions(proportions = c(wifi_prop, data_prop))
  check_duration(duration       = duration)

  # Calculate aggregated power ================================================
  aggr_pwr     <- get_mobiledata_pwr(wifi_prop     = wifi_prop,
                                     use_5g        = use_5g,
                                     urbanicity    = urbanicity,
                                     loc_props     = loc_props,
                                     act_pwr_props = act_pwr_props,
                                     data_prop     = data_prop,
                                     high_pwr_prop = high_pwr_prop,
                                     params        = data_params)

  # Calculate tissue-specific SAR =============================================
  ## Calculate aggregated brain SAR -------------------------------------------
  brain_sar    <- get_mobiledata_sar(wifi_prop = wifi_prop,
                                     data_prop = data_prop,
                                     params    = data_params,
                                     tissue_params = brain_params)

  ## Calculate aggregated body SAR --------------------------------------------
  body_sar     <- get_mobiledata_sar(wifi_prop = wifi_prop,
                                     data_prop = data_prop,
                                     params    = data_params,
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
#' Calculate mobile data aggregated power
#'
#' @param wifi_prop wifi proportion
#' @param use_5g ...
#' @param urbanicity ...
#' @param data_prop data proportion
#' @param loc_props ....
#' @param act_pwr_props ....
#' @param high_pwr_prop Proportion of time spent on high data transfer activities
#' @param params parameter list
#' @returns aggregated power
get_mobiledata_pwr <- function(wifi_prop,
                               use_5g, #new
                               act_pwr_props, #new
                               loc_props, #new
                               data_prop, #deprecated
                               high_pwr_prop, #deprecated
                               urbanicity, #new
                               params) {
  # NEW CODE IN DEVELOPMENT ===================================================
  # Get power from data
  data_pwr <- get_mpd_data_pwr(use_5g = use_5g,
                               urbanicity = urbanicity,
                               act_pwr_props = act_pwr_props,
                               loc_props = loc_props,
                               params = params)
  # Get power from wifi
  wifi_pwr <- get_mpd_wifi_pwr(params)
  # scale by wifi vs data use and return result
  aggr_pwr <- wifi_prop*wifi_pwr + (1-wifi_prop)*data_pwr
  # return(aggr_pwr)

  # OLD CODE below - Get low power proportion =================================
  low_pwr_prop <- 1-high_pwr_prop
  check_proportions(high_pwr_prop)
  # From mobile data ==========================================================
  # TODO: write separate function for mobile data contribution
  ## 3g -----------------------------------------------------------------------
  ### High data transfer ----
  #### Home/work (indoor)
  data_3g_high_indo  <- (params$home_prop+params$work_prop)*params$data_3g_high_ind_pwr
  #### Outdoors
  data_3g_high_outd  <- params$outdoor_prop*params$data_3g_high_otd_pwr
  #### Transport
  data_3g_high_trans <- params$travel_prop*params$data_3g_high_tra_pwr
  #### All locations
  data_3g_high <- high_pwr_prop*sum(data_3g_high_indo,
                                    data_3g_high_outd,
                                    data_3g_high_trans)
  ### Low data transfer ----
  #### Home/work
  data_3g_low_indo  <- (params$home_prop+params$work_prop)*params$data_3g_low_ind_pwr
  #### Outdoors
  data_3g_low_outd  <- params$outdoor_prop*params$data_3g_low_otd_pwr
  #### Transport
  data_3g_low_trans <- params$travel_prop*params$data_3g_low_tra_pwr
  #### All locations
  data_3g_low <- low_pwr_prop*sum(data_3g_low_indo,
                                  data_3g_low_outd,
                                  data_3g_low_trans)
  ### Total 3g ----
  data_3g <- sum(data_3g_high, data_3g_low)

  ## 4g -----------------------------------------------------------------------
  ### High data transfer ----
  #### Home/work (indoor)
  data_4g_high_indo  <- (params$home_prop+params$work_prop)*params$data_4g_high_ind_pwr
  #### Outdoors
  data_4g_high_outd  <- params$outdoor_prop*params$data_4g_high_otd_pwr
  #### Transport
  data_4g_high_trans <- params$travel_prop*params$data_4g_high_tra_pwr
  #### All locations
  data_4g_high <- high_pwr_prop*sum(data_4g_high_indo,
                                    data_4g_high_outd,
                                    data_4g_high_trans)
  ### Low data transfer ----
  #### Home/work
  data_4g_low_indo  <- (params$home_prop+params$work_prop)*params$data_4g_low_ind_pwr
  #### Outdoors
  data_4g_low_outd  <- params$outdoor_prop*params$data_4g_low_otd_pwr
  #### Transport
  data_4g_low_trans <- params$travel_prop*params$data_4g_low_tra_pwr
  #### All locations
  data_4g_low <- low_pwr_prop*sum(data_4g_low_indo,
                                  data_4g_low_outd,
                                  data_4g_low_trans)
  ### Total 4g ----
  data_4g <- sum(data_4g_high, data_4g_low)

  ## 5g -----------------------------------------------------------------------
  ### High data transfer ----
  #### Home/work (indoor)
  data_5g_high_indo  <- (params$home_prop+params$work_prop)*params$data_5g_high_ind_pwr
  #### Outdoors
  data_5g_high_outd  <- params$outdoor_prop*params$data_5g_high_otd_pwr
  #### Transport
  data_5g_high_trans <- params$travel_prop*params$data_5g_high_tra_pwr
  #### All locations
  data_5g_high <- high_pwr_prop*sum(data_5g_high_indo,
                                    data_5g_high_outd,
                                    data_5g_high_trans)
  ### Low data transfer ----
  #### Home/work
  data_5g_low_indo  <- (params$home_prop+params$work_prop)*params$data_5g_low_ind_pwr
  #### Outdoors
  data_5g_low_outd  <- params$outdoor_prop*params$data_5g_low_otd_pwr
  #### Transport
  data_5g_low_trans <- params$travel_prop*params$data_5g_low_tra_pwr
  #### All locations
  data_5g_low <- low_pwr_prop*sum(data_5g_low_indo,
                                  data_5g_low_outd,
                                  data_5g_low_trans)
  ### Total 5g ----
  data_5g <- sum(data_5g_high, data_5g_low)

  ## Scale by 3G/4G/5G proportions for 5G users or 5G non-users
  if (use_5g) {
    data_3g_scaled <- data_3g*params$tech_3g_prop
    data_4g_scaled <- data_4g*params$tech_4g_prop
    data_5g_scaled <- data_5g*params$tech_5g_prop
  } else {
    data_3g_scaled <- data_3g*params$tech_3g_prop_5gno
    data_4g_scaled <- data_4g*params$tech_4g_prop_5gno
    data_5g_scaled <- data_5g*params$tech_5g_prop_5gno
  }


  ## Total mobile data --------------------------------------------------------
  data_contr <- data_prop * sum(data_3g_scaled,
                                data_4g_scaled,
                                data_5g_scaled)

  # From WiFi =================================================================
  ## 2.4 GHz ------------------------------------------------------------------
  ### High data transfer
  wifi_2_high <- high_pwr_prop*params$wifi_2_high_pwr*params$wifi_2_high_dutycycle
  ### Low data transfer
  wifi_2_low  <- low_pwr_prop*params$wifi_2_low_pwr*params$wifi_2_low_dutycycle
  ### Total 2.4GHz
  wifi_2      <- params$wifi_2_prop * sum(wifi_2_high, wifi_2_low)

  ## 5.0 GHz ------------------------------------------------------------------
  ### High data transfer
  wifi_5_high <- high_pwr_prop*params$wifi_5_high_pwr*params$wifi_5_high_dutycycle
  ### Low data transfer
  wifi_5_low  <- low_pwr_prop*params$wifi_5_low_pwr*params$wifi_5_low_dutycycle
  ### Total 5.0GHz
  wifi_5      <- params$wifi_5_prop * sum(wifi_5_high, wifi_5_low)

  ## Total WiFi ---------------------------------------------------------------
  wifi_contr <- wifi_prop * sum(wifi_2,
                                wifi_5)

  # Total mobile data =========================================================
  aggr_pwr <- sum(data_contr, wifi_contr)

  return(aggr_pwr)
}

# -----------------------------------------------------------------------------
#' Calculate mpd power from data
#'
#' @param use_5g TRUE if participant uses 5G, FALSE otherwise
#' @param urbanicity urbanicity of home/work environment
#' @param act_pwr_props ...
#' @param loc_props location proportions
#' @param params device-specific parameters
#' @returns pwr
get_mpd_data_pwr <- function(use_5g,
                             urbanicity,
                             act_pwr_props,
                             loc_props,
                             params) {
  # 3G
  data_3g_pwr <- get_mpd_data_3g_pwr(params)
  # 4G
  data_4g_pwr <- get_mpd_data_4g_pwr(params)
  # 5G
  data_5g_pwr <- get_mpd_data_5g_pwr(params)
  # Scale by use proportions depending on 5G use variable
  props <- calculate_data_tech_proportions(use_5g = use_5g,
                                           params = params)
  data_pwr <- sum(props$prop_3g*data_3g_pwr,
                  props$prop_4g*data_4g_pwr,
                  props$prop_5g*data_5g_pwr)

  return(data_pwr)
}

# -----------------------------------------------------------------------------
#' Calculate mpd power from wifi
#'
#' @param params device-specific parameters
#' @returns pwr
get_mpd_wifi_pwr <- function(params) {
  # 2.4GHz
  wifi_2_pwr <- get_mpd_wifi_2_pwr(params)
  # 5.0GHz
  wifi_5_pwr <- get_mpd_wifi_5_pwr(params)
  # Scale by use proportions and add
  wifi_pwr <- sum(params$wifi_2_prop*wifi_2_pwr,
                  params$wifi_5_prop*wifi_5_pwr)
  return(wifi_pwr)
}

# -----------------------------------------------------------------------------
#' Calculate mpd power from 3G
#'
#' @param urbanicity urbanicity
#' @param loc_props loc props
#' @param act_pwr_props ...
#' @param params device-specific parameters
#' @returns pwr
get_mpd_data_3g_pwr <- function(urbanicity,
                                loc_props,
                                act_pwr_props,
                                params) {
  # High data transfer
  # Low data transfer
  return(NA)
}

# -----------------------------------------------------------------------------
#' Calculate mpd power from 4G
#'
#' @param urbanicity urbanicity
#' @param loc_props loc props
#' @param act_pwr_props ...
#' @param params device-specific parameters
#' @returns pwr
get_mpd_data_4g_pwr <- function(urbanicity,
                                loc_props,
                                act_pwr_props,
                                params) {
  return(NA)
}

# -----------------------------------------------------------------------------
#' Calculate mpd power from 5G
#'
#' @param urbanicity urbanicity
#' @param loc_props loc props
#' @param act_pwr_props ...
#' @param params device-specific parameters
#' @returns pwr
get_mpd_data_5g_pwr <- function(urbanicty,
                                loc_props,
                                act_pwr_props,
                                params) {
  return(NA)
}

# -----------------------------------------------------------------------------
#' Calculate wifi power from 2.4ghz
#'
#' @param params device-specific parameters
#' @returns pwr
get_mpd_wifi_2_pwr <- function(params) {
  return(NA)
}

# -----------------------------------------------------------------------------
#' Calculate wifi power from 5.0ghz
#'
#' @param params device-specific parameters
#' @returns pwr
get_mpd_wifi_5_pwr <- function(params) {
  return(NA)
}

# =============================================================================
#' Calculate mobile data SAR
#'
#' @param wifi_prop wifi proportion
#' @param data_prop data_proportion
#' @param params parameter list
#' @param tissue_params tissue-specific parameters (SAR-values)
get_mobiledata_sar <- function(wifi_prop,
                               data_prop,
                               params,
                               tissue_params) {
  # From mobile data
  data_contr <- data_prop * tissue_params$data_face_sar

  # From WiFi
  ## 2.4 GHz
  wifi_2     <- params$wifi_2_prop * tissue_params$wifi_2_face_sar
  ## 5.0 GHz
  wifi_5     <- params$wifi_5_prop * tissue_params$wifi_5_face_sar
  ## Total
  wifi_contr <- wifi_prop * sum(wifi_2,
                                wifi_5)

  # Aggregated SAR
  aggr_sar <- sum(data_contr, wifi_contr)
  return(aggr_sar)
}



