
# Run with devtools::load_all(): simulate_params() and load_tissue_params() are
# internal functions.
#
# sex and age are fixed to male/adult so that this script always tests the same
# phantom (Duke) and the deterministic cross check below stays comparable.

# simulate n parameter files
# n = 2000 and not 1000: with vr_duration_pzero = 0.95 only about 1 in 20 draws
# is non-zero, so fewer replicates give a very noisy mean
n <- 2000
param_simulations <- lapply(seq_len(n), function(i) {

  out <- simulate_params(sex = "male",
                         age = "adult",
                         simulation = "_template")
  out$global$sim <- paste0("sim", i)
  if (i%%200==0){print(i)}
  out

})




stochastic_vr_dose <- lapply(seq_len(length(param_simulations)), function(i) {



  sim_params = param_simulations[[i]]
  vr_duration = sim_params$global$input_stoch$vr_duration$vr_duration


  body_vr_dose <- vr_dose(
    tissue      = "body",
    duration_vr = vr_duration,
    params      = sim_params
  )

  brain_vr_dose <- vr_dose(
    tissue      = "brain",
    duration_vr = vr_duration,
    params      = sim_params
  )


  list(
    body_vr_dose  = body_vr_dose,
    brain_vr_dose = brain_vr_dose,
    # keep the drivers, so a surprising dose can be traced back to its input
    vr_duration    = vr_duration,
    vr_online_prop = sim_params$devices$vr$online_prop$vr_online_prop,
    vr_dist_device = sim_params$devices$vr$vr_distance$vr_dist_device,
    vr_2400_pwr    = sim_params$devices$vr$pwr$vr_2400_pwr,
    vr_5000_pwr    = sim_params$devices$vr$pwr$vr_5000_pwr
  )
})

stochastic_vr_dose_df <- data.frame(
  body_vr_dose   = sapply(stochastic_vr_dose, \(x) x$body_vr_dose),
  brain_vr_dose  = sapply(stochastic_vr_dose, \(x) x$brain_vr_dose),
  vr_duration    = sapply(stochastic_vr_dose, \(x) x$vr_duration),
  vr_online_prop = sapply(stochastic_vr_dose, \(x) x$vr_online_prop),
  vr_dist_device = sapply(stochastic_vr_dose, \(x) x$vr_dist_device),
  vr_2400_pwr    = sapply(stochastic_vr_dose, \(x) x$vr_2400_pwr),
  vr_5000_pwr    = sapply(stochastic_vr_dose, \(x) x$vr_5000_pwr)
)



par(mfrow = c(2, 2),
    mar = c(4, 4, 3, 1))

#========================
# Body VR dose
#========================


hist(stochastic_vr_dose_df$body_vr_dose,
     probability = TRUE,
     breaks = 100,
     col = "lightblue",
     border = "white",
     main = "Body VR dose",
     xlab = "Dose")

lines(density(stochastic_vr_dose_df$body_vr_dose),
      col = "red",
      lwd = 2)

abline(v = mean(stochastic_vr_dose_df$body_vr_dose),
       col = "blue",
       lwd = 2,
       lty = 2)

boxplot(stochastic_vr_dose_df$body_vr_dose,
        horizontal = TRUE,
        col = "lightblue",
        main = "Body VR dose",
        xlab = "Dose")

stripchart(stochastic_vr_dose_df$body_vr_dose,
           method = "jitter",
           pch = 16,
           cex = 0.5,
           vertical = FALSE,
           add = TRUE)


#========================
# Brain VR dose
#========================

hist(stochastic_vr_dose_df$brain_vr_dose,
     probability = TRUE,
     breaks = 100,
     col = "lightblue",
     border = "white",
     main = "Brain VR dose",
     xlab = "Dose")

lines(density(stochastic_vr_dose_df$brain_vr_dose),
      col = "red",
      lwd = 2)

abline(v = mean(stochastic_vr_dose_df$brain_vr_dose),
       col = "blue",
       lwd = 2,
       lty = 2)


boxplot(stochastic_vr_dose_df$brain_vr_dose,
        horizontal = TRUE,
        col = "lightblue",
        main = "Brain VR dose",
        xlab = "Dose")

