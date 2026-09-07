
# Run with devtools::load_all(): simulate_params() and load_tissue_params() are
# internal functions.
#
# sex and age are fixed to male/adult because so far only Duke has simulated sar
# values (Ella, Thelonious and Eartha are still zero-filled).

# simulate n parameter files
# n = 1000 and not 100: with gaming_duration_pzero = 0.8 only about a fifth of the
# draws are non-zero, so 100 replicates give a very noisy mean
n <- 1000
param_simulations <- lapply(seq_len(n), function(i) {

  out <- simulate_params(sex = "male",
                         age = "adult",
                         simulation = "_template")
  out$global$sim <- paste0("sim", i)
  if (i%%100==0){print(i)}
  out

})




stochastic_gaming_dose <- lapply(seq_len(length(param_simulations)), function(i) {



  sim_params = param_simulations[[i]]
  gaming_duration = sim_params$global$input_stoch$gaming_duration$gaming_duration


  body_gaming_dose <- gaming_dose(
    tissue          = "body",
    duration_gaming = gaming_duration,
    params          = sim_params
  )

  brain_gaming_dose <- gaming_dose(
    tissue          = "brain",
    duration_gaming = gaming_duration,
    params          = sim_params
  )


  list(
    body_gaming_dose  = body_gaming_dose,
    brain_gaming_dose = brain_gaming_dose,
    # keep the drivers, so a surprising dose can be traced back to its input
    gaming_duration    = gaming_duration,
    gaming_online_prop = sim_params$devices$gaming$online_prop$gaming_online_prop,
    gaming_dist_pc     = sim_params$devices$gaming$gaming_distance$gaming_dist_pc,
    gaming_2400_pwr    = sim_params$devices$gaming$pwr$gaming_2400_pwr,
    gaming_5000_pwr    = sim_params$devices$gaming$pwr$gaming_5000_pwr
  )
})

stochastic_gaming_dose_df <- data.frame(
  body_gaming_dose   = sapply(stochastic_gaming_dose, \(x) x$body_gaming_dose),
  brain_gaming_dose  = sapply(stochastic_gaming_dose, \(x) x$brain_gaming_dose),
  gaming_duration    = sapply(stochastic_gaming_dose, \(x) x$gaming_duration),
  gaming_online_prop = sapply(stochastic_gaming_dose, \(x) x$gaming_online_prop),
  gaming_dist_pc     = sapply(stochastic_gaming_dose, \(x) x$gaming_dist_pc),
  gaming_2400_pwr    = sapply(stochastic_gaming_dose, \(x) x$gaming_2400_pwr),
  gaming_5000_pwr    = sapply(stochastic_gaming_dose, \(x) x$gaming_5000_pwr)
)



par(mfrow = c(2, 2),
    mar = c(4, 4, 3, 1))

#========================
# Body gaming dose
#========================


hist(stochastic_gaming_dose_df$body_gaming_dose,
     probability = TRUE,
     breaks = 100,
     col = "lightblue",
     border = "white",
     main = "Body gaming dose",
     xlab = "Dose")

lines(density(stochastic_gaming_dose_df$body_gaming_dose),
      col = "red",
      lwd = 2)

abline(v = mean(stochastic_gaming_dose_df$body_gaming_dose),
       col = "blue",
       lwd = 2,
       lty = 2)

boxplot(stochastic_gaming_dose_df$body_gaming_dose,
        horizontal = TRUE,
        col = "lightblue",
        main = "Body gaming dose",
        xlab = "Dose")

stripchart(stochastic_gaming_dose_df$body_gaming_dose,
           method = "jitter",
           pch = 16,
           cex = 0.5,
           vertical = FALSE,
           add = TRUE)


#========================
# Brain gaming dose
#========================

hist(stochastic_gaming_dose_df$brain_gaming_dose,
     probability = TRUE,
     breaks = 100,
     col = "lightblue",
     border = "white",
     main = "Brain gaming dose",
     xlab = "Dose")

lines(density(stochastic_gaming_dose_df$brain_gaming_dose),
      col = "red",
      lwd = 2)

abline(v = mean(stochastic_gaming_dose_df$brain_gaming_dose),
       col = "blue",
       lwd = 2,
       lty = 2)


boxplot(stochastic_gaming_dose_df$brain_gaming_dose,
        horizontal = TRUE,
        col = "lightblue",
        main = "Brain gaming dose",
        xlab = "Dose")

stripchart(stochastic_gaming_dose_df$brain_gaming_dose,
           method = "jitter",
           pch = 16,
           cex = 0.5,
           vertical = FALSE,
           add = TRUE)

par(mfrow = c(1, 1))


#========================
# Drivers (diagnostics)
#========================

par(mfrow = c(2, 2), mar = c(4, 4, 3, 1))
hist(stochastic_gaming_dose_df$gaming_duration, breaks = 100, col = "lightblue",
     border = "white", main = "Gaming duration", xlab = "s")
hist(stochastic_gaming_dose_df$gaming_dist_pc, breaks = 100, col = "lightblue",
     border = "white", main = "PC distance", xlab = "mm")
hist(stochastic_gaming_dose_df$gaming_2400_pwr, breaks = 100, col = "lightblue",
     border = "white", main = "2.4 GHz power", xlab = "mW")
