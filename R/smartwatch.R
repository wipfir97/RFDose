###############################################################################
# =============================================================================
smartwatch_dose <- function(
    duration_smartwatch,
    params = load_params()) {

  # From watch ================================================================
  ## Brain
  dose_brain_watch <- smartwatch_watch_dose(
    tissue              = "brain",
    duration_smartwatch = duration_smartwatch,
    params              = params
  )
  ## Body
  dose_body_watch <- smartwatch_watch_dose(
    tissue              = "body",
    duration_smartwatch = duration_smartwatch,
    params              = params
  )

  # From phone (bluetooth connection to watch) ================================
  ## Brain
  dose_brain_phone <- smartwatch_phone_dose(
    tissue              = "brain",
    duration_smartwatch = duration_smartwatch,
    params              = params
  )
  ## Body
  dose_body_phone <- smartwatch_phone_dose(
    tissue              = "body",
    duration_smartwatch = duration_smartwatch,
    params              = params
  )

  return(
    list(
      smartwatch_brain_dose = sum(dose_brain_watch, dose_brain_phone),
      smartwatch_body_dose  = sum(dose_body_watch, dose_body_phone)
    )
  )
}

smartwatch_watch_dose <- function(
    tissue,
    duration_smartwatch,
    params = load_params()) {
  # Load tissue-specific dose
  tissue_params <- load_tissue_params(params, "smartwatch", tissue)

  # Calculate active and passive use duration =================================
  mode_dur <- list(
    active = duration_smartwatch*(1/1440),
    passive = 86400 - duration_smartwatch*(1/1440))

  modes <- c("active", "passive")

  dose <- sum(
    vapply(
      modes,
      \(mode) {
        pwr <- params$devices$smartwatch[[paste("watch_pwr", mode, sep = "_")]]
        sar <- tissue_params[["watch_sar"]]
        dur <- mode_dur[[mode]]
        return(pwr*sar*dur)
      },
      numeric(1)
    )
  )
  return(dose)
}

smartwatch_phone_dose <- function(
    tissue,
    duration_smartwatch,
    params = load_params()) {
  # Load tissue specific parameters ===========================================
  tissue_params <- load_tissue_params(params, "smartwatch", tissue)
  # Output power ==============================================================
  pwr <- params$devices$smartwatch[["watch_phone_pwr"]]
  # SAR =======================================================================
  sar <- tissue_params[["watch_phone_sar"]]
  # Dose ======================================================================
  dose <- pwr*sar*duration_smartwatch
  return(dose)
}
