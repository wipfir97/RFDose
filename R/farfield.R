# Calculate total RF-EMF dose (for brain and body) from far-field exposure

# =============================================================================
#' Calculate Dose from far-field exposure
#'
#' @param urbanicity Urbanicity of home environment
#' @param params Parameter list
#' @returns List with brain dose and body dose in mJ/kg/day
#' @export
get_farfield_dose <- function(urbanicity,
                              params) {

  # Extract parameters ========================================================
  ## Extract shared (non-tissue specific) parameters for mobile calling -------
  farf_params  <- load_device_params(params, "farf")

  ## Extract brain-specific parameters (SAR values) for mobile calling --------
  brain_params <- load_tissue_params(params, "farf", "brain")

  ## Extract body-specific parameters (SAR values) for mobile calling ---------
  body_params  <- load_tissue_params(params, "farf", "body")

  # Recode urbanicity to binary format ========================================
  urb_list     <- recode_urbanicity(urbanicity  = urbanicity)

  # Calculate aggregated power ================================================
  aggr_pwr     <- get_farfield_pwr(urb_list = urb_list,
                                   params = farf_params)

  # Calculate tissue-specific SAR =============================================
  ## Calculate aggregated brain SAR -------------------------------------------
  brain_sar    <- get_farfield_sar(params        = params,
                                   tissue_params = brain_params)

  ## Calculate aggregated body SAR --------------------------------------------
  body_sar     <- get_farfield_sar(params        = params,
                                   tissue_params = body_params)

  # Calculate tissue-specific dose ============================================
  ## Calculate brain dose -----------------------------------------------------
  brain_dose   <- 86400*aggr_pwr*brain_sar

  ## Calculate body dose ------------------------------------------------------
  body_dose    <- 86400*aggr_pwr*body_sar

  # Return output =============================================================
  output_list <- list("farfield_dose_brain" = brain_dose,
                      "farfield_dose_body"  = body_dose)
  return(output_list)
}

# =============================================================================
#' Calculate far-field exposure aggregated power
#'
#' @param urb_list list of binary urbanicitiy values created with recode_urbanicity
#' function
#' @param params description
#' @returns far-field power
get_farfield_pwr <- function(urb_list,
                             params) {

  # Calculate far-field power at home =========================================
  ## Urban home
  home_urban    <- urb_list$home_urban * params$home_urban_pwr
  ## Suburban home
  home_subur    <- urb_list$home_suburb * params$home_suburb_pwr
  ## Rural home
  home_rural    <- urb_list$home_rural * params$home_rural_pwr
  ## Total
  home_contr    <- params$home_prop * sum(home_urban,
                                          home_subur,
                                          home_rural)

  # Calculate far-field power outdoors ========================================
  ## Urban outdoors
  outd_urban    <- urb_list$home_urban * params$outdoor_urban_pwr
  ## Suburban outdoors
  outd_subur    <- urb_list$home_suburb * params$outdoor_suburb_pwr
  ## Rural outdoors
  outd_rural    <- urb_list$home_rural * params$outdoor_rural_pwr
  ## Total
  outd_contr    <- params$outdoor_prop * sum(outd_urban,
                                             outd_subur,
                                             outd_rural)

  # Calculate far-field power at work =========================================
  ## Urban work
  work_urban    <- urb_list$work_urban * params$work_urban_pwr
  ## Suburban work
  work_subur    <- urb_list$work_suburb * params$work_suburb_pwr
  ## Rural work
  work_rural    <- urb_list$work_rural * params$work_rural_pwr
  ## Total
  work_contr    <- params$work_prop * sum(work_urban,
                                          work_subur,
                                          work_rural)

  # Calculate far-field power during commute/transport ========================
  tran_contr    <- params$travel_prop * params$travel_pwr

  # Calculate total far-field power and return result =========================
  aggr_pwr      <- sum(home_contr,
                       outd_contr,
                       work_contr,
                       tran_contr)
  return(aggr_pwr)
}

# =============================================================================
#' Calculate far-field exposure SAR
#'
#' This function will be expanded in the future to provide a more fine-tuned
#' calculation of the far-field SAR values.
#' @param params descr
#' @param tissue_params descr
#' @returns aggregated sar
get_farfield_sar <- function(params, tissue_params) {
  aggr_sar <- tissue_params$sar
  return(aggr_sar)
}



