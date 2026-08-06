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
    tissue = "body",
    params = load_params(version = "_template"),
    old_params = load_params(),
    default_value_file = NULL,
    n_sim = 100, save = FALSE, save_path = "",save_tag ="") {
  # Default values ============================================================

  # load irinas default values
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

  ## Replace NAs with default values GA: this code can be deleted when everything is stochastic
  #---------------------------------------------------------------------------
  results <- fill_missing_variables(
    data           = data,
    defaults       = defaultvars,
    warn_threshold = 0.1) # show warning if column has more than 10% missing data

  data     <- results$data
  replaced <- results$replaced


  ## Replace NAs with default values GA: this code can be deleted when everything is stochastic
  #---------------------------------------------------------------------------
  results <- fill_missing_variables(
    data           = data,
    defaults       = defaultvars,
    warn_threshold = 0.1) # show warning if column has more than 10% missing data

  data     <- results$data
  replaced <- results$replaced


  input_args <- as.list(data[1, ])

  input_args <- input_args[names(input_args) %in% names(formals(simulate_params))]
  input_args$simulation <- "_template"
  # simulate n parameter files
  param_simulations <- lapply(seq_len(n_sim), function(i) {

    #calls simulate_params(input_args)

    one_sim <- do.call(simulate_params, input_args)
    one_sim$global$sim <- paste0("sim", i)
    if (i%%10==0){print(paste0("Create simulation: ",i))}
    one_sim

  })


  # calls n times one singel dose calculation
  output <- get_total_dose(results$data,
            tissue = tissue,
            param_simulations,
            old_params
          )

  ## get list of input_args + defaults used
  #---------------------------------------------------------------------------
  all_inputs <- fill_missing_variables(
    data           = data,
    defaults       = yaml::read_yaml(system.file("extdata","defaultvariables_SDM.yaml", package = "RFDose")))$data
  ## Return output as data frame
  if (save){
    print(paste0("save in path: ",save_path))
    #save defaults and inputs
    yaml::write_yaml(
      x = all_inputs,
      file = paste0(save_path,"Input_values",save_tag,".yaml")
    )
    print("saved inputs")
    #save background param simulations
    yaml::write_yaml(
      x = param_simulations,
      file = paste0(save_path,"params",save_tag,".yaml")
    )
    print("saved simulations")
    #save final results
    write.csv(
      output,
      file = paste0(save_path,"dose_results",save_tag,".csv"),
      row.names = FALSE
    )
    print("saved results")
  }
  return(output)
}


