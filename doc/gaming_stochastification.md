# Stochastification of the gaming exposure source

**Date:** 2026-09-14
**Code:** `R/gaming.R`, draws in `R/distributions.R`, parameters in
`inst/extdata/params_stochastic.yaml` and `params_template.yaml`, test in `tests/test_gaming.R`

**What it models:** RF-EMF exposure from **portable (handheld) gaming consoles** connected over
WiFi, at 2.4 and 5 GHz.

---

## Before

The deterministic version multiplied four fixed numbers — output power × duty cycle × one SAR value
per band × duration — weighted by the WiFi band split and scaled by the fraction of gaming time
spent online. Every input was a point value, identical for every participant. The SAR values were
not gaming-specific: they were copied verbatim from the tablet source, and they distinguished
neither body model, nor device position, nor distance.

## What changed

**1. SAR now comes from the phantom-resolved simulation tables.** `determine_dummy(sex, age)`
selects Duke, Ella, Thelonious or Eartha, and the SAR is taken as the arithmetic mean of the eight
belly positions at 2400 / 5000 MHz. Since no console-specific simulation exists, the belly positions
serve as a proxy for a device held in front of the torso — a reasonable stand-in for a handheld
console, which is typically held at lap or chest height. This replaces the borrowed tablet values
and makes the gaming dose depend on sex and age.

**2. Distance is modelled explicitly.** The belly simulations were run at 200 mm. `dist_law()`
rescales the SAR to a device-to-body distance drawn per simulation (truncated lognormal, mean
300 mm, sd 100, range 100–800 mm), covering everything from a console resting against the body to
one held at arm's length. For brain tissue the distance is the hypotenuse √((height/2)² + d²),
because the console is held in front of the trunk and is therefore further from the head than from
the body — the same geometry `mobiledata` uses for a phone at belly height.

**3. Five quantities are now drawn from distributions** instead of being fixed:

| quantity | distribution | central value |
|---|---|---|
| gaming duration | hurdle gamma, 80 % zeros | 600 s population mean |
| online fraction | Beta | 0.25 |
| output power, 2.4 / 5 GHz | truncated lognormal, capped at the EU EIRP limits | 100 / 200 mW |
| duty cycle, 2.4 / 5 GHz | Beta | 0.020 / 0.028 |
| device-to-body distance | truncated lognormal | 300 mm |

The WiFi band split was already stochastic. It is now read from the correct parameter: the old code
referenced a key that does not exist in the simulated parameter file and would have silently
produced a dose of zero once handed a Monte Carlo parameter set.

**4. Unit correction.** The dose is now divided by 1000, because the phantom SAR tables are given in
mW/kg per watt. The deterministic version omitted this.

**5. Structure.** Gaming is now reported as its own column in the model output instead of being
summed into "other sources", so its uncertainty can be examined separately.

## Effect on the numbers

Reference case: 600 s of gaming, 300 mm distance, 25 % online, template point values.

| | body | brain |
|---|---|---|
| deterministic (old) | 0.357 | 0.231 |
| stochastic (Duke) | **0.324** | **0.0111** |

The body dose is essentially unchanged (−9 %). The brain dose falls by a factor of 21. The two
channels move differently because the ÷1000 and the roughly 2000× larger phantom-resolved SAR values
largely cancel, leaving the distance correction — and that correction is much weaker for the brain
(factor 0.94 at 300 mm) than for the body (factor 0.45), since the head is already far from a device
held at torso height.

Because SAR is now phantom-resolved, the dose also differs by body model — which the deterministic
version could not express at all:

| phantom | height (mm) | body | brain |
|---|---|---|---|
| Duke (adult male) | 1770 | 0.324 | 0.0111 |
| Ella (adult female) | 1630 | 0.401 | 0.0285 |
| Eartha (girl) | 1360 | 0.686 | 0.107 |
| Thelonious (boy) | 1160 | 0.944 | 0.201 |

Children absorb roughly 2–3× the whole-body dose and up to 18× the brain dose of the adult male at
the same usage — the expected consequence of smaller body mass and a smaller head closer to the
device.

## Validation

- A deterministic cross-check reproduces the entire chain — phantom lookup, position averaging,
  distance law, band mix and unit conversion — against an independent hand computation to within
  1e-8.
- The parameter draws were verified over 500–1000 simulations against their target distributions:
  realised mean device distance 302 mm against a target of 300, 82 % zero durations against a target
  of 80 %, online fraction 0.256 against 0.25, output power 79.6 / 157.3 mW (the truncated lognormal
  is deliberately cut at the regulatory cap, so its realised mean sits below the nominal 100 / 200).
- Switching the distance correction off returns exactly the uncorrected belly mean.

## Assumptions worth flagging

- **The belly positions stand in for the console geometry.** No console-specific simulation exists.
  The proxy is defensible for a handheld device held in front of the torso, but a dedicated
  simulation would be better.
- **The 300 mm mean distance is an assumption**, based on typical handheld viewing distance, not a
  measurement.
- **The brain geometry reuses the standing-posture belly-to-head offset** (height/2, 885 mm for
  Duke). For a seated player looking down at a console this is an approximation.
- **SAR at 700–900 MHz carries large simulation uncertainty** (see `doc/SAR_IMPORT_NOTES.md` §5).
  This does not affect gaming, which only uses the 2400 and 5000 MHz bands.
