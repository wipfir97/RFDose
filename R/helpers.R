# =============================================================================
#' Loading parameters
#'
#'@param path Name of parameter file to load (must be in yaml format)
#'@returns List of parameters loaded from yaml input file
load_params <- function(path = NULL) {
  if (is.null(path)) {
    path <- system.file("extdata", "params.yaml", package = "RFDose")
  }
  params          <- yaml::read_yaml(path)
  return(params)
}

# =============================================================================
#' Load device-specific parameters
#'
#' @param params Parameter list
#' @param device_type Device type
#' @returns Parameter list specific to selected device
#' @importFrom utils modifyList
load_device_params <- function(params, device_type) {
  # Check if device name exists in parameter file
  if (!(device_type %in% names(params$devices))) {
    stop("Invalid device type. Choose from: ",
         paste(names(params$devices), collapse = ", "))
  }
  # Merge global parameters with device-specific parameters
  device_params        <- modifyList(params$global,
                                     params$devices[[device_type]]$shared)
  # Flatten list and edit parameter names
  device_params        <- unlist(device_params)
  names(device_params) <- sub("^.*\\.", "", names(device_params))
  device_params        <- as.list(device_params)
  return(device_params)
}

# =============================================================================
#' Load tissue-specific parameters
#'
#' @param params Device-specific parameter list
#' @param device_type Name of device
#' @param tissue_name Name of tissue
#' @returns Parameter list specific to selected device and tissue
load_tissue_params <- function(params, device_type, tissue_name) {
  # Check if device name exists in parameter file
  if (!(device_type %in% names(params$devices))) {
    stop("Invalid device type. Choose from: ",
         paste(names(params$devices), collapse = ", "))
  }

  # Extract tissue parameters while keeping device/global parameters
  tissue_params        <- params$devices[[device_type]][[tissue_name]]
  # Flatten list and edit parameter names
  tissue_params        <- unlist(tissue_params)
  names(tissue_params) <- sub("^.*\\.", "", names(tissue_params))
  tissue_params        <- as.list(tissue_params)
  return(tissue_params)
}



# =============================================================================
#' Check input values - proportions
#'
#' @param proportions Single proportion avlue or vector with proportions to check
#' @returns TRUE if proportions are valid, FALSE if invalid
check_proportions <- function(proportions) {
  # Ensure input is numeric
  for (proportion in proportions) {
    if (!is.numeric(proportion)) {
      stop("Input proportions must be numeric. Check your input values.")
    }
  }

  # Check if proportions are each below 0
  for (proportion in proportions) {
    if (proportion > 1 | proportion < 0 | is.na(proportion)) {
      stop("Input proportions must be between 0 and 1. Check your input values.")
    }
  }

  # For vector of proportions, check if they add up to 1 or are all 0
  if (length(proportions) > 1) {
    if (!isTRUE(all.equal(sum(unlist(proportions)), 1, tolerance = 1e-6))) {
      if(!(sum(unlist(proportions)) == 0)) {
        stop("Proportions do not sum to 1. Check your input values:")
      }
    }
  }
}

# =============================================================================
#' Check input values - duration
#'
#' @param duration single duration value or vector
#' @returns TRUE if duration is valid, FALSE if duration is not valid
check_duration <- function(duration) {
  # Ensure input is numeric
  problems <- c()
  if (any(!is.numeric(duration))) {
    stop("Duration must be numeric. Check your input values.")
  }

  if (any(duration < 0)) {
    stop("Duration cannot be a negative value. Check your input values.")
  }

  if (any(duration > 86400)) {
    problems <- c(problems, "Some durations exceed 86400 seconds per day.")
  }

  if (sum(duration > 86400)) {
    problems <- c(problems, "The sum of durations exceeds 86400 seconds per day.")
  }

  if (length(problems) > 0) {
    warning(paste(problems, collapes = " "))
  }
}

# =============================================================================
#' Check if value is numeric and non-NA
#'
#' @param x number
#' @param name name of value
check_numeric_not_na <- function(x, name) {
  if (length(x) != 1L || !is.numeric(x) || is.na(x)) {
    stop("{name} must be numeric and non-NA")
  }
}

# =============================================================================
#' Check if value is character and non-NA
#'
#' @param x number
#' @param name name of value
check_character_not_na <- function(x, name) {
  if (length(x) != 1L || !is.character(x) || is.na(x)) {
    stop("{name} must be type character and non-NA")
  }
}

