# =============================================================================
#' Calculate RF-EMF Dose from Far-field Sources
#'
#' Calculates the tissue-specific RF-EMF dose from far-field sources
#'
#' @details
#'
#' The RF-EMF dose from far-field sources is calculated as:
#'
#' \deqn{Dose_{farfield} = mSAR_{farfield}*86400}
#'
#' Where:
#'
#' * \eqn{Dose_{farfield}} is the dose from far-field sources
#' * \eqn{mSAR_{farfield}} is the momentary SAR value in mJ/kg
#'
#' @param tissue Tissue for which to calculate dose (default: "brain" or "body")
#' @param country Country of residence (Austria = "AT", Belgium = "BE", France = FR,
#' Hungary = "HU", Italy = "IT", Netherlands = "NL", Poland = "PL", Spain = "ES",
#' Switzerland = "CH", United Kingdom = "UK", elsewhere = "Other")
#' @param urbanicity Urbanicity of home / workplace (rural, suburban, or urban)
#' @param travel_time Time spent commuting in seconds per day
#' @param params Parameter list (optional). If not specified, calculations use
#' default parameters.
#'
#' @returns Tissue-specific RF-EMF dose from far-field sources in mJ/kg/day
#'
#' @examples
#' farfield_dose(
#'   tissue      = "body",
#'   country     = "CH",
#'   urbanicity  = "suburban",
#'   travel_time = 1800)
#'
#' @seealso [farfield_msar()]
#' @export
farfield_dose <- function(
    tissue,
    country,
    urbanicity,
    travel_time,
    params = load_params()) {
  # Check input values ========================================================
  check_tissue(tissue, "data", params)
  check_country(country)
  check_urbanicity(urbanicity)
  check_duration(travel_time)

  # Calculate mSAR ============================================================
  ## Brain --------------------------------------------------------------------
  msar <- farfield_msar(
    tissue      = tissue,
    country     = country,
    urbanicity  = urbanicity,
    travel_time = travel_time,
    params      = params
  )

  # Calculate dose and return result ==========================================
  duration <- 86400 # assumption: exposed all day
  dose <- duration*msar

  return(dose)
}

# =============================================================================
#' Calculate mSAR of Far-field Sources
#'
#' Calculates the mSAR of far-field sources
#'
#' @details
#' The output power depends on the country, urbanicity, and time spent commuting.
#'
#' @param tissue Tissue for which to calculate nSAR (default: "brain" or "body")
#' @param country Country of residence (Austria = "AT", Belgium = "BE", France = FR,
#' Hungary = "HU", Italy = "IT", Netherlands = "NL", Poland = "PL", Spain = "ES",
#' Switzerland = "CH", United Kingdom = "UK", elsewhere = "Other")
#' @param urbanicity Urbanicity of home / workplace (rural, suburban, or urban)
#' @param travel_time Time spent commuting in seconds per day
#' @param params Parameter list (optional). If not specified, calculations use
#' default parameters.
#'
#' @returns mSAR in W/kg/W/m**2
#'
#' @examples
#' farfield_msar(
#'   tissue      = "body",
#'   country     = "CH",
#'   urbanicity  = "suburban",
#'   travel_time = 1800)
#'
#' @export
#' @seealso [farfield_pwr()], [farfield_sar()]
farfield_msar <- function(
    tissue,
    country,
    urbanicity,
    travel_time,
    params = load_params()) {
  # Calculate output power / farfield exposure ================================
  pwr <- farfield_pwr(
    country     = country,
    urbanicity  = urbanicity,
    travel_time = travel_time,
    params      = params
  )
  # Calculate nSAR ============================================================
  sar <- farfield_sar(
    tissue = tissue,
    params = params
  )
  # Calculate mSAR and return result ==========================================
  msar <- pwr*sar

  return(msar)
}

# =============================================================================
#' Calculate Output Power of Far-field Sources
#'
#' Calculates the output power of far-field sources
#'
#' @details
#' The output power depends on the country, urbanicity, and time spent commuting.
#'
#' @param country Country of residence (Austria = "AT", Belgium = "BE", France = FR,
#' Hungary = "HU", Italy = "IT", Netherlands = "NL", Poland = "PL", Spain = "ES",
#' Switzerland = "CH", United Kingdom = "UK", elsewhere = "Other")
#' @param urbanicity Urbanicity of home / workplace (rural, suburban, or urban)
#' @param travel_time Time spent commuting in seconds per day
#' @param params Parameter list (optional). If not specified, calculations use
#' default parameters.
#'
#' @returns Output power in mW/m**2
#'
#' @examples
#' farfield_pwr(
#' country     = "CH",
#' urbanicity  = "suburban",
#' travel_time = 1800)
#'
#' @export
farfield_pwr <- function(
    country,
    urbanicity,
    travel_time,
    params = load_params()) {
  # Calculate location proportions
  loc_props <- location_props(
    travel_time = travel_time,
    home_prop   = params$global$home_prop,
    outd_prop   = params$global$outd_prop,
    work_prop   = params$global$work_prop)
  locations   <- c("home", "work", "out", "travel")
  # Define prefix
  # Calculate exposure for each location and sum
  pwr <- sum(
    vapply(
      locations,
      \(loc) {
        loc_prop   <- loc_props[[loc]]
        if (loc == "travel") {
          param_name <- paste(loc, "pwr", country, sep = "_")
        } else {
          param_name <- paste(loc, substr(urbanicity, 0, 3), "pwr", country, sep = "_")
        }
        loc_pwr    <- params$devices$farf[[param_name]]
        loc_pwr_scaled <- loc_prop*loc_pwr
        return(loc_pwr_scaled)
      },
      numeric(1)
    )
  )
  return(pwr)
}


# =============================================================================
#' Calculate nSAR from Far-Field Sources
#'
#' Calculates tissue-specific nSAR from far-field sources.
#'
#' @details
#' The normalized specific absorption rate (nSAR) depends on the tissue.
#'
#' @param tissue Tissue for which to calculate nSAR (default: "brain" or "body")
#' @param params Parameter list (optional). If not specified, calculations use
#' default parameters.
#'
#' @returns nSAR in W/kg/W/m**2
#'
#' @examples
#' farfield_sar(
#' tissue       = "brain")
#'
#' @export
farfield_sar <- function(
    tissue,
    params = load_params()) {
  # Load tissue-specific parameters
  tissue_params <- load_tissue_params(params, "farf", tissue)
  # Get sar and return result
  sar <- tissue_params[["sar"]]
  return(sar)
}
