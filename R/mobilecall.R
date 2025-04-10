# Calculate total RF-EMF dose (for brain and body) from mobile call

# =============================================================================
#' Calculate RF-EMF Dose from Mobile Calling
#'
#' In general, the RF-EMF dose from a specific source is calculated using this equation:
#' \deqn{
#' \text{Dose} = \text{SAR} \times \text{Power} \times \text{Duration}
#' }
#' Where:
#' \itemize{
#'   \item \eqn{\text{Dose}} is the RF-EMF dose from mobile calling (mJ/kg/day).
#'   \item \eqn{\text{SAR}} is the Specific Absorption Rate (W/kg/W).
#'   \item \eqn{\text{Power}} is the source or device output power (mW).
#'   \item \eqn{\text{Duration}} is the exposure or use duration per day (s).
#' }
#' Users may wear bluetooth headphones during mobile calls.
#' Because of this, we consider three sources of RF-EMF exposure:
#' 1) The dose from the mobile phone itself, 2) the dose from the bluetooth headphones,
#' and 3) the dose from the mobile phone while using bluetooth.
#' Thus, the final RF-EMF dose is calculated by adding these three sources:
#' \deqn{
#' \text{Dose}_{\text{total}} = \text{Dose}_{\text{mp}} + \text{Dose}_{\text{bthp}} + \text{Dose}_{\text{btmp}}
#' }
#' Where:
#' \itemize{
#'   \item \eqn{\text{Dose}_{\text{total}}} is the total RF-EMF dose from mobile calling (mJ/kg/day).
#'   \item \eqn{\text{Dose}_{\text{mp}}} is the RF-EMF dose from the mobile phone (no Bluetooth, mJ/kg/day).
#'   \item \eqn{\text{Dose}_{\text{bthp}}} is the RF-EMF dose from the Bluetooth headphones (mJ/kg/day).
#'   \item \eqn{\text{Dose}_{\text{btmp}}} is the RF-EMF dose from the mobile phone while using Bluetooth (mJ/kg/day).
#' }
#' See also \link{get_mobilecall_sar}
#'
#' @param duration Duration of daily mobile calling in seconds
#' @param ear_prop Proportion of time mobile phone is held against the ear during mobile call
#' @param urbanicity Urbanicity of environment (rural, suburban, urban)
#' @param params Parameter list
#'
#' @returns List with brain dose and body dose in mJ/kg/day
#' @export
get_mobilecall_dose <- function(duration,
                                ear_prop,
                                urbanicity,
                                params) {
  # Extract parameters ========================================================
  ## Extract shared (non-tissue specific) parameters for mobile calling -------
  call_params  <- load_device_params(params, "call")
  ## Extract brain-specific parameters (SAR values) for mobile calling --------
  brain_params <- load_tissue_params(params, "call", "brain")
  ## Extract body-specific parameters (SAR values) for mobile calling ---------
  body_params  <- load_tissue_params(params, "call", "body")
  ## Derive phone position proportions ----------------------------------------
  speaker_prop <- (1-ear_prop)/2
  headp_prop   <- (1-ear_prop)/2

  # Check input values for validity ===========================================
  check_proportions(proportions = c(ear_prop, speaker_prop, headp_prop))
  check_duration(duration       = duration)
  recode_urbanicity(urbanicity  = urbanicity)

  # Calculate aggregated power ================================================
  aggr_pwr     <- get_mobilecall_pwr(headp_prop = headp_prop,
                                     params     = call_params)
  print(paste("aggr_pwr", aggr_pwr))

  # Calculate SAR =============================================================
  # Calculate brain SAR -------------------------------------------------------
  brain_sar    <- get_mobilecall_sar(ear_prop      = ear_prop,
                                     speaker_prop  = speaker_prop,
                                     headp_prop    = headp_prop,
                                     params        = call_params,
                                     tissue_params = brain_params)
  # Calculate body SAR --------------------------------------------------------
  body_sar     <- get_mobilecall_sar(ear_prop      = ear_prop,
                                     speaker_prop  = speaker_prop,
                                     headp_prop    = headp_prop,
                                     params        = call_params,
                                     tissue_params = body_params)
  print(paste("brain_sar", brain_sar))
  print(paste("body_sar",  body_sar))

  # Calculate total dose ======================================================
  # Calculate brain dose ------------------------------------------------------
  brain_dose_phone    <- duration*aggr_pwr$pwr_phone*brain_sar$sar_phone
  brain_dose_phone_bt <- duration*aggr_pwr$pwr_phone_bt*brain_sar$sar_phone_bt
  brain_dose_headp_bt <- duration*aggr_pwr$pwr_headp_bt*brain_sar$sar_headp_bt*2
  brain_dose_total    <- sum(brain_dose_phone,
                             brain_dose_phone_bt,
                             brain_dose_headp_bt)

  #print(paste("brain dose phone", brain_dose_phone))
  #print(paste("brain dose phone bt", brain_dose_phone_bt))
  #print(paste("brain dose headp bt", brain_dose_headp_bt))
  #print(paste("1", aggr_pwr$pwr_headp_bt, "2",brain_sar$sar_headp_bt))

  # Calculate body dose -------------------------------------------------------
  body_dose_phone     <- duration*aggr_pwr$pwr_phone*body_sar$sar_phone
  body_dose_phone_bt  <- duration*aggr_pwr$pwr_phone_bt*body_sar$sar_phone_bt
  body_dose_headp_bt  <- duration*aggr_pwr$pwr_headp_bt*body_sar$sar_headp_bt*2
  body_dose_total     <- sum(body_dose_phone,
                             body_dose_phone_bt,
                             body_dose_headp_bt)

  # Return output =============================================================
  output_list <- list("brain_call_dose" = brain_dose_total,
                      "body_call_dose"  = body_dose_total)
  return(output_list)
}

