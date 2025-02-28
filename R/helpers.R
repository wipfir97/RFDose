placeholder_function <- function() {
  return(0)
}
# =============================================================================
#' Loading parameters
#'
#'@param filename Name of parameter file to load (must be in yaml format)
#'@returns List of parameters loaded from yaml input file
load_params <- function(filename) {
  params_file     <- system.file("extdata", filename,
                                 package = "EMFDoseCalculatoR")
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

# =============================================================================
#' Check input values - proportions
#'
#' @param proportions Vector with proportions to check
#' @returns TRUE if proportions are valid, FALSE if invalid
check_proportions <- function(proportions) {
  # Ensure input is numeric
  if (!is.numeric(proportions)) {
    warning("Input proportions must be numeric.")
    return(FALSE)
  }

  # Check if proportions sum to approximately 1
  if (!isTRUE(all.equal(sum(proportions), 1, tolerance = 1e-6))) {
    warning("Proportions do not sum to 1. Check your input values.")
    return(FALSE)
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
    warning("Duration must be numeric.")
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
    stop("Invalid values found. Allowed values are: 'urban', 'suburban', 'rural'.")
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
