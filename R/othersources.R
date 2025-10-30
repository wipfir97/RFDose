# Calculate total RF-EMF dose (for brain and body) from other exposure sources

# =============================================================================
#' Calculate Dose from other exposure sources
#'
#' @param duration_hotspot daily hotspot use duration (s)
#' @param duration_smartwatch daily smart watch use duration (s)
#' @param duration_tracker daily tracker use duration (s)
#' @param duration_vr daily vr use duration (s)
#' @param duration_headphones daily bluetooth headphone use duration (s)
#' @param duration_gaming daily portable gaming console use duration (s)
#' @param params Parameter list
#' @returns List with brain dose and body dose in mJ/kg/day
#' @export
get_other_dose <- function(duration_hotspot,
                           duration_smartwatch,
                           duration_tracker,
                           duration_vr,
                           duration_headphones,
                           duration_gaming,
                           params = NULL) {
  # Load parameters if not provided ===========================================
  params <- if (is.null(params)) {
    load_params("params.yaml")  # from inst/extdata
  }

  # Calculate doses from individual devices ===================================
  ## From hotspot -------------------------------------------------------------
  hots_dose <- get_hotspot_dose(duration_hotspot,
                                params)

  ## From watch ---------------------------------------------------------------
  watc_dose <- get_smartwatch_dose(duration_smartwatch,
                                   params)

  ## From tracker -------------------------------------------------------------
  trac_dose <- get_tracker_dose(duration_tracker,
                                params)

  ## From VR headset ----------------------------------------------------------
  virt_dose <- get_vr_dose(duration_vr,
                           params)

  ## From BT headphones -------------------------------------------------------
  head_dose <- get_headphone_dose(duration_headphones,
                                  params)

  ## From portaple gaming device ----------------------------------------------
  game_dose <- get_gaming_dose(duration_gaming,
                               params)


  # Add doses and return total dose ===========================================
  ## Brain
  total_brain_dose <- sum(hots_dose$hots_brain_dose,
                          watc_dose$watch_brain_dose,
                          trac_dose$tracker_brain_dose,
                          virt_dose$vr_brain_dose,
                          head_dose$headphone_brain_dose,
                          game_dose$game_brain_dose)
  ## Body
  total_body_dose  <- sum(hots_dose$hots_body_dose,
                          watc_dose$watch_body_dose,
                          trac_dose$tracker_body_dose,
                          virt_dose$vr_body_dose,
                          head_dose$headphone_body_dose,
                          game_dose$game_body_dose)
  ## Save output
  output <- list("brain_othe_dose" = total_brain_dose,
                 "body_othe_dose"  = total_body_dose)

  return(output)
}

# Dose calculations by device =================================================
# Hotspot ---------------------------------------------------------------------
#' Calculate brain and body dose from using mobile phone as hotspot
#'
#' @param duration_hotspot Daily duration of using phone as hotspot in seconds
#' @param params Parameter list
#' @returns list with daily brain and body dose from hotspot use
#' @export
get_hotspot_dose <- function(duration_hotspot,
                             params = NULL) {
  # Load parameters if not provided ===========================================
  params <- if (is.null(params)) {
    load_params("params.yaml")  # from inst/extdata
  }
  # Get hotspot parameters from parameter list --------------------------------
  ## Device-specific
  hots_params        <- load_device_params(params, "hots")
  ## Brain-specific
  hots_brain_params  <- load_tissue_params(params, "hots", "brain")
  ## Body-specific
  hots_body_params   <- load_tissue_params(params, "hots", "body")

  # Calculate output power from hotspot ---------------------------------------
  hots_pwr       <- get_hotspot_pwr(params = hots_params)

  # Calculate brain SAR from hotspot ------------------------------------------
  hots_brain_sar <- get_hotspot_sar(params = hots_params,
                                    tissue_params = hots_brain_params)

  # Calculate body SAR from hotspot -------------------------------------------
  hots_body_sar  <- get_hotspot_sar(params = hots_params,
                                 tissue_params = hots_body_params)

  # Calculate brain and body dose from hotspot --------------------------------
  hots_brain_dose <- duration_hotspot * hots_pwr * hots_brain_sar
  hots_body_dose  <- duration_hotspot * hots_pwr * hots_body_sar

  # Make list with brain and body dose and return output
  output <- list("hots_brain_dose" = hots_brain_dose,
                 "hots_body_dose"  = hots_body_dose)

  return(output)
}

