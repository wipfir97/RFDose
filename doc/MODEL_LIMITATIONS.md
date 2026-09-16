# Known limitations and open issues of the Stochastic Dose Model

**Purpose:** a single place to record modelling assumptions, approximations and data gaps that a
reader of the results should know about. Each entry says what the issue is, where it bites, how
large it is where we could measure it, and where it is documented in full.

**Status of this file:** living document. Add to it whenever something is found; do not delete
entries when they are resolved, mark them resolved instead.

**Last updated:** 2026-09-15

---

## A. Physics approximations

### A1. The distance correction uses an inverse-square law that does not match the data

`dist_law()` in `R/helpers.R` rescales SAR between distances as
`SAR(d) = SAR(d_ref) · ((d_ref + 6)/(d + 6))²`.

Checked against the two simulated distances we have — the ear scenario at 0.8 cm and the
front-of-eyes scenario at 20 cm — the whole-body SAR drops only by a factor of **6 to 11**, where
an inverse-square law predicts **216**. This holds for all four phantoms and all ten frequencies
(40 combinations checked, no exception). No plausible near-field offset rescues it: to make the
inverse-square law fit, the `delta` term would have to be about 90 mm instead of 6 mm.

**Likely explanation.** At 2.4 GHz the wavelength is 125 mm, so 8 mm is deep in the near field
(λ/16) while 200 mm is already approaching the far field (1.6 λ). A single power law is not expected
to describe both regimes. Near-field absorption behaviour is acknowledged as poorly characterised.

**Consequence.** The correction over-estimates when rescaling to a distance closer than the
simulated one, and under-estimates when rescaling further away. The error grows with the size of
the rescaling.

**How much it matters per source.** Measured by switching `params$global$dist_correction` off at
the template point values:

| source | whole body | brain |
|---|---|---|
| mobile call | **× 8.7** | × 1.15 |
| mobile data | × 1.8 | **× 3.6** |
| VR | × 2.25 | × 2.25 |
| gaming | × 2.2 | × 1.06 |
| cordless | × 1.03 | × 1.01 |

*(factor by which the dose changes when the correction is switched on, relative to off)*

**What was NOT concluded.** The two anchors differ in antenna position as well as distance, so the
comparison conflates the two effects — though the position effect alone is only about 1.5× for whole
body (measured between belly and front-of-eyes, both simulated at 20 cm). For the **brain** channel
the position effect is 4.9–16.9×, comparable to or larger than the distance effect, so the brain
channel cannot be used as evidence here. Fitting a single replacement exponent is therefore not
supported by the data either.

**Status:** open, acknowledged, no fix planned. Keep rescaling distances short where possible, and
report results with the correction switched on and off as a sensitivity band.

Detail: `doc/vr_stochastification.md`, section "Known limitation".

### A2. The phone-in-pocket case substitutes a completely different geometry

`R/mobilecall.R:537` and `:989` take the mean of the eight **belly** positions, simulated with the
antenna 20 cm in front of the belly, and rescale it to a hard-coded **8 mm** for the phone-in-pocket
scenario — a factor of 216 under the current distance law.

The deterministic model did not do this. ETAIN had a **dedicated pant-pocket simulation**:
*"Dipole antenna placed vertically on the right hip, phone call, in pocket, 1 cm separation"*. The
GOLIAT campaign has no pant-pocket or hip geometry at all, so the belly scenario is being used as a
stand-in and stretched to roughly the right separation.

A phone flat against the hip inside a pant pocket and a phone held 20 cm in front of the belly are
not the same exposure situation — as put in discussion, *"right hip at 1 cm vs belly at 20 cm has
nothing to do together"*. Even with a perfect distance law the substitution would be questionable;
the aggressive rescaling compounds it. This is the largest rescaling anywhere in the model, and it
is applied to the source with the largest whole-body contribution.

**Status:** open. Not introduced by the stochastification work — inherited — but it should be
decided whether to keep it, drop the pocket sub-position, or request a hip simulation.

### A3. Seven of the ten model frequencies are interpolated, not simulated

