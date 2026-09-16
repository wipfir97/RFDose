# Calculate total RF-EMF dose (for brain and body) from a VR headset over WiFi

# There is no headset-specific sar simulation. We use the mean of the six ear
# positions (cheek1-3, tilt1-3) as a proxy and rescale it from their 8 mm
# reference distance to the stochastic antenna-to-head standoff.
#
# WHY THE EAR AND NOT front_of_eyes, which is anatomically where a headset sits:
#   - GOLIAT simulated the ear scenario at 0.8 cm, the only geometry in the right
#     distance regime for a head-worn device; front_of_eyes was simulated at 20 cm.
#   - Rescaling front_of_eyes down to a headset standoff gives values 11-16x
#     ABOVE the ear values for whole body, even though it sits further from the
#     head, and implies the phantom absorbs about 8x the radiated power.
#   - The deterministic model also derived VR from the ear sar: its vr_*_sar
#     values are the wifi_*_ear_sar values rounded to six digits.
# See doc/vr_stochastification.md.

# =============================================================================
#' Calculate RF-EMF Dose from a VR Headset
#'
#' @param tissue Tissue for which to calculate dose (default: "brain" or "body")
#' @param duration_vr Duration of VR headset use in seconds. >= 0 and <= 86400
#' @param params Parameter list.
#' @returns Tissue-specific RF-EMF dose in mJ/kg/day
#' @export
#' @import yaml
vr_dose <- function(
    tissue,
    duration_vr,
    params = load_params()) {

  # Check input values ========================================================
  ## Duration
  check_duration(duration = duration_vr)

  # Calculate brain and body mSAR =============================================
  msar <- vr_msar(
    tissue = tissue,
    params = params
  )

  # Calculate dose and return result ==========================================
  ## online_prop: proportion of the headset-on time with actual WiFi traffic
  dose <- msar * duration_vr *
    params$devices$vr$online_prop$vr_online_prop/1000 # mW->W

  return(dose)
}

vr_msar <- function(
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
        pwr <- vr_pwr(
          freq   = freq,
          params = params
        )
        ## Calculate SAR
        sar <- vr_sar(
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

vr_pwr <- function(
    freq,
    params) {
  pwr <- params$devices$vr$pwr[[paste0("vr_", freq, "_pwr")]] *
    params$devices$vr$dutycycle[[paste0("vr_", freq, "_dutycycle")]]
  return(pwr)
}

vr_sar <- function(
    tissue,
    freq,
    params) {

  ear_position <- c("cheek1","cheek2","cheek3",
                    "tilt1","tilt2","tilt3")

  #find name of simulation dummy
  dummy <- determine_dummy(params$global$input_stoch$sex,
                           params$global$input_stoch$age)
  # define prefix for finding correct tissue parameter
  prefix <- paste0(dummy,"_",tissue,"_", freq,"_")
  # load tissue-specific parameters (SAR values)
  tissue_params <- load_tissue_params(params, "call", tissue,dummy) # here we still use call because at the moment all sar values are stored in call

  # no headset-specific simulation exists, so we take the unweighted mean over the
  # ear positions instead of weighting them with the position proportions
  sar_ear <- mean(
    vapply(
      ear_position,
      \(positions) {
        ear_sar <- paste0(prefix,positions,"_sar")
        return(tissue_params[[ear_sar]])
      },
      numeric(1)
    )
  )

  # tripwire: a dummy whose sar table has not been filled in would silently give a
  # dose of zero, which is indistinguishable from "this person does not use VR"
  if (sar_ear == 0) {
    warning("No SAR values for dummy ", dummy, " (", tissue, ", ", freq,
            " MHz). VR dose will be 0.")
  }

  #distance stochastics
  if (params$global$dist_correction) {
    #adjust distance with distance law (in mm), reference is 8 because GOLIAT
    #simulated the ear positions at 0.8 cm.
    #Unlike gaming there is no hypotenuse here: the headset is worn on the head,
    #so the same standoff applies to the brain and to the whole body.
    sar_ear <- dist_law(sar = sar_ear,
                        dist = params$devices$vr$vr_distance$vr_dist_device,
                        dist_ref = 8,
                        delta = 6)
  }
  return(sar_ear)
}
