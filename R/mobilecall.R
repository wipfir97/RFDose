# Calculate total RF-EMF dose (for brain and body) from mobile call
# Updated functions for improved clarity
# work in progress

# Total mobile call dose from all sources =====================================
get_mobilecall_dose <- function(duration,
                                ear_prop,
                                headp_prop,
                                urbanicity,
                                params) {
  # Extract parameters ========================================================
  ## Extract shared (non-tissue specific) parameters for mobile calling -------
  call_params  <- load_device_params(params, "call")
  ## Extract brain-specific parameters (SAR values) for mobile calling --------
  brain_params <- load_tissue_params(params, "call", "brain")
  ## Extract body-specific parameters (SAR values) for mobile calling ---------
  body_params  <- load_tissue_params(params, "call", "body")
  ## Derive speaker mode use proportion ---------------------------------------
  speaker_prop <- (1-ear_prop)*(1-headp_prop)
  ## Update headp prop to scale by total mobile call duration
  headp_prop   <-(1-ear_prop)*headp_prop

  # Check input values for validity ===========================================
  check_proportions(proportions = c(ear_prop, speaker_prop, headp_prop))
  check_duration(duration       = duration)
  recode_urbanicity(urbanicity  = urbanicity)

  # Calculate doses from different sources ====================================
  ## Calculate dose from phone (no bluetooth contribution) --------------------
  ### Brain
  phone_dose_brain   <- get_mobilecall_phone_dose(duration      = duration,
                                                  ear_prop      = ear_prop,
                                                  speaker_prop  = speaker_prop,
                                                  headp_prop    = headp_prop,
                                                  urbanicity    = urbanicity,
                                                  params        = call_params,
                                                  tissue_params = brain_params)

  ### Brain
  phone_dose_body   <- get_mobilecall_phone_dose(duration      = duration,
                                                 ear_prop      = ear_prop,
                                                 speaker_prop  = speaker_prop,
                                                 headp_prop    = headp_prop,
                                                 urbanicity    = urbanicity,
                                                 params        = call_params,
                                                 tissue_params = body_params)

  ## Calculate dose from phone (bluetooth contribution) -----------------------
  ### scaled with headphone use proportion!
  ### Brain
  phone_bt_dose_brain <- headp_prop*get_mobilecall_bt_phone_dose(duration      = duration,
                                                                 params        = call_params,
                                                                 tissue_params = brain_params)
  ### Body
  phone_bt_dose_body  <- headp_prop*get_mobilecall_bt_phone_dose(duration      = duration,
                                                                 params        = call_params,
                                                                 tissue_params = body_params)
  ## Calculate dose from bluetooth headphones ---------------------------------
  ### scaled with headphone use proportion!
  headp_bt_dose_brain <- headp_prop*get_mobilecall_bt_headp_dose(duration      = duration,
                                                                 params        = call_params,
                                                                 tissue_params = brain_params)
  headp_bt_dose_body  <- headp_prop*get_mobilecall_bt_headp_dose(duration      = duration,
                                                                 params        = call_params,
                                                                 tissue_params = body_params)

  # Add doses from different sources and return result ========================
  brain_dose <- sum(phone_dose_brain,
                    phone_bt_dose_brain,
                    headp_bt_dose_brain)
  body_dose  <- sum(phone_dose_body,
                    phone_bt_dose_body,
                    headp_bt_dose_body)
  output_list <- list("brain_call_dose" = brain_dose,
                      "body_call_dose"  = body_dose)
  return(output_list)
}

