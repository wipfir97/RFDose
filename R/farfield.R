# Calculate total RF-EMF dose (for brain and body) from far-field exposure
#
# Far field means everything radiated by transmitters that are not the person's
# own devices -- base stations above all. Two things are multiplied:
#
#   pwr   the ambient power density the person sits in, in mW/m2. Measured per
#         country and environment, weighted by how much of the day is spent in
#         each. Not a device output power, unlike every near-field source.
#   sar   how much of that field the body absorbs, in W/kg per W/m2. Resolved
#         by phantom and by frequency since 2026-09-29; it used to be one
#         scalar for everyone, which gave a simulated child the adult's dose.
#
# The frequency resolution needs a spectrum, because the ambient field is not
# monochromatic. Adriana's EU-level composition supplies it. See
# doc/SAR_REDESIGN.md for where the SAR values come from.

###############################################################################
# =============================================================================
#' Calculate the daily RF-EMF dose from ambient far-field exposure
#'
#' @param tissue "body" or "brain"
#' @param country Country code, one of the codes present in the yaml
#' @param travel_time Time spent travelling per day, in seconds
#' @param params Parameter list
#' @returns Tissue-specific RF-EMF dose from far-field exposure in mJ/kg/day
#' @export
farfield_dose <- function(
    tissue,
    country,
    travel_time,
    params = load_params()) {

  msar <- farfield_msar(
    tissue      = tissue,
    country     = country,
    travel_time = travel_time,
    params      = params
  )

  # Assumption: the ambient field is present all day. Unlike a device, it
  # cannot be switched off, so there is no usage duration to draw.
  duration <- 86400
  dose <- duration*msar

  return(dose)
}

#' @returns Tissue-specific mSAR from far-field exposure
farfield_msar <- function(
    tissue,
    country,
    travel_time,
    params = load_params()) {

  pwr <- farfield_pwr(
    country     = country,
    travel_time = travel_time,
    params      = params
  )
  sar <- farfield_sar(
    tissue = tissue,
    params = params
  )
  msar <- pwr*sar

  return(msar)
}

#' Ambient power density, weighted over where the day is spent
#'
#' @returns Power density in mW/m2
farfield_pwr <- function(
    country,
    travel_time,
    params = load_params()) {

  # The four location proportions come from the Dirichlet in
  # global$environment_prop. Until 2026-09-29 this read global$home_prop and
  # its siblings, keys that exist only in the legacy params.yaml, so the
  # function could not run on a simulated parameter set at all.
  loc_props <- location_props(
    travel_time = travel_time,
    home_prop   = params$global$environment_prop$home_prop,
    outd_prop   = params$global$environment_prop$outd_prop,
    work_prop   = params$global$environment_prop$work_prop)

  # Urbanicity is a set of three proportions, not a single label. When the
  # caller of simulate_params() supplies an urbanicity they collapse to 1/0/0
  # and this reduces to picking one level, which is what the function used to
  # do; when it is drawn, all three contribute.
  urb <- params$global$input_stoch$urbanicity
  urb_props <- c(urb = urb$urb_prop, sub = urb$sub_prop, rur = urb$rur_prop)

  locations <- c("home", "work", "out", "travel")
  pwr <- sum(
    vapply(
      locations,
      \(loc) {
        loc_prop <- loc_props[[loc]]
        # travel exposure is not split by urbanicity
        if (loc == "travel") {
          loc_pwr <- params$devices$farf[[paste("travel", "pwr", country, sep = "_")]]
          if (is.null(loc_pwr))
            stop("no far-field exposure level 'travel_pwr_", country, "'")
        } else {
          loc_pwr <- sum(
            vapply(names(urb_props), \(u) {
              nm <- paste(loc, u, "pwr", country, sep = "_")
              v  <- params$devices$farf[[nm]]
              if (is.null(v))
                stop("no far-field exposure level '", nm, "' in the parameters")
              return(urb_props[[u]]*v)
            }, numeric(1))
          )
        }
        return(loc_prop*loc_pwr)
      },
      numeric(1)
    )
  )
  return(pwr)
}

#' Whole-body or brain SAR per unit incident power density
#'
#' Phantom-resolved and averaged over the ambient frequency spectrum.
#'
#' @returns SAR in W/kg per W/m2
farfield_sar <- function(
    tissue,
    params = load_params()) {

  dummy <- determine_dummy(params$global$input_stoch$sex,
                           params$global$input_stoch$age)
  tissue_params <- load_tissue_params(params, "call", tissue, dummy)

  # The ten spectrum buckets. Each key holds the GOLIAT plane-wave simulation
  # for that band, already averaged over the 12 incidence directions -- a
  # person turns during the day, so a single orientation is not meaningful
  # over 24 hours. Three pairs of buckets rest on the same simulated node
  # because GOLIAT did not simulate 800, 900, 1800, 2100, 2600 or 5000 MHz;
  # see data-raw/import_sar.R section 2c.
  bands <- c("450", "700", "800", "900", "1800",
             "2100", "2450", "2600", "3500", "5000")

  sar <- sum(
    vapply(
      bands,
      \(band) {
        prop <- params$devices$farf$ff_freq_props[[paste0("frq", band, "_ff_prop")]]
        key  <- paste0(dummy, "_", tissue, "_goliat_", band, "_farfield_sar")
        band_sar <- tissue_params[[key]]
        if (is.null(band_sar))
          stop("no far-field SAR '", key, "' in the parameters")
        return(prop*band_sar)
      },
      numeric(1)
    )
  )

  # the yaml holds mW/kg per W/m2, the model wants W/kg per W/m2
  return(sar/1000)
}
