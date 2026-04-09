# Calculate total RF-EMF dose (for brain and body) from cordless calls

# =============================================================================
#' Calculate Dose from Cordless Calling
#'
#' @param duration Duration of cordless calls in seconds. >= 0 and <= 86400
#' @param ear_proportion Proportion of time cordless phone is held against ear
#' during calls. >=0 and <=1.
#' @param params Parameter list.
#' @returns List with brain dose and body dose in mJ/kg/day
#' @export
#' @import yaml
get_cordless_dose <- function(duration,
                              ear_proportion,
                              params = NULL) {


  # Load parameters if not provided ===========================================
  if (is.null(params)) {
    params <- load_params("params.yaml")}

  # Check input values ========================================================
  ## Duration
  check_duration(duration = duration)
  ## Proportion
  check_proportions(proportions = ear_proportion)

  # Extract parameters ========================================================
  ## Extract shared (non-tissue specific) parameters for wifi -----------------
  dect_params  <- load_device_params(params, "dect")

  ## Extract brain-specific parameters (SAR values) for wifi ------------------
  brain_params <- load_tissue_params(params, "dect", "brain")

  ## Extract body-specific parameters (SAR values) for wifi -------------------
  body_params  <- load_tissue_params(params, "dect", "body")


  # Calculate aggregated power ================================================
  aggr_pwr     <- get_cordless_pwr(dect_params)

  # Calculate tissue-specific SAR =============================================
  ## Brain SAR ----------------------------------------------------------------
  brain_sar    <- get_cordless_sar(ear_proportion, dect_params, brain_params)

  ## Body SAR -----------------------------------------------------------------
  body_sar     <- get_cordless_sar(ear_proportion, dect_params, body_params)

  # Calculate total doses =====================================================
  ## Calculate total brain dose -----------------------------------------------
  brain_dose   <- duration*aggr_pwr*brain_sar

  ## Calculate total body dose ------------------------------------------------
  body_dose    <- duration*aggr_pwr*body_sar

  # Return results ============================================================
  dect_output  <- list("brain_dect_dose" = brain_dose,
                       "body_dect_dose"  = body_dose)

  return(dect_output)
}


# =============================================================================
#' Calculate Aggregated Power of Cordless Phone
#'
#' @param params descr
#' @returns descr
get_cordless_pwr  <- function(params) {
  # Calculate aggregated power and return output
  aggr_pwr <- params$dect_pwr * params$dect_duty_factor
  return(aggr_pwr)
}


# =============================================================================
#' Calculate Aggregated SAR during cordless call (tissue-specific)
#'
#' @param ear_proportion Proportion of holding cordless phone against ear
#' @param params descr
#' @param tissue_params descr
#' @returns sar
#' @import yaml
get_cordless_sar  <- function(ear_proportion,
                              params,
                              tissue_params) {
  # Contribution from holding phone on ear
  ear_contr     <- ear_proportion*tissue_params$dect_ear_sar
  # Contribution from phone in speaker mode
  speaker_contr <- (1-ear_proportion)*tissue_params$dect_speaker_sar
  # Combine and return results
  aggr_sar      <- sum(ear_contr, speaker_contr)
  return(aggr_sar)
}

# -----------------------------------------------------------------------------
