# Calculate total RF-EMF dose (for brain and body) from WiFi

###############################################################################
# =============================================================================
wifi_dose <- function(
    travel_time,
    wifi_prop_travel,
    params = load_params()) {
  # Input checks ==============================================================
  ## TODO add input checks

  # Calculate exposure duration ===============================================
  loc_props <- location_props(
    travel_time = travel_time,
    home_prop   = params$global$home_prop,
    outd_prop   = params$global$outd_prop,
    work_prop   = params$global$work_prop)
  duration <- 86400 * sum(
    loc_props$home, # assumption: always WiFi exposure at home and work
    loc_props$work, # assumption: no WiFi exposure outdoors
    loc_props$travel * wifi_prop_travel)

  # Calculate mSAR ============================================================
  ## Brain --------------------------------------------------------------------
  msar_brain <- wifi_msar(
    tissue           = "brain",
    travel_time      = travel_time,
    wifi_prop_travel = wifi_prop_travel,
    params           = params
  )
  ## Body ---------------------------------------------------------------------
  msar_body <- wifi_msar(
    tissue           = "body",
    travel_time      = travel_time,
    wifi_prop_travel = wifi_prop_travel,
    params           = params
  )

  # Calculate dose and return result ==========================================
  ## Brain --------------------------------------------------------------------
  dose_brain <- duration*msar_brain
  ## Body ---------------------------------------------------------------------
  dose_body <- duration*msar_body
  return(
    list(
      brain_wifi_dose = dose_brain,
      body_wifi_dose = dose_body
    )
  )
}

wifi_msar <- function(
    tissue,
    travel_time,
    wifi_prop_travel,
    params = load_params()) {
  # Calculate mSAR ============================================================
  bands <- c("2", "5") # 2.4 GHz, 5.0 GHz
  msar <- sum(
    vapply(
      bands,
      \(band) {
        # Output power
        pwr <- wifi_pwr(
          band = band,
          params = params
        )
        # SAR
        sar <- wifi_sar(
          tissue = tissue,
          band   = band,
          params = params
        )
        # Band proporion
        prop_band <- params$global[[paste("wifi", band, "prop", sep = "_")]]
        # Calculate mSAR and return results
        msar_band <- pwr*sar*prop_band
        return(msar_band)
      },
      numeric(1)
    )
  )
  return(msar)
}

wifi_pwr <- function(
    band,
    params = load_params()) {
  # parameter name based on input
  param_name <- paste("wifi", band, "pwr", sep = "_")
  # get parameter value and return result
  pwr <- params$devices$wifi[[param_name]]
  return(pwr)
}

wifi_sar <- function(
    tissue,
    band,
    params = load_params()) {
  # Load tissue-specific parameters
  tissue_params <- load_tissue_params(params, "wifi", tissue)
  # Parameter name based on input
  param_name    <- paste("wifi", band, "sar", sep = "_")
  # Get parameter value and return result
  sar <- tissue_params[[param_name]]
  return(sar)
}
