## code to prepare GOLIAT SAR files (`inst/extdata/sar_goliat_*.yaml`) goes here
## One file per phantom, plus one with the average of the four phantoms.

source("data-raw/source-sar-goliat/reading_raw_goliat_sar.R") # creates `goliat_sar` and `phantoms`

# Rules: which GOLIAT SAR value replaces each ETAIN SAR value =================
# Each value is the mean SAR of the GOLIAT rows matching `placement` (regular
# expression; all placements if not given), from the column matching `tissue`
# (brain: SAR_brain, body: SAR_wholebody), first per frequency in
# `frequency_mhz`, then across these frequencies weighted by `frequency_prop`
# (equal weights if not given). Rows are taken from the near-field data, or
# from the far-field data for rules with `field = "FF"`. Rules with `value` set
# the SAR value directly instead. SAR values without a rule keep their ETAIN
# value.

# Devices and SAR values that keep their ETAIN value on purpose (no GOLIAT rules)
etain_kept <- c("smartwatch", "headphones", "call > bt_headp_sar")

# Placement proportions that go with the GOLIAT SAR values (the same as in
# params.yaml). They are also written into the SAR files, so that every SAR
# file carries its own proportions, also when used with another parameter file.
goliat_params <- list(
  lptp = list(legs_prop = 0, tabl_prop = 1),
  call = list(headp_face_prop = 0, headp_pock_prop = 0, headp_else_prop = 1))

# Mobile network generations: frequencies (MHz) and their share of use
band_2g <- list(frequency_mhz = c(900, 1800), frequency_prop = c(0.5, 0.5))
band_3g <- list(frequency_mhz = c(900, 2140), frequency_prop = c(0.5, 0.5))
band_4g <- list(frequency_mhz  = c(700,  835,  900,  1800, 2140, 2600),
                frequency_prop = c(0.04, 0.19, 0.21, 0.28, 0.19, 0.09))
band_5g <- list(frequency_mhz = 3500)

# WiFi bands: 2.4 GHz = 2450 MHz, 5 GHz = mean of 5200 and 5800 MHz
band_wifi_2 <- list(frequency_mhz = 2450)
band_wifi_5 <- list(frequency_mhz = c(5200, 5800))

# Far-field sources: frequencies (MHz) and their share
band_farf <- list(
  frequency_mhz  = c(450,  700,  835,  900,  1800, 2140, 2450, 2600, 3500, 5200, 5800),
  frequency_prop = c(0.08, 0.04, 0.15, 0.17, 0.23, 0.15, 0.02, 0.07, 0.07, 0.01, 0.01))

