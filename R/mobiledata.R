###############################################################################
# Calculate dose
mobiledata_dose <- function(
    duration_low,
    duration_lowmed,
    duration_medhigh,
    duration_high,
    use_5g,
    wifi_prop_home,
    wifi_prop_work,
    wifi_prop_travel,
    urbanicity,
    travel_time,
    params = load_params()) {
  # Check input ===============================================================

  # Calculate mSAR ============================================================
  ## Brain --------------------------------------------------------------------
  msar_brain <- mpd_msar(
    tissue           = "brain",
    duration_low     = duation_low,
    duration_lowmed  = duration_lowmed,
    duration_medhigh = duration_medhigh,
    duration_high    = duration_high,
    use_5g           = use_5g,
    wifi_prop_home   = wifi_prop_home,
    wifi_prop_work   = wifi_prop_work,
    wifi_prop_travel = wifi_prop_travel,
    urbanicity       = urbanicity,
    travel_time      = travel_time,
    params           = params
  )
  ## Body ---------------------------------------------------------------------
  msar_body <- mpd_msar(
    tissue           = "body",
    duration_low     = duation_low,
    duration_lowmed  = duration_lowmed,
    duration_medhigh = duration_medhigh,
    duration_high    = duration_high,
    use_5g           = use_5g,
    wifi_prop_home   = wifi_prop_home,
    wifi_prop_work   = wifi_prop_work,
    wifi_prop_travel = wifi_prop_travel,
    urbanicity       = urbanicity,
    travel_time      = travel_time,
    params           = params
  )

  # Calculate total use duration ==============================================
  duration <- sum(
    duration_low,
    duration_lowmed,
    duration_medhigh,
    duration_high)

  # Calculate dose ============================================================
  ## Brain --------------------------------------------------------------------
  dose_brain <- duration*msar_brain

  ## Body ---------------------------------------------------------------------
  dose_body  <- duration*msar_body

  # Return result =============================================================

  return(NA)
}


###############################################################################
# Calculate mSAR
mpd_msar <- function(
    tissue,
    duration_low,
    duration_lowmed,
    duration_medhigh,
    duration_high,
    use_5g,
    wifi_prop_home,
    wifi_prop_work,
    wifi_prop_travel,
    urbanicity,
    travel_time,
    params = load_params()) {

  # Setup =====================================================================
  ## Define frequency bands for each technology
  data_bands <- c("3g", "4g", "5g")
  wifi_bands <- c("2", "5") # 2.4 GHz and 5.0 GHz

  ## Define functions to get correct params per technology
  data_prop <- function(params, band, use_5g) {
    if (use_5g) {
      params$devices$data[[paste0("data_", band, "_prop")]]
    } else {
      params$devices$data[[paste0("data_", band, "_prop_no5g")]]
    }
  }

  ## Define function to get correct wifi param
  wifi_prop <- function(params, band) {
    params$devices$data[[paste0("wifi_", tech, "_prop")]]
  }

  # Apply mSAR calculation to all data frequency bands ========================
  msar_data <- setNames(
    lapply(data_bands, function(band) {

      prop <- data_prop(params, band, use_5g)

      pwr <- mpd_pwr_data(
        band         = band,
        headp_prop   = headp_prop,
        ear_prop     = ear_prop,
        speaker_prop = speaker_prop,
        urbanicity   = urbanicity,
        travel_time  = travel_time,
        params       = params
      )

      sar <- mpd_sar_data(
        tissue       = tissue,
        band         = band,
        headp_prop   = headp_prop,
        ear_prop     = ear_prop,
        speaker_prop = speaker_prop,
        urbanicity   = urbanicity,
        travel_time  = travel_time,
        params       = params
      )

      prop*sar*pwr
    }),
    data_bands
  )

  # apply mSAR calculation to all WiFi frequency bands =========================
  msar_wifi <- setNames(
    lapply(wifi_bands, function(band) {

      prop <- wifi_prop(params, band, use_5g)

      pwr <- mpd_pwr_wifi(
        band             = band,
        duration_low     = duration_low,
        duration_lowmed  = duration_lowmed,
        duration_medhigh = duration_medhigh,
        duration_high    = duration_high,
        urbanicity   = urbanicity,
        travel_time  = travel_time,
        params       = params
      )

      sar <- mpd_sar_wifi(
        tissue       = tissue,
        band         = band,
        headp_prop   = headp_prop,
        ear_prop     = ear_prop,
        speaker_prop = speaker_prop,
        urbanicity   = urbanicity,
        travel_time  = travel_time,
        params       = params
      )

      prop*sar*pwr
    }),
    wifi_bands
  )

  # Scale mSAR with WiFi vs data use proporion ================================
  msar <- sum(
    prop_data*msar_data,
    prop_wifi*msar_wifi)

  # Combine and return results ================================================
  return(msar)
}


