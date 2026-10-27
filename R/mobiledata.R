###############################################################################
# Calculate RF-EMF dose (for brain and body) from mobile data


###############################################################################
# Total mobile data dose ======================================================
#' Calculation of RF-EMF Dose from Mobile Phone Data Use
#'
#' The mobile data RF-EMF dose is calculated as:
#' \deqn{Dose_{data} = mSAR_{data}*duration_{data}}
#'
#' Where:
#'
#' * \eqn{Dose_{data}} is the dose from mobile data use
#' * \eqn{mSAR_{data}} is the momentary SAR value in mW/kg (see [mpd_msar()])
#' * \eqn{duration_{data}} is the duration of mobile data use in s/day (sum of
#'   the durations of the four activities)
#'
#' @details
#'
#' We distinguish between 4 types of mobile data use:
#'
#' 1. Low output power: sending e-mails, browsing the internet, scrolling and
#'    chatting on social media, sending text messages
#' 2. Low to medium output power: online gaming, streaming music, sending voice
#'    messages
#' 3. Medium to high output power: watching videos, uploading pictures or
#'    videos, making video calls
#' 4. High output power: uploading large files
#'
#' @param tissue Tissue for which to calculate dose (default: "brain" or "body")
#' @param duration_low Duration (in seconds per day) of low output power activities
#' @param duration_lowmed Duration (in seconds per day) of low-medium output power activities
#' @param duration_medhigh Duration (in seconds per day) of medium-high output power activities
#' @param duration_high Duration (in seconds per day) of high output power activities
#' @param use_5g TRUE if 5G services are used for data transfer, FALSE if not
#' @param wifi_prop_home Proportion of time connected to WiFi (vs mobile data)
#' at home
#' @param wifi_prop_work Proportion of time connected to WiFi (vs mobile data)
#' at school / work
#' @param wifi_prop_travel Proportion of time connected to WiFi (vs mobile data)
#' while commuting
#' @param urbanicity Urbanicity of home / workplace (rural, suburban, or urban)
#' @param travel_time Time spent commuting in seconds per day
#' @param params Parameter list (optional). If not specified, calculations use
#' default parameters.
#'
#' @returns Tissue-specific RF-EMF dose from data use in mJ/kg/day
#'
#' @examples
#' mobiledata_dose(
#' tissue           = "brain",
#' duration_low     = 4860,
#' duration_lowmed  = 540,
#' duration_medhigh = 4860,
#' duration_high    = 540,
#' use_5g           = FALSE,
#' wifi_prop_home   = 0.5,
#' wifi_prop_work   = 0.5,
#' wifi_prop_travel = 0.5,
#' urbanicity       = "suburban",
#' travel_time      = 1800)
#'
#' @seealso [mpd_msar()]
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
  check_tissue(tissue, "data", params)
  check_duration(c(duration_low, duration_lowmed, duration_medhigh, duration_high))
  check_boolean_not_na(use_5g)
  check_proportions(wifi_prop_home)
  check_proportions(wifi_prop_work)
  check_proportions(wifi_prop_travel)
  check_urbanicity(urbanicity)
  check_duration(travel_time)

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
#' Calculation of mSAR from Mobile Phone Data
#'
#' Calculates mSAR (momentary specifc absorption rate) from data (mobile data
#' and WiFi) use for a specific tissue
#'
#' @details
#' The mSAR is calculated as
#'
#' \deqn{mSAR = (1 - p_{wifi}) \times mSAR_{data} + p_{wifi} \times mSAR_{wifi}}
#'
#' with, for each network \eqn{n} (mobile data or WiFi),
#'
#' \deqn{mSAR_{n} = \sum_{b} s_{n,b} \times nSAR_{n,b} \times P_{n,b}}
#'
#' where
#'
#' * \eqn{p_{wifi} = t_{home} w_{home} + t_{work} w_{work} + t_{travel} w_{travel}}
#'   is the proportion of use over WiFi, with \eqn{t} the shares of the day at
#'   home, at work and commuting (see [location_props()]) and \eqn{w} the WiFi
#'   proportions (`wifi_prop_home`, `wifi_prop_work`, `wifi_prop_travel`); no
#'   WiFi is used outdoors
#' * \eqn{s_{n,b}} is the share of the frequency band \eqn{b}: 3G to 5G for
#'   mobile data (without 5G if `use_5g` is FALSE), 2.4 and 5 GHz for WiFi
#' * \eqn{nSAR_{n,b}} is the normalized SAR in W/kg/W (see [mpd_sar_data()],
#'   [mpd_sar_wifi()])
#' * \eqn{P_{n,b}} is the mean output power of the phone in mW, including the
#'   duty cycles of the activities (see [mpd_pwr_data()], [mpd_pwr_wifi()])
#'
#' @param tissue Tissue for which to calculate mSAR (default: "brain" or "body")
#' @param duration_low Duration (in seconds per day) of low output power activities
#' @param duration_lowmed Duration (in seconds per day) of low-medium output power activities
#' @param duration_medhigh Duration (in seconds per day) of medium-high output power activities
#' @param duration_high Duration (in seconds per day) of high output power activities
#' @param use_5g TRUE if 5G services are used for data transfer, FALSE if not
#' @param wifi_prop_home Proportion of time connected to WiFi (vs mobile data)
#' at home
#' @param wifi_prop_work Proportion of time connected to WiFi (vs mobile data)
#' at school / work
#' @param wifi_prop_travel Proportion of time connected to WiFi (vs mobile data)
#' while commuting
#' @param urbanicity Urbanicity of home / workplace (rural, suburban, or urban)
#' @param travel_time Time spent commuting in seconds per day
#' @param params Parameter list (optional). If not specified, calculations use
#' default parameters.
#'
#' @returns Momentary SAR (mSAR) from mobile data use in mW/kg
#'
#' @examples
#' mpd_msar(
#' tissue           = "brain",
#' duration_low     = 4860,
#' duration_lowmed  = 540,
#' duration_medhigh = 4860,
#' duration_high    = 540,
#' use_5g           = FALSE,
#' wifi_prop_home   = 0.5,
#' wifi_prop_work   = 0.5,
#' wifi_prop_travel = 0.5,
#' urbanicity       = "suburban",
#' travel_time      = 1800)
#'
#' @seealso [mpd_pwr_data()], [mpd_pwr_wifi()], [mpd_sar_data()], [mpd_sar_wifi()]
#' @export
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
# Calculate output power (data)
#' Calculate Mobile Phone Output Power during Mobile Data Use
#'
#' Calculates the mean output power of the mobile phone during mobile data use.
#'
#' @details
#' The output power depends on the technology, on where the phone is used
#' (urbanicity; indoors, outdoors or commuting), and on the activities the
#' phone is used for:
#'
#' \deqn{P = \sum_{l} \sum_{k} t_{l} \times q_{k} \times DC_{k} \times P_{l}}
#'
#' where \eqn{l} is the place (indoors, i.e. at home or at work; outdoors;
#' commuting), \eqn{k} the activity (low to high output power), \eqn{t_{l}} the
#' share of the day at the place (see [location_props()]), \eqn{q_{k}} the share
#' of the activity in the use time (see [act_pwr_props()]), \eqn{DC_{k}} the duty
#' cycle of the activity, and \eqn{P_{l}} the output power at the place in mW
#' (indoors and outdoors: for the urbanicity).
#'
#' @param band Technology ("3g", "4g" or "5g")
#' @param duration_low Duration (in seconds per day) of low output power activities
#' @param duration_lowmed Duration (in seconds per day) of low-medium output power activities
#' @param duration_medhigh Duration (in seconds per day) of medium-high output power activities
#' @param duration_high Duration (in seconds per day) of high output power activities
#' @param urbanicity Urbanicity of home / workplace (rural, suburban, or urban)
#' @param travel_time Time spent commuting in seconds per day
#' @param params Parameter list (optional). If not specified, calculations use
#' default parameters.
#'
#' @returns Output power in mW, including the duty cycles
#'
#' @examples
#' mpd_pwr_data(
#' band             = "4g",
#' duration_low     = 4860,
#' duration_lowmed  = 540,
#' duration_medhigh = 4860,
#' duration_high    = 540,
#' urbanicity       = "rural",
#' travel_time      = 1800)
#'
#' @export
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
# Wifi ========================================================================
#' Calculate Mobile Phone Output Power during WiFi Use
#'
#' Calculates the mean output power of the mobile phone during WiFi use
#'
#' @details
#' The output power depends on the frequency band (2.4 GHz or 5.0 GHz) and the
#' type of activity:
#'
#' \deqn{P = P_{wifi} \times \sum_{k} q_{k} \times DC_{k}}
#'
#' where \eqn{P_{wifi}} is the output power of the band in mW, \eqn{q_{k}} the
#' share of the activity \eqn{k} in the use time (see [act_pwr_props()]) and
#' \eqn{DC_{k}} its duty cycle.
#'
#' @param band WiFi frequency band ("2" for 2.4 GHz, "5" for 5.0 GHz)
#' @param duration_low Duration (in seconds per day) of low output power activities
#' @param duration_lowmed Duration (in seconds per day) of low-medium output power activities
#' @param duration_medhigh Duration (in seconds per day) of medium-high output power activities
#' @param duration_high Duration (in seconds per day) of high output power activities
#' @param params Parameter list (optional). If not specified, calculations use
#' default parameters.
#'
#' @returns Output power in mW, including the duty cycles
#'
#' @examples
#' mpd_pwr_wifi(
#' band             = "2",
#' duration_low     = 4860,
#' duration_lowmed  = 540,
#' duration_medhigh = 4860,
#' duration_high    = 540)
#'
#' @export
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
# Calculate SAR (data) ========================================================
#' Calculate nSAR during mobile data use on mobile phone
#'
#' Calculates tissue-specific nSAR from mobile data use on mobile phone.
#'
#' @details
#' The normalized specific absorption rate (nSAR) depends on the tissue and
#' the frequency band.
#'
#'
#' @param tissue Tissue for which to calculate nSAR (default: "brain" or "body")
#' @param band Technology ("3g", "4g", or "5g")
#' @param params Parameter list (optional). If not specified, calculations use
#' default parameters.
#'
#' @returns nSAR in W/kg/W
#'
#' @examples
#' mpd_sar_data(
#' tissue       = "brain",
#' band         = "5g")
#'
#' @export
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

# Calculate SAR (wifi) ========================================================
#' Calculate nSAR during WiFi Use on mobile phone
#'
#' Calculates tissue-specific nSAR from WiFi use on mobile phone.
#'
#' @details
#' The normalized specific absorption rate (nSAR) depends on the tissue and
#' the frequency band.
#'
#'
#' @param tissue Tissue for which to calculate nSAR (default: "brain" or "body")
#' @param band Frequency band ("2" for 2.4 GHz, "5" for 5.0 GHz)
#' @param params Parameter list (optional). If not specified, calculations use
#' default parameters.
#'
#' @returns nSAR in W/kg/W
#'
#' @examples
#' mpd_sar_wifi(
#' tissue       = "brain",
#' band         = "2")
#'
#' @export
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