sar_rules <- list(
  list(device = "dect", tissue = "brain", key = "dect_ear_sar",
       frequency_mhz = 1800, placement = "ear"),
  list(device = "dect", tissue = "brain", key = "dect_speaker_sar",
       frequency_mhz = 1800, placement = "front"),
  list(device = "dect", tissue = "body", key = "dect_ear_sar",
       frequency_mhz = 1800, placement = "ear"),
  list(device = "dect", tissue = "body", key = "dect_speaker_sar",
       frequency_mhz = 1800, placement = "front"),
  # tblt
  c(list(device = "tblt", tissue = "brain", key = "tblt_2_sar", placement = "front"), band_wifi_2),
  c(list(device = "tblt", tissue = "brain", key = "tblt_5_sar", placement = "front"), band_wifi_5),
  c(list(device = "tblt", tissue = "body",  key = "tblt_2_sar", placement = "front"), band_wifi_2),
  c(list(device = "tblt", tissue = "body",  key = "tblt_5_sar", placement = "front"), band_wifi_5),
  # lptp: laptop on legs not simulated (SAR set to 0), laptop on table = belly
  list(device = "lptp", tissue = "brain", key = "wifi_2_legs_sar", value = 0),
  list(device = "lptp", tissue = "brain", key = "wifi_5_legs_sar", value = 0),
  list(device = "lptp", tissue = "body",  key = "wifi_2_legs_sar", value = 0),
  list(device = "lptp", tissue = "body",  key = "wifi_5_legs_sar", value = 0),
  c(list(device = "lptp", tissue = "brain", key = "wifi_2_tabl_sar", placement = "belly"), band_wifi_2),
  c(list(device = "lptp", tissue = "brain", key = "wifi_5_tabl_sar", placement = "belly"), band_wifi_5),
  c(list(device = "lptp", tissue = "body",  key = "wifi_2_tabl_sar", placement = "belly"), band_wifi_2),
  c(list(device = "lptp", tissue = "body",  key = "wifi_5_tabl_sar", placement = "belly"), band_wifi_5),
  # call (mobile data calls): phone at ear = ear, speaker = front
  c(list(device = "call", tissue = "brain", key = "data_2g_ear_sar", placement = "ear"), band_2g),
  c(list(device = "call", tissue = "body",  key = "data_2g_ear_sar", placement = "ear"), band_2g),
  c(list(device = "call", tissue = "brain", key = "data_3g_ear_sar", placement = "ear"), band_3g),
  c(list(device = "call", tissue = "body",  key = "data_3g_ear_sar", placement = "ear"), band_3g),
  c(list(device = "call", tissue = "brain", key = "data_4g_ear_sar", placement = "ear"), band_4g),
  c(list(device = "call", tissue = "body",  key = "data_4g_ear_sar", placement = "ear"), band_4g),
  c(list(device = "call", tissue = "brain", key = "data_5g_ear_sar", placement = "ear"), band_5g),
  c(list(device = "call", tissue = "body",  key = "data_5g_ear_sar", placement = "ear"), band_5g),
  c(list(device = "call", tissue = "brain", key = "data_2g_speaker_sar", placement = "front"), band_2g),
  c(list(device = "call", tissue = "body",  key = "data_2g_speaker_sar", placement = "front"), band_2g),
  c(list(device = "call", tissue = "brain", key = "data_3g_speaker_sar", placement = "front"), band_3g),
  c(list(device = "call", tissue = "body",  key = "data_3g_speaker_sar", placement = "front"), band_3g),
  c(list(device = "call", tissue = "brain", key = "data_4g_speaker_sar", placement = "front"), band_4g),
  c(list(device = "call", tissue = "body",  key = "data_4g_speaker_sar", placement = "front"), band_4g),
  c(list(device = "call", tissue = "brain", key = "data_5g_speaker_sar", placement = "front"), band_5g),
  c(list(device = "call", tissue = "body",  key = "data_5g_speaker_sar", placement = "front"), band_5g),
  # headphones: phone at face or in pocket not simulated (SAR set to 0),
  # phone elsewhere = belly
  list(device = "call", tissue = "brain", key = "data_2g_headp_face_sar", value = 0),
  list(device = "call", tissue = "body",  key = "data_2g_headp_face_sar", value = 0),
  list(device = "call", tissue = "brain", key = "data_3g_headp_face_sar", value = 0),
  list(device = "call", tissue = "body",  key = "data_3g_headp_face_sar", value = 0),
  list(device = "call", tissue = "brain", key = "data_4g_headp_face_sar", value = 0),
  list(device = "call", tissue = "body",  key = "data_4g_headp_face_sar", value = 0),
  list(device = "call", tissue = "brain", key = "data_5g_headp_face_sar", value = 0),
  list(device = "call", tissue = "body",  key = "data_5g_headp_face_sar", value = 0),
  list(device = "call", tissue = "brain", key = "data_2g_headp_pock_sar", value = 0),
  list(device = "call", tissue = "body",  key = "data_2g_headp_pock_sar", value = 0),
  list(device = "call", tissue = "brain", key = "data_3g_headp_pock_sar", value = 0),
  list(device = "call", tissue = "body",  key = "data_3g_headp_pock_sar", value = 0),
  list(device = "call", tissue = "brain", key = "data_4g_headp_pock_sar", value = 0),
  list(device = "call", tissue = "body",  key = "data_4g_headp_pock_sar", value = 0),
  list(device = "call", tissue = "brain", key = "data_5g_headp_pock_sar", value = 0),
  list(device = "call", tissue = "body",  key = "data_5g_headp_pock_sar", value = 0),
  c(list(device = "call", tissue = "brain", key = "data_2g_headp_else_sar", placement = "belly"), band_2g),
  c(list(device = "call", tissue = "body",  key = "data_2g_headp_else_sar", placement = "belly"), band_2g),
  c(list(device = "call", tissue = "brain", key = "data_3g_headp_else_sar", placement = "belly"), band_3g),
  c(list(device = "call", tissue = "body",  key = "data_3g_headp_else_sar", placement = "belly"), band_3g),
  c(list(device = "call", tissue = "brain", key = "data_4g_headp_else_sar", placement = "belly"), band_4g),
  c(list(device = "call", tissue = "body",  key = "data_4g_headp_else_sar", placement = "belly"), band_4g),
  c(list(device = "call", tissue = "brain", key = "data_5g_headp_else_sar", placement = "belly"), band_5g),
  c(list(device = "call", tissue = "body",  key = "data_5g_headp_else_sar", placement = "belly"), band_5g),
  # call over WiFi: same placements as mobile data calls
  c(list(device = "call", tissue = "brain", key = "wifi_2_ear_sar", placement = "ear"), band_wifi_2),
  c(list(device = "call", tissue = "body",  key = "wifi_2_ear_sar", placement = "ear"), band_wifi_2),
  c(list(device = "call", tissue = "brain", key = "wifi_5_ear_sar", placement = "ear"), band_wifi_5),
  c(list(device = "call", tissue = "body",  key = "wifi_5_ear_sar", placement = "ear"), band_wifi_5),
  c(list(device = "call", tissue = "brain", key = "wifi_2_speaker_sar", placement = "front"), band_wifi_2),
  c(list(device = "call", tissue = "body",  key = "wifi_2_speaker_sar", placement = "front"), band_wifi_2),
  c(list(device = "call", tissue = "brain", key = "wifi_5_speaker_sar", placement = "front"), band_wifi_5),
  c(list(device = "call", tissue = "body",  key = "wifi_5_speaker_sar", placement = "front"), band_wifi_5),
  list(device = "call", tissue = "brain", key = "wifi_2_headp_face_sar", value = 0),
  list(device = "call", tissue = "body",  key = "wifi_2_headp_face_sar", value = 0),
  list(device = "call", tissue = "brain", key = "wifi_5_headp_face_sar", value = 0),
  list(device = "call", tissue = "body",  key = "wifi_5_headp_face_sar", value = 0),
  list(device = "call", tissue = "brain", key = "wifi_2_headp_pock_sar", value = 0),
  list(device = "call", tissue = "body",  key = "wifi_2_headp_pock_sar", value = 0),
  list(device = "call", tissue = "brain", key = "wifi_5_headp_pock_sar", value = 0),
  list(device = "call", tissue = "body",  key = "wifi_5_headp_pock_sar", value = 0),
  c(list(device = "call", tissue = "brain", key = "wifi_2_headp_else_sar", placement = "belly"), band_wifi_2),
  c(list(device = "call", tissue = "body",  key = "wifi_2_headp_else_sar", placement = "belly"), band_wifi_2),
  c(list(device = "call", tissue = "brain", key = "wifi_5_headp_else_sar", placement = "belly"), band_wifi_5),
  c(list(device = "call", tissue = "body",  key = "wifi_5_headp_else_sar", placement = "belly"), band_wifi_5),
  # data (mobile data use): phone in front of the face = front
  c(list(device = "data", tissue = "brain", key = "data_3g_sar", placement = "front"), band_3g),
  c(list(device = "data", tissue = "body",  key = "data_3g_sar", placement = "front"), band_3g),
  c(list(device = "data", tissue = "brain", key = "data_4g_sar", placement = "front"), band_4g),
  c(list(device = "data", tissue = "body",  key = "data_4g_sar", placement = "front"), band_4g),
  c(list(device = "data", tissue = "brain", key = "data_5g_sar", placement = "front"), band_5g),
  c(list(device = "data", tissue = "body",  key = "data_5g_sar", placement = "front"), band_5g),
  c(list(device = "data", tissue = "brain", key = "wifi_2_sar", placement = "front"), band_wifi_2),
  c(list(device = "data", tissue = "body",  key = "wifi_2_sar", placement = "front"), band_wifi_2),
  c(list(device = "data", tissue = "brain", key = "wifi_5_sar", placement = "front"), band_wifi_5),
  c(list(device = "data", tissue = "body",  key = "wifi_5_sar", placement = "front"), band_wifi_5),
  # vr: ear placements
  c(list(device = "vr", tissue = "brain", key = "vr_2_sar", placement = "ear"), band_wifi_2),
  c(list(device = "vr", tissue = "body",  key = "vr_2_sar", placement = "ear"), band_wifi_2),
  c(list(device = "vr", tissue = "brain", key = "vr_5_sar", placement = "ear"), band_wifi_5),
  c(list(device = "vr", tissue = "body",  key = "vr_5_sar", placement = "ear"), band_wifi_5),
  # gaming: front placements
  c(list(device = "gaming", tissue = "brain", key = "gaming_2_sar", placement = "front"), band_wifi_2),
  c(list(device = "gaming", tissue = "body",  key = "gaming_2_sar", placement = "front"), band_wifi_2),
  c(list(device = "gaming", tissue = "brain", key = "gaming_5_sar", placement = "front"), band_wifi_5),
  c(list(device = "gaming", tissue = "body",  key = "gaming_5_sar", placement = "front"), band_wifi_5),
  # hotspot: belly placements, WiFi 2.4 GHz
  c(list(device = "hotspot", tissue = "brain", key = "hotspot_sar", placement = "belly"), band_wifi_2),
  c(list(device = "hotspot", tissue = "body",  key = "hotspot_sar", placement = "belly"), band_wifi_2),
  # call, Bluetooth (phone side): face and pocket set to 0, elsewhere = belly
  list(device = "call", tissue = "brain", key = "bt_phone_face_sar", value = 0),
  list(device = "call", tissue = "body",  key = "bt_phone_face_sar", value = 0),
  list(device = "call", tissue = "brain", key = "bt_phone_pock_sar", value = 0),
  list(device = "call", tissue = "body",  key = "bt_phone_pock_sar", value = 0),
  c(list(device = "call", tissue = "brain", key = "bt_phone_else_sar", placement = "belly"), band_wifi_2),
  c(list(device = "call", tissue = "body",  key = "bt_phone_else_sar", placement = "belly"), band_wifi_2),
  # wifi (access points): far field, all incidences
  c(list(device = "wifi", tissue = "brain", key = "wifi_2_sar", field = "FF"), band_wifi_2),
  c(list(device = "wifi", tissue = "body",  key = "wifi_2_sar", field = "FF"), band_wifi_2),
  c(list(device = "wifi", tissue = "brain", key = "wifi_5_sar", field = "FF"), band_wifi_5),
  c(list(device = "wifi", tissue = "body",  key = "wifi_5_sar", field = "FF"), band_wifi_5),
  # farf (far-field sources): far field, all incidences
  c(list(device = "farf", tissue = "brain", key = "sar", field = "FF"), band_farf),
  c(list(device = "farf", tissue = "body",  key = "sar", field = "FF"), band_farf)
)

