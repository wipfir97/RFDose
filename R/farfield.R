# Calculate total RF-EMF dose (for brain and body) from far-field exposure

# =============================================================================
#' Calculate Dose from far-field exposure
#'
#' Calculates RF-EMF dose from far-field exposure
#'
#' @details
#' The far-field RF-EMF dose is calculated as:
#' \deqn{Dose_{farfield} = 86400s \times Power_{farfield} \times SAR_{farfield}}
#'
#' Where:
#'
#' * \eqn{Power_{farfield}} is the output power of farfield sources
#' * \eqn{SAR_{mobiledata}} is the specific absorption rate in W/kg/W
#'
#' @param country Country (Austria="AT", Belgium="BE", France="FR", Hungary="HU",
#' Italy="IT", Netherlands="NL", Poland="PL", Spain="ES", Switzerland="CH", United Kingdom="UK",
#' other country/unknown="Other")
#' @param urbanicity Urbanicity of home environment
#' @param travel_time Time per day spent commuting (s)
#' @param params Parameter list
#'
#' @returns List with brain dose and body dose in mJ/kg/day
#'
#' @seealso [get_farfield_pwr()],[get_farfield_sar()]
#' @export
get_farfield_dose <- function(country,
                              urbanicity,
                              travel_time,
                              params = NULL) {
  # Load parameters if not provided ===========================================
  if (is.null(params)) {
    params <- load_params("params.yaml")}

  # Check input arguments =====================================================
  check_country(country)
  check_duration(travel_time)

  # Extract parameters ========================================================
  ## Extract shared (non-tissue specific) parameters for mobile calling -------
  farf_params  <- load_device_params(params, "farf")

  ## Extract brain-specific parameters (SAR values) for mobile calling --------
  brain_params <- load_tissue_params(params, "farf", "brain")

  ## Extract body-specific parameters (SAR values) for mobile calling ---------
  body_params  <- load_tissue_params(params, "farf", "body")

  # Calculate aggregated power ================================================
  aggr_pwr     <- get_farfield_pwr(country     = country,
                                   urbanicity  = urbanicity,
                                   travel_time = travel_time,
                                   params      = farf_params)

  # Calculate tissue-specific SAR =============================================
  ## Calculate aggregated brain SAR -------------------------------------------
  brain_sar    <- get_farfield_sar(params        = farf_params,
                                   tissue_params = brain_params)

  ## Calculate aggregated body SAR --------------------------------------------
  body_sar     <- get_farfield_sar(params        = farf_params,
                                   tissue_params = body_params)

  # Calculate tissue-specific dose ============================================
  ## Calculate brain dose -----------------------------------------------------
  brain_dose   <- 86400*aggr_pwr*brain_sar

  ## Calculate body dose ------------------------------------------------------
  body_dose    <- 86400*aggr_pwr*body_sar

  # Return output =============================================================
  output_list <- list("brain_farf_dose" = brain_dose,
                      "body_farf_dose"  = body_dose)

  return(output_list)
}

# =============================================================================
#' Calculate far-field exposure aggregated power
#'
#' Calculates far-field source output power
#'
#' @param country Country
#' @param urbanicity Urbanicity of home environment
#' @param travel_time Time per day spent commuting (s)
#' @param params Parameter list
#'
#' @returns far-field power in mw/m**2
get_farfield_pwr <- function(country,
                             urbanicity,
                             travel_time,
                             params) {


  # Recode urbanicity to binary format ========================================
  urb_list     <- recode_urbanicity(urbanicity  = urbanicity)


  # Calculate proportion of time spent at home vs work vs outdoors based on travel time
  loc_props <- calculate_location_proportions(
    travel_time = travel_time,
    home_prop   = params$home_prop,
    outd_prop   = params$outd_prop,
    work_prop   = params$work_prop)

  # Calculate far-field power at home =========================================
  ## Urban home ---------------------------------------------------------------
  home_urban <- prod(urb_list$home_urban,
                     get_farfield_pwr_by_country(
                       country,
                       "home_urban_pwr",
                       params
                       )
                     )
  ## Suburban home ------------------------------------------------------------
  home_subur <- prod(urb_list$home_suburb,
                     get_farfield_pwr_by_country(
                       country,
                       "home_suburb_pwr",
                       params
                       )
                     )
  ## Rural home ---------------------------------------------------------------
  home_rural <- prod(urb_list$home_rural,
                     get_farfield_pwr_by_country(
                       country,
                       "home_rural_pwr",
                       params
                       )
                     )
  ## Total --------------------------------------------------------------------
  home_contr    <- loc_props$home * sum(home_urban,
                                        home_subur,
                                        home_rural)


  # Calculate far-field power outdoors ========================================
  ## Urban outdoors
  outd_urban    <- urb_list$home_urban * get_farfield_pwr_by_country(country,
                                                                     "outdoor_urban_pwr",
                                                                     params)
  ## Suburban outdoors
  outd_subur    <- urb_list$home_suburb * get_farfield_pwr_by_country(country,
                                                                      "outdoor_suburb_pwr",
                                                                      params)
  ## Rural outdoors
  outd_rural    <- urb_list$home_rural * get_farfield_pwr_by_country(country,
                                                                     "outdoor_rural_pwr",
                                                                     params)
  ## Total
  outd_contr    <- loc_props$outd * sum(outd_urban,
                                        outd_subur,
                                        outd_rural)


  # Calculate far-field power at work =========================================
  ## Urban work
  work_urban    <- urb_list$work_urban * get_farfield_pwr_by_country(country,
                                                                     "work_urban_pwr",
                                                                     params)
  ## Suburban work
  work_subur    <- urb_list$work_suburb *  get_farfield_pwr_by_country(country,
                                                                       "work_suburb_pwr",
                                                                       params)
  ## Rural work
  work_rural    <- urb_list$work_rural *  get_farfield_pwr_by_country(country,
                                                                      "work_rural_pwr",
                                                                      params)
  ## Total
  work_contr    <- loc_props$work * sum(work_urban,
                                        work_subur,
                                        work_rural)


  # Calculate far-field power during commute/transport ========================
  tran_contr    <- loc_props$travel * get_farfield_pwr_by_country(country,
                                                                  "travel_pwr",
                                                                  params)

  # Calculate total far-field power and return result =========================
  aggr_pwr      <- sum(home_contr,
                       outd_contr,
                       work_contr,
                       tran_contr)

  return(aggr_pwr)
}

# -----------------------------------------------------------------------------
#' Get far-field output power by country
#'
#' @param country country
#' @param base Base name
#' @param params Parameter list
get_farfield_pwr_by_country <- function(country, base, params) {

  suffix <- ifelse(
    country == "Other", "other", country)

  param_name <- paste0(base, "_", suffix)

  value <- params[[param_name]]
  if (is.na(value)) {
    stop("Parameter value not found in parameter list.")
  }

  return(params[[param_name]])
}

# =============================================================================
#' Calculate far-field exposure SAR
#'
#' This function will be expanded in the future to provide a more fine-tuned
#' calculation of the far-field SAR values.
#' @param params Parameter list
#' @param tissue_params Tissue-specific parameter list (SAR values)
#' @returns aggregated sar in W/kg/W/m**2
get_farfield_sar <- function(params, tissue_params) {
  aggr_sar <- tissue_params$sar
  return(aggr_sar)
}