# Total mobile call dose from phone (no bluetooth) ============================
## Dose -----------------------------------------------------------------------
#' Mobilecall Phone dose
#'
#' @param duration User duration
#' @param ear_prop Ear proportion
#' @param speaker_prop Speaker proportion
#' @param headp_prop Headphone proportion
#' @param urbanicity Urbanicity
#' @param params Parameter list
#' @param tissue_params Tissue-specific parameter list
#' @returns Dose
get_mobilecall_phone_dose <- function(duration,
                                      ear_prop,
                                      speaker_prop,
                                      headp_prop,
                                      urbanicity,
                                      params,
                                      tissue_params) {
  # Calculate power
  pwr <- get_mobilecall_phone_pwr(urbanicity = urbanicity,
                                  params     = params)
  # Calculate SAR
  sar <- get_mobilecall_phone_sar(ear_prop      = ear_prop,
                                  speaker_prop  = speaker_prop,
                                  headp_prop    = headp_prop,
                                  params        = params,
                                  tissue_params = tissue_params)
  # Calculate dose and return results
  dose <- duration*sar*pwr
  return(dose)
}
## Power ----------------------------------------------------------------------
#' Mobilecall Phone Power
#'
#' @param urbanicity Urbanicity
#' @param params Parameter list
#' @returns Power
get_mobilecall_phone_pwr <- function(urbanicity,
                                     params) {
  # From wifi
  wifi_pwr <- get_mobilecall_phone_wifi_pwr(wifi_2_prop = params$wifi_2_prop,
                                            wifi_5_prop = params$wifi_5_prop,
                                            wifi_2_pwr  = params$wifi_2_pwr,
                                            wifi_5_pwr  = params$wifi_5_pwr,
                                            wifi_2_duty_cycle = params$wifi_2_duty_cycle,
                                            wifi_5_duty_cycle = params$wifi_5_duty_cycle)
  # From data
  data_pwr <- get_mobilecall_phone_data_pwr(urbanicity = urbanicity,
                                            params     = params)
  # From native
  native_pwr <- get_mobilecall_phone_native_pwr(urbanicity = urbanicity,
                                                params     = params)
  # Scale by technology use proportion and return output power
  pwr <- sum(params$wifi_prop*wifi_pwr,
             params$data_prop*data_pwr,
             params$native_prop*native_pwr)
  return(pwr)
}
### Wifi
#' Wifi Phone Power
#'
#' @param wifi_2_prop Proportion of 2.4GHz WiFi
#' @param wifi_5_prop Proportion of 5.0GHz WiFi
#' @param wifi_2_pwr 2.4GHz WiFi Call Power
#' @param wifi_5_pwr 5.0GHz WiFi Call Power
#' @param wifi_2_duty_cycle 2.4GHz WiFi Duty Cycle
#' @param wifi_5_duty_cycle 5.0GHz WiFi Duty Cycle
get_mobilecall_phone_wifi_pwr <- function(wifi_2_prop,
                                          wifi_5_prop,
                                          wifi_2_pwr,
                                          wifi_5_pwr,
                                          wifi_2_duty_cycle,
                                          wifi_5_duty_cycle) {
  # 2.4 GHz
  pwr_2 <- wifi_2_pwr*wifi_2_duty_cycle
  # 5.0 GHz
  pwr_5 <- wifi_5_pwr*wifi_5_duty_cycle
  # Scale with 2.4/5.0 GHz proportion and return result
  pwr <- sum(pwr_2*wifi_2_prop,
             pwr_5*wifi_5_prop)
  return(pwr)
}
### Data
#' Mobilecall Data Power
#'
#' TODO: adapt calculations to urbanicity levels
#' @param urbanicity Urbanicity
#' @param params Parameter list
#' @returns mobilecall data power
get_mobilecall_phone_data_pwr <- function(urbanicity,
                                          params) {
  # TODO replace this constant with urbanicity-sensitive calculations
  pwr <- params$data_pwr
  return(pwr)
}
### Native
#' Mobilecall Native Power
#'
#' TODO: adapt calculations to urbanicity levels
#' @param urbanicity Urbanicity
#' @param params Parameter list
#' @returns mobilecall native power
get_mobilecall_phone_native_pwr <- function(urbanicity,
                                            params) {
  # TODO replace this constant with urbanicity-sensitive calculations
  pwr <- params$native_pwr
  return(pwr)
}

## SAR ------------------------------------------------------------------------
#' Mobilecall SAR
#'
#' @param ear_prop Ear proportion
#' @param headp_prop Headphone proportion
#' @param speaker_prop Speaker proportion
#' @param params Parameter list
#' @param tissue_params SAR values
get_mobilecall_phone_sar <- function(ear_prop,
                                     headp_prop,
                                     speaker_prop,
                                     params,
                                     tissue_params) {
  # SAR from WiFi
  wifi_sar   <- get_mobilecall_phone_wifi_sar(ear_prop      = ear_prop,
                                              headp_prop    = headp_prop,
                                              speaker_prop  = speaker_prop,
                                              params        = params,
                                              tissue_params = tissue_params)
  # SAR from Data
  data_sar   <- get_mobilecall_phone_data_sar(ear_prop      = ear_prop,
                                              headp_prop    = headp_prop,
                                              speaker_prop  = speaker_prop,
                                              params        = params,
                                              tissue_params = tissue_params)
  # SAR from Native
  native_sar <- get_mobilecall_phone_native_sar(ear_prop      = ear_prop,
                                                headp_prop    = headp_prop,
                                                speaker_prop  = speaker_prop,
                                                params        = params,
                                                tissue_params = tissue_params)

  # Scale by technology use proportion and return output
  sar <- sum(params$wifi_prop*wifi_sar,
             params$data_prop*data_sar,
             params$native_prop*native_sar)

  return(sar)
}

