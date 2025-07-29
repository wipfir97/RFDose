# Calculate total RF-EMF dose (for brain and body) from mobile data

# =============================================================================
#' Calculate Dose from mobile data
#'
#' @param duration Duration of mobile data transfer in seconds
#' @param use_5g If participant uses 5G or not
#' @param wifi_prop Proportion of time WiFi connection is used for data
#' transfer (vs mobile data)
#' @param high_pwr_prop Proportion of time spent on high data transfer activities
#' @param params Parameter list
#' @returns List with brain dose and body dose in mJ/kg/day
#' @export
get_mobiledata_dose <- function(duration,
                                use_5g,
                                wifi_prop,
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

  # Check input values for validity ===========================================
  check_proportions(proportions = c(wifi_prop, data_prop))
  check_duration(duration       = duration)

  # Calculate aggregated power ================================================
  aggr_pwr     <- get_mobiledata_pwr(wifi_prop = wifi_prop,
                                     use_5g = use_5g,
                                     data_prop = data_prop,
                                     high_pwr_prop = high_pwr_prop,
                                     params = data_params)

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
#' @param data_prop data proportion
#' @param high_pwr_prop Proportion of time spent on high data transfer activities
#' @param params parameter list
#' @returns aggregated power
get_mobiledata_pwr <- function(wifi_prop,
                               use_5g,
                               data_prop,
                               high_pwr_prop,
                               params) {
  # Get low power proportion ==================================================
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



