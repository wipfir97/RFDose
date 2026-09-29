# Run with devtools::load_all(): simulate_params() and load_tissue_params() are
# internal functions.
#
# Far field differs from every other source in the model: there is no device,
# no output power and no usage duration. The dose is the ambient power density
# the person sits in, times how much of it the body absorbs, times the whole
# day. What varies between draws is where the day is spent, how urban the
# surroundings are, and the frequency composition of the ambient field.

n <- 2000
param_simulations <- lapply(seq_len(n), function(i) {
  out <- simulate_params(sex = "male", age = "adult", simulation = "_template")
  out$global$sim <- paste0("sim", i)
  if (i %% 200 == 0) print(i)
  out
})

stochastic_farf_dose <- lapply(seq_along(param_simulations), function(i) {
  p <- param_simulations[[i]]
  tt <- p$global$environment_prop$travel_prop * 86400
  data.frame(
    sim         = i,
    body        = farfield_dose("body",  "CH", tt, p),
    brain       = farfield_dose("brain", "CH", tt, p),
    pwr         = farfield_pwr("CH", tt, p),
    travel_time = tt,
    urb_prop    = p$global$input_stoch$urbanicity$urb_prop
  )
})
d <- do.call(rbind, stochastic_farf_dose)

op <- par(mfrow = c(2, 2))
hist(d$body,  breaks = 40, main = "far field, whole body", xlab = "mJ/kg/day")
hist(d$brain, breaks = 40, main = "far field, brain",      xlab = "mJ/kg/day")
hist(d$pwr,   breaks = 40, main = "ambient power density", xlab = "mW/m2")
plot(d$urb_prop, d$body, pch = 16, cex = .3,
     main = "dose against urbanicity", xlab = "urban proportion", ylab = "mJ/kg/day")
par(op)

cat("\n--- drawn inputs ------------------------------------------------------\n")
cat(sprintf("mean travel time: %.0f s  (expected ~%.0f, travel_prop_mean 0.02)\n",
            mean(d$travel_time), 0.02 * 86400))
cat(sprintf("mean urban proportion: %.3f  (expected ~0.4)\n", mean(d$urb_prop)))
cat(sprintf("ambient power density: %.3f mW/m2  (range %.3f - %.3f)\n",
            mean(d$pwr), min(d$pwr), max(d$pwr)))

# =============================================================================
# deterministic cross check on the template point values
# =============================================================================
template_params <- load_params(version = "_template")
BANDS <- c("450", "700", "800", "900", "1800", "2100", "2450", "2600", "3500", "5000")

hand_sar <- function(dummy, tissue) {
  tp <- load_tissue_params(template_params, "call", tissue, dummy)
  sum(vapply(BANDS, function(b) {
    template_params$devices$farf$ff_freq_props[[paste0("frq", b, "_ff_prop")]] *
      tp[[paste0(dummy, "_", tissue, "_goliat_", b, "_farfield_sar")]]
  }, numeric(1))) / 1000
}

cat("\n--- deterministic cross check -----------------------------------------\n")
cat("spectrum-weighted far-field SAR (W/kg per W/m2), per phantom:\n")
for (dm in c("Duke", "Ella", "Thelonious", "Eartha")) {
  p <- template_params
  p$global$input_stoch$sex <- if (dm %in% c("Duke", "Thelonious")) "male" else "female"
  p$global$input_stoch$age <- if (dm %in% c("Duke", "Ella")) "adult" else "child"
  for (tis in c("body", "brain")) {
    got  <- farfield_sar(tis, p)
    want <- hand_sar(dm, tis)
    cat(sprintf("  %-11s %-5s %.6f  hand: %.6f\n", dm, tis, got, want))
    stopifnot(isTRUE(all.equal(got, want, tolerance = 1e-12)))
  }
}
cat("farfield_sar matches the hand calculation: OK\n")

# INVARIANT: the spectrum must sum to 1, otherwise the weighted SAR is not a
# weighted average and the whole construction is meaningless.
w <- unlist(template_params$devices$farf$ff_freq_props)
stopifnot(isTRUE(all.equal(sum(w[grepl("^frq", names(w))]), 1, tolerance = 1e-12)))
cat("the ten spectrum weights sum to 1: OK\n")

# INVARIANT: children absorb more per kilogram than adults. This is the whole
# point of resolving by phantom -- before 2026-09-29 every phantom got the
# adult value.
sar_of <- function(sx, ag) {
  p <- template_params
  p$global$input_stoch$sex <- sx; p$global$input_stoch$age <- ag
  farfield_sar("body", p)
}
stopifnot(sar_of("male", "child")   > sar_of("male", "adult"))
stopifnot(sar_of("female", "child") > sar_of("female", "adult"))
cat("both children absorb more per kg than the matching adult: OK\n")

# INVARIANT: supplying an urbanicity must reproduce picking that level alone.
p <- simulate_params(sex = "male", age = "adult", urbanicity = "rural",
                     simulation = "_template")
stopifnot(p$global$input_stoch$urbanicity$rur_prop == 1)
rural_pwr <- farfield_pwr("CH", 600, p)
lp <- location_props(600, p$global$environment_prop$home_prop,
                     p$global$environment_prop$work_prop,
                     p$global$environment_prop$outd_prop)
hand_pwr <- lp$home * p$devices$farf$home_rur_pwr_CH +
            lp$work * p$devices$farf$work_rur_pwr_CH +
            lp$out  * p$devices$farf$out_rur_pwr_CH +
            lp$travel * p$devices$farf$travel_pwr_CH
stopifnot(isTRUE(all.equal(rural_pwr, hand_pwr, tolerance = 1e-12)))
cat("a supplied urbanicity reduces to that single level: OK\n")

# INVARIANT: more time travelling must not change the total time budget.
for (tt in c(0, 600, 3600)) {
  lp <- location_props(tt, 0.69, 0.21, 0.08)
  stopifnot(isTRUE(all.equal(sum(unlist(lp)), 0.98, tolerance = 1e-12)))
}
cat("the location proportions keep their total as travel time varies: OK\n")

cat("\nNOTE: the exposure levels are point values, not drawn. The parameter\n")
cat("workbook specifies Gamma distributions but leaves every mean empty, and\n")
cat("its environment scheme differs from the one in the code -- see\n")
cat("doc/OPEN_QUESTIONS.md C9 and B1.\n")
