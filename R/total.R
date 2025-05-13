#' Calculate Total RF-EMF Doses for ALL samples
#'
#' @param data A data frame. Must have the following columns:
#' sample_id: unique participant identifier
#' mpc_duration: daily duration of mobile phone call in seconds
#' mpc_ear_prop: proportion of time phone is held against ear during call
#' urbanicity: urban, suburban, or rural
#' mpd_duration: daily duration of mobile data traffic in seconds
#' mpd_wifi_prop: proportion of time WiFi is used (vs data) for mobile data traffic
#' dect_duration: daily duration of DECT/cordless phone call in seconds
#' dect_ear_prop:
#' lptp_duration:
#' tblt_duration:
#' wifi_duration:
#' @param param_file optional path to YAML parameter configuration file
#' @param default_value_file optional path to YAML default value file in case of missing data
#' @returns A data frame. Columns named SOURCE_dose_TISSUE contain RF-EMF dose
#' of each participant in mJ/kg/day
#' @import dplyr
#' @importFrom tidyr unnest
#' @importFrom tidyr unnest_wider
#' @import yaml
#' @export
calculate_emf_doses <- function(data,
                                param_file = NULL,
                                default_value_file = NULL) {

  # Parameters ================================================================
  ## Load internal parameter file if no param_file is supplied ----------------
  params <- if (is.null(param_file)) {
    load_params("params.yaml")  # from inst/extdata
  } else {
    yaml::read_yaml(param_file)
  }
  ## Check parameter file for validity if supplied ----------------------------
  # TODO: add validity check

  # Default values ============================================================
  ## Load internal default value file if no default_value_file is supplied ----
  defaultvars <- if (is.null(default_value_file)) {
    yaml::read_yaml(system.file("extdata", "defaultvariables.yaml",
                                package = "ETAINDoseCalculator"))  # from inst/extdata
  } else {
    yaml::read_yaml(default_value_file)
  }

  ## Check default value file for validity if supplied ------------------------
  # TODO: add validity check

  ## Replace NAs with default values ------------------------------------------
  results <- fill_missing_variables(data = data,
                                    defaults = defaultvars,
                                    warn_threshold = 0.1)
  data <- results$data
  replaced <-results$replaced

  ## Save default value documentation -----------------------------------------
  # TODO: document how many values were replaced for each sample


  # Calculate RF-EMF Dose for all entries in dataset ==========================
  ## Go through each row, calculate doses, append results as column
  results <- data %>%
    rowwise() %>%
    mutate(outcome = list(get_total_dose(as.list(cur_data()), params))) %>%
    unnest_wider(outcome) %>%
    ungroup()

  ## Return output as data frame
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
  call_dose <- get_mobilecall_dose(duration   = sample$mpc_duration,
                                    ear_prop   = sample$mpc_ear_prop,
                                    headp_prop = sample$mpc_headp_prop,
                                    urbanicity = sample$urbanicity,
                                    params     = params)

  ## Calculate mobile data contribution ---------------------------------------
  data_dose <- get_mobiledata_dose(duration   = sample$mpd_duration,
                                   wifi_prop  = sample$mpd_wifi_prop,
                                   high_pwr_prop = sample$mpd_high_dt_prop,
                                   params)

  ## Calculate far-field contribution -----------------------------------------
  farf_dose <- get_farfield_dose(urbanicity   = sample$urbanicity,
                                 params       = params)

  ## Calculate WiFi contribution ----------------------------------------------
  wifi_dose <- get_wifi_dose(duration = sample$wifi_duration,
                             params   = params)

  ## Calculate laptop contribution --------------------------------------------
  lptp_dose <- get_laptop_dose(duration = sample$lptp_duration,
                               params   = params)

  ## Calculate tablet contribution --------------------------------------------
  tblt_dose <- get_tablet_dose(duration = sample$tblt_duration,
                               params   = params)

  ## Calculate cordless contribution ------------------------------------------
  dect_dose <- get_cordless_dose(duration       = sample$dect_duration,
                                 ear_proportion = sample$dect_ear_prop,
                                 params         = params)

  ## Calculate contribution of other sources -----------------------------------
  othe_dose <- get_other_dose(duration_hotspot    = sample$hotspot_duration,
                              duration_smartwatch = sample$smartwatch_duration,
                              duration_tracker    = sample$tracker_duration,
                              duration_vr         = sample$vr_duration,
                              duration_headphones = sample$headphone_duration,
                              duration_smarthome  = sample$smarthome_duration,
                              params              = params)


  # Calculate total dose ======================================================
  ## Brain
  total_brain_dose <- sum(call_dose$brain_call_dose,
                          data_dose$brain_data_dose,
                          dect_dose$brain_dect_dose,
                          farf_dose$brain_farf_dose,
                          wifi_dose$brain_wifi_dose,
                          lptp_dose$brain_lptp_dose,
                          tblt_dose$brain_tblt_dose,
                          othe_dose$brain_othe_dose)

  ## Body
  total_body_dose <- sum(call_dose$body_call_dose,
                         data_dose$body_data_dose,
                         dect_dose$body_dect_dose,
                         farf_dose$body_farf_dose,
                         wifi_dose$body_wifi_dose,
                         lptp_dose$body_lptp_dose,
                         tblt_dose$body_tblt_dose,
                         othe_dose$body_othe_dose)

  ## Save as list
  tota_dose <- list("brain_total_dose" = total_brain_dose,
                    "body_total_dose"  = total_body_dose)

  # Return output =============================================================
  output_list <- c(call_dose,
                   data_dose,
                   dect_dose,
                   farf_dose,
                   wifi_dose,
                   lptp_dose,
                   tblt_dose,
                   othe_dose,
                   tota_dose)

  return(output_list)
}

