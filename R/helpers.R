# =============================================================================
#' Load dose calculation parameters
#'
#' Loads default parameters or parameters from external source and returns them
#' as a nested list.
#'
#' @param path Path of parameter file to load (must be a YAML file). If null,
#' default parameters are loaded.
#' @returns List of parameters loaded from yaml input file
#'
#' @export
#' @seealso [RFDose::load_tissue_params()]
load_params <- function(path = NULL) {
  if (is.null(path)) {
    path <- system.file("extdata", "params.yaml", package = "RFDose")
  }
  params  <- yaml::read_yaml(path)
  return(params)
}

# =============================================================================
#' Load tissue-specific parameters
#'
#' Loads device- and tissue-specific parameters (SAR values) and returns them as
#' a list.
#'
#' @param params List of parameters (default parameter file or custom YAML that
#' matches default's structure)
#' @param device_type Name of device (default: )
#' @param tissue_name Name of tissue (default: "brain" or "body")
#'
#' @returns List of parameters (SAR values) specific to selected device type and
#' tissue.
#'
#' @export
#' @seealso [RFDOSE::load_params()]
load_tissue_params <- function(params, device_type, tissue_name) {
  # Check if device name exists in parameter file
  if (!(device_type %in% names(params$devices))) {
    stop("Invalid device type. Available devices: ",
         paste(names(params$devices), collapse = ", "))
  }
  # Check if tissue name exists in parameter file
  check_tissue(tissue = tissue_name, device = device_type, params = params)

  # Extract tissue parameters while keeping device/global parameters
  tissue_params        <- params$devices[[device_type]][[tissue_name]]
  # Flatten list and edit parameter names
  tissue_params        <- unlist(tissue_params)
  names(tissue_params) <- sub("^.*\\.", "", names(tissue_params))
  tissue_params        <- as.list(tissue_params)

  return(tissue_params)
}

# =============================================================================

# TODO: Check parameter file validity

## Structure
## All values must be numeric

# =============================================================================

# TODO: Check default value file validity

## Structure
## Correct data type

# =============================================================================
#' Check input proportion(s)
#'
#' Checks supplied input proportion or vector of proportions; needed to stop
#' calculation or raise warning in case of irregular input values.
#'
#' @param proportions Single proportion value (between 0 and 1 ) or vector
#' with multiple proportions to check
#'
#' @returns Returns invisible TRUE if all checks pass. Side effects of stopping
#' or showing warning message if any check fails.
check_proportions <- function(proportions) {
  # Ensure input is not NULL
  if (is.null(proportions) || length(proportions) == 0) {
    stop("Input proportions must not be empty or NULL.")
  }

  # Ensure there are no NAs
  if (anyNA(proportions)) {
    stop("Input proportions must not contain NA values.")
  }

  # Ensure input is numeric (and atomic)
  if (!is.numeric(proportions) || !is.atomic(proportions)) {
    stop("Input proportions must be numeric. Check your input values.")
  }

  tol <- .Machine$double.eps^0.5 # set a tolerance
  # Check if proportions are within allowed range (0 to 1)
  out_of_range <- proportions > (1 + tol) | proportions < -tol
  if (any(out_of_range)) {
    stop("Input proportion(s) are not between 0 and 1.")
  }

  # For vector of proportions, check if they add up to 1 or are all 0
  if (length(proportions) > 1) {
    total <- sum(proportions)
    sums_to_one  <- isTRUE(all.equal(total, 1, tolerance = tol))
    sums_to_zero <- isTRUE(all.equal(total, 0, tolerance = tol))
    if (!sums_to_one && !sums_to_zero) {
      warning("Input proportions do not sum to 1.")
    }
  }

  invisible(TRUE) # returns value but does not print it
}

# =============================================================================
#' Check input duration(s)
#'
#' Checks supplied input duration or vector of durations; needed to stop
#' calculation or raise warning in case of irregular input values.
#'
#' @param duration single duration (numeric) or vector of durations
#'
#' @returns Returns invisible TRUE if all checks pass. Side effects of stopping
#' or showing warning message if any check fails
check_duration <- function(duration) {
  # Ensure input is not NULL
  if (is.null(duration) || length(duration) == 0) {
    stop("Duration must not be empty or NULL.")
  }

  # Ensure there are no NAs
  if (anyNA(duration)) {
    stop("Duration cannot be NA.")
  }

  # Ensure input is numeric (and atomic)
  if (!is.numeric(duration) || !is.atomic(duration)) {
    stop("Duration must be numeric.")
  }

  tol <- .Machine$double.eps^0.5 # set a tolerance
  # Ensure duration is not below 0
  if (any(duration < -tol)) {
    stop("Duration cannot be negative.")
  }

  # Raise warning if sum of durations is higher than number of seconds per day
  if (sum(duration) > (86400 + tol)) {
    warning("The sum of durations exceeds 86400 seconds per day.")
  }

  invisible(TRUE)
}

