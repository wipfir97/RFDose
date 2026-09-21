# Stochastification of the tablet exposure source

**Date:** 2026-09-16
**Code:** `R/tablet.R`, draws in `R/distributions.R`, wiring in `R/total.R`, parameters in
`inst/extdata/params_stochastic.yaml` and `params_template.yaml`, tests in `tests/test_tablet.R`
and `tests/testthat/test-tablet.R`

**What it models:** RF-EMF exposure from a tablet connected over WiFi, at 2.4 and 5 GHz.

---

## Before

The deterministic version multiplied fixed numbers — output power × duty cycle × one SAR value per
band × duration — weighted by the WiFi band split, with the duty cycle selected by the mix of four
usage-intensity classes. Every input was a point value, identical for every participant, and the
SAR did not distinguish body model, device position or distance.

It carried the same latent bug as gaming and VR: it read `params$global$wifi_2_prop`, a key that
exists in `params.yaml` but in neither `params_template.yaml` nor `params_stochastic.yaml`. Handed a
simulated parameter set, `tablet_dose()` did not silently return zero as `vr_dose()` did — it
**errored** (`vapply: values must be length 1, but FUN(X[[1]]) result is length 0`), because the
NULL propagated into a zero-length product. The source was therefore unreachable from the stochastic
pipeline and only ever ran on `params.yaml`.

The shipped testthat reference values were also already stale. `tests/testthat/test-tablet.R`
expected `tablet_dose(brain) = 12.19`, but the HEAD code on `params.yaml` returns 14.68 — 20 % off,
well outside the file's own 1 % tolerance. The `tablet_sar` expectations (0.000999, 0.000163,
0.000861, 0.000586) are the values from `params_template.yaml`, while the calls they check ran
against `params.yaml`, which holds different numbers. The two files disagree on the tablet SAR by a
factor of 1.12 (brain 2.4 GHz) and 1.96 (brain 5 GHz) with nothing explaining it — the same
unexplained divergence already recorded for VR in `doc/MODEL_LIMITATIONS.md` §E.

---

## The position decision

There is no tablet-specific SAR simulation. The GOLIAT campaign provides three antenna geometries:
front of eyes (20 cm), belly (20 cm), ear (0.8 cm). A tablet has to borrow one.

**Decision: `front_of_eyes` throughout, at 300 mm.** Three lines of evidence agree, and it is what
was instructed.

**1. It is the geometry of the device.** A tablet is held up to be looked at. Unlike a phone it is
not carried in a pocket and not held at the belly while walking, so there is no case for mixing in
the belly positions the way `mobiledata.R` does.

**2. The deterministic model already made this choice.** Its `tblt_*_sar` values are the
`wifi_*_headp_face_sar` values — a phone held in front of the face:

| | `tblt_*_sar` | `wifi_*_headp_face_sar` |
|---|---|---|
| brain 2.4 GHz | 0.001119463 | 0.001119463 |
| brain 5 GHz | 0.000320072 | 0.000320072 |
| body 2.4 GHz | 0.000863117 | 0.000860849 |
| body 5 GHz | 0.000553633 | 0.000553633 |

Three of four are identical to the last digit; body 2.4 GHz differs by 0.26 %, which looks like a
transcription slip rather than a different derivation. Note also that the deterministic `gaming`
values are these same numbers rounded to six digits, which is how the copy-paste chain ran.

**3. The lap and table geometries belong to laptop.** `laptop.R` uses `legs` and `tabl` positions;
reusing them here would model a tablet lying flat, which is not the modelled behaviour.

### Distance

The reference for `front_of_eyes` is **200 mm** (`doc/SAR_IMPORT_NOTES.md` §1b). The modelled
viewing distance is **300 mm**. The rescaling is therefore short and **outward**, a factor of
0.4532 — the mildest application of the distance law anywhere in the model, and in its safer
direction. Compare `mobilecall.R`'s pant-pocket case, which stretches the same 200 mm reference down
to 8 mm, a factor of 216 (`doc/MODEL_LIMITATIONS.md` §A2).

The physics check confirms it. Whole-body SAR × body mass is the fraction of the radiated power that
is absorbed and cannot exceed 1:

| phantom | 2.4 GHz | 5 GHz |
|---|---|---|
| Duke | 0.038 | 0.022 |
| Ella | 0.036 | 0.027 |
| Thelonious | 0.036 | 0.020 |
| Eartha | 0.037 | 0.021 |

2–4 %, comfortably inside the bound. This is the same check that ruled the `front_of_eyes` proxy
**out** for VR, where rescaling the same values down to a headset standoff gives 493–522 % at 20 mm
and 756–800 % at the 15 mm actually modelled. The difference is entirely the direction of the
rescaling.

