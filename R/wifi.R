# =============================================================================
#' Calculate RF-EMF Dose from WiFi Router
#'
#' Calculates the tissue-specific RF-EMF dose from WiFi router
#'
#' @details
#'
#' The RF-EMF dose from WiFi router is calculated as:
#'
#' \deqn{Dose_{WiFi} = mSAR_{WiFi} \times duration_{WiFi}}
#'
#' Where:
#'
#' * \eqn{Dose_{WiFi}} is the dose from WiFi Router
#' * \eqn{mSAR_{WiFi}} is the momentary SAR value in mW/kg (see [wifi_msar()])
#' * \eqn{duration_{WiFi}} is the duration of time exposed to a WiFi router in seconds/day
#'
#' The exposure lasts the whole time at home and at work, none of the time
#' outdoors, and the whole time commuting if WiFi is used while commuting
#' (`wifi_prop_travel` above 0):
#'
#' \deqn{duration_{WiFi} = 86400 \times (t_{home} + t_{work} + t_{travel})}
#'
#' where \eqn{t} are the shares of the day at home, at work and commuting (see
#' [location_props()]); \eqn{t_{travel}} counts only if `wifi_prop_travel` is
#' above 0.
#'
#' @param tissue Tissue for which to calculate dose (default: "brain" or "body")
#' @param travel_time Time spent commuting in seconds per day
#' @param wifi_prop_travel Proportion of time connected to WiFi (vs mobile data)
#' while commuting
#' @param params Parameter list (optional). If not specified, calculations use
#' default parameters.
#'
#' @returns Tissue-specific RF-EMF dose from Wifi router in mJ/kg/day
#'
#' @examples
#' wifi_dose(
#'   tissue           = "body",
#'   travel_time      = 1800,
#'   wifi_prop_travel = 0.5)
#'
#' @export
#' @seealso [wifi_msar()]
wifi_dose <- function(
    tissue,
    travel_time,
    wifi_prop_travel,
    params = load_params()) {
  # Input checks ==============================================================
  check_tissue(tissue, "data", params)
  check_duration(travel_time)
  check_proportions(wifi_prop_travel)

  # Calculate exposure duration ===============================================
  loc_props <- location_props(
    travel_time = travel_time,
    home_prop   = params$global$home_prop,
    outd_prop   = params$global$outd_prop,
    work_prop   = params$global$work_prop)

  # assumption: always WiFi exposure at home and at work
  # assumption: no WiFi exposure outdoors
  # assumption: if wifi_prop_travel > 0, always WiFi exposure while commuting,
  #             else no WiFi exposure
  if (wifi_prop_travel == 0) {
    wifi_on_commute <- 0
  } else {
    wifi_on_commute <- 1
  }
  duration <- 86400 * sum(
    loc_props$home, # assumption: always WiFi exposure at home and work
    loc_props$work, # assumption: no WiFi exposure outdoors
    loc_props$travel * wifi_on_commute)

  # Calculate mSAR ============================================================
  ## Brain --------------------------------------------------------------------
  msar <- wifi_msar(
    tissue = tissue,
    params = params
  )

  # Calculate dose and return result ==========================================
  dose <- duration*msar
  return(dose)
}

# =============================================================================
#' Calculate mSAR of WiFi Router
#'
#' Calculates the mSAR of WiFi Router
#'
#' @details
#' \deqn{mSAR_{WiFi} = \sum_{b} s_{b} \times nSAR_{b} \times S_{b}}
#'
#' where \eqn{s_{b}} is the share of the frequency band \eqn{b} (2.4 and 5
#' GHz), \eqn{nSAR_{b}} the normalized SAR in W/kg per W/m\eqn{^2} (see
#' [wifi_sar()]) and \eqn{S_{b}} the power density of the WiFi router in
#' mW/m\eqn{^2} (see [wifi_pwr()]). The time spent commuting and the WiFi use
#' while commuting only change the exposure time (see [wifi_dose()]).
#'
#' @param tissue Tissue for which to calculate mSAR (default: "brain" or "body")
#' @param params Parameter list (optional). If not specified, calculations use
#' default parameters.
#'
#' @returns mSAR in mW/kg
#'
#' @examples
#' wifi_msar(
#'   tissue = "body")
#'
#' @export
#' @seealso [wifi_pwr()], [wifi_sar()]
wifi_msar <- function(
    tissue,
    params = load_params()) {
  # Calculate mSAR ============================================================
  bands <- c("2", "5") # 2.4 GHz, 5.0 GHz
  msar <- sum(
    vapply(
      bands,
      \(band) {
        # Power density
        pwr <- wifi_pwr(
          band = band,
          params = params
        )
        # SAR
        sar <- wifi_sar(
          tissue = tissue,
          band   = band,
          params = params
        )
        # Band proporion
        prop_band <- params$global[[paste("wifi", band, "prop", sep = "_")]]
        # Calculate mSAR and return results
        msar_band <- pwr*sar*prop_band
        return(msar_band)
      },
      numeric(1)
    )
  )
  return(msar)
}


# =============================================================================
#' Calculate Power Density of WiFi Router
#'
#' Calculates the power density of WiFi router
#'
#' @details
#' The power density depends on the WiFi frequency band.
#'
#' @param band Frequency band ("2" for 2.4 GHz, "5" for 5.0 GHz)
#' @param params Parameter list (optional). If not specified, calculations use
#' default parameters.
#'
#' @returns Power density in mW/m\eqn{^2}
#'
#' @examples
#' wifi_pwr(
#' band = "2")
#'
#' @export
wifi_pwr <- function(
    band,
    params = load_params()) {
  # parameter name based on input
  param_name <- paste("wifi", band, "pwr", sep = "_")
  # get parameter value and return result
  pwr <- params$devices$wifi[[param_name]]
  return(pwr)
}

# =============================================================================
#' Calculate nSAR from WiFi Router
#'
#' Calculates tissue-specific nSAR from WiFi Router
#'
#' @details
#' The normalized specific absorption rate (nSAR) depends on the tissue and
#' the WiFi frequency band.
#'
#' @param tissue Tissue for which to calculate nSAR (default: "brain" or "body")
#' @param band Frequency band ("2" for 2.4 GHz, "5" for 5.0 GHz)
#' @param params Parameter list (optional). If not specified, calculations use
#' default parameters.
#'
#' @returns nSAR in W/kg per W/m\eqn{^2} of incident power density
#'
#' @examples
#' wifi_sar(
#' tissue = "brain",
#' band   = "5")
#'
#' @export
wifi_sar <- function(
    tissue,
    band,
    params = load_params()) {
  # Load tissue-specific parameters
  tissue_params <- load_tissue_params(params, "wifi", tissue)
  # Parameter name based on input
  param_name    <- paste("wifi", band, "sar", sep = "_")
  # Get parameter value and return result
  sar <- tissue_params[[param_name]]
  return(sar)
}