# =============================================================================
#' Calculate mobile call aggregated power
#'
#' Note that the parameters ear_prop, speaker_prop and headphone_prop must add up
#' to one!
#' @param headp_prop Proportion of time the phone is used with bluetooth headphones during call
#' (needed for calculating bluetooth contribution)
#' @param params Mobile call related parameter list
#' @returns mobile call aggregated power from phone and bluetooth headphones
get_mobilecall_pwr <- function(headp_prop,
                               params) {
  # Check input values ========================================================

  # Calculate output power ====================================================
  ## Calculate power of phone itself ------------------------------------------
  pwr_phone    <- get_mobilecall_pwr_phone(params = params)
  # Calculate power from phone using bluetooth headphones
  pwr_phone_bt <- get_mobilecall_pwr_phone_bt(headp_prop = headp_prop,
                                              params     = params)
  # Calculate power from bluetooth headphones
  pwr_headp_bt <- get_mobilecall_pwr_headp_bt(headp_prop = headp_prop,
                                              params     = params)

  # return output =============================================================
  output <- list("pwr_phone"    = pwr_phone,
                 "pwr_phone_bt" = pwr_phone_bt,
                 "pwr_headp_bt" = pwr_headp_bt)

  return(output)
}

# -----------------------------------------------------------------------------
#' Calculate aggregated output power from mobile phone during call (no bluetooth)
#'
#' Calculation of total output power of the mobile phone (no bluetooth) during
#' voice calling by multiplying the proportion of the time a technology is used
#' times its output power (mW):
#' \deqn{AggregatedPower = ProportionNative \times PowerNative + ProportionData \times PowerData + ProportionWifi \times PowerWifi}
#' At the moment, the output power of each technology is constant, but this
#' will be refined to take user-specific parameters into account in the future.
#' @param params Mobile call related parameter list
#' @returns aggregated output power (mW) during mobile call with phone (no bluetooth)
get_mobilecall_pwr_phone <- function(params) {
  # Calculate contribution from native calling
  native_pwr <- params$native_prop * params$native_pwr

  # Calculate contribution from data calling
  data_pwr   <- params$data_prop * params$data_pwr

  # Calculate contribution from wifi calling
  wifi_pwr   <- params$wifi_prop * params$wifi_pwr

  # Sum up contributions to calculate aggregated power
  aggr_pwr   <- sum(native_pwr, data_pwr, wifi_pwr)

  return(aggr_pwr)
}

# -----------------------------------------------------------------------------
#' Calculate mobile call aggregated power from phone bluetooth
#' @param headp_prop Proportion of time the phone is used with bluetooth headphones during call
#' (needed for calculating bluetooth contribution)
#' @param params mobile call related parameter list
#' @returns aggregated output power of phone transmitting via bluetooth
#' scaled with headphone use proportion
get_mobilecall_pwr_phone_bt <- function(headp_prop,
                                        params) {
  aggr_pwr <- headp_prop * params$headp_phone_bt_pwr
  return(aggr_pwr)
}