The deterministic model used the **ETAIN** SAR campaign; the stochastic model uses **GOLIAT**. The
two campaigns simulated different frequencies, and the model's own frequency grid matches neither
exactly:

```
GOLIAT simulated :  700,  835, 1450, 2140, 2450, 3500, 5200, 5800
ETAIN  simulated :  700,  800,  900, 1800, 2100, 2450, 2600, 3500, 5000
model computes in:  700,  800,  900, 1450, 1800, 2100, 2400, 2600, 3500, 5000
```

The model grid is close to ETAIN's (8 of 10 shared) but adds 1450 and 2400 and drops 2450. That grid
is not an arbitrary inheritance from the old code — it reflects the **actual mobile network bands**
that the band-proportion parameters refer to (`f700_4g_prop`, `f1800_2g_prop`, and so on). Phones
transmit on 800 and 2600 MHz, not on 835 and 2450, so the SAR values have to be brought onto the
network grid one way or another.

The consequence is that only **3 of the 10** frequencies the model computes in — 700, 1450 and
3500 — are values GOLIAT actually simulated. The other seven are linearly interpolated, some across
wide gaps:

| model freq | interpolated between | gap | position in the interval |
|---|---|---|---|
| 700 | — | — | simulated directly |
| 800 | 700 – 835 | 135 MHz | 74 % |
| 900 | 835 – 1450 | 615 MHz | 11 % |
| 1450 | — | — | simulated directly |
| 1800 | 1450 – 2140 | 690 MHz | 51 % |
| 2100 | 1450 – 2140 | 690 MHz | 94 % |
| 2400 | 2140 – 2450 | 310 MHz | 84 % |
| 2600 | 2450 – 3500 | **1050 MHz** | 14 % |
| 3500 | — | — | simulated directly |
| 5000 | 3500 – 5200 | **1700 MHz** | 88 % |

SAR does not vary linearly with frequency — absorption has resonances and the body is electrically
larger at higher frequencies — so a straight line across 1700 MHz (for 5000 MHz, the WiFi 5 GHz
band) or 1050 MHz (for 2600 MHz, an LTE band) is a real approximation. 1800 MHz sits in the middle
of a 690 MHz gap, which is the worst position of any of them even though the gap is not the widest.

**Status:** unavoidable given that the simulation grid and the network grid differ. Worth knowing
when a result leans on one of the widely-interpolated bands, in particular 5000 MHz — which is the
band that carries the WiFi 5 GHz contribution of every WiFi source in the model, including VR,
gaming, laptop and tablet.

Detail: `doc/SAR_IMPORT_NOTES.md` §3, and the worked example in `data-raw/import_sar.R` section 5.

---

## B. Proxy substitutions — sources with no dedicated simulation

GOLIAT provides three antenna geometries only: front of eyes (20 cm), belly (20 cm), ear (0.8 cm).
Every source that is not a phone has to borrow one.

| source | proxy used | reference distance | rationale |
|---|---|---|---|
| gaming (handheld console) | mean of 8 belly positions | 20 cm | device held in front of the torso |
| VR headset | mean of 6 ear positions | 0.8 cm | only geometry in the right distance regime for a head-worn device |
| phone in pocket | mean of 8 belly positions | 20 cm | see A2 — the weakest of the three |

For VR the choice of the ear over the anatomically correct front-of-eyes is forced: rescaling
front-of-eyes to a headset standoff implies the phantom absorbs about 500 % of the radiated power,
which is impossible. The deterministic model also derived VR from the ear SAR. The cost is that the
source sits beside the temple rather than at the forehead, so the SAR distribution inside the head
differs from a real headset's by an amount we cannot bound.

**Still to come:** laptop and tablet will face the same problem. ETAIN had dedicated "on the lap"
and "on the table" scenarios; GOLIAT does not reproduce them.

Detail: `doc/gaming_stochastification.md`, `doc/vr_stochastification.md`.

---

## C. Data quality in the delivered SAR simulations

### C1. Large deviations at 700 and 835 MHz for Ella and Thelonious