### Wifi
#' Get Mobilecall Wifi SAR
#'
#' TODO: split this function into smaller modules
#' @param ear_prop Ear proportion
#' @param headp_prop Headphone proportion
#' @param speaker_prop Speaker proportion
#' @param params Parameter list
#' @param tissue_params Tissue parameter list
get_mobilecall_phone_wifi_sar <- function(ear_prop,
                                          headp_prop,
                                          speaker_prop,
                                          params,
                                          tissue_params) {
  # 2.4 GHz ==================================================================
  ## Phone against ear -------------------------------------------------------
  wifi_2_ear     <- tissue_params$wifi_2_ear_sar
  ## Phone with headphones ---------------------------------------------------
  ### Front of face
  wifi_2_headp_face <- tissue_params$wifi_2_headp_face_sar
  ### Phone in pocket
  wifi_2_headp_pock <- tissue_params$wifi_2_headp_pock_sar
  ### Phone elsewhere
  wifi_2_headp_else <- tissue_params$wifi_2_headp_else_sar
  ### Scale by headphone phone position
  wifi_2_headp <- sum(params$headp_face_prop*wifi_2_headp_face,
                      params$headp_pock_prop*wifi_2_headp_pock,
                      params$headp_else_prop*wifi_2_headp_else)
  ## Phone in speaker mode ---------------------------------------------------
  wifi_2_speaker <- tissue_params$wifi_2_speaker_sar
  ## Scale by phone use mode -------------------------------------------------
  wifi_2 <- sum(ear_prop*wifi_2_ear,
                headp_prop*wifi_2_headp,
                speaker_prop*wifi_2_speaker)

  # 5.0 GHz ==================================================================
  ## Phone against ear -------------------------------------------------------
  wifi_5_ear     <- tissue_params$wifi_5_ear_sar
  ## Phone with headphones ---------------------------------------------------
  ### Front of face
  wifi_5_headp_face <- tissue_params$wifi_5_headp_face_sar
  ### Phone in pocket
  wifi_5_headp_pock <- tissue_params$wifi_5_headp_pock_sar
  ### Phone elsewhere
  wifi_5_headp_else <- tissue_params$wifi_5_headp_else_sar
  ### Scale by headphone phone position
  wifi_5_headp <- sum(params$headp_face_prop*wifi_5_headp_face,
                      params$headp_pock_prop*wifi_5_headp_pock,
                      params$headp_else_prop*wifi_5_headp_else)
  ## Phone in speaker mode ---------------------------------------------------
  wifi_5_speaker <- tissue_params$wifi_5_speaker_sar
  ## Scale by phone use mode -------------------------------------------------
  wifi_5 <- sum(ear_prop*wifi_5_ear,
                headp_prop*wifi_5_headp,
                speaker_prop*wifi_5_speaker)

  # Scale by WiFi technology proportion and return result ====================
  sar  <- sum(params$wifi_2_prop*wifi_2,
              params$wifi_5_prop*wifi_5)
  #print(paste("2", wifi_2, "5", wifi_5))
  return(sar)
}
### Data
#' Get Mobilecall Data SAR
#'
#' TODO: split this function into smaller modules
#' @param ear_prop Ear proportion
#' @param headp_prop Headphone proportion
#' @param speaker_prop Speaker proportion
#' @param params Parameter list
#' @param tissue_params Tissue parameter list
get_mobilecall_phone_data_sar <- function(ear_prop,
                                          headp_prop,
                                          speaker_prop,
                                          params,
                                          tissue_params) {
  ## Phone against ear -------------------------------------------------------
  data_ear        <- tissue_params$data_ear_sar
  ## Phone with headphones ---------------------------------------------------
  ### Front of face
  data_headp_face <- tissue_params$data_headp_face_sar
  ### Phone in pocket
  data_headp_pock <- tissue_params$data_headp_pock_sar
  ### Phone elsewhere
  data_headp_else <- tissue_params$data_headp_else_sar
  ### Scale by headphone phone position
  data_headp      <- sum(params$headp_face_prop*data_headp_face,
                         params$headp_pock_prop*data_headp_pock,
                         params$headp_else_prop*data_headp_else)
  ## Phone in speaker mode ---------------------------------------------------
  data_speaker    <- tissue_params$data_speaker_sar

  ## Scale by phone use mode -------------------------------------------------
  sar <- sum(ear_prop*data_ear,
             headp_prop*data_headp,
             speaker_prop*data_speaker)
  return(sar)
}
### Native
get_mobilecall_phone_native_sar <- function(ear_prop,
                                            headp_prop,
                                            speaker_prop,
                                            params,
                                            tissue_params) {
  ## Phone against ear -------------------------------------------------------
  native_ear        <- tissue_params$native_ear_sar
  ## Phone with headphones ---------------------------------------------------
  ### Front of face
  native_headp_face <- tissue_params$native_headp_face_sar
  ### Phone in pocket
  native_headp_pock <- tissue_params$native_headp_pock_sar
  ### Phone elsewhere
  native_headp_else <- tissue_params$native_headp_else_sar
  ### Scale by headphone phone position
  native_headp      <- sum(params$headp_face_prop*native_headp_face,
                           params$headp_pock_prop*native_headp_pock,
                           params$headp_else_prop*native_headp_else)
  ## Phone in speaker mode ---------------------------------------------------
  native_speaker    <- tissue_params$native_speaker_sar

  ## Scale by phone use mode -------------------------------------------------
  sar <- sum(ear_prop*native_ear,
             headp_prop*native_headp,
             speaker_prop*native_speaker)
  return(sar)
}
# Total mobile call dose from phone (bluetooth) ===============================
## Dose -----------------------------------------------------------------------
#' Mobilecall bluetooth phone dose
#'
#' @param duration duration
#' @param params parameter list
#' @param tissue_params tissue parameters
get_mobilecall_bt_phone_dose <- function(duration,
                                         params,
                                         tissue_params) {
  # calculate power
  pwr <- get_mobilecall_bt_phone_pwr(params = params)
  # calculate sar
  sar <- get_mobilecall_bt_phone_sar(params = params,
                                     tissue_params = tissue_params)

  # calculate dose and return result
  dose <- duration*pwr*sar
  return(dose)
}

