# Bluetooth functions #########################################################
## mpc_bt_earset_msar =========================================================
cases_mpc_bt_earset_msar <- list(
  list(
    input = list(
      tissue = "brain"
    ),
    output = 0.000462133/0.17

  ),
  list(
    input = list(
      tissue = "body"
    ),
    output = 0.000268246/0.17
  )
)

test_that("mpc_bt_earset_msar matches reference values", {
  for (case in cases_mpc_bt_earset_msar) {
    result <- do.call(mpc_bt_earset_msar, case$input)
    expect_equal(result, case$output, tolerance = 1e-3)
  }
})

## mpc_bt_phone_msar ==========================================================
cases_mpc_bt_phone_msar <- list(
  list(
    input = list(
      tissue = "brain"
    ),
    output = 9.05709E-06/0.17

  ),
  list(
    input = list(
      tissue = "body"
    ),
    output = 9.97613E-05/0.17
  )
)

test_that("mpc_bt_phone_msar matches reference values", {
  for (case in cases_mpc_bt_phone_msar) {
    result <- do.call(mpc_bt_phone_msar, case$input)
    expect_equal(result, case$output, tolerance = 1e-3)
  }
})



# Call functions ##############################################################
## mpc_msar ===================================================================
cases_mpc_msar <- list(
  list(
    input = list(
      tissue       = "brain",
      prop_native  = 0.7,
      prop_data    = 0.115394,
      prop_wifi    = 0.184606,
      headp_prop   = 0.229485,
      ear_prop     = 0.447769,
      speaker_prop = 0.322746,
      urbanicity   = "suburban",
      use_5g       = TRUE,
      travel_time  = 1850
    ),
    output = 0.209016
  ),
  list(
    input = list(
      tissue       = "body",
      prop_native  = 0.7,
      prop_data    = 0.115394,
      prop_wifi    = 0.184606,
      headp_prop   = 0.229485,
      ear_prop     = 0.447769,
      speaker_prop = 0.322746,
      urbanicity   = "suburban",
      use_5g       = TRUE,
      travel_time  = 1850
    ),
    output = 0.042345
  )
)

test_that("mpc_msar matches reference values", {
  for (case in cases_mpc_msar) {
    result <- do.call(mpc_msar, case$input)
    expect_equal(result, case$output, tolerance = 1e-3)
  }
})

## mpc_pwr_native =============================================================
cases_mpc_pwr_native <- list(
  list(
    input = list(
      band        = "2g",
      urbanicity  = "suburban",
      travel_time = 1850
    ),
    output = 142.49923
  ),
  list(
    input = list(
      band        = "3g",
      urbanicity  = "suburban",
      travel_time = 1850
    ),
    output = 1.84463
  ),
  list(
    input = list(
      band        = "4g",
      urbanicity  = "suburban",
      travel_time = 1850
    ),
    output = 6.63250
  ),
  list(
    input = list(
      band        = "5g",
      urbanicity  = "suburban",
      travel_time = 1850
    ),
    output = 0
  )
)

test_that("mpc_pwr_native matches reference values", {
  for (case in cases_mpc_pwr_native) {
    result <- do.call(mpc_pwr_native, case$input)
    expect_equal(result, case$output, tolerance = 1e-3)
  }
})

## mpc_sar_native =============================================================
cases_mpc_sar_native <- list(
  list(
    input = list(
      tissue       = "brain",
      band         = "2g",
      headp_prop   = 0.229485,
      ear_prop     = 0.447769,
      speaker_prop = 0.322746
    ),
    output = 0.038915611
  ),
  list(
    input = list(
      tissue       = "body",
      band         = "3g",
      headp_prop   = 0.229485,
      ear_prop     = 0.447769,
      speaker_prop = 0.322746
    ),
    output = 0.00663549
  ),
  list(
    input = list(
      tissue       = "brain",
      band         = "4g",
      headp_prop   = 0.229485,
      ear_prop     = 0.447769,
      speaker_prop = 0.322746
    ),
    output = 0.035978107
  ),
  list(
    input = list(
      tissue       = "body",
      band         = "5g",
      headp_prop   = 0.229485,
      ear_prop     = 0.447769,
      speaker_prop = 0.322746
    ),
    output = 0.00585367
  )
)

