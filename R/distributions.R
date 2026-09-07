simulate_params <- function(duration,
                            ear_prop,
                            headp_prop,
                            urbanicity,
                            use_5g,
                            travel_time,
                            headp_ear_num,
                            wifi_prop_home,
                            wifi_prop_work,
                            wifi_prop_travel,
                            sex,
                            age,
                            country,
                            mpd_dur_low,
                            mpd_dur_lowtomed,
                            mpd_dur_medtohigh,
                            mpd_dur_high,
                            dect_duration,
                            dect_ear_prop,
                            lptp_dur_low,
                            lptp_dur_lowtomed,
                            lptp_dur_medtohigh,
                            lptp_dur_high,
                            tblt_dur_low,
                            tblt_dur_lowtomed,
                            tblt_dur_medtohigh,
                            tblt_dur_high,
                            hotspot_duration,
                            smartwatch_duration,
                            tracker_duration,
                            vr_duration,
                            headphone_duration,
                            gaming_duration,
                            simulation,
                            params = NULL){
  params <- load_params(version = simulation)

  #:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  #set non-stochastic inputs
  non_stochastic_inputs <- c(
    "country",
    "mpd_dur_low",
    "mpd_dur_lowtomed",
    "mpd_dur_medtohigh",
    "mpd_dur_high",
    "dect_duration",
    "dect_ear_prop",
    "lptp_dur_low",
    "lptp_dur_lowtomed",
    "lptp_dur_medtohigh",
    "lptp_dur_high",
    "tblt_dur_low",
    "tblt_dur_lowtomed",
    "tblt_dur_medtohigh",
    "tblt_dur_high",
    "hotspot_duration",
    "smartwatch_duration",
    "tracker_duration",
    "vr_duration",
    "headphone_duration"
  )

  for (nm in non_stochastic_inputs) {

    is_missing <- eval(
      substitute(
        missing(x),
        list(x = as.name(nm))
      )
    )

    if (!is_missing) {
      params$global$input_default[[nm]] <- get(nm)
    }

  }
  #:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  # set stochastic input

  ####### mobile call
  params_stochastic = yaml::read_yaml(system.file("extdata", paste0("params_stochastic.yaml"), package = "RFDose"))

  # use defaults if missing
  if (missing(duration)) {duration <- params_stochastic$global$input_stoch$duration$mpc_duration_mean}
  if (missing(ear_prop)) {ear_prop <- params_stochastic$global$input_stoch$call_mode_prop$mpc_ear_prop_mean}
  if (missing(headp_prop)) {headp_prop <- params_stochastic$global$input_stoch$call_mode_prop$mpc_headp_prop_mean}
  speaker_prop <- 1 - ear_prop - headp_prop
  if (missing(headp_ear_num)) {headp_ear_num <- params_stochastic$global$input_stoch$headp_num$headp_ear_num_mean}
  if (missing(wifi_prop_home)) {wifi_prop_home <- params_stochastic$global$input_stoch$wifi_environment_probs$mpd_wifi_prop_home_mean}
  if (missing(wifi_prop_work)) {wifi_prop_work <- params_stochastic$global$input_stoch$wifi_environment_probs$mpd_wifi_prop_work_mean}
  if (missing(wifi_prop_travel)) {wifi_prop_travel <- params_stochastic$global$input_stoch$wifi_environment_probs$mpd_wifi_prop_travel_mean}
  if (missing(travel_time)) {
    travel_prop <- params_stochastic$global$environment_prop$travel_prop_mean
    home_prop <- params_stochastic$global$environment_prop$home_prop_mean
  } else {
    travel_prop <- travel_time/86400
    home_prop <- params_stochastic$global$environment_prop$home_prop_mean +
                params_stochastic$global$environment_prop$travel_prop_mean -
                travel_prop
  }



  #pick duration
  # correct duration mean to pZero values:
  pzero <- params_stochastic$global$input_stoch$duration$mpc_duration_pzero
  duration <- duration/(1-pzero)

  params$global$input_stoch$duration$mpc_duration <- evaluate_distribution(
        dist_name = params_stochastic$global$input_stoch$duration$distribution,
        mean = duration,
        sd = params_stochastic$global$input_stoch$duration$mpc_duration_sd,
        p_zero = pzero,
        min = params_stochastic$global$input_stoch$duration$mpc_duration_min,
        max = params_stochastic$global$input_stoch$duration$mpc_duration_max
      )

  #pick ear_prop, headp_prop, speaker_prop
  props <- evaluate_distribution(
    dist_name = params_stochastic$global$input_stoch$call_mode_prop$distribution,
    mean = c(ear_prop,headp_prop,speaker_prop),
    a0 = params_stochastic$global$input_stoch$call_mode_prop$call_mode_prop_a0
  )
  params$global$input_stoch$call_mode_prop$mpc_ear_prop   <- props[1]
  params$global$input_stoch$call_mode_prop$mpc_headp_prop <- props[2]
  params$global$input_stoch$call_mode_prop$speaker_prop   <- props[3]

  #pick headp_ear_num
  params$global$input_stoch$headp_num$headp_ear_num <- evaluate_distribution(
    dist_name = params_stochastic$global$input_stoch$headp_num$distribution,
    mean = c(params_stochastic$global$input_stoch$headp_num$headp_ear_num_mean,
             1-params_stochastic$global$input_stoch$headp_num$headp_ear_num_mean),
    a0 = params_stochastic$global$input_stoch$headp_num$headp_ear_num_a0
  )[1] + 1

  #pick home_prop, work_prop, outdoor_prop and travel_prop
  env_props <- evaluate_distribution(
    dist_name = params_stochastic$global$environment_prop$distribution,
    mean = c(home_prop,
             params_stochastic$global$environment_prop$outd_prop_mean,
             params_stochastic$global$environment_prop$work_prop_mean,
             travel_prop),
    a0 = params_stochastic$global$environment_prop$environment_prop_a0
  )
  params$global$environment_prop$home_prop <- env_props[1]
  params$global$environment_prop$outd_prop <- env_props[2]
  params$global$environment_prop$work_prop <- env_props[3]
  params$global$environment_prop$travel_prop <- env_props[4]


  #pick wifi_prop_home
  params$global$input_stoch$wifi_environment_probs$mpd_wifi_prop_home <- evaluate_distribution(
    dist_name = params_stochastic$global$input_stoch$wifi_environment_probs$distribution,
    mean = c(params_stochastic$global$input_stoch$wifi_environment_probs$mpd_wifi_prop_home_mean,
             1-params_stochastic$global$input_stoch$wifi_environment_probs$mpd_wifi_prop_home_mean),
    a0 = params_stochastic$global$input_stoch$wifi_environment_probs$mpd_wifi_prop_home_a0
  )[1]

  #pick mpd_wifi_prop_work
  params$global$input_stoch$wifi_environment_probs$mpd_wifi_prop_work <- evaluate_distribution(
    dist_name = params_stochastic$global$input_stoch$wifi_environment_probs$distribution,
    mean = c(params_stochastic$global$input_stoch$wifi_environment_probs$mpd_wifi_prop_work_mean,
             1-params_stochastic$global$input_stoch$wifi_environment_probs$mpd_wifi_prop_work_mean),
    a0 = params_stochastic$global$input_stoch$wifi_environment_probs$mpd_wifi_prop_work_a0
  )[1]

  #pick mpd_wifi_prop_travel
  params$global$input_stoch$wifi_environment_probs$mpd_wifi_prop_travel <- evaluate_distribution(
    dist_name = params_stochastic$global$input_stoch$wifi_environment_probs$distribution,
    mean = c(params_stochastic$global$input_stoch$wifi_environment_probs$mpd_wifi_prop_travel_mean,
             1-params_stochastic$global$input_stoch$wifi_environment_probs$mpd_wifi_prop_travel_mean),
    a0 = params_stochastic$global$input_stoch$wifi_environment_probs$mpd_wifi_prop_travel_a0
  )[1]


  #pick sex (if default is given, this sex is taken for every simulation)
  if (missing(sex)) { sex <- evaluate_distribution(
      dist_name = params_stochastic$global$input_stoch$sex$distribution,
      p_categorie1 = params_stochastic$global$input_stoch$sex$male_prop,
      categorie1 = "male",
      categorie2 = "female"
    )
  }
  params$global$input_stoch$sex <- sex

  #pick age (if default is given, this age is taken for every simulation)
  if (missing(age)) { age <- evaluate_distribution(
    dist_name = params_stochastic$global$input_stoch$age$distribution,
    p_categorie1 = params_stochastic$global$input_stoch$age$adult_prop,
    categorie1 = "adult",
    categorie2 = "child"
    )
  }
  params$global$input_stoch$age <- age

  #pick use_5g (if default is given, it is taken for every simulation)
  if (missing(use_5g)) {use_5g <- evaluate_distribution(
    dist_name = params_stochastic$global$input_stoch$use_5g$distribution,
    p_categorie1 = params_stochastic$global$input_stoch$use_5g$use_5g_prop,
    categorie1 = TRUE,
    categorie2 = FALSE
  )
  }
  params$global$input_stoch$use_5g <- use_5g
  #pick urbanicity
  if (missing(urbanicity)) {
    urban_props <- evaluate_distribution(
      dist_name = params_stochastic$global$input_stoch$urbanicity$distribution,
      mean = c(params_stochastic$global$input_stoch$urbanicity$urb_prop,
               params_stochastic$global$input_stoch$urbanicity$sub_prop,
               params_stochastic$global$input_stoch$urbanicity$rur_prop),
      a0 = params_stochastic$global$input_stoch$urbanicity$urbanicity_a0
    )
    params$global$input_stoch$urbanicity$urb_prop <- urban_props[1]
    params$global$input_stoch$urbanicity$sub_prop <- urban_props[2]
    params$global$input_stoch$urbanicity$rur_prop <- urban_props[3]

  } else {
    params$global$input_stoch$urbanicity$urb_prop <- 1*(urbanicity=="urban")
    params$global$input_stoch$urbanicity$sub_prop <- 1*(urbanicity=="suburban")
    params$global$input_stoch$urbanicity$rur_prop <- 1*(urbanicity=="rural")
  }





  ####### mobile data

  # mpd_dur_low, mpd_dur_lowmed, mpd_dur_medhigh, mpd_dur_high
  mpd_durations <- list()
  if (missing(mpd_dur_low)) {mpd_durations$low <- params_stochastic$global$input_stoch$mpd_duration[[paste0("mpd_dur_low_mean")]]}
  else{mpd_durations$low <- mpd_dur_low}
  if (missing(mpd_dur_lowtomed)) {mpd_durations$lowmed <- params_stochastic$global$input_stoch$mpd_duration[[paste0("mpd_dur_lowmed_mean")]]}
  else{mpd_durations$lowmed <- mpd_dur_lowtomed}
  if (missing(mpd_dur_medtohigh)) {mpd_durations$medhigh <- params_stochastic$global$input_stoch$mpd_duration[[paste0("mpd_dur_medhigh_mean")]]}
  else{mpd_durations$medhigh <- mpd_dur_medtohigh}
  if (missing(mpd_dur_high)) {mpd_durations$high <- params_stochastic$global$input_stoch$mpd_duration[[paste0("mpd_dur_high_mean")]]}
  else{mpd_durations$high <- mpd_dur_high}

  levels <- c("low","lowmed","medhigh","high")
  for (l in levels) {
    params$global$input_stoch$mpd_duration[[paste0("mpd_dur_",l)]] <- evaluate_distribution(
      dist_name = params_stochastic$global$input_stoch$mpd_duration$distribution,
      mean =  mpd_durations[[l]],
      sd   = params_stochastic$global$input_stoch$mpd_duration[[paste0("mpd_dur_",l, "_sd")]],
      max  = params_stochastic$global$input_stoch$mpd_duration[[paste0("mpd_dur_",l, "_max")]]
    )
  }
  ####### cordless
  if (missing(dect_duration)) {dect_duration <- params_stochastic$global$input_stoch$dect_duration$dect_duration_mean
  }
  if (missing(dect_ear_prop)) {dect_ear_prop <- params_stochastic$global$input_stoch$dect_ear_prop$dect_ear_prop_mean}
  # pick dect_duration
  pzero <- params_stochastic$global$input_stoch$dect_duration$dect_duration_pzero
  dect_duration <- dect_duration/(1-pzero)

  params$global$input_stoch$dect_duration$dect_duration <- evaluate_distribution(
    dist_name = params_stochastic$global$input_stoch$dect_duration$distribution,
    mean = dect_duration,
    sd = params_stochastic$global$input_stoch$dect_duration$dect_duration_sd,
    p_zero = pzero,
    min = params_stochastic$global$input_stoch$dect_duration$dect_duration_min,
    max = params_stochastic$global$input_stoch$dect_duration$dect_duration_max
  )
  # dect_ear_prop
  params$global$input_stoch$dect_position$dect_ear_prop <- evaluate_distribution(
    dist_name = params_stochastic$global$input_stoch$dect_position$distribution,
    mean = c(params_stochastic$global$input_stoch$dect_position$dect_ear_prop_mean,
             1-params_stochastic$global$input_stoch$dect_position$dect_ear_prop_mean),
    a0 = params_stochastic$global$input_stoch$dect_position$dect_ear_prop_a0
  )[1]

  ####### gaming
  if (missing(gaming_duration)) {gaming_duration <- params_stochastic$global$input_stoch$gaming_duration$gaming_duration_mean
  }
  # pick gaming_duration
  pzero <- params_stochastic$global$input_stoch$gaming_duration$gaming_duration_pzero
  gaming_duration <- gaming_duration/(1-pzero)

  params$global$input_stoch$gaming_duration$gaming_duration <- evaluate_distribution(
    dist_name = params_stochastic$global$input_stoch$gaming_duration$distribution,
    mean = gaming_duration,
    sd = params_stochastic$global$input_stoch$gaming_duration$gaming_duration_sd,
    p_zero = pzero,
    min = params_stochastic$global$input_stoch$gaming_duration$gaming_duration_min,
    max = params_stochastic$global$input_stoch$gaming_duration$gaming_duration_max
  )

  # lptp_dur_low
  # lptp_dur_lowtomed
  # lptp_dur_medtohigh
  # lptp_dur_high
  # tblt_dur_low
  # tblt_dur_lowtomed
  # tblt_dur_medtohigh
  # tblt_dur_high
  # hotspot_duration
  # smartwatch_duration
  # tracker_duration
  # vr_duration
  # headphone_duration

  # country

  #:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  # set stochastic parameters

  ####### mobile call
  # pick wifi_probs_____________________________________________________________
  wifi_p <- evaluate_distribution(
    dist_name = params_stochastic$global$wifi_probs$distribution,
    mean = c(params_stochastic$global$wifi_probs$wifi_2400_prop,
             params_stochastic$global$wifi_probs$wifi_5000_prop),
    a0 = params_stochastic$global$wifi_probs$wifi_prop_a0
  )
  params$global$wifi_probs$wifi_2400_prop <-  wifi_p[1]
  params$global$wifi_probs$wifi_5000_prop <-  wifi_p[2]

  # pick call_type______________________________________________________________
  nativecall_prop <- evaluate_distribution(
    dist_name = params_stochastic$devices$call$call_type$distribution,
    mean = c(params_stochastic$devices$call$call_type$native_prop_mean,
             1 - params_stochastic$devices$call$call_type$native_prop_mean),
    a0 = params_stochastic$device$call$call_type$call_type_a0
  )[1]
  params$devices$call$call_type$native_prop <-  nativecall_prop
  wificall_prop <-  (1-nativecall_prop)*(
    params$global$input_stoch$wifi_environment_probs$mpd_wifi_prop_home*params$global$environment_prop$home_prop +
    params$global$input_stoch$wifi_environment_probs$mpd_wifi_prop_work*params$global$environment_prop$work_prop +
    params$global$input_stoch$wifi_environment_probs$mpd_wifi_prop_travel*params$global$environment_prop$travel_prop
  )
  params$devices$call$call_type$wifi_prop <- wificall_prop
  params$devices$call$call_type$data_prop <- 1-nativecall_prop-wificall_prop

  # pick native_band_props______________________________________________________
  native_prop <- evaluate_distribution(
    dist_name = params_stochastic$devices$call$native_band_props$distribution,
    mean = c(params_stochastic$devices$call$native_band_props$native_2g_prop_mean,
             params_stochastic$devices$call$native_band_props$native_3g_prop_mean,
             params_stochastic$devices$call$native_band_props$native_4g_prop_mean,
             params_stochastic$devices$call$native_band_props$native_5g_prop_mean,
             params_stochastic$devices$call$native_band_props$native_6g_prop_mean),
    a0 = params_stochastic$device$call$native_band_props$native_prop_a0
  )
  params$devices$call$native_band_props$native_2g_prop <- native_prop[1]
  params$devices$call$native_band_props$native_3g_prop <- native_prop[2]
  params$devices$call$native_band_props$native_4g_prop <- native_prop[3]
  params$devices$call$native_band_props$native_5g_prop <- native_prop[4]
  params$devices$call$native_band_props$native_6g_prop <- native_prop[5]

  # pick data_band_props, data_band_no5g_props
  if (use_5g){
    data_prop <- evaluate_distribution(
      dist_name = params_stochastic$devices$call$data_band_props$distribution,
      mean = c(params_stochastic$devices$call$data_band_props$data_2g_prop_mean,
               params_stochastic$devices$call$data_band_props$data_3g_prop_mean,
               params_stochastic$devices$call$data_band_props$data_4g_prop_mean,
               params_stochastic$devices$call$data_band_props$data_5g_prop_mean,
               params_stochastic$devices$call$data_band_props$data_6g_prop_mean),
      a0 = params_stochastic$device$call$data_band_props$data_prop_a0
    )
    params$devices$call$data_band_props$data_2g_prop <- data_prop[1]
    params$devices$call$data_band_props$data_3g_prop <- data_prop[2]
    params$devices$call$data_band_props$data_4g_prop <- data_prop[3]
    params$devices$call$data_band_props$data_5g_prop <- data_prop[4]
    params$devices$call$data_band_props$data_6g_prop <- data_prop[5]
  } else {
    data_prop <- evaluate_distribution(
      dist_name = params_stochastic$devices$call$data_band_no5g_props$distribution,
      mean = c(params_stochastic$devices$call$data_band_no5g_props$data_2g_prop_no5g_mean,
               params_stochastic$devices$call$data_band_no5g_props$data_3g_prop_no5g_mean,
               params_stochastic$devices$call$data_band_no5g_props$data_4g_prop_no5g_mean,
               params_stochastic$devices$call$data_band_no5g_props$data_5g_prop_no5g_mean,
               params_stochastic$devices$call$data_band_no5g_props$data_6g_prop_no5g_mean),
      a0 = params_stochastic$device$call$data_band_no5g_props$data_prop_no5g_a0
    )
    params$devices$call$data_band_no5g_props$data_2g_prop_no5g <- data_prop[1]
    params$devices$call$data_band_no5g_props$data_3g_prop_no5g <- data_prop[2]
    params$devices$call$data_band_no5g_props$data_4g_prop_no5g <- data_prop[3]
    params$devices$call$data_band_no5g_props$data_5g_prop_no5g <- data_prop[4]
    params$devices$call$data_band_no5g_props$data_6g_prop_no5g <- data_prop[5]
  }

  # pick 2g_freq_props__________________________________________________________
  prop_2g <- evaluate_distribution(
    dist_name = params_stochastic$devices$call[["2g_freq_props"]]$distribution,
    mean = c(params_stochastic$devices$call[["2g_freq_props"]]$f900_2g_prop_mean,
             params_stochastic$devices$call[["2g_freq_props"]]$f1800_2g_prop_mean),
    a0 = params_stochastic$device$call[["2g_freq_props"]]$prop_2g_a0
  )
  params$devices$call[["2g_freq_props"]]$f900_2g_prop <-  prop_2g[1]
  params$devices$call[["2g_freq_props"]]$f1800_2g_prop <-  prop_2g[2]

  # pick 3g_freq_props
  prop_3g <- evaluate_distribution(
    dist_name = params_stochastic$devices$call[["3g_freq_props"]]$distribution,
    mean = c(params_stochastic$devices$call[["3g_freq_props"]]$f900_3g_prop_mean,
             params_stochastic$devices$call[["3g_freq_props"]]$f2100_3g_prop_mean),
    a0 = params_stochastic$device$call[["3g_freq_props"]]$prop_3g_a0
  )
  params$devices$call[["3g_freq_props"]]$f900_3g_prop <-  prop_3g[1]
  params$devices$call[["3g_freq_props"]]$f2100_3g_prop <-  prop_3g[2]

  # pick 4g_freq_props
  prop_4g <- evaluate_distribution(
    dist_name = params_stochastic$devices$call[["4g_freq_props"]]$distribution,
    mean = c(params_stochastic$devices$call[["4g_freq_props"]]$f700_4g_prop_mean,
             params_stochastic$devices$call[["4g_freq_props"]]$f800_4g_prop_mean,
             params_stochastic$devices$call[["4g_freq_props"]]$f900_4g_prop_mean,
             params_stochastic$devices$call[["4g_freq_props"]]$f1450_4g_prop_mean,
             params_stochastic$devices$call[["4g_freq_props"]]$f1800_4g_prop_mean,
             params_stochastic$devices$call[["4g_freq_props"]]$f2100_4g_prop_mean,
             params_stochastic$devices$call[["4g_freq_props"]]$f2600_4g_prop_mean),
    a0 = params_stochastic$device$call[["4g_freq_props"]]$prop_4g_a0
  )
  params$devices$call[["4g_freq_props"]]$f700_4g_prop <-  prop_4g[1]
  params$devices$call[["4g_freq_props"]]$f800_4g_prop <-  prop_4g[2]
  params$devices$call[["4g_freq_props"]]$f900_4g_prop <-  prop_4g[3]
  params$devices$call[["4g_freq_props"]]$f1450_4g_prop <-  prop_4g[4]
  params$devices$call[["4g_freq_props"]]$f1800_4g_prop <-  prop_4g[5]
  params$devices$call[["4g_freq_props"]]$f2100_4g_prop <-  prop_4g[6]
  params$devices$call[["4g_freq_props"]]$f2600_4g_prop <-  prop_4g[7]

  # pick 5g_freq_props
  prop_5g <- evaluate_distribution(
    dist_name = params_stochastic$devices$call[["5g_freq_props"]]$distribution,
    mean = c(params_stochastic$devices$call[["5g_freq_props"]]$f3500_5g_prop_mean,
             params_stochastic$devices$call[["5g_freq_props"]]$fxxxx_5g_prop_mean),
    a0 = params_stochastic$device$call[["5g_freq_props"]]$prop_5g_a0
  )
  params$devices$call[["5g_freq_props"]]$f3500_5g_prop <-  prop_5g[1]
  params$devices$call[["5g_freq_props"]]$fxxxx_5g_prop <-  prop_5g[2]

  # pick 6g_freq_props
  prop_6g <- evaluate_distribution(
    dist_name = params_stochastic$devices$call[["6g_freq_props"]]$distribution,
    mean = c(params_stochastic$devices$call[["6g_freq_props"]]$fyyyy_6g_prop_mean,
             params_stochastic$devices$call[["6g_freq_props"]]$fzzzz_6g_prop_mean),
    a0 = params_stochastic$device$call[["6g_freq_props"]]$prop_6g_a0
  )
  params$devices$call[["6g_freq_props"]]$fyyyy_6g_prop <-  prop_6g[1]
  params$devices$call[["6g_freq_props"]]$fzzzz_6g_prop <-  prop_6g[2]

  # pick phone_positions________________________________________________________
  ## ear
  ear_p <- evaluate_distribution(
    dist_name = params_stochastic$devices$call$phone_positions$distribution,
    mean = c(params_stochastic$devices$call$phone_positions$cheek1_prop_mean,
             params_stochastic$devices$call$phone_positions$cheek2_prop_mean,
             params_stochastic$devices$call$phone_positions$cheek3_prop_mean,
             params_stochastic$devices$call$phone_positions$tilt1_prop_mean,
             params_stochastic$devices$call$phone_positions$tilt2_prop_mean,
             params_stochastic$devices$call$phone_positions$tilt3_prop_mean),
    a0 = params_stochastic$device$call$phone_positions$ear_prop_a0
  )
  params$devices$call$phone_positions$cheek1_prop <-  ear_p[1]
  params$devices$call$phone_positions$cheek2_prop <-  ear_p[2]
  params$devices$call$phone_positions$cheek3_prop <-  ear_p[3]
  params$devices$call$phone_positions$tilt1_prop <-  ear_p[4]
  params$devices$call$phone_positions$tilt2_prop <-  ear_p[5]
  params$devices$call$phone_positions$tilt3_prop <-  ear_p[6]

  ## front eyes
  front_eyes_p <- evaluate_distribution(
    dist_name = params_stochastic$devices$call$phone_positions$distribution,
    mean = c(params_stochastic$devices$call$phone_positions$front_of_eyes_center_vertical_prop_mean,
             params_stochastic$devices$call$phone_positions$front_of_eyes_center_horizontal_prop_mean,
             params_stochastic$devices$call$phone_positions$front_of_eyes_left_vertical_prop_mean,
             params_stochastic$devices$call$phone_positions$front_of_eyes_left_horizontal_prop_mean,
             params_stochastic$devices$call$phone_positions$front_of_eyes_right_vertical_prop_mean,
             params_stochastic$devices$call$phone_positions$front_of_eyes_right_horizontal_prop_mean,
             params_stochastic$devices$call$phone_positions$front_of_eyes_down_vertical_prop_mean,
             params_stochastic$devices$call$phone_positions$front_of_eyes_down_horizontal_prop_mean),
    a0 = params_stochastic$device$call$phone_positions$front_of_eyes_prop_a0
  )
  params$devices$call$phone_positions$front_of_eyes_center_vertical_prop <-  front_eyes_p[1]
  params$devices$call$phone_positions$front_of_eyes_center_horizontal_prop <-  front_eyes_p[2]
  params$devices$call$phone_positions$front_of_eyes_left_vertical_prop <-  front_eyes_p[3]
  params$devices$call$phone_positions$front_of_eyes_left_horizontal_prop <-  front_eyes_p[4]
  params$devices$call$phone_positions$front_of_eyes_right_vertical_prop <-  front_eyes_p[5]
  params$devices$call$phone_positions$front_of_eyes_right_horizontal_prop <-  front_eyes_p[6]
  params$devices$call$phone_positions$front_of_eyes_down_vertical_prop <-  front_eyes_p[7]
  params$devices$call$phone_positions$front_of_eyes_down_horizontal_prop <-  front_eyes_p[8]
  ## belly
  belly_p <- evaluate_distribution(
    dist_name = params_stochastic$devices$call$phone_positions$distribution,
    mean = c(params_stochastic$devices$call$phone_positions$belly_center_vertical_prop_mean,
             params_stochastic$devices$call$phone_positions$belly_center_horizontal_prop_mean,
             params_stochastic$devices$call$phone_positions$belly_left_vertical_prop_mean,
             params_stochastic$devices$call$phone_positions$belly_left_horizontal_prop_mean,
             params_stochastic$devices$call$phone_positions$belly_right_vertical_prop_mean,
             params_stochastic$devices$call$phone_positions$belly_right_horizontal_prop_mean,
             params_stochastic$devices$call$phone_positions$belly_up_vertical_prop_mean,
             params_stochastic$devices$call$phone_positions$belly_up_horizontal_prop_mean),
    a0 = params_stochastic$device$call$phone_positions$belly_prop_a0
  )
  params$devices$call$phone_positions$belly_center_vertical_prop <-  belly_p[1]
  params$devices$call$phone_positions$belly_center_horizontal_prop <-  belly_p[2]
  params$devices$call$phone_positions$belly_left_vertical_prop <-  belly_p[3]
  params$devices$call$phone_positions$belly_left_horizontal_prop <-  belly_p[4]
  params$devices$call$phone_positions$belly_right_vertical_prop <-  belly_p[5]
  params$devices$call$phone_positions$belly_right_horizontal_prop <-  belly_p[6]
  params$devices$call$phone_positions$belly_up_vertical_prop <-  belly_p[7]
  params$devices$call$phone_positions$belly_up_horizontal_prop <-  belly_p[8]


  # pick native_dutycycle_______________________________________________________
  ## dutycycle 2g
  params$devices$call$native_dutycycle$native_2g_dutycycle <- evaluate_distribution(
    dist_name = params_stochastic$devices$call$native_dutycycle$distribution,
    mean = c(params_stochastic$devices$call$native_dutycycle$native_2g_dutycycle_mean,
             1-params_stochastic$devices$call$native_dutycycle$native_2g_dutycycle_mean),
    a0 = params_stochastic$devices$call$native_dutycycle$native_2g_dutycycle_a0)[1]
  ## dutycycle 3g
  params$devices$call$native_dutycycle$native_3g_dutycycle <- evaluate_distribution(
    dist_name = params_stochastic$devices$call$native_dutycycle$distribution,
    mean = c(params_stochastic$devices$call$native_dutycycle$native_3g_dutycycle_mean,
             1-params_stochastic$devices$call$native_dutycycle$native_3g_dutycycle_mean),
    a0 = params_stochastic$devices$call$native_dutycycle$native_3g_dutycycle_a0)[1]
  ## dutycycle 4g
  params$devices$call$native_dutycycle$native_4g_dutycycle <- evaluate_distribution(
    dist_name = params_stochastic$devices$call$native_dutycycle$distribution,
    mean = c(params_stochastic$devices$call$native_dutycycle$native_4g_dutycycle_mean,
             1-params_stochastic$devices$call$native_dutycycle$native_4g_dutycycle_mean),
    a0 = params_stochastic$devices$call$native_dutycycle$native_4g_dutycycle_a0)[1]
  ## dutycycle 5g
  params$devices$call$native_dutycycle$native_5g_dutycycle <- evaluate_distribution(
    dist_name = params_stochastic$devices$call$native_dutycycle$distribution,
    mean = c(params_stochastic$devices$call$native_dutycycle$native_5g_dutycycle_mean,
             1-params_stochastic$devices$call$native_dutycycle$native_5g_dutycycle_mean),
    a0 = params_stochastic$devices$call$native_dutycycle$native_5g_dutycycle_a0)[1]
  ## dutycycle 6g
  params$devices$call$native_dutycycle$native_6g_dutycycle <- evaluate_distribution(
    dist_name = params_stochastic$devices$call$native_dutycycle$distribution,
    mean = c(params_stochastic$devices$call$native_dutycycle$native_6g_dutycycle_mean,
             1-params_stochastic$devices$call$native_dutycycle$native_6g_dutycycle_mean),
    a0 = params_stochastic$devices$call$native_dutycycle$native_6g_dutycycle_a0)[1]
  # pick data_dutycycle
  ## dutycycle 2g
  params$devices$call$data_dutycycle$data_2g_dutycycle <- evaluate_distribution(
    dist_name = params_stochastic$devices$call$data_dutycycle$distribution,
    mean = c(params_stochastic$devices$call$data_dutycycle$data_2g_dutycycle_mean,
             1-params_stochastic$devices$call$data_dutycycle$data_2g_dutycycle_mean),
    a0 = params_stochastic$devices$call$data_dutycycle$data_2g_dutycycle_a0)[1]
  ## dutycycle 3g
  params$devices$call$data_dutycycle$data_3g_dutycycle <- evaluate_distribution(
    dist_name = params_stochastic$devices$call$data_dutycycle$distribution,
    mean = c(params_stochastic$devices$call$data_dutycycle$data_3g_dutycycle_mean,
             1-params_stochastic$devices$call$data_dutycycle$data_3g_dutycycle_mean),
    a0 = params_stochastic$devices$call$data_dutycycle$data_3g_dutycycle_a0)[1]
  ## dutycycle 4g
  params$devices$call$data_dutycycle$data_4g_dutycycle <- evaluate_distribution(
    dist_name = params_stochastic$devices$call$data_dutycycle$distribution,
    mean = c(params_stochastic$devices$call$data_dutycycle$data_4g_dutycycle_mean,
             1-params_stochastic$devices$call$data_dutycycle$data_4g_dutycycle_mean),
    a0 = params_stochastic$devices$call$data_dutycycle$data_4g_dutycycle_a0)[1]
  ## dutycycle 5g
  params$devices$call$data_dutycycle$data_5g_dutycycle <- evaluate_distribution(
    dist_name = params_stochastic$devices$call$data_dutycycle$distribution,
    mean = c(params_stochastic$devices$call$data_dutycycle$data_5g_dutycycle_mean,
             1-params_stochastic$devices$call$data_dutycycle$data_5g_dutycycle_mean),
    a0 = params_stochastic$devices$call$data_dutycycle$data_5g_dutycycle_a0)[1]
  ## dutycycle 6g
  params$devices$call$data_dutycycle$data_6g_dutycycle <- evaluate_distribution(
    dist_name = params_stochastic$devices$call$data_dutycycle$distribution,
    mean = c(params_stochastic$devices$call$data_dutycycle$data_6g_dutycycle_mean,
             1-params_stochastic$devices$call$data_dutycycle$data_6g_dutycycle_mean),
    a0 = params_stochastic$devices$call$data_dutycycle$data_6g_dutycycle_a0)[1]

  # pick wifi_dutycycle
  ## wifi_2_dutycycle
  params$devices$call$wifi_dutycycle$wifi_2400_dutycycle <- evaluate_distribution(
    dist_name = params_stochastic$devices$call$wifi_dutycycle$distribution,
    mean = c(params_stochastic$devices$call$wifi_dutycycle$wifi_2_dutycycle_mean,
             1-params_stochastic$devices$call$wifi_dutycycle$wifi_2_dutycycle_mean),
    a0 = params_stochastic$devices$call$wifi_dutycycle$wifi_2_dutycycle_a0)[1]
  ## wifi_5_dutycycle
  params$devices$call$wifi_dutycycle$wifi_5000_dutycycle <- evaluate_distribution(
    dist_name = params_stochastic$devices$call$wifi_dutycycle$distribution,
    mean = c(params_stochastic$devices$call$wifi_dutycycle$wifi_5_dutycycle_mean,
             1-params_stochastic$devices$call$wifi_dutycycle$wifi_5_dutycycle_mean),
    a0 = params_stochastic$devices$call$wifi_dutycycle$wifi_5_dutycycle_a0)[1]

  # pick native_pwr_____________________________________________________________
  power_vars <- c(
    "native_2g_sub_ind_pwr",
    "native_2g_urb_ind_pwr",
    "native_2g_rur_ind_pwr",
    "native_2g_sub_out_pwr",
    "native_2g_urb_out_pwr",
    "native_2g_rur_out_pwr",
    "native_2g_travel_pwr",
    "native_3g_sub_ind_pwr",
    "native_3g_urb_ind_pwr",
    "native_3g_rur_ind_pwr",
    "native_3g_sub_out_pwr",
    "native_3g_urb_out_pwr",
    "native_3g_rur_out_pwr",
    "native_3g_travel_pwr",
    "native_4g_sub_ind_pwr",
    "native_4g_urb_ind_pwr",
    "native_4g_rur_ind_pwr",
    "native_4g_sub_out_pwr",
    "native_4g_urb_out_pwr",
    "native_4g_rur_out_pwr",
    "native_4g_travel_pwr",
    "native_5g_sub_ind_pwr",
    "native_5g_urb_ind_pwr",
    "native_5g_rur_ind_pwr",
    "native_5g_sub_out_pwr",
    "native_5g_urb_out_pwr",
    "native_5g_rur_out_pwr",
    "native_5g_travel_pwr",
    "native_6g_sub_ind_pwr",
    "native_6g_urb_ind_pwr",
    "native_6g_rur_ind_pwr",
    "native_6g_sub_out_pwr",
    "native_6g_urb_out_pwr",
    "native_6g_rur_out_pwr",
    "native_6g_travel_pwr"
  )

  for (nm in power_vars) {
    mean <- params_stochastic$devices$call$native_pwr[[paste0(nm, "_mean")]]
    if (mean >0){
      params$devices$call$native_pwr[[nm]] <- evaluate_distribution(
        dist_name = params_stochastic$devices$call$native_pwr$distribution,
        mean = params_stochastic$devices$call$native_pwr[[paste0(nm, "_mean")]],
        sd   = params_stochastic$devices$call$native_pwr[[paste0(nm, "_sd")]],
        max  = params_stochastic$devices$call$native_pwr[[paste0(nm, "_max")]]
      )
    }
  }
  # pick data_pwr
  power_vars <- c(
    "data_2g_sub_ind_pwr",
    "data_2g_urb_ind_pwr",
    "data_2g_rur_ind_pwr",
    "data_2g_sub_out_pwr",
    "data_2g_urb_out_pwr",
    "data_2g_rur_out_pwr",
    "data_2g_travel_pwr",
    "data_3g_sub_ind_pwr",
    "data_3g_urb_ind_pwr",
    "data_3g_rur_ind_pwr",
    "data_3g_sub_out_pwr",
    "data_3g_urb_out_pwr",
    "data_3g_rur_out_pwr",
    "data_3g_travel_pwr",
    "data_4g_sub_ind_pwr",
    "data_4g_urb_ind_pwr",
    "data_4g_rur_ind_pwr",
    "data_4g_sub_out_pwr",
    "data_4g_urb_out_pwr",
    "data_4g_rur_out_pwr",
    "data_4g_travel_pwr",
    "data_5g_sub_ind_pwr",
    "data_5g_urb_ind_pwr",
    "data_5g_rur_ind_pwr",
    "data_5g_sub_out_pwr",
    "data_5g_urb_out_pwr",
    "data_5g_rur_out_pwr",
    "data_5g_travel_pwr",
    "data_6g_sub_ind_pwr",
    "data_6g_urb_ind_pwr",
    "data_6g_rur_ind_pwr",
    "data_6g_sub_out_pwr",
    "data_6g_urb_out_pwr",
    "data_6g_rur_out_pwr",
    "data_6g_travel_pwr",
    "wifi_2400_pwr",
    "wifi_5000_pwr",
    "bt_pwr"
  )
  for (nm in power_vars) {
    mean <- params_stochastic$devices$call$data_pwr[[paste0(nm, "_mean")]]
    if (mean > 0){
      params$devices$call$data_pwr[[nm]] <- evaluate_distribution(
        dist_name = params_stochastic$devices$call$data_pwr$distribution,
        mean = mean,
        sd   = params_stochastic$devices$call$data_pwr[[paste0(nm, "_sd")]],
        max  = params_stochastic$devices$call$data_pwr[[paste0(nm, "_max")]]
      )
    }
  }
  # pick position_props
  pos_prop <- evaluate_distribution(
    dist_name = params_stochastic$devices$call$position_props$distribution,
    mean = c(params_stochastic$devices$call$position_props$headp_face_prop_mean,
             params_stochastic$devices$call$position_props$headp_pock_prop_mean,
             params_stochastic$devices$call$position_props$headp_else_prop_mean),
    a0 = params_stochastic$device$call$position_props$position_prop_a0
  )
  params$devices$call$position_props$headp_face_prop <-  pos_prop[1]
  params$devices$call$position_props$headp_pock_prop <-  pos_prop[2]
  params$devices$call$position_props$headp_else_prop <-  pos_prop[3]

  # pick mpc_distance

  params$devices$call$mpc_distance$mpc_dist_ear <- evaluate_distribution(
    dist_name = params_stochastic$devices$call$mpc_distance$distribution,
    mean = params_stochastic$devices$call$mpc_distance$mpc_dist_ear_mean,
    sd   = params_stochastic$devices$call$mpc_distance$mpc_dist_ear_sd,
    min = params_stochastic$devices$call$mpc_distance$mpc_dist_ear_min,
    max  = params_stochastic$devices$call$mpc_distance$mpc_dist_ear_max
  )

  params$devices$call$mpc_distance$mpc_dist_speaker <- evaluate_distribution(
    dist_name = params_stochastic$devices$call$mpc_distance$distribution,
    mean = params_stochastic$devices$call$mpc_distance$mpc_dist_speaker_mean,
    sd   = params_stochastic$devices$call$mpc_distance$mpc_dist_speaker_sd,
    min = params_stochastic$devices$call$mpc_distance$mpc_dist_speaker_min,
    max  = params_stochastic$devices$call$mpc_distance$mpc_dist_speaker_max
  )

  ####### mobile call

  # pick dutycicle
  dutycycle_vars <- c(
    "data_3g_low_dutycycle",
    "data_3g_lowmed_dutycycle",
    "data_3g_medhigh_dutycycle",
    "data_3g_high_dutycycle",
    "data_4g_low_dutycycle",
    "data_4g_lowmed_dutycycle",
    "data_4g_medhigh_dutycycle",
    "data_4g_high_dutycycle",
    "data_5g_low_dutycycle",
    "data_5g_lowmed_dutycycle",
    "data_5g_medhigh_dutycycle",
    "data_5g_high_dutycycle",
    "data_6g_low_dutycycle",
    "data_6g_lowmed_dutycycle",
    "data_6g_medhigh_dutycycle",
    "data_6g_high_dutycycle",
    "wifi_2400_low_dutycycle",
    "wifi_2400_lowmed_dutycycle",
    "wifi_2400_medhigh_dutycycle",
    "wifi_2400_high_dutycycle",
    "wifi_5000_low_dutycycle",
    "wifi_5000_lowmed_dutycycle",
    "wifi_5000_medhigh_dutycycle",
    "wifi_5000_high_dutycycle")

  for (dc in dutycycle_vars){
    params$devices$data$dutycycle[[dc]] <- evaluate_distribution(
      dist_name = params_stochastic$devices$data$dutycycle$distribution,
      mean = c(params_stochastic$devices$data$dutycycle[[paste0(dc,"_mean")]],
               1-params_stochastic$devices$data$dutycycle[[paste0(dc,"_mean")]]),
      a0 = params_stochastic$devices$data$dutycycle[[paste0(dc,"_a0")]])[1]
  }

  # pick pwr
  power_vars <- c(
    "data_3g_sub_ind_pwr",
    "data_3g_urb_ind_pwr",
    "data_3g_rur_ind_pwr",
    "data_3g_sub_out_pwr",
    "data_3g_urb_out_pwr",
    "data_3g_rur_out_pwr",
    "data_3g_travel_pwr",
    "data_4g_sub_ind_pwr",
    "data_4g_urb_ind_pwr",
    "data_4g_rur_ind_pwr",
    "data_4g_sub_out_pwr",
    "data_4g_urb_out_pwr",
    "data_4g_rur_out_pwr",
    "data_4g_travel_pwr",
    "data_5g_sub_ind_pwr",
    "data_5g_urb_ind_pwr",
    "data_5g_rur_ind_pwr",
    "data_5g_sub_out_pwr",
    "data_5g_urb_out_pwr",
    "data_5g_rur_out_pwr",
    "data_5g_travel_pwr",
    "data_6g_sub_ind_pwr",
    "data_6g_urb_ind_pwr",
    "data_6g_rur_ind_pwr",
    "data_6g_sub_out_pwr",
    "data_6g_urb_out_pwr",
    "data_6g_rur_out_pwr",
    "data_6g_travel_pwr",
    "wifi_2400_pwr",
    "wifi_5000_pwr")
  for (pw in power_vars){
    params$devices$data$pwr[[pw]] <- evaluate_distribution(
      dist_name = params_stochastic$devices$data$pwr$distribution,
      mean = params_stochastic$devices$data$pwr[[paste0(pw, "_mean")]],
      sd   = params_stochastic$devices$data$pwr[[paste0(pw, "_sd")]],
      max  = params_stochastic$devices$data$pwr[[paste0(pw, "_max")]]
    )
  }

  # pick mpd_distance
  params$devices$data$mpd_distance$mpd_dist_belly <- evaluate_distribution(
    dist_name = params_stochastic$devices$data$mpd_distance$distribution,
    mean = params_stochastic$devices$data$mpd_distance$mpd_dist_belly_mean,
    sd   = params_stochastic$devices$data$mpd_distance$mpd_dist_belly_sd,
    min = params_stochastic$devices$data$mpd_distance$mpd_dist_belly_min,
    max  = params_stochastic$devices$data$mpd_distance$mpd_dist_belly_max
  )

  ####### cordless

  # pick pwr
  params$devices$dect$pwr$dect_pwr <- evaluate_distribution(
    dist_name = params_stochastic$devices$dect$pwr$distribution,
    mean = params_stochastic$devices$dect$pwr$dect_pwr_mean,
    sd   = params_stochastic$devices$dect$pwr$dect_pwr_sd,
    max  = params_stochastic$devices$dect$pwr$dect_pwr_max
  )


  # pick dc (dutycycle)
  params$devices$dect$dutycycle$dect_dutycycle <- evaluate_distribution(
    dist_name = params_stochastic$devices$dect$dutycycle$distribution,
    mean = c(params_stochastic$devices$dect$dutycycle$dect_dutycycle_mean,
             1-params_stochastic$devices$dect$dutycycle$dect_dutycycle_mean),
    a0 = params_stochastic$devices$dect$dutycycle$dect_dutycycle_a0)[1]



  # pick distance
  params$devices$dect$dect_distance$dect_distance_ear <- evaluate_distribution(
    dist_name = params_stochastic$devices$dect$dect_distance$distribution,
    mean = params_stochastic$devices$dect$dect_distance$dect_distance_ear_mean,
    sd   = params_stochastic$devices$dect$dect_distance$dect_distance_ear_sd,
    min = params_stochastic$devices$dect$dect_distance$dect_distance_ear_min,
    max  = params_stochastic$devices$dect$dect_distance$dect_distance_ear_max
  )

  params$devices$dect$dect_distance$dect_distance_speaker <- evaluate_distribution(
    dist_name = params_stochastic$devices$dect$dect_distance$distribution,
    mean = params_stochastic$devices$dect$dect_distance$dect_distance_speaker_mean,
    sd   = params_stochastic$devices$dect$dect_distance$dect_distance_speaker_sd,
    min = params_stochastic$devices$dect$dect_distance$dect_distance_speaker_min,
    max  = params_stochastic$devices$dect$dect_distance$dect_distance_speaker_max
  )


  ####### gaming

  # pick online_prop (proportion of gaming time the device actually transmits)
  params$devices$gaming$online_prop$gaming_online_prop <- evaluate_distribution(
    dist_name = params_stochastic$devices$gaming$online_prop$distribution,
    mean = c(params_stochastic$devices$gaming$online_prop$gaming_online_prop_mean,
             1-params_stochastic$devices$gaming$online_prop$gaming_online_prop_mean),
    a0 = params_stochastic$devices$gaming$online_prop$gaming_online_prop_a0)[1]

  # pick pwr
  gaming_freqs <- c("2400", "5000") # 2.4 GHz and 5.0 GHz
  for (freq in gaming_freqs) {
    params$devices$gaming$pwr[[paste0("gaming_", freq, "_pwr")]] <- evaluate_distribution(
      dist_name = params_stochastic$devices$gaming$pwr$distribution,
      mean = params_stochastic$devices$gaming$pwr[[paste0("gaming_", freq, "_pwr_mean")]],
      sd   = params_stochastic$devices$gaming$pwr[[paste0("gaming_", freq, "_pwr_sd")]],
      min  = params_stochastic$devices$gaming$pwr[[paste0("gaming_", freq, "_pwr_min")]],
      max  = params_stochastic$devices$gaming$pwr[[paste0("gaming_", freq, "_pwr_max")]]
    )
  }

  # pick dc (dutycycle)
  for (freq in gaming_freqs) {
    dc_mean <- params_stochastic$devices$gaming$dutycycle[[paste0("gaming_", freq, "_dutycycle_mean")]]
    params$devices$gaming$dutycycle[[paste0("gaming_", freq, "_dutycycle")]] <- evaluate_distribution(
      dist_name = params_stochastic$devices$gaming$dutycycle$distribution,
      mean = c(dc_mean, 1-dc_mean),
      a0 = params_stochastic$devices$gaming$dutycycle$gaming_dutycycle_a0)[1]
  }

  # pick distance (pc to body, in mm)
  params$devices$gaming$gaming_distance$gaming_dist_pc <- evaluate_distribution(
    dist_name = params_stochastic$devices$gaming$gaming_distance$distribution,
    mean = params_stochastic$devices$gaming$gaming_distance$gaming_dist_pc_mean,
    sd   = params_stochastic$devices$gaming$gaming_distance$gaming_dist_pc_sd,
    min = params_stochastic$devices$gaming$gaming_distance$gaming_dist_pc_min,
    max  = params_stochastic$devices$gaming$gaming_distance$gaming_dist_pc_max
  )




  return(params)
}