# =============================================================================
#' Check if value is numeric and non-NA
#'
#' @param x Single value to be checked: should be numeric, atomic, and not NA
#' to pass check
#'
#' @returns Returns invisible TRUE if check passes. Side effect of stopping
#' calculation if check fails.
check_numeric_not_na <- function(x) {
  if (length(x) != 1L || !is.numeric(x) || is.na(x)) {
    stop("Value must be numeric and non-NA")
  }
  invisible(TRUE)
}

# =============================================================================
#' Check if value is character and non-NA
#'
#' @param x Single value to be checked: should be character, atomic, and not NA
#' to pass check
#'
#' @returns Returns invisible TRUE if check passes. Side effect of stopping
#' calculation if check fails.
check_character_not_na <- function(x) {
  if (length(x) != 1L || !is.character(x) || is.na(x)) {
    stop("Value must be type character and non-NA")
  }
  invisible(TRUE)
}

# =============================================================================
#' Check if value is logical/Boolean and non-NA
#'
#' @param x Single value to be checked: should be a logical/Boolean, atomic, and not NA
#' to pass check
#'
#' @returns Returns invisible TRUE if check passes. Side effect of stopping
#' calculation if check fails.
check_boolean_not_na <- function(x) {
  if (length(x) != 1L || !is.logical(x) || is.na(x)) {
    stop("Value must be type Boolean and non-NA")
  }
  invisible(TRUE)
}

# =============================================================================
#' Check if input urbanicity is valid
#'
#' Checks if a supplied urbanicity value is valid (must be "urban", "rural",
#' or "suburban").
#'
#' @param urbanicity Single urbanicity value (must be one of these: "urban", "rural", "suburban")
#'
#' @returns Returns invisible TRUE if checks pass. Side effect of stopping
#' calculation if any check fails.
check_urbanicity <- function(urbanicity) {
  # check that input is not NA and type character
  check_character_not_na(urbanicity)

  # ensure input is atomic (not a list)
  if (length(urbanicity) != 1) {
    stop("urbanicity must be a single value, not a vector of length ",
         length(urbanicity), ".")
  }
  # Ensure input is a valid urbanicity value
  valid_urbanicity <- c("rural", "suburban", "urban")

  if (!urbanicity %in% valid_urbanicity) {
    stop("Invalid urbanicity input value. Please enter rural, suburban, or urban.")
  }
  invisible(TRUE)
}

# =============================================================================
#' Check if tissue is valid
#'
#' Check if tissue with this name can be found in YAML file, and if it has any
#' nested parameters. Parameters themselves are NOT checked for validity.
#'
#' @param tissue Name of tissue to be checked (character, length 1)
#' @param device Device for which to check tissue (character, length 1)
#' @param params Parameter list, as returned by [RFDOSE::load_params()]
#'
#' @returns Returns invisible TRUE if all checks pass. Side effect of stopping
#' calculations if any check fails.
check_tissue <- function(tissue, device, params) {
  check_character_not_na(tissue)
  check_character_not_na(device)

  if (length(tissue) != 1) {
    stop("tissue must be a single character value, not a vector of length ",
         length(tissue), ".")
  }

  device_params <- params$devices[[device]]
  if (is.null(device_params)) {
    stop("Invalid device '", device, "'. Available devices: ",
         paste(names(params$devices), collapse = ", "))
  }

  param_names <- names(device_params)

  if (!(tissue %in% param_names)) {
    stop("Invalid tissue '", tissue, "' for device '", device, "'.")
  }

  tissue_params <- device_params[[tissue]]
  if (is.null(tissue_params) || length(tissue_params) == 0) {
    stop("Tissue '", tissue, "' for device '", device,
         "' has no nested parameters (SAR values).")
  }

  invisible(TRUE)
}