# =============================================================================
#' Check if value is boolean and non-NA
#'
#' @param x number
#' @param name name of value
check_boolean_not_na <- function(x, name) {
  if (length(x) != 1L || !is.logical(x) || is.na(x)) {
    stop("{name} must be type Boolean and non-NA")
  }
}

# =============================================================================
#' Check and re-code input values - urbanicity
#'
#' @param urbanicity descr
#' @returns re-coded urbanicity (binary variables)
recode_urbanicity <- function(urbanicity) {
  # Ensure input contains only valid urbanicity values
  valid_values <- c("urban", "rural", "suburban")
  if (!urbanicity %in% valid_values) {
    stop("Invalid urbanicity values found. Allowed values are: 'urban', 'suburban', 'rural'.")
  }
  # Create output list with recoded urbanicity variable
  out <- list()
  out$home_urban  <- as.integer(urbanicity == "urban")
  out$work_urban  <- as.integer(urbanicity == "urban")
  out$outd_urban  <- as.integer(urbanicity == "urban")
  out$home_suburb <- as.integer(urbanicity == "suburban")
  out$work_suburb <- as.integer(urbanicity == "suburban")
  out$outd_suburb <- as.integer(urbanicity == "suburban")
  out$home_rural  <- as.integer(urbanicity == "rural")
  out$work_rural  <- as.integer(urbanicity == "rural")
  out$outd_rural  <- as.integer(urbanicity == "rural")

  return(out)
}

# =============================================================================
#' Check input value s- urbanicity
#'
#' @param urbanicity urbanicity
check_urbanicity <- function(urbanicity) {
  # Ensure input contains only valid urbanicity values
  valid_urbanicity <- c("rural", "suburban", "urban")

  if (!urbanicity %in% valid_urbanicity) {
    stop("{urbanicity} is an invalid urbanicity input value. Please enter rural, suburban, or urban.")
  }
}

# =============================================================================
#' Check input values - country
#'
#' @param country Country
check_country <- function(country) {
  # Ensure input contains only valid urbanicity values
  valid_countries <- c("AT", "BE", "FR", "HU", "IT", "NL", "PL", "ES", "CH", "UK", "Other")

  if (!country %in% valid_countries) {
    stop("Invalid country input value found.")
  }
}

# =============================================================================
#' Check input values - number of headphones
#'
#' @param headp_num Number of headphones
check_headp_num <- function(headp_num) {
  if (!headp_num %in% c(0, 1, 2)) {
    stop("Invalid number of headphones. Must be 0, 1 or 2.")
  }
}


# =============================================================================
#' Fill missing variables
#'
#' @param data data
#' @param defaults defaults
#' @param warn_threshold threshold proportion of missing data to raise warning
#' @returns data frame with missing data replaced with default values
fill_missing_variables <- function(data, defaults, warn_threshold = 0.1) {
  # List that stores number of replacements for each variable
  replaced <- list()
  # Count number of rows
  n_rows <- nrow(data)
  # Replace empty strings with NA for character variables
  data[data==""]<-NA

  for (var in names(defaults)) {
    if (!var %in% colnames(data)) {
      # Entirely missing column → fill with default
      data[[var]] <- rep(defaults[[var]], n_rows)
      replaced[[var]] <- n_rows
    } else {
      # Count NAs
      n_missing <- sum(is.na(data[[var]]))
      replaced[[var]] <- n_missing

      if (n_missing > 0) {
        data[[var]][is.na(data[[var]])] <- defaults[[var]]
      }

      # Warn if proportion missing exceeds threshold
      if (n_missing / n_rows > warn_threshold) {
        warning(sprintf("Variable '%s' had %.1f%% missing values replaced (threshold %.0f%%)",
                        var, 100 * n_missing / n_rows, 100 * warn_threshold))
      }
    }
  }

  return(list(data = data, replaced = replaced))
}

