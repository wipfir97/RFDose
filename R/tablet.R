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
tablet_dose <- function(
    dur_low,
    dur_lowtomed,
    dur_medtohigh,
    dur_high,
    params = load_params()) {

  # Check input ===============================================================
  check_duration(c(dur_low, dur_lowtomed, dur_medtohigh, dur_high))

  # Calculate total duration ==================================================
  duration <- sum(
    dur_low,
    dur_lowtomed,
    dur_medtohigh,
    dur_high)

  # Calculate time proportions of each activity ===============================
  act_pwr_props <- act_pwr_props(
    low_dur     = dur_low,
    lowmed_dur  = dur_lowtomed,
    medhigh_dur = dur_medtohigh,
    high_dur    = dur_high)

  # Calculate mSAR ============================================================
  ## Brain
  msar_brain <- tablet_msar(
    tissue        = "brain",
    dur_low       = dur_low,
    dur_lowtomed  = dur_lowtomed,
    dur_medtohigh = dur_medtohigh,
    dur_high      = dur_high,
    params        = params
  )
  ## Body
  msar_body <- tablet_msar(
    tissue        = "body",
    dur_low       = dur_low,
    dur_lowtomed  = dur_lowtomed,
    dur_medtohigh = dur_medtohigh,
    dur_high      = dur_high,
    params        = params
  )

  # Calculate dose ============================================================
  ## Brain
  dose_brain <- msar_brain * duration
  ## Body
  dose_body  <- msar_body * duration

  return(list("brain_tblt_dose" = dose_brain, "body_tblt_dose"  = dose_body))
}

tablet_msar <- function(
    tissue,
    dur_low,
    dur_lowtomed,
    dur_medtohigh,
    dur_high,
    params = load_params()) {
  return(NA)
}

tablet_pwr <- function(
    dur_low,
    dur_lowtomed,
    dur_medtohigh,
    dur_high,
    params = load_params()) {
  return(NA)
}

tablet_sar <- function(
    tissue,
    dur_low,
    dur_lowtomed,
    dur_medtohigh,
    dur_high,
    params = load_params()) {
  return(NA)
}

# =============================================================================
#' Calculate Tablet Aggregated Power
#'
#' @param act_pwr_props descr
#' @param params descr
#' @returns Aggregated tablet power
get_tablet_pwr <- function(
    act_pwr_props,
    params) {
  # Calculate power for 2.4 GHz ===============================================
  ## Weighted duty cycles -----------------------------------------------------
  ### Low output power activities
  tblt_2_low_dutycycle   <- sum(
    act_pwr_props$low_prop*params$wifi_2_low_dutycycle,
    act_pwr_props$lowmed_prop*params$wifi_2_lowmed_dutycycle)
  ### High output power activities
  tblt_2_high_dutycycle  <- sum(
    act_pwr_props$medhigh_prop*params$wifi_2_medhigh_dutycycle,
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
  tblt_5_low_dutycycle   <- sum(
    act_pwr_props$low_prop*params$wifi_5_low_dutycycle,
    act_pwr_props$lowmed_prop*params$wifi_5_lowmed_dutycycle)
  ### High output power activities
  tblt_5_high_dutycycle  <- sum(
    act_pwr_props$medhigh_prop*params$wifi_5_medhigh_dutycycle,
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
get_tablet_sar <- function(
    params,
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