# Smart watch -----------------------------------------------------------------
#' Calculate brain and body dose from using smart watch connected to mobile phone
#'
#' Important: exposure comes from both mobile phone and from smart watch.
#' @param duration_smartwatch Daily duration of using smart watch in seconds
#' @param params Parameter list
#' @returns list with daily brain and body dose from smart watch use
#' @export
get_smartwatch_dose <- function(duration_smartwatch,
                                params = NULL) {
  # Load parameters if not provided ===========================================
  params <- if (is.null(params)) {
    load_params("params.yaml")  # from inst/extdata
  }
  # Get watch parameters from parameter list ----------------------------------
  ## Device-specific
  watch_params        <- load_device_params(params, "watch")
  ## Brain-specific
  watch_brain_params  <- load_tissue_params(params, "watch", "brain")
  ## Body-specific
  watch_body_params   <- load_tissue_params(params, "watch", "body")

  # Calculate dose from mobile phone ------------------------------------------
  ## Brain
  watch_phone_brain_dose <- get_smartwatch_phone_dose(duration_smartwatch = duration_smartwatch,
                                                      params               = watch_params,
                                                      tissue_params        = watch_brain_params)
  ## Body
  watch_phone_body_dose  <- get_smartwatch_phone_dose(duration_smartwatch = duration_smartwatch,
                                                      params               = watch_params,
                                                      tissue_params        = watch_body_params)
  # Calculate dose from smartwatch --------------------------------------------
  ## Brain
  watch_brain_dose <- get_smartwatch_watch_dose(duration_smartwatch  = duration_smartwatch,
                                                params               = watch_params,
                                                tissue_params        = watch_brain_params)
  ## Body
  watch_body_dose  <- get_smartwatch_watch_dose(duration_smartwatch = duration_smartwatch,
                                                params              = watch_params,
                                                tissue_params       = watch_body_params)
  # Add doses and return output -----------------------------------------------
  ## Brain
  watch_total_brain_dose <- watch_phone_brain_dose + watch_brain_dose
  ## Body
  watch_total_body_dose  <- watch_phone_body_dose  + watch_body_dose

  ## Return output
  output <- list("watch_brain_dose" = watch_total_brain_dose,
                 "watch_body_dose"  = watch_total_body_dose)

  return(output)
}

# Smart watch - Phone contribution --------------------------------------------
#' Calculate contribution from mobile phone while using smart watch
#'
#'@param duration_smartwatch Daily duration of smartwatch use in seconds
#'@param params Parameter list
#'@param tissue_params tissue-specific parameter list
get_smartwatch_phone_dose <- function(duration_smartwatch,
                                      params,
                                      tissue_params) {
  # Calculate output power ----------------------------------------------------
  pwr <- get_smartwatch_phone_pwr(params = params)

  # Calculate SAR -------------------------------------------------------------
  sar <- get_smartwatch_phone_sar(params = params,
                                  tissue_params = tissue_params)

  # Calculate dose ------------------------------------------------------------
  dose <- duration_smartwatch * sar * pwr


  # Return output -------------------------------------------------------------
  return(dose)
}

# Smart watch - Watch contribution --------------------------------------------
#' Calculate contribution from smart watch
#'
#' @param duration_smartwatch Daily duration of smartwatch use in seconds
#' @param params Parameter list
#' @param params Tissue parameter list
get_smartwatch_watch_dose <- function(duration_smartwatch,
                                      params,
                                      tissue_params) {
  # Calculate output power ----------------------------------------------------
  pwr <- get_smartwatch_pwr(params = params)

  # Calculate SAR -------------------------------------------------------------
  sar <- get_smartwatch_sar(params        = params,
                            tissue_params = tissue_params)

  # Calculate dose ------------------------------------------------------------
  dose <- duration_smartwatch * pwr * sar

  # Return output -------------------------------------------------------------
  return(dose)
}