#' Draw a random value from a specified distribution
#'
#' Draws a single random value from one of the supported probability
#' distributions.
#'
#' @param dist_name Character string specifying the distribution.
#'   Supported values are `"trunc_norm"`, `"gamma"`, `"trunc_gamma"`,
#'   `"trunc_hurdle_gamma"` and `"dirichlet"`.
#' @param mean Mean of the distribution. For `"dirichlet"`, a numeric vector of
#'   mean proportions summing to 1.
#' @param sd Standard deviation of the distribution (not used for
#'   `"dirichlet"`).
#' @param p_zero Probability of drawing zero for `"trunc_hurdle_gamma"`.
#' @param min Lower truncation bound (only used for `"trunc_norm"`).
#' @param max Upper truncation bound (used for truncated distributions).
#' @param a0 Concentration parameter of the Dirichlet distribution.
#'
#' @return A single random draw from the selected distribution.
#' @export
evaluate_distribution <- function(dist_name,
                                  mean,
                                  sd,
                                  p_zero,
                                  min = 0,
                                  max = NULL,
                                  a0,
                                  p_categorie1,
                                  categorie1,
                                  categorie2) {

  if (dist_name == "trunc_norm") {

    if (is.null(min) || is.null(max)) {
      stop("'min' and 'max' must be provided for a truncated normal distribution.")
    }

    return(
      r_truncnorm(
        mean = mean,
        sd = sd,
        min = min,
        max = max
      )
    )

  } else if (dist_name == "gamma") {

    return(
      r_gamma(
        mean = mean,
        sd = sd
      )
    )
  } else if (dist_name == "trunc_gamma"){
    return(
      r_trunc_gamma(
        mean = mean,
        sd = sd,
        min = min,
        max = max
      )
    )

  } else if (dist_name == "trunc_hurdle_gamma"){
    return(
      r_trunc_hurdle_gamma(
        mean = mean,
        sd = sd,
        p_zero = p_zero,
        min = min,
        max = max
      )
    )

  } else if (dist_name == "dirichlet"){
    return(
      r_dirichlet(mean,a0)
    )

  } else if (dist_name == "beta"){
    # The beta distr. is a special case of the Dirichlet distr. with two props.
    if (length(mean) != 2) stop("Input needs to be 2 values!")
    return(
      r_dirichlet(mean,a0)
      )

  } else if (dist_name == "bernoulli"){
    return(
      r_bernoulli(p_categorie1= p_categorie1,categorie1=categorie1 ,categorie2 =categorie2 )
    )

  } else if (dist_name == "trunc_lognormal"){
      if (mean == 0){return(0)}
      else{return(r_trunc_lognormal(mean, sd, min = min, max = max))}

  } else {

    stop("Unsupported distribution. Choose 'truncnorm' or 'gamma'.")

  }
}

