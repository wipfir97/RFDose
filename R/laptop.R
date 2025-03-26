# Calculate total RF-EMF dose (for brain and body) from laptop use

# =============================================================================
#' Calculate Dose from Laptop Use
#'
#' @param duration Duration of laptop use in seconds
#' @param params Parameter list
#' @returns List with brain dose and body dose in mJ/kg/day
#' @export
get_laptop_dose <- function(duration,
                            params) {

  # Extract parameters ========================================================
  ## Extract shared (non-tissue specific) parameters for laptop ---------------
  lptp_params  <- load_device_params(params, "lptp")

  ## Extract brain-specific parameters (SAR values) for laptop ----------------
  brain_params <- load_tissue_params(params, "lptp", "brain")

  ## Extract body-specific parameters (SAR values) for laptop -----------------
  body_params  <- load_tissue_params(params, "lptp", "body")


  # Calculate aggregated power ================================================
  aggr_pwr     <- get_laptop_pwr(lptp_params)

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
#' @param params text
#' @returns text
get_laptop_pwr <- function(params) {
  # Calculate power for 2.4 GHz
  lptp_2_contr  <- params$wifi_2_prop * params$wifi_2_pwr

  # Calculate power for 5.0 GHz
  lptp_5_contr  <- params$wifi_5_prop * params$wifi_5_pwr

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
