
# Run with devtools::load_all(): simulate_params() and load_tissue_params() are
# internal functions.
#
# sex and age are fixed to male/adult so that this script always tests the same
# phantom (Duke) and the deterministic cross check below stays comparable.

# simulate n parameter files
# n = 2000 to match test_vr.R. The tablet durations have no point mass at zero,
# so every draw contributes, but two of the eight duty cycles are drawn from
# Beta distributions with a0 < 8 and are very wide, which makes the dose
# distribution heavy tailed and the mean slow to settle.
n <- 2000
param_simulations <- lapply(seq_len(n), function(i) {

  out <- simulate_params(sex = "male",
                         age = "adult",
                         simulation = "_template")
  out$global$sim <- paste0("sim", i)
  if (i%%200==0){print(i)}
  out

})




stochastic_tblt_dose <- lapply(seq_len(length(param_simulations)), function(i) {



  sim_params = param_simulations[[i]]
  dur_low     = sim_params$global$input_stoch$tblt_duration$tblt_dur_low
  dur_lowmed  = sim_params$global$input_stoch$tblt_duration$tblt_dur_lowmed
  dur_medhigh = sim_params$global$input_stoch$tblt_duration$tblt_dur_medhigh
  dur_high    = sim_params$global$input_stoch$tblt_duration$tblt_dur_high


  body_tblt_dose <- tablet_dose(
    tissue      = "body",
    dur_low     = dur_low,
    dur_lowmed  = dur_lowmed,
    dur_medhigh = dur_medhigh,
    dur_high    = dur_high,
    params      = sim_params
  )

  brain_tblt_dose <- tablet_dose(
    tissue      = "brain",
    dur_low     = dur_low,
    dur_lowmed  = dur_lowmed,
    dur_medhigh = dur_medhigh,
    dur_high    = dur_high,
    params      = sim_params
  )


  list(
    body_tblt_dose  = body_tblt_dose,
    brain_tblt_dose = brain_tblt_dose,
    # keep the drivers, so a surprising dose can be traced back to its input
    tblt_duration    = dur_low + dur_lowmed + dur_medhigh + dur_high,
    tblt_dist_device = sim_params$devices$tblt$tblt_distance$tblt_dist_device,
    tblt_2400_pwr    = sim_params$devices$tblt$pwr$tblt_2400_pwr,
    tblt_5000_pwr    = sim_params$devices$tblt$pwr$tblt_5000_pwr,
    tblt_5000_high_dutycycle =
      sim_params$devices$tblt$dutycycle$tblt_5000_high_dutycycle
  )
})

stochastic_tblt_dose_df <- data.frame(
  body_tblt_dose   = sapply(stochastic_tblt_dose, \(x) x$body_tblt_dose),
  brain_tblt_dose  = sapply(stochastic_tblt_dose, \(x) x$brain_tblt_dose),
  tblt_duration    = sapply(stochastic_tblt_dose, \(x) x$tblt_duration),
  tblt_dist_device = sapply(stochastic_tblt_dose, \(x) x$tblt_dist_device),
  tblt_2400_pwr    = sapply(stochastic_tblt_dose, \(x) x$tblt_2400_pwr),
  tblt_5000_pwr    = sapply(stochastic_tblt_dose, \(x) x$tblt_5000_pwr),
  tblt_5000_high_dutycycle =
    sapply(stochastic_tblt_dose, \(x) x$tblt_5000_high_dutycycle)
)



par(mfrow = c(2, 2),
    mar = c(4, 4, 3, 1))

#========================
# Body tablet dose
#========================


hist(stochastic_tblt_dose_df$body_tblt_dose,
     probability = TRUE,
     breaks = 100,
     col = "lightblue",
     border = "white",
     main = "Body tablet dose",
     xlab = "Dose")

lines(density(stochastic_tblt_dose_df$body_tblt_dose),
      col = "red",
      lwd = 2)

abline(v = mean(stochastic_tblt_dose_df$body_tblt_dose),
       col = "blue",
       lwd = 2,
       lty = 2)

boxplot(stochastic_tblt_dose_df$body_tblt_dose,
        horizontal = TRUE,
        col = "lightblue",
        main = "Body tablet dose",
        xlab = "Dose")

stripchart(stochastic_tblt_dose_df$body_tblt_dose,
           method = "jitter",
           pch = 16,
           cex = 0.5,
           vertical = FALSE,
           add = TRUE)


#========================
# Brain tablet dose
#========================

hist(stochastic_tblt_dose_df$brain_tblt_dose,
     probability = TRUE,
     breaks = 100,
     col = "lightblue",
     border = "white",
     main = "Brain tablet dose",
     xlab = "Dose")

lines(density(stochastic_tblt_dose_df$brain_tblt_dose),
      col = "red",
      lwd = 2)

abline(v = mean(stochastic_tblt_dose_df$brain_tblt_dose),
       col = "blue",
       lwd = 2,
       lty = 2)


boxplot(stochastic_tblt_dose_df$brain_tblt_dose,
        horizontal = TRUE,
        col = "lightblue",
        main = "Brain tablet dose",
        xlab = "Dose")

