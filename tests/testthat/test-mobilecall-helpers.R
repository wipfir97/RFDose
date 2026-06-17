# Bluetooth functions #########################################################
## mpc_bt_msar ================================================================
cases_mpc_bt_msar <- list(
  list(
    input = list(
      tissue = "brain"
    ),
    output = (0.000462133+9.05709E-06)/0.17 # (msar bt + msar phone)/headp_prop

  ),
  list(
    input = list(
      tissue = "body"
    ),
    output = (0.000268246+9.97613E-05)/0.17 # (msar bt + msar phone)/headp_prop
  )
)

test_that("mpc_bt_msar matches reference values", {
  for (case in cases_mpc_bt_msar) {
    result <- do.call(mpc_bt_msar, case$input)
    expect_equal(result, case$output, tolerance = 1e-3)
  }
})

## mpc_bt_pwr =================================================================
test_that("mpc_bt_pwr matches reference values", {
    result <- mpc_bt_pwr()
    expect_equal(result, 0.16, tolerance = 1e-3)
})

## mpc_bt_sar =================================================================
cases_mpc_bt_sar <- list(
  list(
    input = list(
      tissue = "brain"
    ),
    output = 0.01699017
  ),
  list(
    input = list(
      tissue = "body"
    ),
    output = 0.009862
  )
)

test_that("mpc_bt_sar matches reference values", {
  for (case in cases_mpc_bt_sar) {
    result <- do.call(mpc_bt_sar, case$input)
    expect_equal(result, case$output, tolerance = 1e-3)
  }
})

## mpc_bt_phone_pwr ===========================================================
test_that("mpc_bt_phone_pwr matches reference values", {
    result <- mpc_bt_phone_pwr()
    expect_equal(result, 0.16, tolerance = 1e-3)
})

## mpc_bt_phone_sar ===========================================================
cases_mpc_bt_phone_sar <- list(
  list(
    input = list(
      tissue = "brain"
    ),
    output = 0.000332981
  ),
  list(
    input = list(
      tissue = "body"
    ),
    output = 0.003667694
  )
)

test_that("mpc_bt_phone_sar matches reference values", {
  for (case in cases_mpc_bt_phone_sar) {
    result <- do.call(mpc_bt_phone_sar, case$input)
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
      prop_data    = 0.16,
      prop_wifi    = 0.14,
      headp_prop   = 0.17,
      ear_prop     = 0.66,
      speaker_prop = 0.17,
      urbanicity   = "suburban",
      use_5g       = TRUE,
      travel_time  = 1800
    ),
    output = 0.254694
  ),
  list(
    input = list(
      tissue       = "body",
      prop_native  = 0.7,
      prop_data    = 0.16,
      prop_wifi    = 0.14,
      headp_prop   = 0.17,
      ear_prop     = 0.66,
      speaker_prop = 0.17,
      urbanicity   = "suburban",
      use_5g       = TRUE,
      travel_time  = 1800
    ),
    output = 0.038438
  )
)

test_that("mpc_msar matches reference values", {
  for (case in cases_mpc_msar) {
    result <- do.call(mpc_msar, case$input)
    expect_equal(result, case$output, tolerance = 1e-2)
  }
})

## mpc_pwr_native =============================================================
cases_mpc_pwr_native <- list(
  list(
    input = list(
      band        = "2g",
      urbanicity  = "suburban",
      travel_time = 1800
    ),
    output = 142.56
  ),
  list(
    input = list(
      band        = "3g",
      urbanicity  = "suburban",
      travel_time = 1800
    ),
    output = 1.85
  ),
  list(
    input = list(
      band        = "4g",
      urbanicity  = "suburban",
      travel_time = 1800
    ),
    output = 6.63
  ),
  list(
    input = list(
      band        = "5g",
      urbanicity  = "suburban",
      travel_time = 1800
    ),
    output = 0
  )
)

test_that("mpc_pwr_native matches reference values", {
  for (case in cases_mpc_pwr_native) {
    result <- do.call(mpc_pwr_native, case$input)
    expect_equal(result, case$output, tolerance = 1e-2)
  }
})