### Brain and body share one distance factor

Both tissues get the same factor, with no hypotenuse. `mobiledata.R` uses a hypotenuse for the brain
in its *belly* branch — the phone sits at the belly, so the brain is offset by roughly half the body
height and moving the phone forward barely changes the head separation. `gaming.R` does the same for
the same reason. Here the device is in front of the face: moving it from 200 to 300 mm increases the
separation to the head and to the torso by the same 100 mm. `mobiledata.R`'s own *front-of-face*
branch applies the plain distance law to both tissues too, so this is consistent with the existing
code. `tests/test_tablet.R` pins it down: the brain/body dose ratio must be identical at 200, 300,
400 and 500 mm.

### Unweighted mean over the eight positions

The eight `front_of_eyes` positions are averaged **unweighted**, as in `gaming.R` and
`virtual_reality.R`, rather than weighted with `phone_positions` as `mobiledata.R` does. Those
weights say a phone is held centred and portrait 60 % of the time, which is a statement about phones.
The choice barely matters: weighting shifts the mean by −6 % to +11 % depending on tissue and band,
against a spread of only 1.66× between the highest and lowest of the eight positions.

---

## What changed

| | before | after |
|---|---|---|
| SAR | one constant per band from `devices$tblt$<tissue>$tblt_<band>_sar` | mean of the 8 `front_of_eyes` positions of the resolved dummy, from the call SAR tables |
| body model | none | `determine_dummy(sex, age)` → Duke / Ella / Thelonious / Eartha |
| distance | none | `tblt_dist_device`, drawn, rescaled from the 200 mm reference by `dist_law()` |
| output power | fixed 100 / 200 mW | drawn, `trunc_lognormal` |
| duty cycles (8) | fixed | drawn, `beta` |
| durations (4) | passed through as point values | drawn, `trunc_lognormal`, mean = the observed value |
| band split | `global$wifi_2_prop` (missing outside `params.yaml`) | `global$wifi_probs$wifi_2400_prop` |
| frequency tokens | `2` / `5` | `2400` / `5000`, so the same token works for power, duty cycle and SAR lookup |
| units | none | dose divided by 1000 (mW → W), as in `cordless_dose()`, `gaming_dose()`, `vr_dose()` |
| dummy with an empty SAR table | silent zero dose | `warning()` |

`tablet_pwr()`'s first argument is renamed `band` → `freq` and now takes `"2400"`/`"5000"`;
`tablet_sar()` likewise. Both are exported, so this is a breaking change for outside callers. The
only callers in the repo are `tablet_msar()` and the testthat file.

### Parameter draws added to `simulate_params()`

The four `tblt_dur_*` entries moved out of `non_stochastic_inputs` into a `####### tablet` input
block that mirrors `mpd_duration`: if a value is supplied it becomes the mean of that individual's
lognormal, otherwise the yaml mean is used. A second `####### tablet` block in the parameter section
draws the two powers, the eight duty cycles and the distance.

### Wiring

`get_total_dose()` now reads the four durations from `sim_params$global$input_stoch$tblt_duration`
and passes `sim_params` instead of `old_params`. The `tblt_dose` column already existed, so nothing
downstream changes shape.

---

## Effect on the numbers

At the template point values (Duke, 728 / 81 / 728 / 81 s, viewing distance 300 mm):

| | deterministic (on `params.yaml`) | stochastic (template) | ratio |
|---|---|---|---|
| brain | 14.68 | 5.92 | 0.40 |
| body | 13.50 | 8.14 | 0.60 |

Two large changes nearly cancel: the dummy-resolved SAR values are about 1000× larger than the old
constants, and the dose is now divided by 1000. What remains is the distance correction (×0.4532)
and the difference between the old single constant and the new position mean. So unlike gaming
(body fell by 4.3×) and VR, the tablet dose lands in the same order of magnitude as before.

Over 2000 Monte Carlo draws (Duke fixed):

| | mean | median | p05 | p95 |
|---|---|---|---|---|
| body | 6.73 | 4.20 | 1.06 | 21.0 |
| brain | 4.81 | 2.55 | 0.55 | 16.1 |

The distribution is strongly right-skewed; mean ≈ 1.6 × median. The drivers are the four lognormal
durations (CV ≈ 0.95 each) and the two wide duty cycles described below.

---

## Validation

`tests/test_tablet.R` runs 2000 simulations and then checks, against a hand computation on the
template:

1. **Whole chain** — dummy resolution, position mean, distance law, activity mix, band mix and the
   /1000 reproduce `tablet_dose()` to 1e-8 for both tissues.