hist(stochastic_gaming_dose_df$gaming_5000_pwr, breaks = 100, col = "lightblue",
     border = "white", main = "5 GHz power", xlab = "mW")
par(mfrow = c(1, 1))

cat("share of simulations with zero dose:",
    mean(stochastic_gaming_dose_df$body_gaming_dose == 0),
    " (expected ~0.80, from gaming_duration_pzero)\n")
cat("mean body dose :", mean(stochastic_gaming_dose_df$body_gaming_dose), "mJ/kg/day\n")
cat("mean brain dose:", mean(stochastic_gaming_dose_df$brain_gaming_dose), "mJ/kg/day\n")
cat("mean PC distance:", mean(stochastic_gaming_dose_df$gaming_dist_pc), " (expected ~600)\n")
cat("mean online prop:", mean(stochastic_gaming_dose_df$gaming_online_prop), " (expected ~0.25)\n")
cat("mean power 2.4 / 5 GHz:", mean(stochastic_gaming_dose_df$gaming_2400_pwr), "/",
    mean(stochastic_gaming_dose_df$gaming_5000_pwr),
    " (expected ~79 / ~158: the trunc_lognormal is cut off at its own mean)\n")


#==============================================================================
# Deterministic cross check against a hand computation
#==============================================================================
# Runs gaming_dose() on the raw template (no simulation) and compares it with the
# value computed by hand from the yaml. This checks the whole chain: dummy
# resolution, belly mean, distance law, band mix and the /1000.

template_params <- load_params(version = "_template")

ref_body  <- gaming_dose(
  tissue          = "body",
  duration_gaming = template_params$global$input_stoch$gaming_duration$gaming_duration,
  params          = template_params)
ref_brain <- gaming_dose(
  tissue          = "brain",
  duration_gaming = template_params$global$input_stoch$gaming_duration$gaming_duration,
  params          = template_params)

belly_position <- c("belly_center_vertical","belly_center_horizontal",
                    "belly_left_vertical","belly_left_horizontal",
                    "belly_right_vertical","belly_right_horizontal",
                    "belly_up_vertical","belly_up_horizontal")

mean_belly_sar <- function(tissue, freq) {
  tp <- load_tissue_params(template_params, "call", tissue, "Duke")
  mean(vapply(belly_position,
              \(p) tp[[paste0("Duke_", tissue, "_", freq, "_", p, "_sar")]],
              numeric(1)))
}

d  <- template_params$devices$gaming$gaming_distance$gaming_dist_pc  # 600
h  <- template_params$devices$call$Duke$height/2                     # 885
f_body  <- ((200 + 6)/(d + 6))^2
f_brain <- ((sqrt(h^2 + 200^2) + 6)/(sqrt(h^2 + d^2) + 6))^2

pwr_2400 <- template_params$devices$gaming$pwr$gaming_2400_pwr *
  template_params$devices$gaming$dutycycle$gaming_2400_dutycycle
pwr_5000 <- template_params$devices$gaming$pwr$gaming_5000_pwr *
  template_params$devices$gaming$dutycycle$gaming_5000_dutycycle
w_2400 <- template_params$global$wifi_probs$wifi_2400_prop
w_5000 <- template_params$global$wifi_probs$wifi_5000_prop

dur  <- template_params$global$input_stoch$gaming_duration$gaming_duration
onln <- template_params$devices$gaming$online_prop$gaming_online_prop

hand_body <- (w_2400*pwr_2400*mean_belly_sar("body", 2400)*f_body +
              w_5000*pwr_5000*mean_belly_sar("body", 5000)*f_body) * dur * onln / 1000
hand_brain <- (w_2400*pwr_2400*mean_belly_sar("brain", 2400)*f_brain +
               w_5000*pwr_5000*mean_belly_sar("brain", 5000)*f_brain) * dur * onln / 1000

cat("\n--- deterministic cross check ---------------------------------------\n")
cat("belly mean sar Duke body  2400 / 5000:", mean_belly_sar("body", 2400), "/",
    mean_belly_sar("body", 5000), "\n")
cat("belly mean sar Duke brain 2400 / 5000:", mean_belly_sar("brain", 2400), "/",
    mean_belly_sar("brain", 5000), "\n")
cat("distance factor body / brain:", f_body, "/", f_brain, "\n")
cat("gaming_dose body :", ref_body,  " hand:", hand_body,  "\n")
cat("gaming_dose brain:", ref_brain, " hand:", hand_brain, "\n")

stopifnot(isTRUE(all.equal(ref_body,  hand_body,  tolerance = 1e-8)))
stopifnot(isTRUE(all.equal(ref_brain, hand_brain, tolerance = 1e-8)))

# Cross check that switching off the distance correction returns the raw belly mean
no_dist_params <- template_params
no_dist_params$global$dist_correction <- FALSE
raw_body <- gaming_dose(tissue = "body", duration_gaming = dur, params = no_dist_params)
stopifnot(isTRUE(all.equal(raw_body, ref_body/f_body, tolerance = 1e-8)))
cat("dist_correction = FALSE falls back to the uncorrected belly mean: OK\n")