stripchart(stochastic_vr_dose_df$brain_vr_dose,
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
hist(stochastic_vr_dose_df$vr_duration, breaks = 100, col = "lightblue",
     border = "white", main = "VR duration", xlab = "s")
hist(stochastic_vr_dose_df$vr_dist_device, breaks = 100, col = "lightblue",
     border = "white", main = "Headset standoff", xlab = "mm")
hist(stochastic_vr_dose_df$vr_2400_pwr, breaks = 100, col = "lightblue",
     border = "white", main = "2.4 GHz power", xlab = "mW")
hist(stochastic_vr_dose_df$vr_5000_pwr, breaks = 100, col = "lightblue",
     border = "white", main = "5 GHz power", xlab = "mW")
par(mfrow = c(1, 1))

cat("share of simulations with zero dose:",
    mean(stochastic_vr_dose_df$body_vr_dose == 0),
    " (expected ~0.95, from vr_duration_pzero)\n")
cat("mean body dose :", mean(stochastic_vr_dose_df$body_vr_dose), "mJ/kg/day\n")
cat("mean brain dose:", mean(stochastic_vr_dose_df$brain_vr_dose), "mJ/kg/day\n")
cat("mean standoff:", mean(stochastic_vr_dose_df$vr_dist_device), " (expected ~15)\n")
cat("mean online prop:", mean(stochastic_vr_dose_df$vr_online_prop), " (expected ~0.4)\n")
cat("mean power 2.4 / 5 GHz:", mean(stochastic_vr_dose_df$vr_2400_pwr), "/",
    mean(stochastic_vr_dose_df$vr_5000_pwr),
    " (expected ~79 / ~158: the trunc_lognormal is cut off at its own mean)\n")

# The standoff must never leave the range the ear proxy is valid in: we do not
# extrapolate below the 8 mm simulation reference, and not far above it either
# because the empirical falloff exponent is ~0.75 rather than the assumed 2.
stopifnot(all(stochastic_vr_dose_df$vr_dist_device >= 8))
stopifnot(all(stochastic_vr_dose_df$vr_dist_device <= 30))


#==============================================================================
# Deterministic cross check against a hand computation
#==============================================================================
# Runs vr_dose() on the raw template (no simulation) and compares it with the
# value computed by hand from the yaml. This checks the whole chain: dummy
# resolution, ear-position mean, distance law, band mix and the /1000.

template_params <- load_params(version = "_template")
dur <- template_params$global$input_stoch$vr_duration$vr_duration

ref_body  <- vr_dose(tissue = "body",  duration_vr = dur, params = template_params)
ref_brain <- vr_dose(tissue = "brain", duration_vr = dur, params = template_params)

ear_position <- c("cheek1","cheek2","cheek3","tilt1","tilt2","tilt3")

mean_ear_sar <- function(tissue, freq) {
  tp <- load_tissue_params(template_params, "call", tissue, "Duke")
  mean(vapply(ear_position,
              \(p) tp[[paste0("Duke_", tissue, "_", freq, "_", p, "_sar")]],
              numeric(1)))
}

d <- template_params$devices$vr$vr_distance$vr_dist_device
# ONE factor for both tissues: the headset is worn on the head, so there is no
# torso-to-head offset and therefore no hypotenuse as there is for gaming.
f <- ((8 + 6)/(d + 6))^2

pwr_2400 <- template_params$devices$vr$pwr$vr_2400_pwr *
  template_params$devices$vr$dutycycle$vr_2400_dutycycle
pwr_5000 <- template_params$devices$vr$pwr$vr_5000_pwr *
  template_params$devices$vr$dutycycle$vr_5000_dutycycle
w_2400 <- template_params$global$wifi_probs$wifi_2400_prop
w_5000 <- template_params$global$wifi_probs$wifi_5000_prop
onln   <- template_params$devices$vr$online_prop$vr_online_prop

hand_body <- (w_2400*pwr_2400*mean_ear_sar("body", 2400)*f +
              w_5000*pwr_5000*mean_ear_sar("body", 5000)*f) * dur * onln / 1000
hand_brain <- (w_2400*pwr_2400*mean_ear_sar("brain", 2400)*f +
               w_5000*pwr_5000*mean_ear_sar("brain", 5000)*f) * dur * onln / 1000

cat("\n--- deterministic cross check ---------------------------------------\n")
cat("ear mean sar Duke body  2400 / 5000:", mean_ear_sar("body", 2400), "/",
    mean_ear_sar("body", 5000), "\n")
cat("ear mean sar Duke brain 2400 / 5000:", mean_ear_sar("brain", 2400), "/",
    mean_ear_sar("brain", 5000), "\n")
cat("distance factor (same for both tissues):", f, "\n")
cat("vr_dose body :", ref_body,  " hand:", hand_body,  "\n")
cat("vr_dose brain:", ref_brain, " hand:", hand_brain, "\n")

stopifnot(isTRUE(all.equal(ref_body,  hand_body,  tolerance = 1e-8)))
stopifnot(isTRUE(all.equal(ref_brain, hand_brain, tolerance = 1e-8)))

# Cross check that switching off the distance correction returns the raw ear mean
no_dist_params <- template_params
no_dist_params$global$dist_correction <- FALSE
raw_body <- vr_dose(tissue = "body", duration_vr = dur, params = no_dist_params)
stopifnot(isTRUE(all.equal(raw_body, ref_body/f, tolerance = 1e-8)))
cat("dist_correction = FALSE falls back to the uncorrected 8 mm ear mean: OK\n")

# VR-SPECIFIC INVARIANT, which test_gaming.R does not have:
# both tissues share one distance factor, so the brain/body dose ratio must not
# depend on the standoff. If anyone reintroduces a hypotenuse for the brain,
# this breaks.
ratios <- sapply(c(8, 15, 20, 30), function(dd) {
  p <- template_params
  p$devices$vr$vr_distance$vr_dist_device <- dd
  vr_dose("brain", dur, p) / vr_dose("body", dur, p)
})
cat("brain/body ratio at 8/15/20/30 mm:", ratios, "\n")
stopifnot(isTRUE(all.equal(max(ratios), min(ratios), tolerance = 1e-10)))

# PHYSICS GUARD RAIL: whole-body SAR times body mass is the fraction of the
# radiated power that is absorbed and cannot exceed 1. This is the check that
# ruled out the front_of_eyes proxy, so it is worth keeping as a test.
# Masses are IT'IS Virtual Population figures; they are NOT stored in the repo.
mass <- c(Duke = 70.2, Ella = 57.3, Thelonious = 18.6, Eartha = 29.0)
cat("\nabsorbed fraction of the radiated power (must be < 1):\n")
for (dm in names(mass)) {
  p <- template_params
  p$global$input_stoch$sex <- if (dm %in% c("Duke","Thelonious")) "male" else "female"
  p$global$input_stoch$age <- if (dm %in% c("Duke","Ella")) "adult" else "child"
  frac <- vr_sar("body", 2400, p) * mass[[dm]] / 1000
  cat(sprintf("  %-11s %.3f\n", dm, frac))
  stopifnot(frac < 1)
}
