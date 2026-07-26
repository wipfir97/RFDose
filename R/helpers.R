# =============================================================================
#' Loading parameters
#'
#'@param path Name of parameter file to load (must be in yaml format)
#'@returns List of parameters loaded from yaml input file
load_params <- function(path = NULL,version = "") {
  if (is.null(path)) {
    path <- system.file("extdata", paste0("params",version,".yaml"), package = "RFDose")
  }
  params  <- yaml::read_yaml(path)
  return(params)
}

# =============================================================================
#' Load tissue-specific parameters
#'
#' @param params Device-specific parameter list
#' @param device_type Name of device
#' @param tissue_name Name of tissue
#' @returns Parameter list specific to selected device and tissue
load_tissue_params <- function(params, device_type, tissue_name, dummy) {
  # Check if device name exists in parameter file
  if (!(device_type %in% names(params$devices))) {
    stop("Invalid device type. Choose from: ",
         paste(names(params$devices), collapse = ", "))
  }

  # Extract tissue parameters while keeping device/global parameters
  tissue_params        <- params$devices[[device_type]][[dummy]][[tissue_name]]
  # Flatten list and edit parameter names
  tissue_params        <- unlist(tissue_params)
  names(tissue_params) <- sub("^.*\\.", "", names(tissue_params))
  tissue_params        <- as.list(tissue_params)
  return(tissue_params)
}

# =============================================================================
#' Determine dummy from sex and age
#'

#' @param  Sex male or female
#' @param  Age adult or child
#' @returns Name of the dummy
determine_dummy <- function(sex, age) {
  if (sex == "male" && age == "adult") return("Duke")
  if (sex == "female" && age == "adult") return("Ella")
  if (sex == "male" && age == "child") return("Thelonious")
  if (sex == "female" && age == "child") return("Eartha")
  NA_character_
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
    tol <- .Machine$double.eps^0.5  # tolerance for floating point 0
    if (proportion > 1 | proportion < -tol | is.na(proportion)) {
      stop("Input proportion(s) are not between 0 and 1.")
    }
  }

  # For vector of proportions, check if they add up to 1 or are all 0
  if (length(proportions) > 1) {
    if (!isTRUE(all.equal(sum(unlist(proportions)), 1, tolerance = 1e-6))) {
      if(!(sum(unlist(proportions)) == 0)) {
        warning("Input proportions do not sum to 1.")
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
  # Ensure input is numeric and not NA
  problems <- c()
  if (any(!is.numeric(duration))) {
    stop("Duration must be numeric. Check your input values.")
  }

  if (any(is.na(duration))) {
    stop("Duration must not be NA. Check your input values.")
  }

  if (any(duration < 0)) {
    stop("Duration cannot be a negative value. Check your input values.")
  }

  if (any(duration > 86400)) {
    problems <- c(problems, "Some durations exceed 86400 seconds per day.")
  }

  if (sum(duration) > 86400) {
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
check_numeric_not_na <- function(x) {
  if (length(x) != 1L || !is.numeric(x) || is.na(x)) {
    stop("Value must be numeric and non-NA")
  } else {
    return(TRUE)
  }
}

# =============================================================================
#' Check if value is character and non-NA
#'
#' @param x number
#' @param name name of value
check_character_not_na <- function(x) {
  if (length(x) != 1L || !is.character(x) || is.na(x)) {
    stop("Value must be type character and non-NA")
  }
}

# =============================================================================
#' Check if value is boolean and non-NA
#'
#' @param x number
#' @param name name of value
check_boolean_not_na <- function(x) {
  if (length(x) != 1L || !is.logical(x) || is.na(x)) {
    stop("Value must be type Boolean and non-NA")
  }
}

# =============================================================================
#' Check input value s- urbanicity
#'
#' @param urbanicity urbanicity
check_urbanicity <- function(urbanicity) {
  check_character_not_na(urbanicity)
  # Ensure input contains only valid urbanicity values
  valid_urbanicity <- c("rural", "suburban", "urban")

  if (!urbanicity %in% valid_urbanicity) {
    stop("Invalid urbanicity input value. Please enter rural, suburban, or urban.")
  }
}

# =============================================================================
#' Check tissue
#'
#' @param tissue Tissue
#' @param device Device
#' @param params Params
check_tissue <- function(tissue, device, params,dummy) {
  check_character_not_na(tissue)
  param_names <- names(params$devices[[device]][[dummy]])
  if (!(tissue %in% param_names)) {
    stop("Invalid tissue.")
  }
}

# =============================================================================
#' Check input values - country
#'
#' @param country Country
check_country <- function(country) {
  check_character_not_na(country)
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
  if (!headp_num %in% c(1, 2)) {
    stop("Invalid number of headphones. Must be 1 or 2.")
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
location_props <- function(
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
act_pwr_props <- function(
    low_dur,
    lowmed_dur,
    medhigh_dur,
    high_dur) {
  total_dur    <- sum(low_dur, lowmed_dur, medhigh_dur, high_dur)
  if (total_dur == 0) {
    return(list("low"     = 0,
                "lowmed"  = 0,
                "medhigh" = 0,
                "high"    = 0))
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
#' Distance-based SAR scaling using the inverse-square law
#'
#' Adjusts a reference Specific Absorption Rate (SAR) value to a different
#' phone-to-body distance using an inverse-square distance law with a small
#' near-field offset. The scaling follows:
#'
#' \deqn{SAR(d) = SAR(d_{ref}) \left(\frac{d_{ref} + \delta}{d + \delta}\right)^2}
#'
#' where \eqn{d} is the target distance, \eqn{d_{ref}} is the reference
#' distance at which the SAR value was computed (e.g. 200 mm), and
#' \eqn{\delta} is a small near-field offset (typically around 6 mm).
#'
#' @param sar_ref Numeric. Reference SAR value at `dist_ref`.
#' @param dist Numeric. Target phone-to-body distance.
#' @param dist_ref Numeric. Reference distance at which `sar_ref` was computed.
#' @param delta Numeric. Near-field offset added to both distances.
#'
#' @return Numeric. The SAR value scaled to the target distance.
#'
#' @export
dist_law <- function(sar_ref,dist,dist_ref,delta){

  return(sar_ref*((dist_ref+delta)/(dist + delta))^2)
}