Relative to their own 1450–5800 MHz plateau, Ella's whole-body SAR sits at 0.29 and 0.39 at the two
lowest frequencies, and Thelonious's at 0.50 at 700 MHz. Duke and Eartha are smooth. Ella's stated
input power also deviates at exactly those two frequencies (813 / 636.9 mW against 267 / 228 for
everyone else).

Investigated as a possible import or normalisation error and **ruled out** as such — the import
reproduces Duke's existing values byte-for-byte. This is understood to be the well-known large
uncertainty of SAR simulations at low frequencies. **No correction is applied.**

Affects the 700, 800 and 900 MHz model frequencies, which carry about 44 % of 4G use and half of 2G
and 3G each.

Detail: `doc/SAR_IMPORT_NOTES.md` §5.0–5.2.

### C2. One extreme value in the Thelonious belly data

`Thelonious_body_700_belly_left_vertical_sar` is 2.7 % of the same position's 1450 MHz value, where
neighbouring belly positions sit at 40–80 %. Consistently low at both 700 and 835 MHz, which argues
for genuine weak coupling rather than a numerical artefact. Kept as delivered.

Detail: `doc/SAR_IMPORT_NOTES.md` §5.2.

### C3. Output power distributions are truncated at their own mean

The WiFi power specifications use `trunc_lognormal` with `mean == max` (100 mW at 2.4 GHz, 200 mW at
5 GHz — the EU EIRP limits). The realised mean therefore comes out about 21 % below the nominal
value: 79 instead of 100, 158 instead of 200. This is consistent across mobile call, mobile data,
gaming and VR, so it is a model-wide convention rather than a local slip, but it means the nominal
means in the yaml are not the means that are actually drawn.

**Status:** open, deliberately not changed. Correcting it would raise the WiFi contribution of
several sources by about 26 %.

### C4. Body masses are not stored in the model

Only `height` is in the yaml. Body mass is needed for the absorbed-power sanity check (whole-body
SAR × mass ≤ radiated power), which is the check that ruled out the front-of-eyes proxy for VR.
`tests/test_vr.R` currently hard-codes the IT'IS Virtual Population figures (Duke 70.2, Ella 57.3,
Thelonious 18.6, Eartha 29.0 kg). They should be added next to `height`.

---

## D. Parameters with no data behind them

These are placeholders. All are plain yaml values, replaceable without touching code. They should be
revisited together once the whole model is stochastic.

| parameter | value | note |
|---|---|---|
| `vr_duration` | pzero 0.95, mean 100 s | no literature or study figures known; strongest driver of the VR dose |
| `vr_*_dutycycle` | 0.05 / 0.05 | carried over from the deterministic model; measured WiFi values elsewhere are 0.027 / 0.044 for a call and 0.009–0.67 activity-dependent |
| `vr_dutycycle_a0` | 100 | round default; WiFi duty cycles elsewhere carry fitted values (134.9, 4657.6, 355.76, 1.41) |
| `vr_dist_device` | 15 mm | assumed from side-housing geometry; the bounds 8–30 mm are better founded than the mean |
| `gaming_duration` | pzero 0.8, mean 600 s | invented, mirroring `dect_duration` |
| `gaming_online_prop_a0` | 10 | judgement call between the house default of 100 and the ~0.8 used for behavioural proportions |
| `gaming_dist_device` | 300 mm | assumed typical handheld viewing distance |

---

## E. Code issues noticed in passing

- `R/mobilecall.R:82` contains a leftover `print(params$global$sim)` that floods the console on
  every call.
- `R/mobilecall.R` reads `params$device$call$phone_positions` with `device` singular while the list
  key is `devices`. It works only because R does partial matching on `$`; adding a real `device`
  element would silently turn the position weights into NULL.
- `tests/testthat/test-get-other-dose.R` calls `get_other_dose()`, a function that does not exist in
  the package, and passes a `duration_tracker` argument that `other_dose_wrapper()` never had. The
  file has been dead for some time.
- `params.yaml` and `params_template.yaml` disagree on the legacy VR SAR values by a factor of
  1.6–1.9 with nothing explaining it. Both are now retired by the stochastic VR implementation.
