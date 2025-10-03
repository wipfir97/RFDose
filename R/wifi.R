# Calculate total RF-EMF dose (for brain and body) from WiFi

# =============================================================================
#' Calculate Dose from wifi Use
#'
#' @param travel_time Daily time spent commuting (s)
#' @param wifi_prop_travel Proportion of time connected to WiFi (vs mobile data) during commute
#' @param params Parameter list
#' @returns List with brain dose and body dose in mJ/kg/day
#' @export
get_wifi_dose <- function(travel_time,
                          wifi_prop_travel,
                          params) {
  # Extract parameters ========================================================
  ## Extract shared (non-tissue specific) parameters for wifi -----------------
  wifi_params  <- load_device_params(params, "wifi")

  ## Extract brain-specific parameters (SAR values) for wifi ------------------
  brain_params <- load_tissue_params(params, "wifi", "brain")

  ## Extract body-specific parameters (SAR values) for wifi -------------------
  body_params  <- load_tissue_params(params, "wifi", "body")

  ## Derive proportion spent at home vs work vs outdoors vs travelling --------
  loc_props <- calculate_location_proportions(travel_time = travel_time,
                                              home_prop   = wifi_params$home_prop,
                                              work_prop   = wifi_params$work_prop,
                                              outd_prop   = wifi_params$outd_prop)

  # Calculate duration of exposure to WiFi router =============================
  duration     <- calculate_wifi_exposure_duration(travel_time      = travel_time,
                                                   wifi_prop_travel = wifi_prop_travel,
                                                   home_prop        = loc_props$home,
                                                   work_prop        = loc_props$work)

  # Calculate aggregated power ================================================
  aggr_pwr     <- get_wifi_pwr(params = wifi_params)

  # Calculate tissue-specific SAR =============================================
  ## Brain SAR ----------------------------------------------------------------
  brain_sar    <- get_wifi_sar(wifi_params,
                               brain_params)

  ## Body SAR -----------------------------------------------------------------
  body_sar     <- get_wifi_sar(wifi_params,
                               body_params)



  # Calculate total doses =====================================================
  # Calculate brain dose ------------------------------------------------------
  brain_dose   <- duration*aggr_pwr*brain_sar

  # Calculate body dose -------------------------------------------------------
  body_dose    <- duration*aggr_pwr*body_sar


  # Return output =============================================================
  wifi_output <- list("brain_wifi_dose" = brain_dose,
                      "body_wifi_dose"  = body_dose)

  return(wifi_output)
}

# =============================================================================
#' Calculate WiFi Aggregated Power
#'
#' @param params parameter list
#' @returns aggregated output power wifi
get_wifi_pwr <- function(params) {
  # Power for different WiFi frequencies ======================================
  ## 2.4 GHz ------------------------------------------------------------------
  wifi_2_contr <- params$wifi_2_prop * params$wifi_2_pwr

  ## 5.0 GHz ------------------------------------------------------------------
  wifi_5_contr <- params$wifi_5_prop * params$wifi_5_pwr

  # Combine frequiencies and return result ====================================
  aggr_pwr     <- sum(wifi_2_contr, wifi_5_contr)

  return(aggr_pwr)
}

# =============================================================================
#' Calculate WiFi Aggregated SAR
#'
#' @param params description
#' @param tissue_params description
#' @returns description
get_wifi_sar <- function(params, tissue_params) {
  # SAR for different WiFi frequencies ========================================
  ## 2.4 GHz ------------------------------------------------------------------
  sar_2_contr <- params$wifi_2_prop * tissue_params$wifi_2_sar

  ## 5.0 GHz ------------------------------------------------------------------
  sar_5_contr <- params$wifi_5_prop * tissue_params$wifi_5_sar


  # Calculate aggregated SAR and return output ================================
  wifi_sar <- sum(sar_2_contr, sar_5_contr)

  return(wifi_sar)
}
