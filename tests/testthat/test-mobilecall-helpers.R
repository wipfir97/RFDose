# Test mobile call helper functions
# mpc_sar_native_bytech =======================================================
## check if mpc_sar_native_bytech sar values match reference values
reference_cases <- list(
  list(
    input = list(
      tissue = "brain",
      tech   = "2g",
      headp_prop = 0.17,
      ear_prop = 0.66,
      speaker_prop = 0.17
    ),
    output = 0.04840192
  ),
  list(
    input = list(
      tissue = "body",
      tech   = "2g",
      headp_prop = 0.17,
      ear_prop = 0.66,
      speaker_prop = 0.17
    ),
    output = 0.00655103
  ),
  list(
    input = list(
      tissue = "brain",
      tech   = "3g",
      headp_prop = 0.17,
      ear_prop = 0.66,
      speaker_prop = 0.17
    ),
    output = 0.044794452
  ),
  list(
    input = list(
      tissue = "body",
      tech   = "3g",
      headp_prop = 0.17,
      ear_prop = 0.66,
      speaker_prop = 0.17
    ),
    output = 0.006058526
  ),
  list(
    input = list(
      tissue = "brain",
      tech   = "4g",
      headp_prop = 0.17,
      ear_prop = 0.66,
      speaker_prop = 0.17
    ),
    output = 0.04286737
  ),
  list(
    input = list(
      tissue = "body",
      tech   = "4g",
      headp_prop = 0.17,
      ear_prop = 0.66,
      speaker_prop = 0.17
    ),
    output = 0.006103341
  ),
  list(
    input = list(
      tissue = "brain",
      tech   = "5g",
      headp_prop = 0.17,
      ear_prop = 0.66,
      speaker_prop = 0.17
    ),
    output = 0.00269136
  ),
  list(
    input = list(
      tissue = "body",
      tech   = "5g",
      headp_prop = 0.17,
      ear_prop = 0.66,
      speaker_prop = 0.17
    ),
    output = 0.004257159
  )
)
test_that("mpc_sar_native_bytech sar values match reference values", {
  for (case in reference_cases) {
    result <- do.call(mpc_sar_native_bytech, case$input)
    expect_equal(result, case$output, tolerance = 1e-2)
  }
})

# mpc_pwr_native_bytech =======================================================
## check if mpc_pwr_native_bytech output power  values match reference values
# TODO: add reference values for other urbanicities,
reference_cases <- list(
  list(
    input = list(
      tech   = "2g",
      urbanicity = "suburban",
      travel_time = 1800
    ),
    output = 142.56
  ),
  list(
    input = list(
      tech   = "3g",
      urbanicity = "suburban",
      travel_time = 1800
    ),
    output = 1.85
  ),
  list(
    input = list(
      tech   = "4g",
      urbanicity = "suburban",
      travel_time = 1800
    ),
    output = 6.63
  ),
  list(
    input = list(
      tech   = "5g",
      urbanicity = "suburban",
      travel_time = 1800
    ),
    output = 0
  )
)

test_that("mpc_pwr_native_bytech output power values match reference values", {
  for (case in reference_cases) {
    result <- do.call(mpc_pwr_native_bytech, case$input)
    expect_equal(result, case$output, tolerance = 1e-2)
  }
})

# mpc_msar_native_bytech ======================================================
# TODO: add more reference values

# mpc_msar_native =============================================================

# mobilecall_msar =============================================================