# -----------------------------------------------------------------------------
#' Calculate mobile call aggregated power from bluetooth headphones
#'
#' @param headp_prop Proportion of time the phone is used with bluetooth headphones during call
#' (needed for calculating bluetooth contribution)
#' @param params description
#' @returns aggregated output power of bluetooth headphones during mobile call
#' scaled with headphone use proportion, multiplied by two (headphone in two ears)
get_mobilecall_pwr_headp_bt <- function(headp_prop,
                                        params) {
  aggr_pwr <- headp_prop * params$headp_phone_bt_pwr
  return(aggr_pwr)
}

# =============================================================================
#' Calculate mobile call SAR
#'
#' Note that ear_prop, speaker_prop and headp_prop should add up to one!
#' @param ear_prop Proportion of time the phone is held against the ear during call
#' @param speaker_prop Proportion of time the phone is used in speaker mode
#' @param headp_prop Proportion of time the phone is used with bluetooth headphones
#' @param params mobile call specific parameter list
#' @param tissue_params tissue-specific parameter list (SAR values)
#' @returns aggregated tissue SAR from mobile call, including bluetooth headphones
get_mobilecall_sar <- function(ear_prop,
                               speaker_prop,
                               headp_prop,
                               params,
                               tissue_params) {
  # Check input values ========================================================
  ## Check phone location proportions -----------------------------------------

  # Calculate SAR values ======================================================
  ## Calculate SAR from phone itself (no bluetooth) ---------------------------
  phone_sar    <- get_mobilecall_sar_phone(ear_prop      = ear_prop,
                                           speaker_prop  = speaker_prop,
                                           headp_prop    = headp_prop,
                                           params        = params,
                                           tissue_params = tissue_params)

  ## Calculate SAR from phone using bluetooth headphones ----------------------
  phone_bt_sar <- get_mobilecall_sar_phone_bt(params        = params,
                                              tissue_params = tissue_params)
  ### Scale with headphone use proportion
  phone_bt_sar <- headp_prop * phone_bt_sar

  ## Calculate SAR from bluetooth headphones ----------------------------------
  headp_bt_sar <- get_mobilecall_sar_headp_bt(params        = params,
                                              tissue_params = tissue_params)
  ### Scale with headphone use proportion
  headp_bt_sar <- headp_prop * headp_bt_sar


  # Return output as list =====================================================
  output <- list("sar_phone"    = phone_sar,
                 "sar_phone_bt" = phone_bt_sar,
                 "sar_headp_bt" = headp_bt_sar)

  return(output)
}

