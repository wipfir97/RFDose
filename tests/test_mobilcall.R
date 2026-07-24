





params <- load_params(version = "_template")

test_params <-simulate_params(country = "Italy",
                              sex = "male",
                              age = "adult",
                              simulation = "_sim1")

mobilecall_dose(
  duration = params$global$input_stoch$duration$mpc_duration,
  ear_prop = params$global$input_stoch$call_mode_prop$mpc_ear_prop,
  headp_prop = params$global$input_stoch$call_mode_prop$mpc_headp_prop,
  urbanicity = "suburban",
  use_5g = params$global$input_stoch$use_5g,
  headp_ear_num = 2,
  tissue = "brain",
  travel_time = 400,
  wifi_prop_home = 0.5,
  wifi_prop_work = 0.5,
  wifi_prop_travel = 0.5,
  simulation = "_template",
  params = test_params
)
