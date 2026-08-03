
# simulate n parameter files
n <- 100
param_simulations <- lapply(seq_len(n), function(i) {

  out <- simulate_params(sex = "male",
                         age = "adult",
                         simulation = "_template")
  out$global$sim <- paste0("sim", i)
  if (i%%10==0){print(i)}
  out

})








stochastic_data_dose <- lapply(seq_len(length(param_simulations)), function(i) {



  sim_params = param_simulations[[i]]
  duration_low = sim_params$global$input_stoch$mpd_duration$mpd_dur_low
  duration_lowmed = sim_params$global$input_stoch$mpd_duration$mpd_dur_lowmed
  duration_medhigh = sim_params$global$input_stoch$mpd_duration$mpd_dur_medhigh
  duration_high = sim_params$global$input_stoch$mpd_duration$mpd_dur_high
  duration = sim_params$global$input_stoch$duration$mpc_duration
  ear_prop = sim_params$global$input_stoch$call_mode_prop$mpc_ear_prop
  headp_prop = sim_params$global$input_stoch$call_mode_prop$mpc_headp_prop
  use_5g = sim_params$global$input_stoch$use_5g
  headp_ear_num = sim_params$global$input_stoch$headp_num$headp_ear_num
  travel_time = sim_params$global$environment_prop$travel_prop*86400
  wifi_prop_home = sim_params$global$input_stoc$wifi_environment_probs$mpd_wifi_prop_home
  wifi_prop_work = sim_params$global$input_stoc$wifi_environment_probs$mpd_wifi_prop_work
  wifi_prop_travel = sim_params$global$input_stoc$wifi_environment_probs$mpd_wifi_prop_travel


  body_data_dose <- mobiledata_dose(
    tissue = "body",
    duration_low = duration_low,
    duration_lowmed = duration_lowmed,
    duration_medhigh = duration_medhigh,
    duration_high = duration_high,
    use_5g = use_5g,
    wifi_prop_home = wifi_prop_home,
    wifi_prop_work = wifi_prop_work,
    wifi_prop_travel = wifi_prop_travel,
    travel_time = travel_time,
    params = sim_params)

  brain_data_dose <- mobiledata_dose(
    tissue = "brain",
    duration_low = duration_low,
    duration_lowmed = duration_lowmed,
    duration_medhigh = duration_medhigh,
    duration_high = duration_high,
    use_5g = use_5g,
    wifi_prop_home = wifi_prop_home,
    wifi_prop_work = wifi_prop_work,
    wifi_prop_travel = wifi_prop_travel,
    travel_time = travel_time,
    params = sim_params)

  list(
    body_data_dose = body_data_dose,
    brain_data_dose = brain_data_dose
  )
})

stochastic_mobiledata_dose_df <- data.frame(
  body_data_dose = sapply(stochastic_data_dose, \(x) x$body_data_dose),
  brain_data_dose = sapply(stochastic_data_dose, \(x) x$brain_data_dose)
)



par(mfrow = c(2, 2),
    mar = c(4, 4, 3, 1))

#========================
# Body data dose
#========================


hist(stochastic_mobiledata_dose_df$body_data_dose,
     probability = TRUE,
     breaks = 100,
     col = "lightblue",
     border = "white",
     main = "Body data dose",
     xlab = "Dose")

lines(density(stochastic_mobiledata_dose_df$body_data_dose),
      col = "red",
      lwd = 2)

abline(v = mean(stochastic_mobiledata_dose_df$body_data_dose),
       col = "blue",
       lwd = 2,
       lty = 2)

boxplot(stochastic_mobiledata_dose_df$body_data_dose,
        horizontal = TRUE,
        col = "lightblue",
        main = "Body data dose",
        xlab = "Dose")

stripchart(stochastic_mobiledata_dose_df$body_data_dose,
           method = "jitter",
           pch = 16,
           cex = 0.5,
           vertical = FALSE,
           add = TRUE)


#========================
# Brain data dose
#========================

hist(stochastic_mobiledata_dose_df$brain_data_dose,
     probability = TRUE,
     breaks = 100,
     col = "lightblue",
     border = "white",
     main = "Brain data dose",
     xlab = "Dose")

lines(density(stochastic_mobiledata_dose_df$brain_data_dose),
      col = "red",
      lwd = 2)

abline(v = mean(stochastic_mobiledata_dose_df$brain_data_dose),
       col = "blue",
       lwd = 2,
       lty = 2)


boxplot(stochastic_mobiledata_dose_df$brain_data_dose,
        horizontal = TRUE,
        col = "lightblue",
        main = "Brain data dose",
        xlab = "Dose")

stripchart(stochastic_mobiledata_dose_df$brain_data_dose,
           method = "jitter",
           pch = 16,
           cex = 0.5,
           vertical = FALSE,
           add = TRUE)

par(mfrow = c(1, 1))