#' Draw a random value from a truncated normal distribution
#'
#' Draws a single random value from a normal distribution truncated to a
#' specified range.
#'
#' @param mean Mean of the underlying normal distribution.
#' @param sd Standard deviation of the underlying normal distribution.
#' @param min Lower truncation bound.
#' @param max Upper truncation bound.
#'
#' @return A single random draw from the truncated normal distribution.
#' @export
r_truncnorm <- function(mean, sd, min, max) {
  if (sd <= 0) {
    stop("sd must be greater than 0.")
  }

  if (min >= max) {
    stop("min must be smaller than max.")
  }

  truncnorm::rtruncnorm(
    n = 1,
    a = min,
    b = max,
    mean = mean,
    sd = sd
  )
}


#' Draw a random value from a Gamma distribution
#'
#' Draws a single random value from a Gamma distribution parameterized by its
#' mean and standard deviation.
#'
#' @param mean Mean of the Gamma distribution.
#' @param sd Standard deviation of the Gamma distribution.
#'
#' @return A single random draw from the Gamma distribution.
#' @export
r_gamma <- function(mean, sd) {
  if (mean <= 0) stop("mean must be greater than 0.")
  if (sd <= 0) stop("sd must be greater than 0.")

  shape <- (mean / sd)^2
  scale <- sd^2 / mean

  rgamma(
    n = 1,
    shape = shape,
    scale = scale
  )
}