# Tracker ---------------------------------------------------------------------
#' Calculate brain and body dose from using personal tracker connected to mobile phone
#'
#' Important: exposure comes from both mobile phone and from smart watch.
#' @param duration_tracker Daily duration of using tracker in seconds
#' @param params Parameter list
#' @returns list with daily brain and body dose from tracker use
#' @export
get_tracker_dose <- function(duration_tracker,
                             params = NULL) {
  # Load parameters if not provided ===========================================
  params <- if (is.null(params)) {
    load_params("params.yaml")  # from inst/extdata
  }
  # Get tracker parameters from parameter list --------------------------------
  ## Device-specific
  tracker_params        <- load_device_params(params, "tracker")
  ## Brain-specific
  tracker_brain_params  <- load_tissue_params(params, "tracker", "brain")
  ## Body-specific
  tracker_body_params   <- load_tissue_params(params, "tracker", "body")

  # Calculate dose from tracker ------------------------------------------
  ## Brain
  tracker_phone_brain_dose <- get_tracker_phone_dose(duration_tracker = duration_tracker,
                                                      params               = tracker_params,
                                                      tissue_params        = tracker_brain_params)
  ## Body
  tracker_phone_body_dose  <- get_tracker_phone_dose(duration_tracker = duration_tracker,
                                                      params               = tracker_params,
                                                      tissue_params        = tracker_body_params)

  # Calculate dose from tracker --------------------------------------------
  ## Brain
  tracker_brain_dose <- get_tracker_tracker_dose(duration_tracker  = duration_tracker,
                                                params               = tracker_params,
                                                tissue_params        = tracker_brain_params)
  ## Body
  tracker_body_dose  <- get_tracker_tracker_dose(duration_tracker = duration_tracker,
                                                params              = tracker_params,
                                                tissue_params       = tracker_body_params)

  # Add doses and return output -----------------------------------------------
  ## Brain
  tracker_total_brain_dose <- tracker_phone_brain_dose + tracker_brain_dose
  ## Body
  tracker_total_body_dose  <- tracker_phone_body_dose  + tracker_body_dose

  ## Return output
  output <- list("tracker_brain_dose" = tracker_total_brain_dose,
                 "tracker_body_dose"  = tracker_total_body_dose)

  return(output)
}

# Tracker - Phone contribution --------------------------------------------
#' Calculate contribution from mobile phone while using tracker
#'
#'@param duration_tracker Daily duration of tracker use in seconds
#'@param params Parameter list
#'@param tissue_params tissue-specific parameter list
get_tracker_phone_dose <- function(duration_tracker,
                                   params,
                                   tissue_params) {
  # Calculate output power ----------------------------------------------------
  pwr <- get_tracker_phone_pwr(params = params)

  # Calculate SAR -------------------------------------------------------------
  sar <- get_tracker_phone_sar(params = params,
                               tissue_params = tissue_params)

  # Calculate dose ------------------------------------------------------------
  dose <- duration_tracker * pwr * sar

  # Return output -------------------------------------------------------------
  return(dose)
}

# Tracker - Tracker contribution --------------------------------------------
#' Calculate contribution from tracker
#'
#' @param duration_tracker Daily duration of tracker use in seconds
#' @param params Parameter list
#' @param tissue_params tissue-specific parameter list
get_tracker_tracker_dose <- function(duration_tracker,
                                     params,
                                     tissue_params) {
  # Calculate output power ----------------------------------------------------
  pwr <- get_tracker_pwr(params = params)

  # Calculate SAR -------------------------------------------------------------
  sar <- get_tracker_sar(params = params,
                         tissue_params = tissue_params)

  # Calculate dose ------------------------------------------------------------
  dose <- duration_tracker * pwr * sar

  # Return output -------------------------------------------------------------
  return(dose)
}


