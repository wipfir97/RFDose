# Calculate total RF-EMF dose (for brain and body) from WiFi
#
# This source covers the WiFi network the person is CONNECTED TO or sitting
# next to: the router at home, the network at the office, and the access point
# on a train or in a cafe while it is being used. Networks the person is merely
# surrounded by, without using them, are ambient exposure and belong to
# farfield.R -- Adriana's campaign measured outdoors and in public indoor
# spaces, so it never captured a network anyone was connected to at home or at
# work. The two sources are disjoint and correctly additive.
#
# Structurally it is an ambient source like farfield: a power density in mW/m2
# times how much of it the body absorbs, times the time spent in the field.
# There is no device against the body, so no distance correction.

###############################################################################
# =============================================================================
#' Calculate the daily RF-EMF dose from WiFi
#'
#' @param tissue "body" or "brain"
#' @param travel_time Time spent travelling per day, in seconds
#' @param wifi_prop_travel Proportion of the travel time with WiFi in use
#' @param params Parameter list
#' @returns Tissue-specific RF-EMF dose from WiFi in mJ/kg/day
#' @export
wifi_dose <- function(
    tissue,
    travel_time,
    wifi_prop_travel,
    params = load_params()) {
  # Input checks ==============================================================
  ## TODO add input checks

  # Calculate exposure duration ===============================================
  # Until 2026-09-29 these read global$home_prop and its siblings, keys that
  # exist only in the legacy params.yaml. wifi.R was the last source in that
  # state, so it could not run on a simulated parameter set at all.
  loc_props <- location_props(
    travel_time = travel_time,
    home_prop   = params$global$environment_prop$home_prop,
    outd_prop   = params$global$environment_prop$outd_prop,
    work_prop   = params$global$environment_prop$work_prop)

  duration <- 86400 * sum(
    loc_props$home, # assumption: always in a WiFi network at home and at work
    loc_props$work, # assumption: no WiFi exposure outdoors
    loc_props$travel * wifi_prop_travel)

  # Calculate mSAR ============================================================
  msar <- wifi_msar(
    tissue           = tissue,
    travel_time      = travel_time,
    wifi_prop_travel = wifi_prop_travel,
    params           = params
  )

  # Calculate dose and return result ==========================================
  dose <- duration*msar
  return(dose)
}

#' @returns Tissue-specific mSAR from WiFi
wifi_msar <- function(
    tissue,
    travel_time,
    wifi_prop_travel,
    params = load_params()) {
  # Calculate mSAR ============================================================
  # The band tokens were "2" and "5" until 2026-09-29. They are the model's
  # band names now, so that one token builds every key this function needs --
  # the power, the band share and the SAR.
  bands <- c("2450", "5000")
  msar <- sum(
    vapply(
      bands,
      \(band) {
        # Power density of the field
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
        # Band proportion, drawn from the Beta in global$wifi_probs
        prop_band <- params$global$wifi_probs[[paste0("wifi_", band, "_prop")]]
        if (is.null(prop_band))
          stop("no WiFi band proportion 'wifi_", band, "_prop' in the parameters")
        # Calculate mSAR and return results
        msar_band <- pwr*sar*prop_band
        return(msar_band)
      },
      numeric(1)
    )
  )
  return(msar)
}

#' Power density of the WiFi field
#'
#' HERMES3 personal measurements, each the mean of a home and a school value.
#' Point values: the parameter workbook specifies no spread for them.
#'
#' @returns Power density in mW/m2
wifi_pwr <- function(
    band,
    params = load_params()) {
  param_name <- paste("wifi", band, "pwr", sep = "_")
  pwr <- params$devices$wifi[[param_name]]
  if (is.null(pwr))
    stop("no WiFi power density '", param_name, "' in the parameters")
  return(pwr)
}

#' Whole-body or brain SAR per unit incident power density
#'
#' Phantom-resolved since 2026-09-29; it used to be one scalar for everyone,
#' which gave a simulated child the adult's WiFi dose.
#'
#' The values are GOLIAT's far-field plane-wave simulations, the same ones
#' farfield.R uses, read at the two WiFi bands. That is a deliberate
#' approximation and the reasoning is worth stating: a router is typically one
#' to five metres away, which at 2.45 GHz is 8 to 40 wavelengths and therefore
#' already the far field. ETAIN did simulate an "indoor WiFi router" in the
#' intermediate field and got a value about 50 % higher, but only at 2.45 GHz,
#' only for Duke and Ella, and only in the distilled workbook rather than in
#' the simulation database. See doc/wifi_stochastification.md.
#'
#' @returns SAR in W/kg per W/m2
wifi_sar <- function(
    tissue,
    band,
    params = load_params()) {

  dummy <- determine_dummy(params$global$input_stoch$sex,
                           params$global$input_stoch$age)
  tissue_params <- load_tissue_params(params, "call", tissue, dummy)

  key <- paste0(dummy, "_", tissue, "_goliat_", band, "_farfield_sar")
  sar <- tissue_params[[key]]
  if (is.null(sar))
    stop("no far-field SAR '", key, "' in the parameters")

  # the yaml holds mW/kg per W/m2, the model wants W/kg per W/m2
  return(sar/1000)
}
