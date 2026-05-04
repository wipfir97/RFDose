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