# Native calls use the same SAR values as mobile data calls (data_* -> native_*)
native_rules <- lapply(
  Filter(function(rule) rule$device == "call" && startsWith(rule$key, "data_"), sar_rules),
  function(rule) {
    rule$key <- sub("^data_", "native_", rule$key)
    rule
  })
sar_rules <- c(sar_rules, native_rules)

# GOLIAT SAR of one phantom for one rule, converted from mW/kg (NF: 1 W input,
# FF: 1 W/m2 incident) to W/kg/W or W/kg per W/m2, the units used in the dose
# calculations
goliat_value <- function(rule, phantom) {
  column <- c(brain = "SAR_brain", body = "SAR_wholebody")[[rule$tissue]]
  field  <- if (is.null(rule$field)) "NF" else rule$field
  placement <- if (is.null(rule$placement)) "" else rule$placement # "" matches all
  freqs  <- rule$frequency_mhz
  props  <- if (is.null(rule$frequency_prop)) rep(1 / length(freqs), length(freqs)) else rule$frequency_prop
  if (length(props) != length(freqs) || abs(sum(props) - 1) > 1e-8) {
    stop("`frequency_prop` of ", rule$key, " (", rule$tissue, ") must have one ",
         "proportion per frequency and sum to 1.")
  }

  freq_means <- sapply(freqs, function(freq) {
    rows <- goliat_sar$field == field &
      goliat_sar$phantom == phantom &
      goliat_sar$frequency_mhz == freq &
      grepl(placement, goliat_sar$placement)
    if (!any(rows)) {
      stop("No GOLIAT ", field, " rows at ", freq, " MHz match the rule for ",
           rule$key, " (", rule$tissue, ").")
    }
    mean(goliat_sar[[column]][rows])
  })
  sum(props * freq_means) / 1000
}