## Power ----------------------------------------------------------------------
#' Mobilecall bluetooth phone power
#'
#' @param params parameter list
get_mobilecall_bt_phone_pwr <- function(params) {
  pwr <- params$headp_phone_bt_pwr
  return(pwr)
}

## SAR ------------------------------------------------------------------------
#' Mobilecall bluetooth phone sar
#'
#' @param params params
#' @param tissue_params tissue params
get_mobilecall_bt_phone_sar <- function(params,
                                        tissue_params) {
  # Phone in front of face
  sar_face <- tissue_params$bt_phone_face_sar
  # Phone in pocket
  sar_pock <- tissue_params$bt_phone_pock_sar
  # Phone elsewhere
  sar_else <- tissue_params$bt_phone_else_sar

  # Scale by position and return result
  sar <- sum(params$headp_face_prop*sar_face,
             params$headp_pock_prop*sar_pock,
             params$headp_else_prop*sar_else)
  return(sar)
}


# Total mobile call dose from bluetooth headphones ============================
## Dose -----------------------------------------------------------------------
get_mobilecall_bt_headp_dose <- function(duration,
                                         params,
                                         tissue_params) {
  # calculate power
  pwr <- get_mobilecall_bt_headp_pwr(params = params)
  # calculate sar
  sar <- get_mobilecall_bt_headp_sar(params = params,
                                     tissue_params = tissue_params)
  # calculate dose
  dose <- duration*pwr*sar*2
  return(dose)
}
## Power ----------------------------------------------------------------------
get_mobilecall_bt_headp_pwr <- function(params) {
  pwr <- params$headp_phone_bt_pwr
  return(pwr)
}
## SAR ------------------------------------------------------------------------
get_mobilecall_bt_headp_sar <- function(params,
                                        tissue_params) {
  sar <- tissue_params$bt_headp_sar
  return(sar)
}
