# Calculate total RF-EMF dose (for brain and body) from laptop use

# =============================================================================
#' Calculate Dose from Laptop Use
#'
#' @param dur_low tba
#' @param dur_lowtomed tba
#' @param dur_medtohigh tba
#' @param dur_high tba
#' @param params Parameter list
#' @returns List with brain dose and body dose in mJ/kg/day
#' @export
#' @import yaml
get_laptop_dose <- function(dur_low,
                            dur_lowtomed,
                            dur_medtohigh,
                            dur_high,
                            params = NULL) {
  # Load parameters if not provided ===========================================
  if (is.null(params)) {
    params <- load_params("params.yaml")}

  check_duration(dur_low)
  check_duration(dur_lowtomed)
  check_duration(dur_medtohigh)
  check_duration(dur_high)

  # Calculate total use duration ==============================================
  duration <- sum(dur_low,
                  dur_lowtomed,
                  dur_medtohigh,
                  dur_high)

  # Check input values ========================================================
  check_duration(duration)

  # Calculate time proportions of each activity ===============================
  act_pwr_props <- get_act_pwr_props(low_dur     = dur_low,
                                     lowmed_dur  = dur_lowtomed,
                                     medhigh_dur = dur_medtohigh,
                                     high_dur    = dur_high)

  # Extract parameters ========================================================
  ## Extract shared (non-tissue specific) parameters for laptop ---------------
  lptp_params  <- load_device_params(params, "lptp")

  ## Extract brain-specific parameters (SAR values) for laptop ----------------
  brain_params <- load_tissue_params(params, "lptp", "brain")

  ## Extract body-specific parameters (SAR values) for laptop -----------------
  body_params  <- load_tissue_params(params, "lptp", "body")


  # Calculate aggregated power ================================================
  aggr_pwr     <- get_laptop_pwr(act_pwr_props,
                                 lptp_params)

  # Calculate tissue-specific SAR =============================================
  ## Brain SAR ----------------------------------------------------------------
  brain_sar    <- get_laptop_sar(lptp_params, brain_params)

  ## Body SAR -----------------------------------------------------------------
  body_sar     <- get_laptop_sar(lptp_params, body_params)

  # Calculate total doses =====================================================
  ## Brain dose ---------------------------------------------------------------
  brain_dose <- duration * aggr_pwr * brain_sar

  ## Body dose ----------------------------------------------------------------
  body_dose  <- duration * aggr_pwr * body_sar

  # Return output =============================================================
  lptp_output <- list("brain_lptp_dose" = brain_dose,
                      "body_lptp_dose"  = body_dose)
  return(lptp_output)
}

# =============================================================================
#' Calculate Laptop Aggregated Power
#'
#' @param act_pwr_props text
#' @param params text
#' @returns text
get_laptop_pwr <- function(act_pwr_props,
                           params) {
  # Calculate power for 2.4 GHz ===============================================
  ## Weighted duty cycles -----------------------------------------------------
  lptp_2_low_dutycycle   <- sum(act_pwr_props$low_prop*params$wifi_2_low_dutycycle,
                                act_pwr_props$lowmed_prop*params$wifi_2_lowmed_dutycycle)

  lptp_2_high_dutycycle  <- sum(act_pwr_props$medhigh_prop*params$wifi_2_medhigh_dutycycle,
                                act_pwr_props$high_prop*params$wifi_2_high_dutycycle)

  ## Output power -------------------------------------------------------------
  lptp_2_pwr_low    <- lptp_2_low_dutycycle * params$wifi_2_pwr
  lptp_2_pwr_high   <- lptp_2_high_dutycycle * params$wifi_2_pwr

  lptp_2_pwr <- sum(lptp_2_pwr_low, lptp_2_pwr_high)

  lptp_2_contr  <- params$wifi_2_prop * lptp_2_pwr

  # Calculate power for 5.0 GHz ===============================================
  ## Weighted duty cycles -----------------------------------------------------
  lptp_5_low_dutycycle     <- act_pwr_props$low_prop*params$wifi_5_low_dutycycle
  lptp_5_lowmed_dutycycle  <- act_pwr_props$lowmed_prop*params$wifi_5_lowmed_dutycycle
  lptp_5_medhigh_dutycycle <- act_pwr_props$medhigh_prop*params$wifi_5_medhigh_dutycycle
  lptp_5_high_dutycycle    <- act_pwr_props$high_prop*params$wifi_5_high_dutycycle
  ## Output power -------------------------------------------------------------
  lptp_5_pwr    <- params$wifi_5_pwr * sum(lptp_5_low_dutycycle,
                                           lptp_5_lowmed_dutycycle,
                                           lptp_5_medhigh_dutycycle,
                                           lptp_5_high_dutycycle)
  lptp_5_contr  <- params$wifi_5_prop * lptp_5_pwr

  # Combine 2.4 and 5.0 GHz
  aggr_pwr      <- sum(lptp_2_contr, lptp_5_contr)


  # Return output
  return(aggr_pwr)
}

# =============================================================================
#' Calculate Laptop Aggregated SAR
#'
#' @param params descr
#' @param tissue_params descr
#' @returns Aggregated tissue SAR from laptop use (W/kg/W)
get_laptop_sar <- function(params,
                           tissue_params) {
  # Calculate SAR for 2.4 GHz with laptop on legs
  sar_2_legs  <- params$legs_prop * tissue_params$wifi_2_legs_sar

  # Calculate SAR for 2.4 GHz with laptop on table
  sar_2_tabl  <- params$tabl_prop * tissue_params$wifi_2_tabl_sar

  # Calculate SAR for 5.0 GHz with laptop on legs
  sar_5_legs  <- params$legs_prop * tissue_params$wifi_5_legs_sar

  # Calculate SAR for 5.0 GHz with laptop on table
  sar_5_tabl  <- params$tabl_prop * tissue_params$wifi_5_tabl_sar

  # Add for legs and table for 2.4 GHz and 5.0 GHz respectively
  sar_2_contr <- params$wifi_2_prop * sum(sar_2_legs, sar_2_tabl)
  sar_5_contr <- params$wifi_5_prop * sum(sar_5_legs, sar_5_tabl)

  # Aggregate SAR for 2.4 GHz and 5.0 GHz and return output
  aggr_sar    <- sum(sar_2_contr, sar_5_contr)

  return(aggr_sar)
}
