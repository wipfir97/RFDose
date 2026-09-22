
# Run with devtools::load_all(): simulate_params() and load_tissue_params() are
# internal functions.
#
# sex and age are fixed to male/adult so that this script always tests the same
# phantom (Duke) and the deterministic cross check below stays comparable.

# simulate n parameter files
# n = 2000, as for tablet and VR. The laptop durations have no point mass at
# zero, but two of the eight duty cycles are drawn from very wide Beta
# distributions, which makes the dose distribution heavy tailed.
n <- 2000
param_simulations <- lapply(seq_len(n), function(i) {

  out <- simulate_params(sex = "male",
                         age = "adult",
                         simulation = "_template")
  out$global$sim <- paste0("sim", i)
  if (i%%200==0){print(i)}
  out

})




stochastic_lptp_dose <- lapply(seq_len(length(param_simulations)), function(i) {



  sim_params = param_simulations[[i]]
  dur_low     = sim_params$global$input_stoch$lptp_duration$lptp_dur_low
  dur_lowmed  = sim_params$global$input_stoch$lptp_duration$lptp_dur_lowmed
  dur_medhigh = sim_params$global$input_stoch$lptp_duration$lptp_dur_medhigh
  dur_high    = sim_params$global$input_stoch$lptp_duration$lptp_dur_high


  body_lptp_dose <- laptop_dose(
    tissue      = "body",
    dur_low     = dur_low,
    dur_lowmed  = dur_lowmed,
    dur_medhigh = dur_medhigh,
    dur_high    = dur_high,
    params      = sim_params
  )

  brain_lptp_dose <- laptop_dose(
    tissue      = "brain",
    dur_low     = dur_low,
    dur_lowmed  = dur_lowmed,
    dur_medhigh = dur_medhigh,
    dur_high    = dur_high,
    params      = sim_params
  )


  list(
    body_lptp_dose  = body_lptp_dose,
    brain_lptp_dose = brain_lptp_dose,
    # keep the drivers, so a surprising dose can be traced back to its input
    lptp_duration  = dur_low + dur_lowmed + dur_medhigh + dur_high,
    lptp_lap_prop  = sim_params$global$input_stoch$lptp_position$lptp_lap_prop,
    lptp_dist_lap  = sim_params$devices$lptp$lptp_distance$lptp_dist_lap,
    lptp_dist_desk = sim_params$devices$lptp$lptp_distance$lptp_dist_desk,
    lptp_2400_pwr  = sim_params$devices$lptp$pwr$lptp_2400_pwr,
    lptp_5000_pwr  = sim_params$devices$lptp$pwr$lptp_5000_pwr
  )
})

stochastic_lptp_dose_df <- data.frame(
  body_lptp_dose  = sapply(stochastic_lptp_dose, \(x) x$body_lptp_dose),
  brain_lptp_dose = sapply(stochastic_lptp_dose, \(x) x$brain_lptp_dose),
  lptp_duration   = sapply(stochastic_lptp_dose, \(x) x$lptp_duration),
  lptp_lap_prop   = sapply(stochastic_lptp_dose, \(x) x$lptp_lap_prop),
  lptp_dist_lap   = sapply(stochastic_lptp_dose, \(x) x$lptp_dist_lap),
  lptp_dist_desk  = sapply(stochastic_lptp_dose, \(x) x$lptp_dist_desk),
  lptp_2400_pwr   = sapply(stochastic_lptp_dose, \(x) x$lptp_2400_pwr),
  lptp_5000_pwr   = sapply(stochastic_lptp_dose, \(x) x$lptp_5000_pwr)
)



par(mfrow = c(2, 2),
    mar = c(4, 4, 3, 1))

#========================
# Body laptop dose
#========================


hist(stochastic_lptp_dose_df$body_lptp_dose,
     probability = TRUE,
     breaks = 100,
     col = "lightblue",
     border = "white",
     main = "Body laptop dose",
     xlab = "Dose")

lines(density(stochastic_lptp_dose_df$body_lptp_dose),
      col = "red",
      lwd = 2)

abline(v = mean(stochastic_lptp_dose_df$body_lptp_dose),
       col = "blue",
       lwd = 2,
       lty = 2)

boxplot(stochastic_lptp_dose_df$body_lptp_dose,
        horizontal = TRUE,
        col = "lightblue",
        main = "Body laptop dose",
        xlab = "Dose")

stripchart(stochastic_lptp_dose_df$body_lptp_dose,
           method = "jitter",
           pch = 16,
           cex = 0.5,
           vertical = FALSE,
           add = TRUE)


#========================
# Brain laptop dose
#========================

