# Stochastification of the VR headset exposure source

**Date:** 2026-09-15
**Code:** `R/virtual_reality.R`, draws in `R/distributions.R`, parameters in
`inst/extdata/params_stochastic.yaml` and `params_template.yaml`, test in `tests/test_vr.R`

**What it models:** RF-EMF exposure from a VR headset connected over WiFi, at 2.4 and 5 GHz.

---

## Before

The deterministic version multiplied four fixed numbers — output power × duty cycle × one SAR
value per band × duration — weighted by the WiFi band split and scaled by the fraction of headset
time spent online. Every input was a point value, identical for every participant, and the SAR did
not distinguish body model, device position or distance.

It also carried a latent bug: it read `params$global$wifi_2_prop`, a key that exists in
`params.yaml` but **not** in `params_template.yaml`. Handed a simulated parameter set it would have
returned a dose of exactly zero, silently. Verified: `vr_dose("brain", 1800, template)` was 0.

---

## The proxy decision — the substantive part of this conversion

There is no headset-specific SAR simulation. The GOLIAT campaign provides exactly three antenna
geometries (see `doc/SAR_IMPORT_NOTES.md` §1b):

| scenario | separation |
|---|---|
| Front of eyes | 20 cm |
| Belly | 20 cm |
| Ear | 0.8 cm |

A headset has to borrow one of them. The predecessor's note in the file pointed to **front of
eyes**, which is anatomically where a headset sits. That turns out to be the wrong choice, for
three independent reasons.

**1. Energy conservation rules it out.** Whole-body SAR × body mass is the fraction of the radiated
power the body absorbs, and cannot exceed 1. Rescaling the front-of-eyes values from 20 cm down to
a headset standoff gives, at 2.4 GHz:

| phantom | front of eyes @ 20 mm | ear @ 15 mm |
|---|---|---|
| Duke | **522 %** | 32 % |
| Ella | **494 %** | 26 % |
| Thelonious | **501 %** | 22 % |
| Eartha | **514 %** | 26 % |

The front-of-eyes proxy is non-physical at any distance below about 52 mm, which is not a headset
standoff. (Body masses are IT'IS Virtual Population figures: 70.2 / 57.3 / 18.6 / 29.0 kg. They are
not stored in the repo.)

**2. It is internally inconsistent.** Rescaled to 15 mm, the front-of-eyes values come out 11–16×
**higher** than the ear values for whole body — even though 15 mm is *further* from the head than
the 8 mm at which the ear scenario was simulated. A source further away cannot deposit an order of
magnitude more energy than one closer in.

**3. The deterministic model already used the ear.** Its `vr_*_sar` values are the
`wifi_*_ear_sar` values rounded to six digits:

```
params.yaml:195  wifi_2_ear_sar: 0.026727749     vs  vr_2_sar: 0.026728   (brain)
params.yaml:200  wifi_5_ear_sar: 0.001040371     vs  vr_5_sar: 0.001040   (brain)
params.yaml:250  wifi_2_ear_sar: 0.010022773     vs  vr_2_sar: 0.010023   (body)
params.yaml:255  wifi_5_ear_sar: 0.006538522     vs  vr_5_sar: 0.006539   (body)
```

So using the ear positions is continuity with the previous model, not a deviation from it.

**What the ear proxy costs:** the source sits beside the temple rather than at the forehead, so the
SAR distribution inside the head is not the same as a real headset's. That error is a multiplicative
constant we cannot bound without a headset simulation. It is the price of being in the right
distance regime, and it is the better trade.

---

## What changed

**1. SAR comes from the phantom-resolved tables.** `determine_dummy(sex, age)` selects Duke, Ella,
Thelonious or Eartha, and the SAR is the arithmetic mean of the six ear positions (cheek1–3,
tilt1–3) at 2400 / 5000 MHz. The mean is **unweighted**, unlike `mobilecall` and `cordless` which
weight the same positions with Dirichlet-drawn proportions — there the weights represent how people
actually hold a phone, here the positions are a stand-in for an unknown headset geometry.

**2. Distance is modelled explicitly, with one factor for both tissues.** `dist_law()` rescales from
the 8 mm ear reference to a drawn standoff. Unlike gaming there is **no hypotenuse**: gaming's
console sits at torso height, so moving it changes the trunk distance a lot and the head distance
hardly at all, which needs two separate geometries. A headset is worn on the head, so there is only
one distance and it applies to both channels.

**3. Seven quantities are drawn from distributions** instead of being fixed:

| quantity | distribution | central value |
|---|---|---|
| usage duration | hurdle gamma, 95 % zeros | 100 s population mean |
| online fraction | Beta | 0.4 |
| output power, 2.4 / 5 GHz | truncated lognormal, capped at the EU EIRP limits | 100 / 200 mW |
| duty cycle, 2.4 / 5 GHz | Beta | 0.05 / 0.05 |
| antenna-to-head standoff | truncated lognormal, bounded 8–30 mm | 15 mm |

The WiFi band split (`global$wifi_probs`) was already stochastic and is now read from the correct
parameter. The phantom is drawn only when `sex`/`age` are not supplied; when they are, they are
fixed across all simulations.

**4. Unit correction.** The dose is divided by 1000, because the phantom SAR tables are in mW/kg
per watt. The deterministic version omitted this.

