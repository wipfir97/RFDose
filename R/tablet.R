# Calculate total RF-EMF dose (for brain and body) from tablet use

# =============================================================================
#' Calculate Dose from Tablet Use
#'
#' @param duration Duration of tablet use in seconds
#' @param params Parameter list
#' @returns List with brain dose and body dose in mJ/kg/day
#' @export
get_tablet_dose <- function(duration,
                            params) {

  # Extract parameters ========================================================
  ## Extract shared (non-tissue specific) parameters for laptop ---------------
  tblt_params  <- load_device_params(params, "tblt")

  ## Extract brain-specific parameters (SAR values) for laptop ----------------
  brain_params <- load_tissue_params(params, "tblt", "brain")

  ## Extract body-specific parameters (SAR values) for laptop -----------------
  body_params  <- load_tissue_params(params, "tblt", "body")


  # Calculate aggregated power ================================================
  aggr_pwr     <- get_tablet_pwr(tblt_params)


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
#' @param params descr
#' @returns Aggregated tablet power
get_tablet_pwr <- function(params) {

  # Calculate power for 2.4 GHz
  tblt_2_contr <- params$wifi_2_prop * params$wifi_2_pwr

  # Calculate power for 5.0 GHz
  tblt_5_contr <- params$wifi_5_prop * params$wifi_5_pwr

  # Combine 2.4 and 5.0 GHz
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
