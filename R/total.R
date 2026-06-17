###############################################################################
#' Calculate Total RF-EMF Doses for ALL samples
#'
#' Wrapper function that calculates RF-EMF doses for a full data frame.
#'
#' @param data A data frame with required columns.
#' @param tissue Tissue for which to calculate dose (default: "brain" or "body")
#' @param param_file Optional path to an external YAML parameter file. Must follow same structure as internal YAML parameter file.
#' @param default_value_file Optional path to external YAML default value file. Must follow same structure as internal YAML default value file.
#' @returns A data frame. Columns named SOURCE_dose_TISSUE contain the calculated RF-EMF dose
#' of each row in mJ/kg/day, for each exposure source and each tissue.
#' @import dplyr
#' @importFrom tidyr unnest
#' @importFrom tidyr unnest_wider
#' @import yaml
#' @export
calculate_emf_doses <- function(
    data,
    tissue,
    params = load_params(),
    default_value_file = NULL) {
  # Default values ============================================================
  ## Load internal default value file if no default_value_file is supplied ----
  defaultvars <- if (is.null(default_value_file)) {
    yaml::read_yaml(
      system.file(
        "extdata",
        "defaultvariables.yaml",
        package = "RFDose"))
  } else {
    yaml::read_yaml(default_value_file)
  }

  ## Replace NAs with default values ------------------------------------------
  results <- fill_missing_variables(
    data           = data,
    defaults       = defaultvars,
    warn_threshold = 0.1) # show warning if column has more than 10% missing data

  data     <- results$data
  replaced <- results$replaced

  # Calculate RF-EMF Dose for all entries in data set =========================
  ## Go through each row, calculate doses, append results as column
  results <- data |>
    dplyr::rowwise() |>
    dplyr::mutate(
      outcome = list(
        get_total_dose(
          as.list(dplyr::pick(dplyr::everything())),
          tissue = tissue,
          params
        )
      )
    ) |>
    tidyr::unnest_wider(outcome) |>
    dplyr::ungroup()

  ## Return output as data frame
  return(as.data.frame(results))
}


###############################################################################
#' Calculate Total RF-EMF Dose for Brain and Body from All Sources
#'
#' @param sample A list with input values for a single sample
#' @param param_file parameter file
#' @returns A list with results for brain and body dose for a single sample
#' @export
get_total_dose <- function(
    sample,
    tissue,
    params = load_params()) {
  # Check input ===============================================================
  ## Check if any input values in sample are missing, return error ------------
  missing_vars <- anyNA(sample)
  if (missing_vars) {
    stop("Your sample is missing required input values. Please check your data.")
  }
  # Calculate contribution of each exposure source ============================
  ## Calculate mobile call contribution ---------------------------------------
  call_dose <- mobilecall_dose(
    tissue           = tissue,
    duration         = sample$mpc_duration,
    ear_prop         = sample$mpc_ear_prop,
    headp_prop       = sample$mpc_headp_prop,
    urbanicity       = sample$urbanicity,
    use_5g           = sample$use_5g,
    travel_time      = sample$travel_time,
    headp_ear_num    = sample$headp_ear_num,
    wifi_prop_home   = sample$mpd_wifi_prop_home,
    wifi_prop_work   = sample$mpd_wifi_prop_work,
    wifi_prop_travel = sample$mpd_wifi_prop_travel,
    params           = params
    )

  ## Calculate mobile data contribution ---------------------------------------
  data_dose <- mobiledata_dose(
    tissue           = tissue,
    duration_low     = sample$mpd_dur_low,
    duration_lowmed  = sample$mpd_dur_lowtomed,
    duration_medhigh = sample$mpd_dur_medtohigh,
    duration_high    = sample$mpd_dur_high,
    use_5g           = sample$use_5g,
    urbanicity       = sample$urbanicity,
    travel_time      = sample$travel_time,
    wifi_prop_home   = sample$mpd_wifi_prop_home,
    wifi_prop_work   = sample$mpd_wifi_prop_work,
    wifi_prop_travel = sample$mpd_wifi_prop_travel,
    params           = params
    )

  ## Calculate far-field contribution -----------------------------------------
  farf_dose <- farfield_dose(
    tissue           = tissue,
    country      = sample$country,
    urbanicity   = sample$urbanicity,
    travel_time  = sample$travel_time,
    params       = params
    )

  ## Calculate WiFi contribution ----------------------------------------------
  wifi_dose <- wifi_dose(
    tissue           = tissue,
    travel_time      = sample$travel_time,
    wifi_prop_travel = sample$mpd_wifi_prop_travel,
    params           = params
    )

  ## Calculate laptop contribution --------------------------------------------
  lptp_dose <- laptop_dose(
    tissue      = tissue,
    dur_low     = sample$lptp_dur_low,
    dur_lowmed  = sample$lptp_dur_lowtomed,
    dur_medhigh = sample$lptp_dur_medtohigh,
    dur_high    = sample$lptp_dur_high,
    params      = params
    )

  ## Calculate tablet contribution --------------------------------------------
  tblt_dose <- tablet_dose(
    tissue      = tissue,
    dur_low     = sample$tblt_dur_low,
    dur_lowmed  = sample$tblt_dur_lowtomed,
    dur_medhigh = sample$tblt_dur_medtohigh,
    dur_high    = sample$tblt_dur_high,
    params      = params
    )

  ## Calculate cordless contribution ------------------------------------------
  dect_dose <- cordless_dose(
    tissue         = tissue,
    duration       = sample$dect_duration,
    ear_prop       = sample$dect_ear_prop,
    params         = params
    )

  ## Calculate contribution of other sources -----------------------------------
  othe_dose <- other_dose_wrapper(
    tissue              = tissue,
    duration_hotspot    = sample$hotspot_duration,
    duration_smartwatch = sample$smartwatch_duration,
    duration_vr         = sample$vr_duration,
    duration_headphones = sample$headphone_duration,
    duration_gaming     = sample$gaming_duration,
    params              = params
    )

  # Return output =============================================================
  output_list <- c(
    "call_dose"  = call_dose,
    "data_dose"  = data_dose,
    "dect_dose"  = dect_dose,
    "farf_dose"  = farf_dose,
    "wifi_dose"  = wifi_dose,
    "lptp_dose"  = lptp_dose,
    "tblt_dose"  = tblt_dose,
    "other_dose" = othe_dose)

  return(output_list)
}

