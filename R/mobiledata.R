###############################################################################
# Calculate dose
#' @export
mobiledata_dose <- function(
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
  # Check input ===============================================================
  ## TODO: add input checks

  # Calculate mSAR ============================================================
  msar <- mpd_msar(
    tissue           = tissue,
    duration_low     = duration_low,
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
  dose <- duration*msar

  # Return result =============================================================
  return(dose)
}

###############################################################################
# Calculate mSAR
mpd_msar <- function(
    tissue,
    duration_low,
    duration_lowmed,
    duration_medhigh,
    duration_high,
    wifi_prop_home,
    wifi_prop_work,
    wifi_prop_travel,
    use_5g,
    urbanicity,
    travel_time,
    params = load_params()) {

  # Setup =====================================================================
  ## Define frequency bands for each technology -------------------------------
  data_bands <- c("3g", "4g", "5g")
  wifi_bands <- c("2", "5") # 2.4 GHz and 5.0 GHz

  ## Calculate overall data vs wifi prop --------------------------------------
  loc_props <- location_props(
    travel_time = travel_time,
    home_prop   = params$global$home_prop,
    work_prop   = params$global$work_prop,
    outd_prop   = params$global$outd_prop)

  wifi_prop_overall <- sum(
    loc_props$home * wifi_prop_home, # assumption of no WiFi outdoors
    loc_props$work * wifi_prop_work,
    loc_props$travel * wifi_prop_travel
  )
  data_prop_overall <- 1-wifi_prop_overall

  # Apply mSAR calculation to all data frequency bands ========================
  msar_data <- sum(
    vapply(
      data_bands,
      \(band) {

      if (use_5g) {
        prop <- params$devices$data[[paste0("data_", band, "_prop")]]
      } else {
        prop <- params$devices$data[[paste0("data_", band, "_prop_no5g")]]
      }

      pwr <- mpd_pwr_data(
        band         = band,
        duration_low     = duration_low,
        duration_lowmed  = duration_lowmed,
        duration_medhigh = duration_medhigh,
        duration_high    = duration_high,
        urbanicity   = urbanicity,
        travel_time  = travel_time,
        params       = params
      )

      sar <- mpd_sar_data(
        tissue       = tissue,
        band         = band,
        params       = params
      )
      return(prop*sar*pwr)
      },
      numeric(1)
    )
  )

  # apply mSAR calculation to all WiFi frequency bands =========================
  msar_wifi <- sum(
    vapply(
      wifi_bands,
      \(band) {

      prop <- params$global[[paste0("wifi_", band, "_prop")]]

      pwr <- mpd_pwr_wifi(
        band             = band,
        duration_low     = duration_low,
        duration_lowmed  = duration_lowmed,
        duration_medhigh = duration_medhigh,
        duration_high    = duration_high,
        params           = params
      )

      sar <- mpd_sar_wifi(
        tissue       = tissue,
        band         = band,
        params       = params
      )
      prop*sar*pwr
    },
    numeric(1)
    )
  )

  # Scale mSAR with WiFi vs data use proporion ================================
  msar <- sum(
    data_prop_overall*msar_data,
    wifi_prop_overall*msar_wifi)

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
  loc_props <- location_props(
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
  activities  <- c("low", "lowmed", "medhigh", "high")

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
        act_prop <- act_props[[activity]]
        dc <- params$devices$data[[paste("wifi", band, activity, "dutycycle", sep = "_")]]
        pwr <- params$devices$data[[paste("wifi", band, "pwr", sep = "_")]]
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
    band,
    tissue,
    params = load_params()) {
  # Load tissue-specific params
  tissue_params <- load_tissue_params(params, "data", tissue)
  # Get SAR value, return result
  sar <- tissue_params[[paste("data", band, "sar", sep = "_")]]
  return(sar)
}

mpd_sar_wifi <- function(
    band,
    tissue,
    params = load_params()) {
  # Load tissue-specific params
  tissue_params <- load_tissue_params(params, "data", tissue)
  # Get SAR value, return result
  sar <- tissue_params[[paste("wifi", band, "sar", sep = "_")]]
  return(sar)
}