# Write one SAR file per phantom and one for the average ======================
# Template: the ETAIN SAR values only (without the ETAIN placement proportions)
sar_etain <- yaml::read_yaml("inst/extdata/sar_etain.yaml")
sar_etain$devices <- lapply(sar_etain$devices, function(device) Filter(is.list, device))
n_sar     <- length(unlist(sar_etain))

params_default <- yaml::read_yaml("inst/extdata/params.yaml")
for (device in names(goliat_params)) {
  unknown <- setdiff(names(goliat_params[[device]]), names(params_default$devices[[device]]))
  if (length(unknown) > 0) {
    stop("Unknown parameter(s) for ", device, ": ", paste(unknown, collapse = ", "))
  }
}
goliat_param_names <- unlist(lapply(names(goliat_params), function(device) {
  paste(device, ">", names(goliat_params[[device]]))
}))

for (name in c(phantoms, "average")) {
  sar <- sar_etain
  for (rule in sar_rules) {
    if (is.null(sar$devices[[rule$device]][[rule$tissue]][[rule$key]])) {
      stop("Unknown SAR value: ", rule$device, " > ", rule$tissue, " > ", rule$key)
    }
    value <- if (!is.null(rule$value)) {
      rule$value
    } else if (name == "average") {
      mean(sapply(phantoms, goliat_value, rule = rule))
    } else {
      goliat_value(rule, name)
    }
    sar$devices[[rule$device]][[rule$tissue]][[rule$key]] <- value
  }
  # Placement proportions go in front of the tissue SAR values
  for (device in names(goliat_params)) {
    sar$devices[[device]] <- c(goliat_params[[device]], sar$devices[[device]])
  }

  source_name <- if (name == "average") "average of the four phantoms" else paste("phantom", name)
  header <- c(
    sprintf("# SAR values (GOLIAT, %s), per device and tissue, in W/kg/W", source_name),
    "# (far-field sources wifi and farf: W/kg per W/m2).",
    "# Generated by data-raw/source-sar-goliat/sar_goliat.R, do not edit by hand.",
    sprintf("# %d of %d values set by GOLIAT rules, the others copied from sar_etain.yaml.",
            length(sar_rules), n_sar),
    sprintf("# Kept from ETAIN on purpose: %s.", paste(etain_kept, collapse = ", ")),
    sprintf("# Also sets the placement proportions used with these SAR values: %s.",
            paste(goliat_param_names, collapse = ", ")))
  writeLines(
    c(header, sub("\n$", "", yaml::as.yaml(sar, precision = 15))),
    file.path("inst", "extdata", paste0("sar_goliat_", tolower(name), ".yaml")))
}