## mpc_sar_native =============================================================
cases_mpc_sar_native <- list(
  list(
    input = list(
      tissue       = "brain",
      band         = "2g",
      headp_prop   = 0.17,
      ear_prop     = 0.66,
      speaker_prop = 0.17
    ),
    output = 0.048401918
  ),
  list(
    input = list(
      tissue       = "body",
      band         = "3g",
      headp_prop   = 0.17,
      ear_prop     = 0.66,
      speaker_prop = 0.17
    ),
    output = 0.006058526
  ),
  list(
    input = list(
      tissue       = "brain",
      band         = "4g",
      headp_prop   = 0.17,
      ear_prop     = 0.66,
      speaker_prop = 0.17
    ),
    output = 0.04286737
  ),
  list(
    input = list(
      tissue       = "body",
      band         = "5g",
      headp_prop   = 0.17,
      ear_prop     = 0.66,
      speaker_prop = 0.17
    ),
    output = 0.004257159
  )
)

test_that("mpc_sar_native matches reference values", {
  for (case in cases_mpc_sar_native) {
    result <- do.call(mpc_sar_native, case$input)
    expect_equal(result, case$output, tolerance = 1e-2)
  }
})

## mpc_pwr_data ===============================================================
cases_mpc_pwr_data <- list(
  list(
    input = list(
      band        = "3g",
      urbanicity  = "suburban",
      travel_time = 1800
    ),
    output = 1.04
  ),
  list(
    input = list(
      band        = "4g",
      urbanicity  = "suburban",
      travel_time = 1800
    ),
    output = 4.28
  ),
  list(
    input = list(
      band        = "5g",
      urbanicity  = "suburban",
      travel_time = 1800
    ),
    output = 2.47
  )
)

test_that("mpc_pwr_data matches reference values", {
  for (case in cases_mpc_pwr_data) {
    result <- do.call(mpc_pwr_data, case$input)
    expect_equal(result, case$output, tolerance = 1e-2)
  }
})
## mpc_sar_data ===============================================================
cases_mpc_sar_data <- list(
  list(
    input = list(
      tissue       = "brain",
      band         = "2g",
      headp_prop   = 0.17,
      ear_prop     = 0.66,
      speaker_prop = 0.17
    ),
    output = 0.048401918
  ),
  list(
    input = list(
      tissue       = "body",
      band         = "3g",
      headp_prop   = 0.17,
      ear_prop     = 0.66,
      speaker_prop = 0.17
    ),
    output = 0.006058526
  ),
  list(
    input = list(
      tissue       = "brain",
      band         = "4g",
      headp_prop   = 0.17,
      ear_prop     = 0.66,
      speaker_prop = 0.17
    ),
    output = 0.04286737
  ),
  list(
    input = list(
      tissue       = "body",
      band         = "5g",
      headp_prop   = 0.17,
      ear_prop     = 0.66,
      speaker_prop = 0.17
    ),
    output = 0.004257159
  )
)

test_that("mpc_sar_data matches reference values", {
  for (case in cases_mpc_sar_data) {
    result <- do.call(mpc_sar_data, case$input)
    expect_equal(result, case$output, tolerance = 1e-2)
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
    output = 8.77
  )
)

test_that("mpc_pwr_wifi matches reference values", {
  for (case in cases_mpc_pwr_wifi) {
    result <- do.call(mpc_pwr_wifi, case$input)
    expect_equal(result, case$output, tolerance = 1e-2)
  }
})

## mpc_sar_wifi ===============================================================
cases_mpc_sar_wifi <- list(
  list(
    input = list(
      tissue       = "brain",
      band         = "2",
      headp_prop   = 0.17,
      ear_prop     = 0.66,
      speaker_prop = 0.17
    ),
    output = 0.011082092
  ),
  list(
    input = list(
      tissue       = "body",
      band         = "2",
      headp_prop   = 0.17,
      ear_prop     = 0.66,
      speaker_prop = 0.17
    ),
    output = 0.004340356
  ),
  list(
    input = list(
      tissue       = "brain",
      band         = "5",
      headp_prop   = 0.17,
      ear_prop     = 0.66,
      speaker_prop = 0.17
    ),
    output = 0.000438569
  ),
  list(
    input = list(
      tissue       = "body",
      band         = "5",
      headp_prop   = 0.17,
      ear_prop     = 0.66,
      speaker_prop = 0.17
    ),
    output = 0.002704676
  )
)

test_that("mpc_sar_wifi matches reference values", {
  for (case in cases_mpc_sar_wifi) {
    result <- do.call(mpc_sar_wifi, case$input)
    expect_equal(result, case$output, tolerance = 1e-2)
  }
})
