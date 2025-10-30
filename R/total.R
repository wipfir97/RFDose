###############################################################################
#' Calculate Total RF-EMF Doses for ALL samples
#'
#' @param data A data frame. Must have the following columns: DOC TO BE ADDED SOON
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
    yaml::read_yaml(system.file("extdata",
                                "defaultvariables.yaml",
                                package = "ETAINDoseCalculator"))
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


  # Calculate RF-EMF Dose for all entries in data set =========================
  ## Go through each row, calculate doses, append results as column
  results <- data %>%
    rowwise() %>%
    mutate(outcome = list(get_total_dose(as.list(cur_data()), params))) %>%
    unnest_wider(outcome) %>%
    ungroup()

  ## Return output as data frame
  return(as.data.frame(results))
}


###############################################################################
#' Calculate Total RF-EMF Dose for Brain and Body from All Sources
#'
#' @param sample A list with input values for a single sample
#' @param params A parameter list
#' @returns A list with results for brain and body dose for a single sample
#' @export
get_total_dose <- function(sample,
                           params) {
  # Preparation ===============================================================
  # Calculate contribution of each exposure source ============================
  ## Calculate mobile call contribution ---------------------------------------
  call_dose <- get_mobilecall_dose(duration      = sample$mpc_duration,
                                   ear_prop      = sample$mpc_ear_prop,
                                   headp_prop    = sample$mpc_headp_prop,
                                   urbanicity    = sample$urbanicity,
                                   use_5g        = sample$use_5g,
                                   travel_time   = sample$travel_time,
                                   headp_ear_num = sample$headp_ear_num,
                                   params        = params)

  ## Calculate mobile data contribution ---------------------------------------
  ### Calculate dose
  data_dose <- get_mobiledata_dose(duration_low     = sample$mpd_dur_low,
                                   duration_lowmed  = sample$mpd_dur_lowtomed,
                                   duration_medhigh = sample$mpd_dur_medtohigh,
                                   duration_high    = sample$mpd_dur_high,
                                   use_5g           = sample$use_5g,
                                   urbanicity       = sample$urbanicity,
                                   travel_time      = sample$travel_time,
                                   act_pwr_props    = act_pwr_props,
                                   wifi_prop_home   = sample$mpd_wifi_prop_home,
                                   wifi_prop_work   = sample$mpd_wifi_prop_work,
                                   wifi_prop_travel = sample$mpd_wifi_prop_travel,
                                   params)

  ## Calculate far-field contribution -----------------------------------------
  farf_dose <- get_farfield_dose(urbanicity   = sample$urbanicity,
                                 travel_time  = sample$travel_time,
                                 params       = params)

  ## Calculate WiFi contribution ----------------------------------------------
  wifi_dose <- get_wifi_dose(travel_time      = sample$travel_time,
                             wifi_prop_travel = sample$mpd_wifi_prop_travel,
                             params           = params)

  ## Calculate laptop contribution --------------------------------------------
  lptp_dose <- get_laptop_dose(dur_low       = sample$lptp_dur_low,
                               dur_lowtomed  = sample$lptp_dur_lowtomed,
                               dur_medtohigh = sample$lptp_dur_medtohigh,
                               dur_high      = sample$lptp_dur_high,
                               params        = params)

  ## Calculate tablet contribution --------------------------------------------
  tblt_dose <- get_tablet_dose(dur_low       = sample$tblt_dur_low,
                               dur_lowtomed  = sample$tblt_dur_lowtomed,
                               dur_medtohigh = sample$tblt_dur_medtohigh,
                               dur_high      = sample$tblt_dur_high,
                               params        = params)

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
                              duration_gaming     = sample$gaming_duration,
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