# VR headset ------------------------------------------------------------------
#' Calculate brain and body dose from using VR headset
#'
#' @param duration_vr Daily duration of using VR headset in seconds
#' @param params Parameter list
#' @returns list with daily brain and body dose from VR headset
#' @export
get_vr_dose <- function(duration_vr,
                        params = NULL) {
  # Load parameters if not provided ===========================================
  params <- if (is.null(params)) {
    load_params("params.yaml")  # from inst/extdata
  }
  # Get vr parameters from parameter list -------------------------------------
  ## Device-specific
  vr_params        <- load_device_params(params, "vr")
  ## Brain-specific
  vr_brain_params  <- load_tissue_params(params, "vr", "brain")
  ## Body-specific
  vr_body_params   <- load_tissue_params(params, "vr", "body")

  # Calculate output power from vr --------------------------------------------
  vr_pwr       <- get_vr_pwr(params = vr_params)

  # Calculate brain SAR from vr -----------------------------------------------
  vr_brain_sar <- get_vr_sar(params        = vr_params,
                             tissue_params = vr_brain_params)

  # Calculate body SAR from vr ------------------------------------------------
  vr_body_sar  <- get_vr_sar(params        = vr_params,
                             tissue_params = vr_body_params)

  # Calculate brain and body dose from vr -------------------------------------
  vr_brain_dose <- duration_vr * vr_pwr * vr_brain_sar
  vr_body_dose  <- duration_vr * vr_pwr * vr_body_sar

  # Make list with brain and body dose and return output
  output <- list("vr_brain_dose" = vr_brain_dose,
                 "vr_body_dose"  = vr_body_dose)

  return(output)
}

# Bluetooth headphones --------------------------------------------------------
#' Calculate brain and body dose from using bluetooth headphones
#'
#' Important: exposure comes from both mobile phone and from smart watch.
#' @param duration_headphones Daily duration of using bt headphones connected to phone
#' @param params Parameter list
#' @returns list with daily brain and body dose from bt headphones connected to phone
#' @export
get_headphone_dose <- function(duration_headphones,
                               params = NULL) {
  # Load parameters if not provided ===========================================
  params <- if (is.null(params)) {
    load_params("params.yaml")  # from inst/extdata
  }
  # Get bluetooth headphones parameters from parameter list -------------------
  ## Device-specific
  headp_params        <- load_device_params(params, "headp")
  ## Brain-specific
  headp_brain_params  <- load_tissue_params(params, "headp", "brain")
  ## Body-specific
  headp_body_params   <- load_tissue_params(params, "headp", "body")

  # Calculate dose from mobile phone ------------------------------------------
  ## Brain
  headp_phone_brain_dose <- get_headp_phone_dose(duration_headphones = duration_headphones,
                                                     params               = headp_params,
                                                     tissue_params        = headp_brain_params)
  ## Body
  headp_phone_body_dose  <- get_headp_phone_dose(duration_headphones = duration_headphones,
                                                     params               = headp_params,
                                                     tissue_params        = headp_body_params)

  # Calculate dose from headphones --------------------------------------------
  ## Brain
  headp_brain_dose <- get_headp_headp_dose(duration_headphones = duration_headphones,
                                           params              = headp_params,
                                           tissue_params       = headp_brain_params)
  ## Body
  headp_body_dose  <- get_headp_headp_dose(duration_headphones = duration_headphones,
                                           params              = headp_params,
                                           tissue_params       = headp_body_params)

  # Add doses and return output -----------------------------------------------
  ## Note: Dose from headphones times 2 because there are 2 ears!
  ## Brain
  headp_total_brain_dose <- headp_phone_brain_dose + 2*headp_brain_dose
  ## Body
  headp_total_body_dose  <- headp_phone_body_dose  + 2*headp_body_dose

  ## Return output
  output <- list("headphone_brain_dose" = headp_total_brain_dose,
                 "headphone_body_dose"  = headp_total_body_dose)

  return(output)
}

