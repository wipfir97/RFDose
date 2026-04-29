# Calculate total RF-EMF dose (for brain and body) from tablet use

# =============================================================================
#' Calculate Dose from Tablet Use
#'
#' @param dur_low tba
#' @param dur_lowmed tba
#' @param dur_medhigh tba
#' @param dur_high tba
#' @param params Parameter list
#' @returns List with brain dose and body dose in mJ/kg/day
#' @export
#' @import yaml
tablet_dose <- function(
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



  # Calculate mSAR ============================================================
  ## Brain
  msar_brain <- tablet_msar(
    tissue        = "brain",
    dur_low       = dur_low,
    dur_lowmed    = dur_lowmed,
    dur_medhigh   = dur_medhigh,
    dur_high      = dur_high,
    params        = params
  )
  ## Body
  msar_body <- tablet_msar(
    tissue        = "body",
    dur_low       = dur_low,
    dur_lowmed    = dur_lowmed,
    dur_medhigh   = dur_medhigh,
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
    dur_lowmed,
    dur_medhigh,
    dur_high,
    params = load_params()) {
  ## List frequency bands
  bands <- c("2", "5") # 2.4 GHz, 5.0 GHz

  msar <- sum(
    vapply(
      bands,
      \(band) {

        prop <- params$global[[paste0("wifi_", band, "_prop")]]

        ## Calculate power
        pwr <- tablet_pwr(
          band          = band,
          dur_low       = dur_low,
          dur_lowmed    = dur_lowmed,
          dur_medhigh   = dur_medhigh,
          dur_high      = dur_high,
          params        = params)

        ## Calculate SAR
        sar <- tablet_sar(
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

tablet_pwr <- function(
    band,
    dur_low,
    dur_lowmed,
    dur_medhigh,
    dur_high,
    params = load_params()) {
  # Calculate activity proportions ============================================
  act_props <- act_pwr_props(
    dur_low,
    dur_lowmed,
    dur_medhigh,
    dur_high)

  activities <- c("low", "lowmed", "medhigh", "high")

  # Calculate power ===========================================================
  pwr <- sum(
    vapply(
      activities,
      \(activity) {
        act_prop <- act_props[[activity]]
        dc <- params$devices$tblt[[paste("wifi", band, activity, "dutycycle", sep = "_")]]
        pwr <- params$devices$tblt[[paste("wifi", band, "pwr", sep = "_")]]
        return(act_prop*dc*pwr)
      },
      numeric(1)
    )
  )
  return(pwr)
}

tablet_sar <- function(
    tissue,
    band,
    params = load_params()) {
  tissue_params <- load_tissue_params(params, "tblt", tissue)
  sar <- tissue_params[[paste("tblt", band, "sar", sep ="_")]]
  return(sar)
}
