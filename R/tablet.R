# Calculate total RF-EMF dose (for brain and body) from tablet use

# =============================================================================
#' Calculate Dose from Tablet Use
#'
#' @param dur_low tba
#' @param dur_lowtomed tba
#' @param dur_medtohigh tba
#' @param dur_high tba
#' @param params Parameter list
#' @returns List with brain dose and body dose in mJ/kg/day
#' @export
#' @import yaml
get_tablet_dose <- function(dur_low,
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

  # Calculate total duration ==================================================
  duration <- sum(dur_low,
                  dur_lowtomed,
                  dur_medtohigh,
                  dur_high)
  check_duration(duration)

  # Calculate time proportions of each activity ===============================
  act_pwr_props <- get_act_pwr_props(low_dur     = dur_low,
                                     lowmed_dur  = dur_lowtomed,
                                     medhigh_dur = dur_medtohigh,
                                     high_dur    = dur_high)


  # Extract parameters ========================================================
  ## Extract shared (non-tissue specific) parameters for laptop ---------------
  tblt_params  <- load_device_params(params, "tblt")

  ## Extract brain-specific parameters (SAR values) for laptop ----------------
  brain_params <- load_tissue_params(params, "tblt", "brain")

  ## Extract body-specific parameters (SAR values) for laptop -----------------
  body_params  <- load_tissue_params(params, "tblt", "body")


  # Calculate aggregated power ================================================
  aggr_pwr     <- get_tablet_pwr(act_pwr_props,
                                 tblt_params)


  # Calculate tissue SAR ======================================================
  ## Brain SAR ----------------------------------------------------------------
  brain_sar    <- get_tablet_sar(tblt_params, brain_params)

  ## Body SAR -----------------------------------------------------------------
  body_sar     <- get_tablet_sar(tblt_params, body_params)

  # Calculate total doses =====================================================
  ## Brain dose ---------------------------------------------------------------
  brain_dose   <- duration * aggr_pwr * brain_sar

  ## Body dose ----------------------------------------------------------------
  body_dose    <- duration * aggr_pwr * body_sar

  # Return output =============================================================
  tblt_output  <- list("brain_tblt_dose" = brain_dose,
                       "body_tblt_dose"  = body_dose)
  return(tblt_output)
}

# =============================================================================
#' Calculate Tablet Aggregated Power
#'
#' @param act_pwr_props descr
#' @param params descr
#' @returns Aggregated tablet power
get_tablet_pwr <- function(act_pwr_props,
                           params) {
  # Calculate power for 2.4 GHz ===============================================
  ## Weighted duty cycles -----------------------------------------------------
  ### Low output power activities
  tblt_2_low_dutycycle   <- sum(act_pwr_props$low_prop*params$wifi_2_low_dutycycle,
                                act_pwr_props$lowmed_prop*params$wifi_2_lowmed_dutycycle)
  ### High output power activities
  tblt_2_high_dutycycle  <- sum(act_pwr_props$medhigh_prop*params$wifi_2_medhigh_dutycycle,
                                act_pwr_props$high_prop*params$wifi_2_high_dutycycle)

  ## Output power -------------------------------------------------------------
  ### Calculate low and high output power, respectively
  tblt_2_pwr_low    <- tblt_2_low_dutycycle * params$wifi_2_pwr
  tblt_2_pwr_high   <- tblt_2_high_dutycycle * params$wifi_2_pwr
  ### Sum up low and high output power
  tblt_2_pwr <- sum(tblt_2_pwr_low, tblt_2_pwr_high)
  ### Scale output by total proportion of 2.4GHz WiFi
  tblt_2_contr  <- params$wifi_2_prop * tblt_2_pwr

  # Calculate power for 5.0 GHz ===============================================
  ## Weighted duty cycles -----------------------------------------------------
  ### Low output power activities
  tblt_5_low_dutycycle   <- sum(act_pwr_props$low_prop*params$wifi_5_low_dutycycle,
                                act_pwr_props$lowmed_prop*params$wifi_5_lowmed_dutycycle)
  ### High output power activities
  tblt_5_high_dutycycle  <- sum(act_pwr_props$medhigh_prop*params$wifi_5_medhigh_dutycycle,
                                act_pwr_props$high_prop*params$wifi_5_high_dutycycle)

  ## Output power -------------------------------------------------------------
  ### Calculate low and high output power, respectively
  tblt_5_pwr_low    <- tblt_5_low_dutycycle * params$wifi_5_pwr
  tblt_5_pwr_high   <- tblt_5_high_dutycycle * params$wifi_5_pwr
  ### Sum up low and high output power
  tblt_5_pwr <- sum(tblt_5_pwr_low, tblt_5_pwr_high)
  ### Scale output by total proportion of 5.0GHz WiFi
  tblt_5_contr  <- params$wifi_5_prop * tblt_5_pwr

  # Combine output power from 2.4 and 5.0 GHz =================================

  aggr_pwr     <- sum(tblt_2_contr, tblt_5_contr)
  # Return output
  return(aggr_pwr)
}

# =============================================================================
#' Calculate Tablet Aggregated SAR
#'
#' @param params descr
#' @param tissue_params descr
#' @returns Aggregated tablet SAR
get_tablet_sar <- function(params,
                           tissue_params) {
  # Calculate SAR from 2.4 GHz
  sar_2    <- params$wifi_2_prop * tissue_params$tblt_2_sar

  # Calculate SAR from 5.0 GHz
  sar_5    <- params$wifi_5_prop * tissue_params$tblt_5_sar

  # Combine 2.4 and 5.0 GHz
  aggr_sar <- sum(sar_2, sar_5)

  # Return output
  return(aggr_sar)
}