# Bluetooth headphones - Phone contribution --------------------------------------------
#' Calculate contribution from mobile phone while using headp
#'
#'@param duration_headphones Daily duration of headphone use in seconds
#'@param params Parameter list
#'@param tissue_params tissue-specific parameter list
get_headp_phone_dose <- function(duration_headphones,
                                 params,
                                 tissue_params) {
  # Calculate output power ----------------------------------------------------
  pwr <- get_headp_phone_pwr(params = params)

  # Calculate SAR -------------------------------------------------------------
  sar <- get_headp_phone_sar(params = params,
                             tissue_params = tissue_params)

  # Calculate dose ------------------------------------------------------------
  dose <- duration_headphones * pwr * sar

  # Return output -------------------------------------------------------------
  return(dose)
}

# Bluetooth headphones - Headphones contribution ------------------------------
#' Calculate contribution from headp
#'
#' @param duration_headphones Daily duration of headphone use in seconds
#' @param params Parameter list
#' @param tissue_params tissue-specific parameter list
get_headp_headp_dose <- function(duration_headphones,
                                 params,
                                 tissue_params) {
  # Calculate output power ----------------------------------------------------
  pwr <- get_headp_pwr(params = params)

  # Calculate SAR -------------------------------------------------------------
  sar <- get_headp_sar(params = params,
                       tissue_params = tissue_params)

  # Calculate dose ------------------------------------------------------------
  dose <- duration_headphones * pwr * sar

  # Return output -------------------------------------------------------------
  return(dose)
}

# Smart home ------------------------------------------------------------------
#' Calculate brain and body dose from smart home
#'
#' @param smarthome TRUE if participant lives in smarthome, FALSE if not
#' @param travel_time Time spent commuting in s/day
#' @param params Parameter list
#' @returns list with daily brain and body dose from smart home
#' @export
get_smarthome_dose <- function(smarthome,
                               travel_time,
                               params = NULL) {
  # Load parameters if not provided ===========================================
  params <- if (is.null(params)) {
    load_params("params.yaml")  # from inst/extdata
  }
  # Get smart home parameters from parameter list -----------------------------
  ## Device-specific
  smah_params        <- load_device_params(params, "smah")
  ## Brain-specific
  smah_brain_params  <- load_tissue_params(params, "smah", "brain")
  ## Body-specific
  smah_body_params   <- load_tissue_params(params, "smah", "body")

  # Calculate output power from smart home ------------------------------------
  smah_pwr       <- get_smarthome_pwr(params = smah_params)

  # Calculate brain SAR from smart home ---------------------------------------
  smah_brain_sar <- get_smarthome_sar(params = smah_params,
                                      tissue_params = smah_brain_params)

  # Calculate body SAR from smart home ----------------------------------------
  smah_body_sar  <- get_smarthome_sar(params        = smah_params,
                                      tissue_params = smah_body_params)

  # Calculate smarthome active duration ---------------------------------------
  ## Time spent at home
  locs <- calculate_location_proportions(travel_time = travel_time,
                                         home_prop   = smah_params$home_prop,
                                         work_prop   = smah_params$work_prop,
                                         outd_prop   = smah_params$outd_prop)
  home_dur <- locs$home*86400
  home_dur <- 60000
  print(home_dur)
  ## If smarthome == TRUE: Multiply with proportion of time smart home is active
  ## Else: set duration to 0
  if (smarthome) {
    duration_smarthome <- home_dur*smah_params$smah_active_prop
  } else {
    duration_smarthome <- 0
  }

  # Calculate brain and body dose from smart home -----------------------------
  smah_brain_dose <- duration_smarthome * smah_pwr * smah_brain_sar
  smah_body_dose  <- duration_smarthome * smah_pwr * smah_body_sar

  # Make list with brain and body dose and return output
  output <- list("smah_brain_dose" = smah_brain_dose,
                 "smah_body_dose"  = smah_body_dose)

  return(output)
}