# =============================================================================
#' Check if country is valid
#'
#' Checks if country code matches a country for which measurement data is available.
#' Use "Other" for any other country.
#'
#' @param country Country to check. Must be one of these: "AT" (Austria),
#' "BE" (Belgium), "FR" (France), "HU" (Hungary), "IT" (Italy), "NL" (Netherlands),
#' "PL" (Poland), "ES" (Spain), "CH" (Switzerland), "UK" (United Kingdom), or
#' "Other" (for any other country; calculations use averaged values from countries
#' with available measurements)
#'
#' @returns Returns invisible TRUE if all checks pass. Side effect of stopping
#' calculations if any check fails.
check_country <- function(country) {
  check_character_not_na(country)
  # Check that country code is among valid countries (country with measurement
  # data or "Other")
  valid_countries <- c("AT", "BE", "FR", "HU", "IT", "NL", "PL", "ES", "CH", "UK", "Other")

  if (!country %in% valid_countries) {
    stop("Invalid country. Available countries:", paste(valid_countries, collapse = " ,"))
  }
  invisible(TRUE)
}

# =============================================================================
#' Check if number of headphones (earbuds) is valid
#'
#' Checks if the number of headphones (earbuds) worn during mobile phone
#' calls is either 0, 1, or 2.
#'
#' @param headp_num Number of headphones (earbuds) worn during mobile phone call.
#'
#' @returns Returns invisible TRUE if all checks pass. Side effect of stopping
#' calculations if any check fails.
check_headp_num <- function(headp_num) {
  check_numeric_not_na(headp_num)
  if (!headp_num %in% c(0, 1, 2)) {
    stop("Invalid number of headphones. Must be 0, 1 or 2.")
  }
  invisible(TRUE)
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
#' Based on travel time (input variable by user). Assumes a fixed ratio of time
#' spent at home vs at work vs outdoors.
#'
#' @details We assume that the time spent commuting takes away from time spent
#' at home, but not the time spent at work or outdoors.
#'
#' @param travel_time daily time spent travelling / commuting in seconds (s)
#' @param home_prop proportion of time spent at home WITHOUT considering commute
#' @param work_prop proportion of time spent at work WITHOUT considering commute
#' @param outd_prop proportion of time spent outside WITHOUT considering commute
#'
#' @returns List with following elements: "travel", "home", "work", "out", corresponding
#' value is the proportion of time spent in each location.
location_props <- function(
    travel_time,
    home_prop,
    work_prop,
    outd_prop) {

  # Input checks --------------------------------------------------------------
  check_duration(travel_time)
  check_proportions(c(home_prop, work_prop, outd_prop))

  # Calculate travel proportion -----------------------------------------------
  travel_prop_scaled <- travel_time/86400

  # Calculate home proportion --------------------------------------------------
  ## Assumption: we subtract the travel/commute time from the time spent at home,
  ## but not from time outdoors or time at work
  home_prop_scaled   <- home_prop - travel_prop_scaled

  ## ensure travel prop is not higher than time spent at home
  if (home_prop_scaled < 0) {
    stop("Calculation not defined if travel_time is higher than assumed time spend at home.")
  }

  # Calculate work and outdoor proportion -------------------------------------
  work_prop_scaled   <- work_prop
  out_prop_scaled    <- outd_prop

  # Collect results and check if proportions are valid ------------------------
  scaled_props <- list(
    "travel" = travel_prop_scaled,
    "home"   = home_prop_scaled,
    "work"   = work_prop_scaled,
    "out"    = out_prop_scaled)

  check_proportions(unlist(scaled_props))

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
act_pwr_props <- function(
    low_dur,
    lowmed_dur,
    medhigh_dur,
    high_dur) {

  # make vector of durations
  durations <- c(
    low     = low_dur,
    lowmed  = lowmed_dur,
    medhigh = medhigh_dur,
    high    = high_dur)

  # each input must be a single value, not a vector
  if (any(vapply(list(low_dur, lowmed_dur, medhigh_dur, high_dur),
                 length, integer(1)) != 1)) {
    stop("Each duration input must be a single value.")
  }

  # input check
  check_duration(durations)

  # calculate sum of durations
  total_dur    <- sum(durations)

  if (total_dur == 0) {
    result <- list("low" = 0, "lowmed" = 0, "medhigh" = 0, "high" = 0)
  } else {
    result <- list(
      "low"     = low_dur / total_dur,
      "lowmed"  = lowmed_dur / total_dur,
      "medhigh" = medhigh_dur / total_dur,
      "high"    = high_dur / total_dur
    )
    check_proportions(unlist(result))
  }
  return(result)
}
