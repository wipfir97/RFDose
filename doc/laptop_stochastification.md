# Stochastification of the laptop exposure source

**Date:** 2026-09-21
**Code:** `R/laptop.R`, draws in `R/distributions.R`, wiring in `R/total.R`, parameters in
`inst/extdata/params_stochastic.yaml` and `params_template.yaml`, tests in `tests/test_laptop.R`
and `tests/testthat/test-laptop.R`

**What it models:** RF-EMF exposure from a laptop connected over WiFi, at 2.4 and 5 GHz, in two
positions — on the user's lap and on a table.

---

## Before

The deterministic version multiplied fixed numbers — output power × duty cycle × one SAR value per
band and position × duration — weighted by the WiFi band split and by a fixed 20/80 lap/table share,
with the duty cycle selected by the mix of four usage-intensity classes. Every input was a point
value and the SAR did not distinguish body model or distance.

It carried the same latent bug as gaming, VR and tablet: it read `params$global$wifi_2_prop`, a key
that exists only in `params.yaml`, and **errored** on any simulated parameter set. The source was
therefore unreachable from the stochastic pipeline.

The shipped testthat reference values were also stale — they expected `laptop_dose(brain) = 2.12`
and `= 86.18` for the body, where the deterministic code on `params.yaml` returned 1.29 and 173.46.
They also used durations of 218 s where `defaultvariables.yaml` says 219.

`params.yaml` and `params_template.yaml` disagree on the legacy laptop SAR values by factors of 0.33
to 2.52, and **in opposite directions for the two tissues** — `params.yaml` is lower for the brain
and higher for the body. This is the largest of the four such divergences recorded in
`doc/MODEL_LIMITATIONS.md` §E. Both sets are retired here.

---

## The position decision

There is no laptop-specific SAR simulation in GOLIAT, which provides three antenna geometries, all
of them phone positions: front of eyes (20 cm), belly (20 cm), ear (0.8 cm).

This loss is sharper than for the other sources. Gaming and tablet turned out to be reusing the
`wifi_*_headp_face_sar` values — a phone held in front of the face — so nothing specific was given
up. **The laptop's ETAIN values are genuinely its own**: dedicated "on the lap" and "on the table"
simulations whose numbers appear nowhere else in the yaml.

**Decision: keep both positions, derive both from the belly geometry, and distinguish them only by
distance.**

### Why belly for both, and not front-of-eyes for the table case

A laptop's WiFi antennas sit in the **screen bezel**, roughly 185 mm above the base plate. In both
positions that puts the source in front of the torso at about sternum height, with a nearly
horizontal path to the body. `front_of_eyes` assumes a source at eye level directly in front of the
face; a laptop screen is neither at eye level nor that close.

The numbers confirm it. Using `front_of_eyes` for the table case raises the brain dose to 29.5
mJ/kg/day against the deterministic model's 1.29 — a factor of 23, with no physical change to
justify it. The GOLIAT `front_of_eyes_down_*` positions do not rescue this: per the parameter
workbook they sit only 4 and 10 cm below eye level, not the 30–40 cm a laptop screen sits below.

### Distances

Both derived from device and seating geometry:

| position | derivation | distance |
|---|---|---|
| **lap** | antenna 185 mm above the base plate, which rests on the thighs | **200 mm** |
| **table** | 150 mm typing gap + 220 mm base depth + 70 mm lid setback at ~105° | **450 mm** |

The lap figure is worth dwelling on: **it is the distance at which the belly scenario was
simulated**. That position therefore passes through the distance correction with a factor of exactly
1.000, for both tissues — no extrapolation at all. This is the only place in the model where a proxy
geometry is used at its own reference distance.

It also settles a concern raised in discussion, that the lap case would need an aggressive inward
rescaling like the pant-pocket substitution of §A2. It does not.

All laptop distances, and the 200 mm reference, are in the far field at both bands (2.8–6.4 λ at
2.4 GHz, 5.8–13.3 λ at 5 GHz; the reactive near field ends around 20 mm). The distance law is
therefore rescaling within a single field regime, which is the condition `doc/MODEL_LIMITATIONS.md`
§A1 identifies as missing in the ear/front-of-eyes comparison. This is the best-founded application
of `dist_law()` in the model.

