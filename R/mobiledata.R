# Calculate total RF-EMF dose (for brain and body) from mobile data

# =============================================================================
#' Calculate Dose from mobile data
#'
#' @param duration Duration of mobile data transfer in seconds
#' @param wifi_prop Proportion of time WiFi connection is used for data
#' transfer (vs mobile data)
#' @param params Parameter list
#' @returns List with brain dose and body dose in mJ/kg/day
#' @export
get_mobiledata_dose <- function(duration,
                                wifi_prop,
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
                                     data_prop = data_prop,
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
  output_list <- list("mobiledata_dose_brain" = brain_dose,
                      "mobiledata_dose_body"  = body_dose)
  return(output_list)
}

# =============================================================================
#' Calculate mobile data aggregated power
#'
#' @param wifi_prop wifi proportion
#' @param data_prop data proportion
#' @param params parameter list
#' @returns aggregated power
get_mobiledata_pwr <- function(wifi_prop,
                               data_prop,
                               params) {
  # From mobile data
  ## 3g
  data_3g    <- params$tech_3g_prop*params$tech_3g_pwr
  ## 4g
  data_4g    <- params$tech_4g_prop*params$tech_4g_pwr
  ## 5g
  data_5g    <- params$tech_5g_prop*params$tech_5g_pwr
  ## Total
  data_contr <- data_prop * sum(data_3g,
                                data_4g,
                                data_5g)

  # From WiFi
  ## 2.4 GHz
  wifi_2     <- params$wifi_2_prop * params$wifi_2_pwr
  ## 5.0 GHz
  wifi_5     <- params$wifi_5_prop * params$wifi_5_pwr
  ## Total
  wifi_contr <- wifi_prop * sum(wifi_2,
                                wifi_5)

  # Total output power
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