#' Draw a random value from a truncated Gamma distribution
#'
#' Draws a single random value from a Gamma distribution truncated at an upper
#' bound.
#'
#' @param mean Mean of the underlying Gamma distribution.
#' @param sd Standard deviation of the underlying Gamma distribution.
#' @param max Upper truncation bound.
#'
#' @return A single random draw from the truncated Gamma distribution.
#' @export
r_trunc_gamma <- function(mean, sd, min = 0, max = Inf) {
  if (mean <= 0) stop("mean must be greater than 0.")
  if (sd <= 0) stop("sd must be greater than 0.")
  if (min < 0) stop("min must be non-negative.")
  if (min >= max) stop("min must be smaller than max.")

  shape <- (mean / sd)^2
  scale <- sd^2 / mean

  p_min <- pgamma(min, shape = shape, scale = scale  )
  p_max <- pgamma(max, shape = shape, scale = scale)

  u <- runif(1, p_min, p_max)

  qgamma(u, shape = shape, scale = scale)
}

#' Draw a random value from a truncated hurdle Gamma distribution
#'
#' Draws either zero with probability `p_zero` or a value from an upper
#' truncated Gamma distribution.
#'
#' @param mean Mean of the underlying Gamma distribution (not equivalent to the mean of
#' the final hurdle distribution because of the introduction of additional zeros there).
#' -> the mean characterizes the typical behaviour where the values are not set to zero.
#' @param sd Standard deviation of the underlying Gamma distribution.
#' @param p_zero Probability of returning zero.
#' @param max Upper truncation bound.
#'
#' @return A single random draw from the truncated hurdle Gamma distribution.
#' @export
r_trunc_hurdle_gamma <- function(mean, sd, p_zero, min = 0, max = Inf) {
  if (mean <= 0) stop("mean must be greater than 0.")
  if (sd <= 0) stop("sd must be greater than 0.")

  is_positive <- rbinom(1, size = 1, prob = 1 - p_zero)

  if (!is_positive) {
    return(0)
  }

  r_trunc_gamma(mean, sd, min, max)
}