###############################################################################
#' takes 100 parameter files and calculets 100 doses.
#'
#' @param sample A list with input values for a single sample
#' @param param_file parameter file
#' @returns A list with results for brain and body dose for a single sample
#' @export
get_total_dose <- function(
    sample,
    tissue,
    param_simulations = load_params(version = "_template"),
    old_params = load_params() ){
  # Check input ===============================================================
  ## Check if any input values in sample are missing, return error ------------
  missing_vars <- anyNA(sample)
  if (missing_vars) {
    stop("Your sample is missing required input values. Please check your data.")
  }

  stochastic_dose <- lapply(seq_len(length(param_simulations)), function(i) {
    # set default values
    sim_params = param_simulations[[i]]
    duration = sim_params$global$input_stoch$duration$mpc_duration
    ear_prop = sim_params$global$input_stoch$call_mode_prop$mpc_ear_prop
    headp_prop = sim_params$global$input_stoch$call_mode_prop$mpc_headp_prop
    use_5g = sim_params$global$input_stoch$use_5g
    headp_ear_num = sim_params$global$input_stoch$headp_num$headp_ear_num
    travel_time = sim_params$global$environment_prop$travel_prop*86400
    wifi_prop_home = sim_params$global$input_stoc$wifi_environment_probs$mpd_wifi_prop_home
    wifi_prop_work = sim_params$global$input_stoc$wifi_environment_probs$mpd_wifi_prop_work
    wifi_prop_travel = sim_params$global$input_stoc$wifi_environment_probs$mpd_wifi_prop_travel
    duration_low = sim_params$global$input_stoch$mpd_duration$mpd_dur_low
    duration_lowmed = sim_params$global$input_stoch$mpd_duration$mpd_dur_lowmed
    duration_medhigh = sim_params$global$input_stoch$mpd_duration$mpd_dur_medhigh
    duration_high = sim_params$global$input_stoch$mpd_duration$mpd_dur_high


    # Calculate contribution of each exposure source ============================
    ## Calculate mobile call contribution STOCHASTIC ---------------------------------------
    call_dose <- mobilecall_dose(
      tissue = tissue,
      duration = duration,
      ear_prop = ear_prop,
      headp_prop = headp_prop,
      use_5g = use_5g,
      travel_time = travel_time,
      headp_ear_num = headp_ear_num,
      wifi_prop_home = wifi_prop_home,
      wifi_prop_work = wifi_prop_work,
      wifi_prop_travel = wifi_prop_travel,
      params = sim_params)

    ## delete this section whene everything is stochastic
    #set parameters which have different types for stochastic and deterministic
    sample$urbanicity <- "suburban"
    sample$use_5g <- FALSE
    sample$travel_time <- 600

    ## Calculate mobile data contribution DETERMINISTIC---------------------------------------
    data_dose <- mobiledata_dose(
      tissue           = tissue,
      duration_low     = duration_low,
      duration_lowmed  = duration_lowmed,
      duration_medhigh = duration_medhigh,
      duration_high    = duration_high,
      use_5g           = use_5g,
      travel_time      = travel_time,
      wifi_prop_home   = wifi_prop_home,
      wifi_prop_work   = wifi_prop_work,
      wifi_prop_travel = wifi_prop_travel,
      params           = sim_params
      )


    ## Calculate far-field contribution DETERMINISTIC-----------------------------------------
    farf_dose <- farfield_dose(
      tissue           = tissue,
      country      = sample$country,
      urbanicity   = sample$urbanicity,
      travel_time  = sample$travel_time,
      params       = old_params
      )

    ## Calculate WiFi contribution DETERMINISTIC----------------------------------------------
    wifi_dose <- wifi_dose(
      tissue           = tissue,
      travel_time      = sample$travel_time,
      wifi_prop_travel = sample$mpd_wifi_prop_travel,
      params           = old_params
      )

    ## Calculate laptop contribution DETERMINISTIC--------------------------------------------
    lptp_dose <- laptop_dose(
      tissue      = tissue,
      dur_low     = sample$lptp_dur_low,
      dur_lowmed  = sample$lptp_dur_lowtomed,
      dur_medhigh = sample$lptp_dur_medtohigh,
      dur_high    = sample$lptp_dur_high,
      params      = old_params
      )

    ## Calculate tablet contribution DETERMINISTIC--------------------------------------------
    tblt_dose <- tablet_dose(
      tissue      = tissue,
      dur_low     = sample$tblt_dur_low,
      dur_lowmed  = sample$tblt_dur_lowtomed,
      dur_medhigh = sample$tblt_dur_medtohigh,
      dur_high    = sample$tblt_dur_high,
      params      = old_params
      )

    ## Calculate cordless contribution DETERMINISTIC------------------------------------------
    dect_dose <- cordless_dose(
      tissue         = tissue,
      duration       = sample$dect_duration,
      ear_prop       = sample$dect_ear_prop,
      params         = old_params
      )

    ## Calculate contribution of other sources DETERMINISTIC-----------------------------------
    othe_dose <- other_dose_wrapper(
      tissue              = tissue,
      duration_hotspot    = sample$hotspot_duration,
      duration_smartwatch = sample$smartwatch_duration,
      duration_vr         = sample$vr_duration,
      duration_headphones = sample$headphone_duration,
      duration_gaming     = sample$gaming_duration,
      params              = old_params
      )
    list(
      "call_dose"  = call_dose,
      "data_dose"  = data_dose,
      "dect_dose"  = dect_dose,
      "farf_dose"  = farf_dose,
      "wifi_dose"  = wifi_dose,
      "lptp_dose"  = lptp_dose,
      "tblt_dose"  = tblt_dose,
      "other_dose" = othe_dose)
  })


  # Return output =============================================================
  stochastic_dose_df <- data.frame(
    call_dose = sapply(stochastic_dose, \(x) x$call_dose),
    data_dose = sapply(stochastic_dose, \(x) x$data_dose),
    farf_dose = sapply(stochastic_dose, \(x) x$farf_dose),
    wifi_dose = sapply(stochastic_dose, \(x) x$wifi_dose),
    lptp_dose = sapply(stochastic_dose, \(x) x$lptp_dose),
    tblt_dose = sapply(stochastic_dose, \(x) x$tblt_dose),
    dect_dose = sapply(stochastic_dose, \(x) x$dect_dose),
    other_dose = sapply(stochastic_dose, \(x) x$other_dose)
  )
  return(stochastic_dose_df)
}