# Gaming with portable console ------------------------------------------------
#' Calculate brain and body dose from gaming with a portable console
#'
#' @param duration_gaming Daily gaming duration with portable console in seconds
#' @param params Parameter list
#' @returns list with daily brain and body dose from smart home
#' @export
get_gaming_dose <- function(duration_gaming,
                               params = NULL) {
  # Load parameters if not provided ===========================================
  params <- if (is.null(params)) {
    load_params("params.yaml")  # from inst/extdata
  }
  # Get smart home parameters from parameter list -----------------------------
  ## Device-specific
  game_params        <- load_device_params(params, "game")
  ## Brain-specific
  game_brain_params  <- load_tissue_params(params, "game", "brain")
  ## Body-specific
  game_body_params   <- load_tissue_params(params, "game", "body")

  # Brain
  ## TODO: this calculation should be simplified and harmonized with other calculations!
  ## 2.4GHz
  game_brain_2 <- game_brain_params$game_2_sar*game_params$wifi_2_prop*game_params$game_2_pwr*game_params$game_2_dutycycle
  ## 5.0GHz
  game_brain_5 <- game_brain_params$game_5_sar*game_params$wifi_5_prop*game_params$game_5_pwr*game_params$game_5_dutycycle
  ## Aggregated
  game_brain_dose <- duration_gaming*game_params$game_online_prop*sum(game_brain_2, game_brain_5)

  # Body
  ## TODO: this calculation should be simplified and harmonized with other calculations!
  ## 2.4GHz
  game_body_2 <- game_body_params$game_2_sar*game_params$wifi_2_prop*game_params$game_2_pwr*game_params$game_2_dutycycle
  ## 5.0GHz
  game_body_5 <- game_body_params$game_5_sar*game_params$wifi_5_prop*game_params$game_5_pwr*game_params$game_5_dutycycle
  ## Aggregated
  game_body_dose <- duration_gaming*game_params$game_online_prop*sum(game_body_2, game_body_5)

  # Make list with brain and body dose and return output
  output <- list("game_brain_dose" = game_brain_dose,
                 "game_body_dose"  = game_body_dose)


  return(output)
}

# Output power calculations ===================================================
# -----------------------------------------------------------------------------
#' Calculate output power from using mobile phone as hotspot
#'
#' @param params Parameter list
#' @returns Aggregated output power of mobile phone hotspot in mW
get_hotspot_pwr <- function(params) {
  pwr_hots <- params$hots_pwr
  return(pwr_hots)
}

# -----------------------------------------------------------------------------
#' Calculate power from smart watch (phone contribution only)
#'
#' @param params Parameter list
#' @returns output power
get_smartwatch_phone_pwr <- function(params) {
  pwr <- params$watch_phone_pwr
  return(pwr)
}

# -----------------------------------------------------------------------------
#' Calculate power from smart watch (watch contribution only)
#'
#' @param params Parameter list
#' @returns output power
get_smartwatch_pwr <- function(params) {
  pwr <- params$watch_pwr
  return(pwr)
}

# -----------------------------------------------------------------------------
#' Calculate power from tracker (phone contribution only)
#'
#' @param params Parameter list
#' @returns output power
get_tracker_phone_pwr <- function(params) {
  pwr <- params$tracker_phone_pwr
  return(pwr)
}

# -----------------------------------------------------------------------------
#' Calculate power from tracker (tracker contribution only)
#'
#' @param params Parameter list
#' @returns output power
get_tracker_pwr <- function(params) {
  pwr <- params$tracker_pwr
  return(pwr)
}

# -----------------------------------------------------------------------------
#' Calculate output power from virtual reality headset
#'
#' @param params Parameter list
#' @returns Aggregated output power of VR headset in mW
get_vr_pwr <- function(params) {
  vr_pwr <- params$vr_pwr
  return(vr_pwr)
}