Physics check — whole-body SAR × body mass, the absorbed fraction of the radiated power:

| phantom | lap @ 200 mm | table @ 450 mm |
|---|---|---|
| Duke | 0.133 | 0.027 |
| Ella | 0.120 | 0.025 |
| Thelonious | 0.100 | 0.020 |
| Eartha | 0.114 | 0.023 |

### The brain uses the hypotenuse

The device sits at torso level while the head is above it, so the brain distance is
`sqrt((height/2)² + d²)` against a reference of `sqrt((height/2)² + 200²)` — the same construction
as `mobiledata.R`'s belly branch and `gaming.R`. Moving the laptop from 200 to 450 mm changes the
body factor to 0.204 but the brain factor only to 0.836: the head is about 90 cm away either way.

### What is deliberately not modelled

A laptop is used **seated**, while the GOLIAT phantoms are standing. Two consequences were examined
and knowingly left out, in favour of keeping the implementation uniform with the other belly-proxy
sources:

- **The antenna sits higher than the belly** — about 20 cm higher in the table case. Accounting for
  it would raise the brain dose by roughly 35 %.
- **`height/2` overstates the belly-to-brain distance.** Anthropometrically the navel sits at about
  0.60 of stature and the brain centre at about 0.94, so the offset is closer to `height/3`. A
  directly derived antenna-to-brain distance comes out at 444–633 mm against the convention's
  614–988 mm, which would raise the brain dose by a factor of about 2.8.

Both are cross-cutting: they apply equally to `mobilecall`, `mobiledata` and `gaming`. They are
recorded in `doc/OPEN_QUESTIONS.md` rather than fixed for one source in isolation. The justification
for leaving them is that the brain channel through a belly proxy is the least trustworthy part of
the model — §A1 measures the bare position effect for the brain at a factor of 4.2 to 105.7 — so a
2.8× refinement sits below the noise of the method that would compute it.

---

## What changed

| | before | after |
|---|---|---|
| SAR | two constants per band (`legs`, `tabl`) from `devices$lptp$<tissue>$wifi_<band>_<pos>_sar` | mean of the 8 belly positions of the resolved dummy, rescaled twice |
| body model | none | `determine_dummy(sex, age)` → Duke / Ella / Thelonious / Eartha |
| distance | none | `lptp_dist_lap` and `lptp_dist_desk`, both drawn, rescaled from the 200 mm reference |
| brain geometry | none | hypotenuse with `height/2`, as in mobiledata and gaming |
| lap/table share | fixed 0.2 / 0.8 | `lptp_lap_prop` drawn, `beta`; the table share is 1 − it |
| output power | fixed 100 / 200 mW | drawn, `trunc_lognormal` |
| duty cycles (8) | fixed | drawn, `beta` |
| durations (4) | passed through as point values | drawn, `trunc_lognormal`, mean = the observed value |
| band split | `global$wifi_2_prop` (missing outside `params.yaml`) | `global$wifi_probs$wifi_2400_prop` |
| frequency tokens | `2` / `5` | `2400` / `5000` |
| units | none | dose divided by 1000 (mW → W) |
| dummy with an empty SAR table | silent zero dose | `warning()` |

`laptop_pwr()` and `laptop_sar()` take `freq` (`"2400"`/`"5000"`) where they took `band`
(`"2"`/`"5"`). Both are exported; the only callers in the repo are `laptop_msar()` and the testthat
file.

### The duty-cycle spreads come from the specification, not from a neighbour

The eight means are unchanged from the deterministic model. The `a0` values are computed from the
**sd values in `SDM_parameters_26062026.xlsx`** via `a0 = mean(1−mean)/sd² − 1`, for the same eight
`wifi_*_dutycycle` entries. This differs from tablet, which borrowed its `a0` from mobile data's
yaml and consequently inherited one badly transplanted value (`doc/MODEL_LIMITATIONS.md` §D1).

Two of the eight come out U-shaped — `lptp_2400_medhigh` (mean 0.176, sd 0.25, `a0` 1.32) and
marginally `lptp_5000_low`. Unlike the tablet case this is **not** a transplant artefact: the
(mean, sd) pair is the specification's own, and a coefficient of variation of 1.4 is what it states.
Left as specified.