hist(stochastic_lptp_dose_df$brain_lptp_dose,
     probability = TRUE,
     breaks = 100,
     col = "lightblue",
     border = "white",
     main = "Brain laptop dose",
     xlab = "Dose")

lines(density(stochastic_lptp_dose_df$brain_lptp_dose),
      col = "red",
      lwd = 2)

abline(v = mean(stochastic_lptp_dose_df$brain_lptp_dose),
       col = "blue",
       lwd = 2,
       lty = 2)


boxplot(stochastic_lptp_dose_df$brain_lptp_dose,
        horizontal = TRUE,
        col = "lightblue",
        main = "Brain laptop dose",
        xlab = "Dose")

stripchart(stochastic_lptp_dose_df$brain_lptp_dose,
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
hist(stochastic_lptp_dose_df$lptp_duration, breaks = 100, col = "lightblue",
     border = "white", main = "Laptop duration (all four activities)", xlab = "s")
hist(stochastic_lptp_dose_df$lptp_lap_prop, breaks = 100, col = "lightblue",
     border = "white", main = "Share of time on the lap", xlab = "-")
hist(stochastic_lptp_dose_df$lptp_dist_lap, breaks = 100, col = "lightblue",
     border = "white", main = "Antenna to torso, on the lap", xlab = "mm")
hist(stochastic_lptp_dose_df$lptp_dist_desk, breaks = 100, col = "lightblue",
     border = "white", main = "Antenna to torso, on a table", xlab = "mm")
par(mfrow = c(1, 1))

cat("mean body dose :", mean(stochastic_lptp_dose_df$body_lptp_dose), "mJ/kg/day\n")
cat("mean brain dose:", mean(stochastic_lptp_dose_df$brain_lptp_dose), "mJ/kg/day\n")
cat("mean duration:", mean(stochastic_lptp_dose_df$lptp_duration),
    " (expected ~4372 = 1967+219+1967+219)\n")
cat("mean lap share:", mean(stochastic_lptp_dose_df$lptp_lap_prop), " (expected ~0.2)\n")
cat("mean distances lap / desk:", mean(stochastic_lptp_dose_df$lptp_dist_lap), "/",
    mean(stochastic_lptp_dose_df$lptp_dist_desk), " (expected ~200 / ~450)\n")
cat("mean power 2.4 / 5 GHz:", mean(stochastic_lptp_dose_df$lptp_2400_pwr), "/",
    mean(stochastic_lptp_dose_df$lptp_5000_pwr),
    " (expected ~79 / ~158: the trunc_lognormal is cut off at its own mean)\n")

# Both distances must stay inside their drawn bounds.
stopifnot(all(stochastic_lptp_dose_df$lptp_dist_lap  >= 120),
          all(stochastic_lptp_dose_df$lptp_dist_lap  <= 350),
          all(stochastic_lptp_dose_df$lptp_dist_desk >= 250),
          all(stochastic_lptp_dose_df$lptp_dist_desk <= 800))


#==============================================================================
# Deterministic cross check against a hand computation
#==============================================================================
# Runs laptop_dose() on the raw template (no simulation) and compares it with
# the value computed by hand from the yaml. This checks the whole chain: dummy
# resolution, belly mean, the two distance corrections, the brain hypotenuse,
# the lap/table mix, activity mix, band mix and the /1000.

template_params <- load_params(version = "_template")
dur <- template_params$global$input_stoch$lptp_duration
d_low     <- dur$lptp_dur_low
d_lowmed  <- dur$lptp_dur_lowmed
d_medhigh <- dur$lptp_dur_medhigh
d_high    <- dur$lptp_dur_high
d_total   <- d_low + d_lowmed + d_medhigh + d_high

ref_body  <- laptop_dose("body",  d_low, d_lowmed, d_medhigh, d_high, template_params)
ref_brain <- laptop_dose("brain", d_low, d_lowmed, d_medhigh, d_high, template_params)

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

d_lap  <- template_params$devices$lptp$lptp_distance$lptp_dist_lap
d_desk <- template_params$devices$lptp$lptp_distance$lptp_dist_desk
lap_p  <- template_params$global$input_stoch$lptp_position$lptp_lap_prop
hh     <- template_params$devices$call$Duke$height/2

# body: the plain horizontal distance. brain: the hypotenuse of that distance
# and half the body height, because the device sits at torso level while the
# head is above it -- the same construction as mobiledata and gaming.
f_body  <- function(d) ((200 + 6)/(d + 6))^2
f_brain <- function(d) ((sqrt(hh^2 + 200^2) + 6)/(sqrt(hh^2 + d^2) + 6))^2

# activity shares -- the power depends on the mix, not on the absolute durations
act <- c(low = d_low, lowmed = d_lowmed, medhigh = d_medhigh, high = d_high)/d_total

hand_pwr <- function(freq) {
  sum(vapply(names(act), \(a)
    act[[a]] * template_params$devices$lptp$dutycycle[[
      paste0("lptp_", freq, "_", a, "_dutycycle")]],
    numeric(1))) * template_params$devices$lptp$pwr[[paste0("lptp_", freq, "_pwr")]]
}

hand <- function(tissue) {
  f <- if (tissue == "body") f_body else f_brain
  sum(vapply(c(2400, 5000), function(fr) {
    s <- mean_belly_sar(tissue, fr)
    template_params$global$wifi_probs[[paste0("wifi_", fr, "_prop")]] * hand_pwr(fr) *
      (lap_p * s * f(d_lap) + (1 - lap_p) * s * f(d_desk))
  }, numeric(1))) * d_total / 1000
}

cat("\n--- deterministic cross check ---------------------------------------\n")
cat("belly mean sar Duke body  2400 / 5000:", mean_belly_sar("body", 2400), "/",
    mean_belly_sar("body", 5000), "\n")
cat("belly mean sar Duke brain 2400 / 5000:", mean_belly_sar("brain", 2400), "/",
    mean_belly_sar("brain", 5000), "\n")
cat("distance factors body  lap / desk:", f_body(d_lap),  "/", f_body(d_desk),  "\n")
cat("distance factors brain lap / desk:", f_brain(d_lap), "/", f_brain(d_desk), "\n")
cat("laptop_dose body :", ref_body,  " hand:", hand("body"),  "\n")
cat("laptop_dose brain:", ref_brain, " hand:", hand("brain"), "\n")

stopifnot(isTRUE(all.equal(ref_body,  hand("body"),  tolerance = 1e-8)))
stopifnot(isTRUE(all.equal(ref_brain, hand("brain"), tolerance = 1e-8)))

# LAPTOP-SPECIFIC INVARIANT: the lap distance equals the 200 mm at which the
# belly scenario was simulated, so that position must come through the distance
# correction completely unchanged, for both tissues.
stopifnot(isTRUE(all.equal(f_body(200),  1, tolerance = 1e-12)))
stopifnot(isTRUE(all.equal(f_brain(200), 1, tolerance = 1e-12)))
cat("lap at 200 mm is the simulation reference, factor exactly 1: OK\n")

# Cross check that switching off the distance correction returns the raw belly
# mean, independent of the lap/table mix
no_dist_params <- template_params
no_dist_params$global$dist_correction <- FALSE
stopifnot(isTRUE(all.equal(laptop_sar("body", 2400, no_dist_params),
                           mean_belly_sar("body", 2400), tolerance = 1e-12)))
cat("dist_correction = FALSE falls back to the uncorrected belly mean: OK\n")

# INVARIANT: the output power depends on the activity MIX, the dose on the total
# duration. Scaling all four durations by the same factor must scale the dose by
# exactly that factor.
k <- 3
scaled <- laptop_dose("body", k*d_low, k*d_lowmed, k*d_medhigh, k*d_high,
                      template_params)
stopifnot(isTRUE(all.equal(scaled, k*ref_body, tolerance = 1e-10)))
cat("dose scales linearly with duration at a fixed activity mix: OK\n")

# INVARIANT: the brain reacts far less to the device distance than the body,
# because the head is about 90 cm away regardless. If anyone drops the
# hypotenuse, the two factors become equal and this breaks.
stopifnot(f_brain(d_desk) > 3 * f_body(d_desk))
cat("brain distance factor is much flatter than the body one: OK\n")

# INVARIANT: no usage at all must give exactly zero and must not error.
stopifnot(laptop_dose("body", 0, 0, 0, 0, template_params) == 0)
cat("zero duration gives zero dose without error: OK\n")

# PHYSICS GUARD RAIL: whole-body SAR times body mass is the fraction of the
# radiated power that is absorbed and cannot exceed 1.
# Masses are IT'IS Virtual Population figures; they are NOT stored in the repo.
mass <- c(Duke = 70.2, Ella = 57.3, Thelonious = 18.6, Eartha = 29.0)
cat("\nabsorbed fraction of the radiated power (must be < 1):\n")
for (dm in names(mass)) {
  p <- template_params
  p$global$input_stoch$sex <- if (dm %in% c("Duke","Thelonious")) "male" else "female"
  p$global$input_stoch$age <- if (dm %in% c("Duke","Ella")) "adult" else "child"
  frac <- laptop_sar("body", 2400, p) * mass[[dm]] / 1000
  cat(sprintf("  %-11s %.4f\n", dm, frac))
  stopifnot(frac < 1)
}