test_that("mpc_sar_native matches reference values", {
  for (case in cases_mpc_sar_native) {
    result <- do.call(mpc_sar_native, case$input)
    expect_equal(result, case$output, tolerance = 1e-5)
  }
})

## mpc_pwr_data ===============================================================
cases_mpc_pwr_data <- list(
  list(
    input = list(
      band        = "3g",
      urbanicity  = "suburban",
      travel_time = 1850
    ),
    output = 1.044178
  ),
  list(
    input = list(
      band        = "4g",
      urbanicity  = "suburban",
      travel_time = 1850
    ),
    output = 4.283853
  ),
  list(
    input = list(
      band        = "5g",
      urbanicity  = "suburban",
      travel_time = 1850
    ),
    output = 2.466986
  )
)

test_that("mpc_pwr_data matches reference values", {
  for (case in cases_mpc_pwr_data) {
    result <- do.call(mpc_pwr_data, case$input)
    expect_equal(result, case$output, tolerance = 1e-4)
  }
})
## mpc_sar_data ===============================================================
cases_mpc_sar_data <- list(
  list(
    input = list(
      tissue       = "brain",
      band         = "2g",
      headp_prop   = 0.229485,
      ear_prop     = 0.447769,
      speaker_prop = 0.322746
    ),
    output = 0.038915611
  ),
  list(
    input = list(
      tissue       = "body",
      band         = "3g",
      headp_prop   = 0.229485,
      ear_prop     = 0.447769,
      speaker_prop = 0.322746
    ),
    output = 0.00663549
  ),
  list(
    input = list(
      tissue       = "brain",
      band         = "4g",
      headp_prop   = 0.229485,
      ear_prop     = 0.447769,
      speaker_prop = 0.322746
    ),
    output = 0.035978107
  ),
  list(
    input = list(
      tissue       = "body",
      band         = "5g",
      headp_prop   = 0.229485,
      ear_prop     = 0.447769,
      speaker_prop = 0.322746
    ),
    output = 0.00585367

  )
)

test_that("mpc_sar_data matches reference values", {
  for (case in cases_mpc_sar_data) {
    result <- do.call(mpc_sar_data, case$input)
    expect_equal(result, case$output, tolerance = 1e-4)
  }
})


## mpc_pwr_wifi ===============================================================
cases_mpc_pwr_wifi <- list(
  list(
    input = list(
      band        = "2"
    ),
    output = 2.738
  ),
  list(
    input = list(
      band        = "5"
    ),
    output = 9.860
  )
)

test_that("mpc_pwr_wifi matches reference values", {
  for (case in cases_mpc_pwr_wifi) {
    result <- do.call(mpc_pwr_wifi, case$input)
    expect_equal(result, case$output, tolerance = 1e-3)
  }
})

## mpc_sar_wifi ===============================================================
cases_mpc_sar_wifi <- list(
  list(
    input = list(
      tissue       = "brain",
      band         = "2",
      headp_prop   = 0.229485,
      ear_prop     = 0.447769,
      speaker_prop = 0.322746
    ),
    output = 0.012555857
  ),
  list(
    input = list(
      tissue       = "body",
      band         = "2",
      headp_prop   = 0.229485,
      ear_prop     = 0.447769,
      speaker_prop = 0.322746
    ),
    output = 0.00560245
  ),
  list(
    input = list(
      tissue       = "brain",
      band         = "5",
      headp_prop   = 0.229485,
      ear_prop     = 0.447769,
      speaker_prop = 0.322746
    ),
    output = 0.000597634
  ),
  list(
    input = list(
      tissue       = "body",
      band         = "5",
      headp_prop   = 0.229485,
      ear_prop     = 0.447769,
      speaker_prop = 0.322746
    ),
    output = 0.00356943
  )
)

test_that("mpc_sar_wifi matches reference values", {
  for (case in cases_mpc_sar_wifi) {
    result <- do.call(mpc_sar_wifi, case$input)
    # tolerance due to rounded values in reference calculations
    expect_equal(result, case$output, tolerance = 1e-6)
  }
})