###############################################################################
# Calculate output power
mpd_pwr_data <- function(
    band,
    duration_low,
    duration_lowmed,
    duration_medhigh,
    duration_high,
    urbanicity,
    travel_time,
    params = load_params()) {

  # Calculate location proportions ============================================
  loc_props <- calculate_location_proportions(
    travel_time = travel_time,
    home_prop   = params$global$home_prop,
    outd_prop   = params$global$outd_prop,
    work_prop   = params$global$work_prop)

  ## sum up work/school and home
  loc_props$ind <- loc_props$home + loc_props$work

  # Calculate activity proportions ============================================
  act_props <- act_pwr_props(
    duration_low,
    duration_lowmed,
    duration_medhigh,
    duration_high)

  # Calculate output power ====================================================
  ## Define which locations and activities to consider
  locations   <- c("ind", "out", "travel")
  activities <- c("low", "lowmed", "medhigh", "high")

  ## Define function to calculate power for each location and activity
  ## TODO: move this to helper functions so laptop and tablet may access it
  calculate_pwr <- function(location, activity, loc_props, act_props, params) {
    loc_prop <- loc_props[[as.character(location)]]
    act_prop <- act_props[[as.character(activity)]]
    # get pwr based on location and urbanicity
    if (location == "travel") {
      pwr  <- params$devices$data[[paste("data", band, location, "pwr", sep = "_")]] # urbanicity not considered
    } else {
      pwr  <- params$devices$data[[paste("data", band, substr(urbanicity, 0, 3), location, "pwr", sep = "_")]]
    }
    # get duty cycle based on activity
    dc   <- params$devices$data[[paste("data", band, activity, "dutycycle", sep = "_")]]

    # scale by location proportion
    pwr_scaled <- act_prop*dc*pwr*loc_prop

    return(pwr_scaled)
  }

  pwr <-with(
    expand.grid(
      location = locations,
      activity = activities,
      KEEP.OUT.ATTRS = FALSE
    ),
    sum(
      mapply(
        calculate_pwr,
        location, activity, MoreArgs = list(loc_props, act_props, params)))
  )

  return(pwr)
}

mpd_pwr_wifi <- function(
    band,
    duration_low,
    duration_lowmed,
    duration_medhigh,
    duration_high,
    params = load_params()) {

  # Calculate activity proportions ============================================
  act_props <- act_pwr_props(
    duration_low,
    duration_lowmed,
    duration_medhigh,
    duration_high)
  activities <- c("low", "lowmed", "medhigh", "high")

  # Define function for WiFi calculation and sum over activities ==============
  ## TODO: improve efficiency of getting output power (same for every activity)
  pwr <- sum(
    vapply(
      activities,
      \(activity) {
        print(activity)
        act_prop <- act_props[[activity]]
        print(act_prop)
        dc <- params$devices$data[[paste("wifi", band, activity, "dutycycle", sep = "_")]]
        print(dc)
        pwr <- params$devices$data[[paste("wifi", band, "pwr", sep = "_")]]
        print(pwr)
        return(act_prop*dc*pwr)
      },
      numeric(1)
    )
  )
  return(pwr)
}


###############################################################################
# Calculate SAR
mpd_sar_data <- function(
    duration_low,
    duration_lowmed,
    duration_medhigh,
    duration_high,
    use_5g,
    wifi_prop_home,
    wifi_prop_work,
    wifi_prop_travel,
    urbanicity,
    travel_time,
    params = load_params()) {
  return(NA)
}

mpd_sar_wifi <- function(
    duration_low,
    duration_lowmed,
    duration_medhigh,
    duration_high,
    use_5g,
    wifi_prop_home,
    wifi_prop_work,
    wifi_prop_travel,
    urbanicity,
    travel_time,
    params = load_params()) {
  return(NA)
}
