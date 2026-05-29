# Calculate total RF-EMF dose (for brain and body) from far-field exposure

###############################################################################
# =============================================================================
#' @export
farfield_dose <- function(
    tissue,
    country,
    urbanicity,
    travel_time,
    params = load_params()) {
  # Check input values ========================================================
  ## TODO: input checks

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

farfield_sar <- function(
    tissue,
    params = load_params()) {
  # Load tissue-specific parameters
  tissue_params <- load_tissue_params(params, "farf", tissue)
  # Get sar and return result
  sar <- tissue_params[["sar"]]
  return(sar)
}