# =============================================================================
#' Calculate proportion of time spent at home vs work vs outdoors vs travelling
#'
#' Based on travel time (input variable by user), assuming a fixed ration for
#' time spent at home vs work vs outdoors
#' @param travel_time daily time spent travelling / commuting in seconds (s)
#' @param home_prop proportion of time spent at home WITHOUT considering commute
#' @param work_prop proportion of time spent at work WITHOUT considering commute
#' @param outd_prop proportion of time spent outside WITHOUT considering commute
#' @returns list with proportions
calculate_location_proportions <- function(
    travel_time,
    home_prop,
    work_prop,
    outd_prop) {
  # Calculate travel proportion -----------------------------------------------
  #check_duration(travel_time)
  travel_prop_scaled <- travel_time/86400

  # Calculate home proportion --------------------------------------------------
  ## Assumption: we subtract the travel/commute time from the time spent at home,
  ## but not from time outdoors or time at work
  home_prop_scaled   <- home_prop - travel_prop_scaled
  ## ensure travel time is not higher than time spent at home
  #if (home_prop_scaled < 0) {
  #  warning("Time spent travelling/commuting must be lower that time spent at home.")
  #}

  # Calculate work and outdoor proportion -------------------------------------
  work_prop_scaled   <- work_prop
  outd_prop_scaled   <- outd_prop

  # Collect results and check if proportions are valid ------------------------
  scaled_props <- list("travel" = travel_prop_scaled,
                       "home"   = home_prop_scaled,
                       "work"   = work_prop_scaled,
                       "out"   = outd_prop_scaled)
  #check_proportions(unlist(scaled_props))

  return(scaled_props)
}

# =============================================================================
#' Get mobile data technology use proportions
#'
#' Based on user variable use_5g that indicates if participant uses 5G on mobile
#' phone or not.
#' @param use_5g boolean variable (TRUE if participant uses 5G, FALSE otherwise)
#' @param params parameter list
#' @returns list with technology use proportions
calculate_data_tech_proportions <- function(use_5g,
                                            params) {
  ## Scale by 3G/4G/5G proportions for 5G users or 5G non-users
  if (use_5g) {
    data_3g <- params$tech_3g_prop
    data_4g <- params$tech_4g_prop
    data_5g <- params$tech_5g_prop
  } else {
    data_3g <- params$tech_3g_prop_5gno
    data_4g <- params$tech_4g_prop_5gno
    data_5g <- params$tech_5g_prop_5gno
  }
  output <- list("prop_3g" = data_3g,
                 "prop_4g" = data_4g,
                 "prop_5g" = data_5g)
  return(output)
}

# =============================================================================
#' Get low/lowmed/medhigh/high activity power proportions
#'
#' @param low_dur ...
#' @param lowmed_dur ...
#' @param medhigh_dur ...
#' @param high_dur ...
act_pwr_props <- function(low_dur,
                          lowmed_dur,
                          medhigh_dur,
                          high_dur) {
  total_dur    <- sum(low_dur, lowmed_dur, medhigh_dur, high_dur)
  if (total_dur == 0) {
    return(list("low_prop"     = 0,
                "lowmed_prop"  = 0,
                "medhigh_prop" = 0,
                "high_prop"    = 0))
  } else {
    low_prop     <- low_dur/total_dur
    lowmed_prop  <- lowmed_dur/total_dur
    medhigh_prop <- medhigh_dur/total_dur
    high_prop    <- high_dur/total_dur
    return(list("low"     = low_prop,
                "lowmed"  = lowmed_prop,
                "medhigh" = medhigh_prop,
                "high"    = high_prop))
  }
}

# =============================================================================
#' Calculate WiFi exposure duration
#'
#' @param travel_time time spent commutng in car/train/bus per day in s
#' @param wifi_prop_travel proportion of time connected to WiFi (vs mobile data) during commute
#' @param home_prop proportion of time per day spent at home
#' @param work_prop proportion of time per day spent at school/work
#' @returns exposure duration in s
calculate_wifi_exposure_duration <- function(travel_time,
                                             wifi_prop_travel,
                                             home_prop,
                                             work_prop) {
  # Assumption: always exposure at home and at work
  # If participant uses WiFi during commute at all, we assume WiFi exposure
  # during whole commute
  if (wifi_prop_travel > 0) {
    wifi_travel_dur <- travel_time
  } else {
    wifi_travel_dur <- 0
  }
  wifi_home_dur   <- home_prop*86400
  wifi_work_dur   <- work_prop*86400
  wifi_dur <- sum(wifi_travel_dur,
                  wifi_home_dur,
                  wifi_work_dur)
  check_duration(wifi_dur)
  return(wifi_dur)
}