**5. Structure.** VR is its own column (`vrhs_dose`) in the model output instead of being summed
into "other sources".

---

## Effect on the numbers

Reference case: 100 s of use, 15 mm standoff, 40 % online, template point values.

| phantom | height (mm) | body | brain |
|---|---|---|---|
| Duke (adult male) | 1770 | 1.035 | 3.488 |
| Ella (adult female) | 1630 | 1.005 | 1.816 |
| Eartha (girl) | 1360 | 2.006 | 0.950 |
| Thelonious (boy) | 1160 | 2.671 | 1.948 |

Scaled to a 30-minute session so it can be compared with the other sources, Duke: body 18.6,
brain 62.8 mJ/kg/day. Against cordless (21.0 / 125.1) and gaming (0.32 / 0.011) at their own
reference durations, VR sits below a DECT handset and well above a handheld console — which is what
a head-worn transmitter should do.

Old versus new, Duke, both at 1800 s: the deterministic model gave 40.7 / 59.0, the new one gives
18.6 / 62.8. The brain dose is almost unchanged and the body dose roughly halves. Given that the
data source, the units and the distance treatment all changed, that closeness is reassuring rather
than expected.

---

## Validation

- Deterministic cross-check of the whole chain — phantom lookup, ear-position mean, distance law,
  band mix, unit conversion — against an independent hand computation, to within 1e-8.
- 2000 simulated draws checked against their target distributions: 94.75 % zero durations against a
  target of 95 %, standoff 15.07 mm against 15, online fraction 0.404 against 0.4, power
  79.3 / 157.8 mW (the truncated lognormal is deliberately cut at the regulatory cap, so its
  realised mean sits below the nominal 100 / 200).
- Switching the distance correction off returns exactly the uncorrected 8 mm ear mean.
- **VR-specific invariant:** because both tissues share one distance factor, the brain/body dose
  ratio must not depend on the standoff. Measured at 8 / 15 / 20 / 30 mm it is 3.369347 throughout.
  If anyone reintroduces a hypotenuse for the brain, this test fails.
- **Physics guard rail:** the absorbed-power check that ruled out the front-of-eyes proxy is now a
  permanent assertion in the test. Current values 0.22–0.32 for the four phantoms.

---

## Assumptions to be revisited

Four numbers here are placeholders. None of them is backed by a measurement, and all four are plain
yaml values that can be replaced without touching code. They should be discussed together once the
whole model is stochastic.

**Usage duration** — `pzero` 0.95 with a population mean of 100 s, giving a conditional mean of
about 33 minutes on days a headset is used. `vr_duration` is 0 in every default file, so this source
has never contributed anything and there is nothing to calibrate against. No literature figures are
known to us. Duration enters the dose linearly and is by far the strongest driver, so this is the
assumption that most determines how large the VR contribution looks.

**Duty cycle** — 0.05 for both bands, carried over unchanged from the deterministic model. For
context, the measured WiFi duty cycles elsewhere in the model are 0.02738 / 0.04385 for a mobile
call, and the activity-dependent values for laptop, tablet and mobile data span 0.009 (low) to 0.67
(high) at 2.4 GHz. The VR value therefore already sits above the other single-value devices, which
suggests somebody allowed for a headset being more data-intensive — but that is not documented. A
tethered headset streaming video would belong in the high-activity class; a standalone one would
not. Modelling the two as separate modes with a mixing proportion would be the cleaner solution.

**Duty-cycle concentration `a0`** — set to 100. The WiFi duty cycles elsewhere carry fitted
concentration parameters (134.9, 4657.6, 355.76, 1.41, 7.64), so 100 is a round default copied from
cordless and gaming rather than anything derived.

**Antenna-to-head standoff** — 15 mm mean, assumed from the geometry of typical side housings. The
*bounds* are better founded than the mean: 8 mm because that is the simulated reference and we do
not extrapolate closer, 30 mm because of the exponent problem below.

---

## Known limitation: the distance exponent is too steep

`dist_law()` assumes an inverse-square falloff. Fitted through the two simulated anchors we actually
have (ear at 8 mm, front of eyes at 200 mm), the empirical exponent is:

| phantom | whole body | brain |
|---|---|---|
| Duke | 0.80 | 1.49 |
| Ella | 0.74 | 1.17 |
| Thelonious | 0.67 | 0.71 |
| Eartha | 0.73 | 0.65 |

Never 2. Over the VR standoff range this means the model under-states the dose, increasingly so at
larger standoffs — by a factor of about 1.7 at 15 mm and 3.3 at 30 mm relative to an exponent of
0.75. This is why the standoff range is kept narrow.

Two caveats on that fit: the two anchors differ in position as well as distance (beside the ear
versus in front of the face), so it conflates the two effects; and it is a two-point fit.

**This is not a VR-specific problem.** The same exponent is used by `mobilecall`, `mobiledata`,
`cordless` and `gaming`. Where it is applied over a short distance change the error is small — for
gaming, 200 → 300 mm. Where it is applied aggressively it is not: `mobilecall.R:537` and `:989`
rescale the belly SAR from 200 mm to a hard-coded 8 mm, a factor of 216, for the phone-in-pocket
case. That is the same construction rejected above for VR, and it is already in production.
Generalising `dist_law()` with a fitted exponent per tissue would be a model-wide change and should
be decided separately.