2. **`dist_correction = FALSE`** falls back exactly to the uncorrected 200 mm mean.
3. **One distance factor** — the brain/body ratio is identical at 200/300/400/500 mm (to 1e-10).
4. **Linearity in duration** — the power depends on the activity *mix*, the dose on the *total*
   duration, so tripling all four durations must triple the dose exactly. This catches a confusion
   between absolute durations and their proportions inside `tablet_pwr()`.
5. **Zero usage** gives exactly zero and does not error.
6. **Physics guard rail** — absorbed fraction < 1 for all four phantoms.

The drawn parameters were checked against their specifications over 2000 draws: durations
707 / 82 / 732 / 82 against nominal 728 / 81 / 728 / 81; distance mean 304 mm inside [200, 500];
all eight duty cycles on their means; power 79 / 158 mW against nominal 100 / 200 — the known
`mean == max` truncation (`doc/MODEL_LIMITATIONS.md` §C3).

`tests/testthat/test-tablet.R` was updated: the reference values are recomputed against the new
implementation and every case that reaches the calculation now passes `params_template.yaml`
explicitly, because the legacy `params.yaml` has neither the nested `tblt` structure nor
`global$input_stoch$sex`/`age`. The input-validation cases still call without `params`, since
`check_duration()` fires before `params` is touched. All 19 assertions pass.

---

## Assumptions to be revisited

These are placeholders. All are plain yaml values, replaceable without touching code.

| parameter | value | basis |
|---|---|---|
| `tblt_dur_*` means | 728 / 81 / 728 / 81 s | the existing defaults from `defaultvariables.yaml`, unchanged |
| `tblt_dur_*` sd | 700 / 78 / 700 / 78 | **assumed**, CV = 0.96 — the top of the 0.90–0.96 range mobiledata's three non-zero duration spreads span |
| `tblt_dist_device` | mean 300 mm, sd 80, bounds 200–500 | the 300 mm is the instruction; the spread and bounds are **assumed** |
| `tblt_*_pwr` | 100 / 200 mW | 1:1 from `wifi_2400_pwr` / `wifi_5000_pwr`; the EU EIRP limits |
| duty cycle means | the existing eight values | unchanged from the deterministic model |
| duty cycle `a0` | borrowed from mobiledata | see below |

### The distance is drawn, not fixed

"Always 30 cm in front of the face" was read as settling the *position* question — front of eyes
rather than a belly mix — not as fixing the distance to a constant. Every other source in the
stochastic model draws its distance, so the tablet draws one too, around a mean of 300 mm. Pinning
it to exactly 300 mm is a one-line change if that is what was meant.

### The borrowed duty-cycle spreads, and one that transplants badly

The eight duty cycle means come from the deterministic model and have no spread attached. The `a0`
values are taken from mobiledata's **fitted** WiFi duty cycles for the corresponding band and
activity class — the same physical quantity, and a better estimate than the round default of 100
used for cordless, gaming and VR. Seven of the eight means agree closely between the two sources:

| | tablet mean | mobiledata mean | borrowed `a0` |
|---|---|---|---|
| 2400 low | 0.009 | 0.009 | 355.76 |
| 2400 lowmed | 0.025 | 0.022 | 176.82 |
| 2400 medhigh | 0.176 | 0.138 | 1.4137 |
| 2400 high | 0.669 | 0.670 | 7.6367 |
| 5000 low | 0.03055 | 0.024 | 80.05 |
| 5000 lowmed | 0.052275 | 0.039 | 38 |
| 5000 medhigh | 0.064 | 0.054 | 26.63 |
| **5000 high** | **0.14515** | **0.495** | **0.4585** |

The last row is a bad transplant. A Beta's `a0` is not scale-free: with mean *m* the shape
parameters are *a = m·a0* and *b = (1−m)·a0*. At mobiledata's mean of 0.495 and `a0 = 0.4585` both
come out near 0.23 — a symmetric U, which is what the fit found. At the tablet mean of 0.145 they
become *a* = 0.067 and *b* = 0.392, so the draws collapse towards zero: over 2000 draws the median
is 0.00015 and 65 % of draws fall below 0.01, while the mean is still 0.145 because a thin tail
reaches 1.

The mean dose is unaffected — a Beta preserves its mean — but the variance this one parameter
injects is not physically motivated. Its weight is limited: the high-activity class is 5 % of the
modelled tablet time and the 5 GHz band 42 % of traffic, so it carries about 14 % of the 5 GHz
output power. It is left as delivered and recorded here and in `doc/MODEL_LIMITATIONS.md` §D rather
than silently replaced. Two candidate fixes when the parameters are revisited together: use the
house default `a0 = 100`, or keep the fitted spread but floor `a0` at the point where the
distribution stays unimodal (`a0 > 1/min(m, 1−m)`, i.e. `a0 > 6.9` at m = 0.145).