stripchart(stochastic_tblt_dose_df$brain_tblt_dose,
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
hist(stochastic_tblt_dose_df$tblt_duration, breaks = 100, col = "lightblue",
     border = "white", main = "Tablet duration (all four activities)", xlab = "s")
hist(stochastic_tblt_dose_df$tblt_dist_device, breaks = 100, col = "lightblue",
     border = "white", main = "Viewing distance", xlab = "mm")
hist(stochastic_tblt_dose_df$tblt_2400_pwr, breaks = 100, col = "lightblue",
     border = "white", main = "2.4 GHz power", xlab = "mW")
hist(stochastic_tblt_dose_df$tblt_5000_high_dutycycle, breaks = 100,
     col = "lightblue", border = "white",
     main = "5 GHz high-activity duty cycle", xlab = "-")
par(mfrow = c(1, 1))

cat("mean body dose :", mean(stochastic_tblt_dose_df$body_tblt_dose), "mJ/kg/day\n")
cat("mean brain dose:", mean(stochastic_tblt_dose_df$brain_tblt_dose), "mJ/kg/day\n")
cat("mean duration:", mean(stochastic_tblt_dose_df$tblt_duration),
    " (expected ~1618 = 728+81+728+81)\n")
cat("mean viewing distance:", mean(stochastic_tblt_dose_df$tblt_dist_device),
    " (expected slightly above 300: the lognormal is truncated at 200 below)\n")
cat("mean power 2.4 / 5 GHz:", mean(stochastic_tblt_dose_df$tblt_2400_pwr), "/",
    mean(stochastic_tblt_dose_df$tblt_5000_pwr),
    " (expected ~79 / ~158: the trunc_lognormal is cut off at its own mean)\n")

# The viewing distance must stay inside the drawn bounds. Unlike VR this never
# extrapolates below the 200 mm simulation reference: the tablet is always
# further away than the simulated antenna, so the distance law is only ever
# applied outward, which is its milder direction.
stopifnot(all(stochastic_tblt_dose_df$tblt_dist_device >= 200))
stopifnot(all(stochastic_tblt_dose_df$tblt_dist_device <= 500))

# The 5 GHz high-activity duty cycle borrows a0 = 0.458 from mobiledata, where
# it was fitted at a mean of 0.495. At the tablet mean of 0.145 both Beta shape
# parameters fall below 1, so the draws pile up near 0 with a thin tail to 1.
# This is a known placeholder issue, recorded in doc/MODEL_LIMITATIONS.md; the
# check below only documents the shape, it is not an endorsement of it.
cat("5 GHz high duty cycle: mean", mean(stochastic_tblt_dose_df$tblt_5000_high_dutycycle),
    " median", median(stochastic_tblt_dose_df$tblt_5000_high_dutycycle),
    " share below 0.01:", mean(stochastic_tblt_dose_df$tblt_5000_high_dutycycle < 0.01), "\n")


#==============================================================================
# Deterministic cross check against a hand computation
#==============================================================================
# Runs tablet_dose() on the raw template (no simulation) and compares it with
# the value computed by hand from the yaml. This checks the whole chain: dummy
# resolution, front_of_eyes mean, distance law, activity mix, band mix and the
# /1000.

template_params <- load_params(version = "_template")
dur <- template_params$global$input_stoch$tblt_duration
d_low     <- dur$tblt_dur_low
d_lowmed  <- dur$tblt_dur_lowmed
d_medhigh <- dur$tblt_dur_medhigh
d_high    <- dur$tblt_dur_high
d_total   <- d_low + d_lowmed + d_medhigh + d_high

ref_body  <- tablet_dose("body",  d_low, d_lowmed, d_medhigh, d_high, template_params)
ref_brain <- tablet_dose("brain", d_low, d_lowmed, d_medhigh, d_high, template_params)

frontal_position <- c("front_of_eyes_center_vertical","front_of_eyes_center_horizontal",
                      "front_of_eyes_left_vertical","front_of_eyes_left_horizontal",
                      "front_of_eyes_right_vertical","front_of_eyes_right_horizontal",
                      "front_of_eyes_down_vertical","front_of_eyes_down_horizontal")

mean_frontal_sar <- function(tissue, freq) {
  tp <- load_tissue_params(template_params, "call", tissue, "Duke")
  mean(vapply(frontal_position,
              \(p) tp[[paste0("Duke_", tissue, "_", freq, "_", p, "_sar")]],
              numeric(1)))
}

dd <- template_params$devices$tblt$tblt_distance$tblt_dist_device
# ONE factor for both tissues: the tablet is held in front of the face, so
# moving it away increases the separation to head and torso alike. No hypotenuse
# as there is for gaming, where the console sits at the belly and the brain is
# offset by half the body height.
f <- ((200 + 6)/(dd + 6))^2

# activity shares -- the power depends on the mix, not on the absolute durations
act <- c(low = d_low, lowmed = d_lowmed, medhigh = d_medhigh, high = d_high)/d_total

hand_pwr <- function(freq) {
  sum(vapply(names(act), \(a)
    act[[a]] * template_params$devices$tblt$dutycycle[[
      paste0("tblt_", freq, "_", a, "_dutycycle")]],
    numeric(1))) * template_params$devices$tblt$pwr[[paste0("tblt_", freq, "_pwr")]]
}

pwr_2400 <- hand_pwr(2400)
pwr_5000 <- hand_pwr(5000)
w_2400 <- template_params$global$wifi_probs$wifi_2400_prop
w_5000 <- template_params$global$wifi_probs$wifi_5000_prop

hand_body <- (w_2400*pwr_2400*mean_frontal_sar("body", 2400)*f +
              w_5000*pwr_5000*mean_frontal_sar("body", 5000)*f) * d_total / 1000
hand_brain <- (w_2400*pwr_2400*mean_frontal_sar("brain", 2400)*f +
               w_5000*pwr_5000*mean_frontal_sar("brain", 5000)*f) * d_total / 1000

cat("\n--- deterministic cross check ---------------------------------------\n")
cat("frontal mean sar Duke body  2400 / 5000:", mean_frontal_sar("body", 2400), "/",
    mean_frontal_sar("body", 5000), "\n")
cat("frontal mean sar Duke brain 2400 / 5000:", mean_frontal_sar("brain", 2400), "/",
    mean_frontal_sar("brain", 5000), "\n")
cat("distance factor 200 -> ", dd, " mm (same for both tissues): ", f, "\n", sep = "")
cat("tablet_dose body :", ref_body,  " hand:", hand_body,  "\n")
cat("tablet_dose brain:", ref_brain, " hand:", hand_brain, "\n")

stopifnot(isTRUE(all.equal(ref_body,  hand_body,  tolerance = 1e-8)))
stopifnot(isTRUE(all.equal(ref_brain, hand_brain, tolerance = 1e-8)))

# Cross check that switching off the distance correction returns the raw
# front_of_eyes mean at its 200 mm reference
no_dist_params <- template_params
no_dist_params$global$dist_correction <- FALSE
raw_body <- tablet_dose("body", d_low, d_lowmed, d_medhigh, d_high, no_dist_params)
stopifnot(isTRUE(all.equal(raw_body, ref_body/f, tolerance = 1e-8)))
cat("dist_correction = FALSE falls back to the uncorrected 200 mm mean: OK\n")

# INVARIANT 1 (shared with VR): both tissues use one distance factor, so the
# brain/body dose ratio must not depend on the viewing distance. If anyone
# reintroduces a hypotenuse for the brain, this breaks.
ratios <- sapply(c(200, 300, 400, 500), function(x) {
  p <- template_params
  p$devices$tblt$tblt_distance$tblt_dist_device <- x
  tablet_dose("brain", d_low, d_lowmed, d_medhigh, d_high, p) /
    tablet_dose("body",  d_low, d_lowmed, d_medhigh, d_high, p)
})
cat("brain/body ratio at 200/300/400/500 mm:", ratios, "\n")
stopifnot(isTRUE(all.equal(max(ratios), min(ratios), tolerance = 1e-10)))

# INVARIANT 2, tablet specific: the output power depends on the activity MIX,
# the dose on the total duration. Scaling all four durations by the same factor
# must therefore scale the dose by exactly that factor. This catches a mix-up
# between absolute durations and their proportions in tablet_pwr().
k <- 3
scaled <- tablet_dose("body", k*d_low, k*d_lowmed, k*d_medhigh, k*d_high,
                      template_params)
stopifnot(isTRUE(all.equal(scaled, k*ref_body, tolerance = 1e-10)))
cat("dose scales linearly with duration at a fixed activity mix: OK\n")

# INVARIANT 3: no usage at all must give exactly zero and must not error.
# act_pwr_props() returns all-zero proportions for a total duration of zero.
stopifnot(tablet_dose("body", 0, 0, 0, 0, template_params) == 0)
cat("zero duration gives zero dose without error: OK\n")

# PHYSICS GUARD RAIL: whole-body SAR times body mass is the fraction of the
# radiated power that is absorbed and cannot exceed 1. For VR this check ruled
# the front_of_eyes proxy out; here the same proxy passes comfortably, because
# the tablet is rescaled outward (200 -> 300 mm) instead of down to 15 mm.
# Masses are IT'IS Virtual Population figures; they are NOT stored in the repo.
mass <- c(Duke = 70.2, Ella = 57.3, Thelonious = 18.6, Eartha = 29.0)
cat("\nabsorbed fraction of the radiated power (must be < 1):\n")
for (dm in names(mass)) {
  p <- template_params
  p$global$input_stoch$sex <- if (dm %in% c("Duke","Thelonious")) "male" else "female"
  p$global$input_stoch$age <- if (dm %in% c("Duke","Ella")) "adult" else "child"
  frac <- tablet_sar("body", 2400, p) * mass[[dm]] / 1000
  cat(sprintf("  %-11s %.4f\n", dm, frac))
  stopifnot(frac < 1)
}