# -----------------------------------------------------------------------------
#' Calculate power from bluetooth headphones (phone contribution only)
#'
#' @param params Parameter list
#' @returns output power
get_headp_phone_pwr <- function(params) {
  pwr <- params$headp_phone_pwr
  return(pwr)
}

# -----------------------------------------------------------------------------
#' Calculate power from bluetooth headphones (headphone contribution only)
#'
#' @param params Parameter list
#' @returns output power
get_headp_pwr <- function(params) {
  pwr <- params$headp_pwr
  return(pwr)
}

# -----------------------------------------------------------------------------
#' Calculate output power from smart home
#'
#' @param params Parameter list
#' @returns Aggregated output power smart home in mW
get_smarthome_pwr <- function(params) {
  smah_pwr <- params$smah_pwr
  return(smah_pwr)
}




# SAR Calculations ============================================================
# -----------------------------------------------------------------------------
#' Calculate SAR from hotspot
#'
#' @param params Parameter list
#' @param tissue_params Tissue params
#' @returns tissue-specific SAR from hotspot
get_hotspot_sar <- function(params,
                            tissue_params) {
  sar_hots <- tissue_params$hots_sar
  return(sar_hots)
}

# -----------------------------------------------------------------------------
#' Calculate SAR from smart watch (phone contribution only)
#'
#' @param params Parameter list
#' @param tissue_params Tissue-specific parameter list (SAR values)
#' @returns SAR value
get_smartwatch_phone_sar <- function(params, tissue_params) {
  sar <- tissue_params$watch_phone_sar
  return(sar)
}

# -----------------------------------------------------------------------------
#' Calculate SAR from smart watch (watch contribution only)
#'
#' @param params Parameter list
#' @param tissue_params Tissue-specific parameter list (SAR values)
#' @returns SAR value
get_smartwatch_sar <- function(params, tissue_params) {
  sar <- tissue_params$watch_sar
  return(sar)
}

# -----------------------------------------------------------------------------
#' Calculate SAR from tracker (phone contribution only)
#'
#' @param params Parameter list
#' @param tissue_params Tissue-specific parameter list (SAR values)
#' @returns SAR value
get_tracker_phone_sar <- function(params, tissue_params) {
  sar <- tissue_params$tracker_phone_sar
  return(sar)
}

# -----------------------------------------------------------------------------
#' Calculate SAR from tracker (watch contribution only)
#'
#' @param params Parameter list
#' @param tissue_params Tissue-specific parameter list (SAR values)
#' @returns SAR value
get_tracker_sar <- function(params, tissue_params) {
  sar <- tissue_params$tracker_sar
  return(sar)
}

# -----------------------------------------------------------------------------
#' Calculate SAR from VR headset
#'
#' @param params Parameter list
#' @param tissue_params Tissue params
#' @returns tissue-specific SAR from VR headset
get_vr_sar <- function(params, tissue_params) {
  vr_sar <- tissue_params$vr_sar
  return(vr_sar)
}

# -----------------------------------------------------------------------------
#' Calculate SAR from bluetooth headphones (phone contribution only)
#'
#' @param params Parameter list
#' @param tissue_params Tissue-specific parameter list (SAR values)
#' @returns SAR value
get_headp_phone_sar <- function(params, tissue_params) {
  sar <- tissue_params$headp_phone_sar
  return(sar)
}

# -----------------------------------------------------------------------------
#' Calculate SAR from bluetooth headphones (watch contribution only)
#'
#' @param params Parameter list
#' @param tissue_params Tissue-specific parameter list (SAR values)
#' @returns SAR value
get_headp_sar <- function(params, tissue_params) {
  sar <- tissue_params$headp_sar
  return(sar)
}


# -----------------------------------------------------------------------------
#' Calculate SAR from smart home
#'
#' @param params Parameter list
#' @param tissue_params Tissue params
#' @returns tissue-specific SAR from smart home
get_smarthome_sar <- function(params, tissue_params) {
  smah_sar <- tissue_params$smah_sar
  return(smah_sar)
}


