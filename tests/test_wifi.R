# Run with devtools::load_all(): simulate_params() and load_tissue_params() are
# internal functions.
#
# WiFi is an ambient source like far field: a power density times how much of
# it the body absorbs, times the time spent in the field. No device against the
# body, no distance correction, no usage duration to draw. What varies between
# draws is the phantom, where the day is spent, and the split between the two
# bands.

n <- 2000
param_simulations <- lapply(seq_len(n), function(i) {
  out <- simulate_params(sex = "male", age = "adult", simulation = "_template")
  out$global$sim <- paste0("sim", i)
  if (i %% 200 == 0) print(i)
  out
})

stochastic_wifi_dose <- lapply(seq_along(param_simulations), function(i) {
  p  <- param_simulations[[i]]
  tt <- p$global$environment_prop$travel_prop * 86400
  wp <- p$global$input_stoch$wifi_environment_probs$mpd_wifi_prop_travel
  data.frame(
    sim   = i,
    body  = wifi_dose("body",  tt, wp, p),
    brain = wifi_dose("brain", tt, wp, p),
    prop2 = p$global$wifi_probs$wifi_2450_prop,
    tt    = tt
  )
})
d <- do.call(rbind, stochastic_wifi_dose)

op <- par(mfrow = c(2, 2))
hist(d$body,  breaks = 40, main = "WiFi, whole body", xlab = "mJ/kg/day")
hist(d$brain, breaks = 40, main = "WiFi, brain",      xlab = "mJ/kg/day")
hist(d$prop2, breaks = 40, main = "2.4 GHz band share", xlab = "proportion")
plot(d$prop2, d$body, pch = 16, cex = .3,
     main = "dose against band share", xlab = "2.4 GHz share", ylab = "mJ/kg/day")
par(op)

cat("\n--- drawn inputs ------------------------------------------------------\n")
cat(sprintf("mean 2.4 GHz band share: %.3f  (expected ~0.58)\n", mean(d$prop2)))
cat(sprintf("mean travel time: %.0f s  (expected ~%.0f)\n", mean(d$tt), 0.02 * 86400))
cat(sprintf("dose, whole body: median %.3f  range %.3f - %.3f\n",
            median(d$body), min(d$body), max(d$body)))

# =============================================================================
# deterministic cross check on the template point values
# =============================================================================
template_params <- load_params(version = "_template")

hand_dose <- function(dummy, tissue, travel_time, wifi_prop_travel) {
  tp <- load_tissue_params(template_params, "call", tissue, dummy)
  lp <- location_props(travel_time,
                       template_params$global$environment_prop$home_prop,
                       template_params$global$environment_prop$work_prop,
                       template_params$global$environment_prop$outd_prop)
  dur <- 86400 * (lp$home + lp$work + lp$travel * wifi_prop_travel)
  msar <- sum(vapply(c("2450", "5000"), function(b) {
    template_params$devices$wifi[[paste0("wifi_", b, "_pwr")]] *
      tp[[paste0(dummy, "_", tissue, "_goliat_", b, "_farfield_sar")]] / 1000 *
      template_params$global$wifi_probs[[paste0("wifi_", b, "_prop")]]
  }, numeric(1)))
  dur * msar
}

cat("\n--- deterministic cross check -----------------------------------------\n")
for (dm in c("Duke", "Ella", "Thelonious", "Eartha")) {
  p <- template_params
  p$global$input_stoch$sex <- if (dm %in% c("Duke", "Thelonious")) "male" else "female"
  p$global$input_stoch$age <- if (dm %in% c("Duke", "Ella")) "adult" else "child"
  for (tis in c("body", "brain")) {
    got  <- wifi_dose(tis, 600, 0.31, p)
    want <- hand_dose(dm, tis, 600, 0.31)
    cat(sprintf("  %-11s %-5s %8.4f  hand: %8.4f\n", dm, tis, got, want))
    stopifnot(isTRUE(all.equal(got, want, tolerance = 1e-12)))
  }
}
cat("wifi_dose matches the hand calculation: OK\n")

# INVARIANT: children absorb more per kilogram than adults. Before 2026-09-29
# every phantom got the same scalar.
sar_of <- function(sx, ag, band) {
  p <- template_params
  p$global$input_stoch$sex <- sx; p$global$input_stoch$age <- ag
  wifi_sar("body", band, p)
}
for (b in c("2450", "5000")) {
  stopifnot(sar_of("male", "child", b)   > sar_of("male", "adult", b))
  stopifnot(sar_of("female", "child", b) > sar_of("female", "adult", b))
}
cat("both children absorb more per kg than the matching adult, in both bands: OK\n")

# INVARIANT: wifi and farfield must read the same SAR table. They are different
# fields but the same body, so the absorption per unit power density is the
# same quantity; a divergence would mean one of them picked up a stale key.
p <- template_params
ff_bands <- c("2450", "5000")
for (b in ff_bands) {
  tp <- load_tissue_params(p, "call", "body", "Duke")
  stopifnot(isTRUE(all.equal(
    wifi_sar("body", b, p),
    tp[[paste0("Duke_body_goliat_", b, "_farfield_sar")]] / 1000,
    tolerance = 1e-12)))
}
cat("wifi_sar reads the same far-field table as farfield_sar: OK\n")

# INVARIANT: no travel WiFi use must shorten the exposure, never lengthen it.
stopifnot(wifi_dose("body", 3600, 0.0, template_params) <
          wifi_dose("body", 3600, 1.0, template_params))
cat("using WiFi while travelling increases the dose: OK\n")

# INVARIANT: the function must work on a simulated parameter set. Until
# 2026-09-29 it read keys that exist only in the legacy params.yaml and failed
# here; it was the last source in that state.
s <- simulate_params(sex = "male", age = "adult", simulation = "_template")
out <- wifi_dose("body", s$global$environment_prop$travel_prop * 86400,
                 s$global$input_stoch$wifi_environment_probs$mpd_wifi_prop_travel, s)
stopifnot(is.numeric(out), length(out) == 1, !is.na(out), out > 0)
cat("runs on a simulated parameter set: OK\n")

cat("\nNOTE: the power densities are HERMES3 point values, not drawn -- the\n")
cat("parameter workbook lists no spread for them. And the SAR is a far-field\n")
cat("value used for a source in the room; see doc/wifi_stochastification.md.\n")
