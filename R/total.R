#' Calculate Total RF-EMF Doses for ALL samples
#'
#' @param test a data frame
#' @returns a data frame
#' @import dplyr
#' @importFrom tidyr unnest
#' @importFrom tidyr unnest_wider
#' @import yaml
#' @export
calculate_emf_doses <- function(data) {

  # Load parameters and default values
  params      <- load_params("params2.yaml")

  # Calculate total dose for each row in input data
  results <- data %>%
    rowwise() %>%
    mutate(outcome = list(get_total_dose(as.list(cur_data()), params))) %>%
    unnest_wider(outcome) %>%
    ungroup()

  return(as.data.frame(results))
}


#' Calculate Total RF-EMF Dose for Brain and Body from All Sources
#' For a SINGLE SAMPLE!
#'
#' @param inputtable A list with input values for a single sample
#' @param params A parameter list
#' @returns A list with results for brain and body dose for a single sample
#' @export
get_total_dose <- function(sample,
                           params) {

  # Calculate contribution of each exposure source ============================
  ## Calculate mobile call contribution ---------------------------------------
  mobilecall_dose <- get_mobilecall_dose(duration   = sample$mpc_duration,
                                         ear_prop   = sample$mpc_ear_prop,
                                         urbanicity = sample$urbanicity,
                                         params     = params)

  ## Calculate mobile data contribution ---------------------------------------
  mobiledata_dose <- get_mobiledata_dose(duration   = sample$mpd_duration,
                                         wifi_prop  = sample$mpd_wifi_prop,
                                         params)

  ## Calculate far-field contribution -----------------------------------------
  farfield_dose   <- get_farfield_dose(urbanicity   = sample$urbanicity,
                                       params       = params)

  ## Calculate WiFi contribution ----------------------------------------------
  wifi_dose       <- get_wifi_dose(duration = sample$wifi_duration,
                                   params   = params)

  ## Calculate laptop contribution --------------------------------------------
  laptop_dose     <- get_laptop_dose(duration = sample$lptp_duration,
                                     params   = params)

  ## Calculate tablet contribution --------------------------------------------
  tablet_dose     <- get_tablet_dose(duration = sample$tblt_duration,
                                     params   = params)

  ## Calculate cordless contribution ------------------------------------------
  cordless_dose   <- get_cordless_dose(as.numeric(sample$dect_duration),
                                       params)

  ## Calculate contribution of other sources -----------------------------------
  other_dose      <- list("other_dose_brain" = NA,
                          "other_dose_body"  = NA)

  # Combine different sources =================================================

  # Calculate total dose ======================================================

  # Return output =============================================================
  output_list <- c(mobilecall_dose,
                   mobiledata_dose,
                   farfield_dose,
                   wifi_dose,
                   laptop_dose,
                   tablet_dose,
                   cordless_dose,
                   other_dose)
  return(output_list)
}

temp_test <- function(data) {
  params      <- load_params("params2.yaml")
  #get_mobilecall_dose(424.5, params)
  #get_mobiledata_dose(10800, params)
  get_farfield_dose(86400, params)
}
