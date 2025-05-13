# =============================================================================
#' Purrr-style operator (grapes or or grapes)
#'
#' @param a a
#' @param b b
`%||%` <- function(a, b) {
  if (!is.null(a)) a else b
}

# =============================================================================
#' Loading parameters
#'
#'@param filename Name of parameter file to load (must be in yaml format)
#'@returns List of parameters loaded from yaml input file
load_params <- function(filename) {
  params_file     <- system.file("extdata", filename,
                                 package = "ETAINDoseCalculator")
  params          <- read_yaml(params_file)
  return(params)
}

# =============================================================================
#' Load device-specific parameters
#'
#' @param params Parameter list
#' @param device_type Device type
#' @returns Parameter list specific to selected device
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
#' @param device_params Device-specific parameter list
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

# ============================================================================
#' Merge custom parameters with base parameters
#'
#' @param base base parameter list
#' @param custom custom parameter list
#' @returns Modified parameter YAML
merge_custom_base_params <- function(base,
                                     custom) {
  return(NA)
}


# ============================================================================
#' Helper function to convert flat parameter list to nested YAML
#'
#' @param lst list
#' @param keys keys
#' @param value value
#' @returns nested parameter list
add_path <- function(lst, keys, value) {
  if (length(keys) == 1) {
    lst[[keys]] <- value
  } else {
    key <- keys[1]
    rest <- keys[-1]
    lst[[key]] <- add_path(lst[[key]], rest, value)
  }
  return(lst)
}

#' Convert flat parameter table to nested parameter YAML
#'
#' @param flat Flat parameter data frame with "path" and "value" columns
#' @returns nested parameter list
flat_params_to_nested <- function(flat) {
  nested_list <- list()

  for (i in seq_len(nrow(flat))) {
    keys <- strsplit(flat$path[i], "\\.")[[1]]
    nested_list <- add_path(nested_list, keys, flat$value[i])
  }
  return(nested_list)
}


# ============================================================================
#' Convert nested parameter YAML to flat parameter table
#'
#' @param nested nested YAML parameter list
#' @param parent_path parent path (optional)
#' @returns flat parameter list
nested_params_to_flat <- function(nested,
                                  parent_path = NULL) {
  # Generate output list
  out <- list()
  # Go through nested list elements, paste names with .
  for (name in names(nested)) {
    full_path <- c(parent_path, name)
    if (is.list(nested[[name]])) {
      out <- c(out, nested_params_to_flat(nested[[name]], full_path))
    } else {
      path_str <- paste(full_path, collapse = ".")
      out[[path_str]] <- nested[[name]]
    }
  }
  return(out)
}

# =============================================================================
#' Check input values - proportions
#'
#' @param proportions Single proportion avlue or vector with proportions to check
#' @returns TRUE if proportions are valid, FALSE if invalid
check_proportions <- function(proportions) {
  # Ensure input is numeric
  if (!is.numeric(proportions)) {
    warning("Input proportions must be numeric. Check your input values.")
    return(FALSE)
  }

  # Check if proportions are each below 0
  for (proportion in proportions) {
    if (proportion > 1 | proportion < 0) {
      warning("Input proportions must be between 0 and 1. Check your input values.")
      return(FALSE)
    }
  }

  # For vector of proportions, check if they add up to 1
  if (length(proportions) > 1) {
    if (!isTRUE(all.equal(sum(proportions), 1, tolerance = 1e-6))) {
      print(proportions)
      warning("Proportions do not sum to 1. Check your input values.")
      return(FALSE)
    }
  }
  return(TRUE)  # Valid proportions
}

# =============================================================================
#' Check input values - duration
#'
#' @param duration duration
#' @returns TRUE if duration is valid, FALSE if duration is not valid
check_duration <- function(duration) {
  # Ensure input is numeric
  if (!is.numeric(duration)) {
    warning("Duration must be numeric. Check your input values.")
    return(FALSE)
  }

  if (duration < 0 | duration > 86400) {
    warning("Duration must be between 0 and 86400 seconds. Check your input values.")
    return(FALSE)
  }
  return(TRUE)
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
#' Check input parameter list
#'
#' @param params parameter list in YAML format
#' @returns TRUE if parameter list is valid, FALSE if parameter list is invalid
check_input_param_list <- function(params) {
  return(FALSE)
}

# =============================================================================
#' Load default parameter list
#'
#' @param dest_file location where downloaded YAML file should be saved
save_default_params_file <- function(dest_file = NULL) {
  if (is.null(dest_file)) {dest_file <- "default_parameters.yaml"}

  yaml::write_yaml(params, file = dest_file)
  return(FALSE)
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