---

## Effect on the numbers

At the template point values (1967 / 219 / 1967 / 219 s, lap 200 mm, table 450 mm, lap share 0.2):

| phantom | body | brain |
|---|---|---|
| Duke | 28.17 | 1.71 |
| Ella | 33.11 | 3.99 |
| Thelonious | 81.02 | 23.75 |
| Eartha | 59.25 | 13.45 |
| *deterministic (Duke, `params.yaml`)* | *173.46* | *1.29* |

The whole-body dose falls by a factor of 6 while the brain dose is essentially unchanged. The fall
is geometry, not a unit slip: converted to the same unit, the ETAIN lap value is 7.11 mW/kg per W
against 1.89 for the belly proxy at its 200 mm reference — the ETAIN lap scenario corresponds to the
belly geometry at roughly 100 mm, i.e. it modelled the antenna substantially closer to the body than
a screen bezel actually sits.

The phantom spread is much wider than in the far field: Thelonious receives 2.9× Duke's whole-body
dose, because he absorbs less power in absolute terms but has a quarter of the mass. The
deterministic model could not represent this at all.

Over 2000 Monte Carlo draws (Duke fixed), the distribution is strongly right-skewed — mean 25.8
against a median of 15.6 for the body — driven by the four lognormal durations and the two wide
duty cycles.

---

## Validation

`tests/test_laptop.R` runs 2000 simulations and then checks, against a hand computation on the
template:

1. **Whole chain** — dummy resolution, belly mean, both distance corrections, the brain hypotenuse,
   the lap/table mix, activity mix, band mix and the /1000 reproduce `laptop_dose()` to 1e-8.
2. **Lap at the reference** — the distance factor at 200 mm is exactly 1 for both tissues.
3. **`dist_correction = FALSE`** falls back exactly to the uncorrected belly mean.
4. **Linearity in duration** — tripling all four durations triples the dose exactly.
5. **The brain factor is much flatter than the body factor** — breaks if anyone drops the
   hypotenuse.
6. **Zero usage** gives exactly zero and does not error.
7. **Physics guard rail** — absorbed fraction < 1 for all four phantoms.

The drawn parameters were checked against their specifications over 1000 draws: durations
1941 / 219 / 2040 / 214 against nominal 1967 / 219 / 1967 / 219; lap share 0.200; distances 204 and
453 mm inside their bounds; all eight duty cycles on their means; power 79 / 159 mW against nominal
100 / 200, the known `mean == max` truncation (`doc/MODEL_LIMITATIONS.md` §C3).

`tests/testthat/test-laptop.R` was updated: reference values recomputed, durations corrected from
218 to 219, `band` → `freq`, and every case that reaches the calculation now passes
`params_template.yaml` explicitly. All 18 assertions pass.

---

## Assumptions to be revisited

| parameter | value | basis |
|---|---|---|
| `lptp_dur_*` means | 1967 / 219 / 1967 / 219 s | the existing defaults, unchanged; they sum to 4372 s against the workbook's `lptp_duration` of 4371 |
| `lptp_dur_*` sd | 1888 / 210 / 1888 / 210 | **assumed**, CV 0.96, as for tablet |
| `lptp_lap_prop` | 0.2, `a0` 100 | the mean is the existing `legs_prop` and is confirmed by the workbook; `a0` is the house default |
| `lptp_dist_lap` | 200 mm, sd 50, 120–350 | the mean is derived (antenna 185 mm above the thighs); spread and bounds **assumed** |
| `lptp_dist_desk` | 450 mm, sd 110, 250–800 | the mean is derived (150 + 220 + 70 mm); spread and bounds **assumed** |
| `lptp_*_pwr` | 100 / 200 mW | the EU EIRP limits, as everywhere else in the model |
| duty cycle means and `a0` | the eight existing values, `a0` from the workbook sd | the only fully specification-backed spreads of any non-phone source |

The device dimensions behind the distances assume a 14–15" laptop. A 13" machine is about 5 mm
shallower, a 17" one about 40 mm deeper; the drawn spread covers both.
