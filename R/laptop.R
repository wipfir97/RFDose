# Calculate total RF-EMF dose (for brain and body) from laptop use

# =============================================================================
#' Calculate Dose from Laptop Use
#'
#' @param dur_low tba
#' @param dur_lowmed tba
#' @param dur_medhigh tba
#' @param dur_high tba
#' @param params Parameter list
#' @returns List with brain dose and body dose in mJ/kg/day
#' @export
#' @import yaml
laptop_dose <- function(
    dur_low,
    dur_lowmed,
    dur_medhigh,
    dur_high,
    params = load_params()) {

  # Check input ===============================================================
  check_duration(c(dur_low, dur_lowmed, dur_medhigh, dur_high))

  # Calculate total duration ==================================================
  duration <- sum(
    dur_low,
    dur_lowmed,
    dur_medhigh,
    dur_high)

  # Calculate time proportions of each activity ===============================
  act_pwr_props <- act_pwr_props(
    low_dur     = dur_low,
    lowmed_dur  = dur_lowmed,
    medhigh_dur = dur_medhigh,
    high_dur    = dur_high)

  # Calculate mSAR ============================================================
  ## Brain
  msar_brain <- laptop_msar(
    tissue        = "brain",
    dur_low       = dur_low,
    dur_lowmed  = dur_lowmed,
    dur_medhigh = dur_medhigh,
    dur_high      = dur_high,
    params        = params
  )
  ## Body
  msar_body <- laptop_msar(
    tissue        = "body",
    dur_low       = dur_low,
    dur_lowmed  = dur_lowmed,
    dur_medhigh = dur_medhigh,
    dur_high      = dur_high,
    params        = params
  )

  # Calculate dose ============================================================
  ## Brain
  dose_brain <- msar_brain * duration
  ## Body
  dose_body  <- msar_body * duration

  return(list("brain_lptp_dose" = dose_brain, "body_lptp_dose"  = dose_body))
}

laptop_msar <- function(
    tissue,
    dur_low,
    dur_lowmed,
    dur_medhigh,
    dur_high,
    params = load_params()) {

  bands <- c("2", "5") # 2.4 GHz, 5.0 GHz

  msar <- sum(
    vapply(
      bands,
      \(band) {

        prop <- params$global[[paste0("wifi_", band, "_prop")]]

        ## Calculate power
        pwr <- laptop_pwr(
          band          = band,
          dur_low       = dur_low,
          dur_lowmed    = dur_lowmed,
          dur_medhigh   = dur_medhigh,
          dur_high      = dur_high,
          params        = params)

        ## Calculate SAR
        sar <- laptop_sar(
          tissue        = tissue,
          band          = band,
          params        = params)

        prop*sar*pwr
      },
      numeric(1)
    )
  )
  return(msar)
}

laptop_pwr <- function(
    band,
    dur_low,
    dur_lowmed,
    dur_medhigh,
    dur_high,
    params = load_params()) {

  # Calculate time proportions of each activity ===============================
  act_props <- act_pwr_props(
    low_dur     = dur_low,
    lowmed_dur  = dur_lowmed,
    medhigh_dur = dur_medhigh,
    high_dur    = dur_high)

  activities <- c("low", "lowmed", "medhigh", "high")

  pwr <- sum(
    vapply(
      activities,
      \(activity) {
        act_prop <- act_props[[activity]]
        dc  <- params$devices$lptp[[paste("wifi", band, activity, "dutycycle", sep = "_")]]
        pwr <- params$devices$lptp[[paste("wifi", band, "pwr", sep = "_")]]
        return(act_prop*dc*pwr)
      },
      numeric(1)
    )
  )
  return(pwr)
}

laptop_sar <- function(
    tissue,
    band,
    params = load_params()) {
  tissue_params <- load_tissue_params(params, "lptp", tissue)
  ## Lap
  lap_prop <- params$devices$lptp$legs_prop
  sar_lap <- lap_prop*tissue_params[[paste("wifi", band, "legs_sar", sep = "_")]]
  ## Table
  tab_prop <- params$devices$lptp$tabl_prop
  sar_tab <- tab_prop*tissue_params[[paste("wifi", band, "tabl_sar", sep = "_")]]

  ## Combine and return
  return(sar_lap + sar_tab)
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
