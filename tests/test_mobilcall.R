



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





stochastic_mobilecall_dose <- lapply(seq_len(length(param_simulations)), function(i) {


    sim_params = param_simulations[[i]]
    duration = sim_params$global$input_stoch$duration$mpc_duration
    ear_prop = sim_params$global$input_stoch$call_mode_prop$mpc_ear_prop
    headp_prop = sim_params$global$input_stoch$call_mode_prop$mpc_headp_prop
    use_5g = sim_params$global$input_stoch$use_5g
    headp_ear_num = sim_params$global$input_stoch$headp_num$headp_ear_num
    travel_time = sim_params$global$environment_prop$travel_prop*86400
    wifi_prop_home = sim_params$global$input_stoc$wifi_environment_probs$mpd_wifi_prop_home
    wifi_prop_work = sim_params$global$input_stoc$wifi_environment_probs$mpd_wifi_prop_work
    wifi_prop_travel = sim_params$global$input_stoc$wifi_environment_probs$mpd_wifi_prop_travel


    body_call_dose <- mobilecall_dose(
      tissue = "body",
      duration = duration,
      ear_prop = ear_prop,
      headp_prop = headp_prop,
      use_5g = use_5g,
      travel_time = travel_time,
      headp_ear_num = headp_ear_num,
      wifi_prop_home = wifi_prop_home,
      wifi_prop_work = wifi_prop_work,
      wifi_prop_travel = wifi_prop_travel,
      params = sim_params)

    brain_call_dose <- mobilecall_dose(
      tissue = "brain",
      duration = duration,
      ear_prop = ear_prop,
      headp_prop = headp_prop,
      use_5g = use_5g,
      travel_time = travel_time,
      headp_ear_num = headp_ear_num,
      wifi_prop_home = wifi_prop_home,
      wifi_prop_work = wifi_prop_work,
      wifi_prop_travel = wifi_prop_travel,
      params = sim_params)

    list(
      body_call_dose = body_call_dose,
      brain_call_dose = brain_call_dose
    )
  })

stochastic_mobilecall_dose_df <- data.frame(
  body_call_dose = sapply(stochastic_mobilecall_dose, \(x) x$body_call_dose),
  brain_call_dose = sapply(stochastic_mobilecall_dose, \(x) x$brain_call_dose)
)


par(mfrow = c(2, 2),
    mar = c(4, 4, 3, 1))

#========================
# Body call dose
#========================


hist(stochastic_mobilecall_dose_df$body_call_dose,
     probability = TRUE,
     breaks = 100,
     col = "lightblue",
     border = "white",
     main = "Body call dose",
     xlab = "Dose")

lines(density(stochastic_mobilecall_dose_df$body_call_dose),
      col = "red",
      lwd = 2)

abline(v = mean(stochastic_mobilecall_dose_df$body_call_dose),
       col = "blue",
       lwd = 2,
       lty = 2)

boxplot(stochastic_mobilecall_dose_df$body_call_dose,
        horizontal = TRUE,
        col = "lightblue",
        main = "Body call dose",
        xlab = "Dose")

stripchart(stochastic_mobilecall_dose_df$body_call_dose,
           method = "jitter",
           pch = 16,
           cex = 0.5,
           vertical = FALSE,
           add = TRUE)


#========================
# Brain call dose
#========================

hist(stochastic_mobilecall_dose_df$brain_call_dose,
     probability = TRUE,
     breaks = 100,
     col = "lightblue",
     border = "white",
     main = "Brain call dose",
     xlab = "Dose")

lines(density(stochastic_mobilecall_dose_df$brain_call_dose),
      col = "red",
      lwd = 2)

abline(v = mean(stochastic_mobilecall_dose_df$brain_call_dose),
       col = "blue",
       lwd = 2,
       lty = 2)


boxplot(stochastic_mobilecall_dose_df$brain_call_dose,
        horizontal = TRUE,
        col = "lightblue",
        main = "Brain call dose",
        xlab = "Dose")

stripchart(stochastic_mobilecall_dose_df$brain_call_dose,
           method = "jitter",
           pch = 16,
           cex = 0.5,
           vertical = FALSE,
           add = TRUE)

par(mfrow = c(1, 1))








mobilecall_dose(
  duration = params$global$input_stoch$duration$mpc_duration,
  ear_prop = params$global$input_stoch$call_mode_prop$mpc_ear_prop,
  headp_prop = params$global$input_stoch$call_mode_prop$mpc_headp_prop,
  use_5g = params$global$input_stoch$use_5g,
  headp_ear_num = 2,
  tissue = "body",
  travel_time = 400,
  wifi_prop_home = 0.5,
  wifi_prop_work = 0.5,
  wifi_prop_travel = 0.5,
  simulation = "_template"
)