# -----------------------------------------------------------------------------
#' Calculate mobile call SAR from mobile phone itself
#'
#' This is done by adding up the contributions of native, data and wifi technologies.
#' The native contribution is calculated like this:
#' \deqn{AA_5 \times \left( (O_5 \times U_5) + (P_5 \times V_5) + (Z_5 \times T_5) \right)}
#'
#' Note that ear_prop, speaker_prop and headp_prop should add up to one!
#' @param ear_prop Proportion of time the phone is held against the ear during call
#' @param speaker_prop Proportion of time the phone is used in speaker mode
#' @param headp_prop Proportion of time the phone is used with bluetooth headphones
#' @param params description
#' @param tissue_params descr
#' @returns description
get_mobilecall_sar_phone <- function(ear_prop,
                                     speaker_prop,
                                     headp_prop,
                                     params,
                                     tissue_params) {
  # Check input parameters ----------------------------------------------------

  # Calculate contribution from native calling --------------------------------
  ## Calculate for phone against ear
  native_ear     <- ear_prop * tissue_params$native_ear_sar

  ## Calculate for phone with headphones
  native_headp   <- headp_prop * tissue_params$native_headp_sar

  ## Calculate for speaker mode
  native_speaker <- speaker_prop * tissue_params$native_speaker_sar

  ## Add up different modes
  native_contr   <- params$native_prop * sum(native_ear,
                                             native_headp,
                                             native_speaker)

  #print(paste("native_sar", native_contr))

  # Calculate contribution from mobile data calling ---------------------------
  ## Calculate for phone against ear
  data_ear        <- ear_prop * tissue_params$data_ear_sar

  ## Calculate for phone with headphones
  ### Phone in front of face
  data_headp_face <- params$headp_face_prop * tissue_params$data_headp_face_sar
  ### Phone in pocket
  data_pock_face  <- params$headp_pock_prop * tissue_params$data_headp_pock_sar
  ### Phone elsewhere
  data_else_face  <- params$headp_else_prop * tissue_params$data_headp_else_sar
  ### Sum up
  data_headp      <- headp_prop * sum(data_headp_face,
                                      data_pock_face,
                                      data_else_face)

  ## Calculate for speaker mode
  data_speaker    <- speaker_prop * tissue_params$data_speaker_sar

  ## Add up different modes
  data_contr      <- params$data_prop * sum(data_ear,
                                            data_headp,
                                            data_speaker)

  #print(paste("data_sar", data_contr))
  # Calculate contribution from Wifi calling ----------------------------------
  # TODO: double check wifi calculation because it doesn't return same value!
  ## Calculate for phone against ear
  wifi_ear_2     <- ear_prop * tissue_params$wifi_2_ear_sar
  wifi_ear_5     <- ear_prop * tissue_params$wifi_5_ear_sar

  ## Calculate for phone with headphones
  ### Phone in front of face
  wifi_headp_2_face <- params$headp_face_prop * tissue_params$wifi_2_headp_face_sar
  wifi_headp_5_face <- params$headp_face_prop * tissue_params$wifi_5_headp_face_sar
  ### Phone in pocket
  wifi_headp_2_pock <- params$headp_pock_prop * tissue_params$wifi_2_headp_pock_sar
  wifi_headp_5_pock <- params$headp_pock_prop * tissue_params$wifi_5_headp_pock_sar
  ### Phone elsewhere
  wifi_headp_2_else <- params$headp_else_prop * tissue_params$wifi_2_headp_else_sar
  wifi_headp_5_else <- params$headp_else_prop * tissue_params$wifi_5_headp_else_sar
  ### Sum up
  wifi_headp_2   <- headp_prop * sum(wifi_headp_2_face,
                                     wifi_headp_2_pock,
                                     wifi_headp_2_else)

  wifi_headp_5   <- headp_prop * sum(wifi_headp_5_face,
                                     wifi_headp_5_pock,
                                     wifi_headp_5_else)
  ## Calculate for speaker mode
  wifi_speaker_2 <- speaker_prop * tissue_params$wifi_2_speaker_sar
  wifi_speaker_5 <- speaker_prop * tissue_params$wifi_5_speaker_sar

  ## Add up different modes
  wifi_2 <- params$wifi_2_prop * sum(wifi_ear_2,
                                     wifi_headp_2,
                                     wifi_speaker_2)

  wifi_5 <- params$wifi_5_prop * sum(wifi_ear_5,
                                     wifi_headp_5,
                                     wifi_speaker_5)

  ## Add up for different WiFi frequencies
  wifi_contr <- params$wifi_prop * sum(wifi_2,
                                       wifi_5)

  #print(paste("wifi_sar", wifi_contr))

  # Add contributions of different technologies and return result -------------
  aggr_sar <- sum(native_contr,
                  data_contr,
                  wifi_contr)
  return(aggr_sar)
}

# -----------------------------------------------------------------------------
#' Calculate SAR from native phone calling (no bluetooth)
#'
#'
get_mobilecall_sar_native <- function() {
  return(NA)
}

# -----------------------------------------------------------------------------
#' Calculate SAR from mobile data phone calling (no bluetooth)
#'
#'
get_mobilecall_sar_data <- function() {
  return(NA)
}

# -----------------------------------------------------------------------------
#' Calculate SAR from WiFi phone calling (no bluetooth)
#'
#'
get_mobilecall_sar_wifi <- function() {
  return(NA)
}

# -----------------------------------------------------------------------------
#' Calculate tissue SAR from phone during mobile call transmitting to bluetooth headphones
#'
#' @param params description
#' @param tissue_params description
#' @returns tissue SAR from bluetooth emitted by phone
get_mobilecall_sar_phone_bt <- function(params, tissue_params){
  # Phone in front of face
  sar_face <- params$headp_face_prop * tissue_params$bt_phone_face_sar
  # Phone in pocket
  sar_pock <- params$headp_pock_prop * tissue_params$bt_phone_pock_sar
  # Phone elsewhere
  sar_else <- params$headp_else_prop * tissue_params$bt_phone_else_sar

  # Sum up locations
  aggr_sar <- sum(sar_face, sar_pock, sar_else)

  return(aggr_sar)
}

# -----------------------------------------------------------------------------
#' Calculate tissue SAR from bluetooth headphones during mobile call
#'
#' @param params description
#' @param tissue_params description
#' @returns tissue SAR from bluetooth emitted by bluetooth headphones
get_mobilecall_sar_headp_bt <- function(params, tissue_params){
  bt_sar <- tissue_params$bt_headp_sar
  return(bt_sar)
}
