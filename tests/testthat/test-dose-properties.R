# Physical properties of the doses ############################################

params <- load_params()
sample <- as.list(make_test_input())

# Input durations of each dose from device use
device_durations <- list(
  call_dose  = "mpc_duration",
  data_dose  = c("mpd_dur_low", "mpd_dur_lowtomed", "mpd_dur_medtohigh", "mpd_dur_high"),
  dect_dose  = "dect_duration",
  lptp_dose  = c("lptp_dur_low", "lptp_dur_lowtomed", "lptp_dur_medtohigh", "lptp_dur_high"),
  tblt_dose  = c("tblt_dur_low", "tblt_dur_lowtomed", "tblt_dur_medtohigh", "tblt_dur_high"),
  other_dose = c("hotspot_duration", "smartwatch_duration", "vr_duration",
                 "headphone_duration", "gaming_duration"))
device_cols      <- names(device_durations)
environment_cols <- setdiff(dose_cols, device_cols) # far-field and WiFi

## Zero use ===================================================================
test_that("doses from device use are zero when no device is used", {
  no_use <- sample
  no_use[unlist(device_durations)] <- 0

  for (tissue in c("brain", "body")) {
    result <- total_dose(no_use, tissue = tissue, params = params)

    expect_equal(result[device_cols], setNames(rep(0, length(device_cols)), device_cols),
                 label = paste(tissue, "doses"))
  }
})

test_that("far-field and WiFi doses do not depend on device use", {
  no_use <- sample
  no_use[unlist(device_durations)] <- 0

  for (tissue in c("brain", "body")) {
    use    <- total_dose(sample, tissue = tissue, params = params)
    result <- total_dose(no_use, tissue = tissue, params = params)

    expect_true(all(result[environment_cols] > 0))
    expect_equal(result[environment_cols], use[environment_cols], label = paste(tissue, "doses"))
  }
})

## Duration ===================================================================
test_that("each device dose scales linearly with its own durations only", {
  for (tissue in c("brain", "body")) {
    base <- total_dose(sample, tissue = tissue, params = params)
    expect_true(all(base[device_cols] > 0))

    for (device in device_cols) {
      # Double the durations of one device: its dose doubles, the others do not change
      doubled <- sample
      doubled[device_durations[[device]]] <- lapply(sample[device_durations[[device]]], `*`, 2)
      expected <- base
      expected[device] <- 2 * base[device]

      expect_equal(total_dose(doubled, tissue = tissue, params = params), expected,
                   label = paste(tissue, device))
    }
  }
})
