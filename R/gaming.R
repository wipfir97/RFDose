# Calculate total RF-EMF dose (for brain and body) from PC gaming over WiFi

# There is no gaming-specific sar simulation. We therefore use the mean of the
# eight belly positions (stored under the call device) as a proxy for a pc
# standing in front of the body, and rescale it from the 200 mm belly reference
# distance to the stochastic pc-to-body distance.

# =============================================================================
#' Calculate Dose from PC Gaming over WiFi
#'
#' @param tissue Tissue for which to calculate dose (default: "brain" or "body")
#' @param duration_gaming Duration of gaming in seconds. >= 0 and <= 86400
#' @param params Parameter list.
#' @returns Tissue-specific RF-EMF dose in mJ/kg/day
#' @export
#' @import yaml
gaming_dose <- function(
    tissue,
    duration_gaming,
    params = load_params()) {

  # Check input values ========================================================
  ## Duration
  check_duration(duration = duration_gaming)

  # Calculate brain and body mSAR =============================================
  msar <- gaming_msar(
    tissue = tissue,
    params = params
  )

  # Calculate dose and return result ==========================================
  ## online_prop: proportion of the gaming time the device is actually online
  dose <- msar * duration_gaming *
    params$devices$gaming$online_prop$gaming_online_prop/1000 # mW->W

  return(dose)
}

gaming_msar <- function(
    tissue,
    params = load_params()) {

  freqs <- c("2400", "5000") # 2.4 GHz and 5.0 GHz

  msar <- sum(
    vapply(
      freqs,
      \(freq) {
        ## Frequency band proportion
        prop <- params$global$wifi_probs[[paste0("wifi_", freq, "_prop")]]
        ## Calculate output power
        pwr <- gaming_pwr(
          freq   = freq,
          params = params
        )
        ## Calculate SAR
        sar <- gaming_sar(
          tissue = tissue,
          freq   = freq,
          params = params
        )
        ## Calculate mSAR of this band and return
        return(prop*pwr*sar)
      },
      numeric(1)
    )
  )
  return(msar)
}

gaming_pwr <- function(
    freq,
    params) {
  pwr <- params$devices$gaming$pwr[[paste0("gaming_", freq, "_pwr")]] *
    params$devices$gaming$dutycycle[[paste0("gaming_", freq, "_dutycycle")]]
  return(pwr)
}

gaming_sar <- function(
    tissue,
    freq,
    params) {

  belly_position <- c("belly_center_vertical","belly_center_horizontal",
                      "belly_left_vertical","belly_left_horizontal",
                      "belly_right_vertical","belly_right_horizontal",
                      "belly_up_vertical","belly_up_horizontal")

  #find name of simulation dummy
  dummy <- determine_dummy(params$global$input_stoch$sex,
                           params$global$input_stoch$age)
  # define prefix for finding correct tissue parameter
  prefix <- paste0(dummy,"_",tissue,"_", freq,"_")
  # load tissue-specific parameters (SAR values)
  tissue_params <- load_tissue_params(params, "call", tissue,dummy) # here we still use call because at the moment all sar values are stored in call

  # no gaming-specific simulation exists, so we take the unweighted mean over the
  # belly positions instead of weighting them with the position proportions
  sar_belly <- mean(
    vapply(
      belly_position,
      \(positions) {
        belly_sar <- paste0(prefix,positions,"_sar")
        return(tissue_params[[belly_sar]])
      },
      numeric(1)
    )
  )

  # so far only Duke has simulated sar values, the other dummies are still zero
  if (sar_belly == 0) {
    warning("No SAR values for dummy ", dummy, " (", tissue, ", ", freq,
            " MHz). Gaming dose will be 0.")
  }

  #distance stochastics
  if (params$global$dist_correction) {
    dist_pc <- params$devices$gaming$gaming_distance$gaming_dist_pc
    if (tissue == "body"){
      #adjust distance with distance law (in mm), reference is 200 because that
      #is the distance the belly simulations were done at
      sar_belly <- dist_law(sar = sar_belly,
                            dist = dist_pc,
                            dist_ref = 200,
                            delta = 6)
    } else if (tissue == "brain"){
      #the pc stands in front of the trunk, so it is further away from the head
      #than from the body. Same geometry as for the phone at belly height.
      dummy_chest_height <- params$devices$call[[dummy]]$height/2

      sar_belly <- dist_law(sar = sar_belly,
                            dist = sqrt(dummy_chest_height^2 + dist_pc^2),
                            dist_ref = sqrt(dummy_chest_height^2 + 200^2),
                            delta = 6)
    }
  }
  return(sar_belly)
}