#' Draws a single vector of proportions from a Dirichlet distribution.
#'
#' @param mean Numeric vector of mean proportions. Values must be non-negative
#'   and sum to 1.
#' @param a0 Positive concentration parameter controlling the variability around
#'   the mean proportions.
#'
#' @return A numeric vector of proportions summing to 1.
#' @export
r_dirichlet <- function(mean, a0 = 100) {
  if (any(mean < 0)) stop("All mean values must be non-negative.")
  if (length(mean) < 2) stop("Needs at least 2 mean values.")
  if (!isTRUE(all.equal(sum(mean), 1, tolerance = 1e-8))) stop("The mean proportions must sum to 1.")
  if (a0 <= 0) stop("concentration must be greater than 0.")

  alpha <- a0 * mean
  as.numeric(MCMCpack::rdirichlet(1, alpha))
}





#' Draws either `categorie1` or `categorie2` according to a Bernoulli distribution.
#'
#' @param p_categorie1 Probability of drawing `categorie2`. Must be between 0 and 1.
#' @categorie1 should be a character
#' @categorie2 should be a character
#' @return A character string, either `categorie1` or `categorie2`.
#' @export
r_bernoulli <- function(p_categorie1,categorie1,categorie2) {

  if (p_categorie1 < 0 || p_categorie1 > 1) {
    stop("p_categorie1 must be between 0 and 1.")
  }

  if (rbinom(1, size = 1, prob = p_categorie1) == 1) {
    return(categorie1)
  } else {
    return(categorie2)
  }
}




#' Draw a random value from a truncated Lognormal distribution
#'
#' Draws a single random value from a Lognormal distribution truncated
#' at an upper bound.
#'
#' @param mean Mean of the Lognormal distribution on the original scale.
#' @param sd Standard deviation of the Lognormal distribution on the original scale.
#' @param max Upper truncation bound.
#'
#' @return A single random draw from the truncated Lognormal distribution.
#' @export
r_trunc_lognormal <- function(mean, sd, min = 0, max = Inf) {

  if (mean <= 0) stop("mean must be greater than 0.")
  if (sd <= 0) stop("sd must be greater than 0.")

  # Convert original scale parameters to log-scale parameters
  sigma2 <- log(1 + (sd^2 / mean^2))

  sigma <- sqrt(sigma2)

  mu <- log(mean) - sigma2 / 2


  # Truncation probabilities
  p_min <- plnorm(min, meanlog = mu, sdlog = sigma)
  p_max <- plnorm(max, meanlog = mu, sdlog = sigma)

  # Draw only between min and max
  u <- runif(1, p_min, p_max)

  qlnorm(
    u,
    meanlog = mu,
    sdlog = sigma
  )
}




















