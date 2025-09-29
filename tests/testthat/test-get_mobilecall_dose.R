test_that("mobilecall dose function matches expected results", {
  # Load reference test data
  ref_file <- system.file("extdata", "test_data_mpc.csv", package = "ETAINDoseCalculator"
  ref_data <- read.csv(ref_file, stringsAsFactors = FALSE)

  # Load parameters

  # Loop over rows
  for (i in seq_len(nrow(ref_data))) {
    input <- ref_data[i, ]


    # Call your function with inputs (adapt this to your function!)
    result <- get_mobilecall_dose(duration      = ref_data$mpc_duration,
                                  ear_prop      = ref_data$mpc_ear_prop,
                                  headp_prop    = ref_data$mpc_headp_prop,
                                  urbanicity    = ref_data$urbanicity,
                                  use_5g        = ref_data$use_5g,
                                  travel_time   = ref_data$travel_time,
                                  headp_ear_num = ref_data$headp_ear_num,
                                  params        = params)

    # Compare with expected value
    expect_equal(result, input$expected_output, tolerance = 1e-6)
  }
})
