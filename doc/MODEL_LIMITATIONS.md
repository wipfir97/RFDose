# Known limitations and open issues of the Stochastic Dose Model

**Purpose:** a single place to record modelling assumptions, approximations and data gaps that a
reader of the results should know about. Each entry says what the issue is, where it bites, how
large it is where we could measure it, and where it is documented in full.

**Status of this file:** living document. Add to it whenever something is found; do not delete
entries when they are resolved, mark them resolved instead.

**Where the open decisions are:** this file records what the limitations *are*. Everything that is
currently undecided or awaiting an answer — from supervisors or from the data providers — is
collected in `doc/OPEN_QUESTIONS.md`, grouped by who can answer it.

**Last updated:** 2026-09-17

---

## A. Physics approximations

### A1. The distance correction uses an inverse-square law that does not match the data

`dist_law()` in `R/helpers.R` rescales SAR between distances as
`SAR(d) = SAR(d_ref) · ((d_ref + 6)/(d + 6))²`.

Checked against the two simulated distances we have — the ear scenario at 0.8 cm and the
front-of-eyes scenario at 20 cm — the whole-body SAR drops only by a factor of **2.5 to 14.5**,
where an inverse-square law predicts **216**. Measured across all four phantoms and all ten model
frequencies (40 combinations, no exception; per phantom: Duke 2.5–11.9, Ella 4.1–9.7,
Thelonious 6.0–14.5, Eartha 6.4–11.0; median 7.6).

No plausible near-field offset rescues it: to reproduce the median ratio the `delta` term would have
to be about **100 mm** instead of 6 mm, and no single value fits the whole set — the 40 combinations
individually require delta between 60 and 320 mm.

**Likely explanation.** At 2.4 GHz the wavelength is 125 mm, so 8 mm is deep in the near field
(λ/16) while 200 mm is already approaching the far field (1.6 λ). A single power law is not expected
to describe both regimes. Near-field absorption behaviour is acknowledged as poorly characterised.

**Consequence.** The correction over-estimates when rescaling to a distance closer than the
simulated one, and under-estimates when rescaling further away. The error grows with the size of
the rescaling.

**How much it matters per source.** Measured by switching `params$global$dist_correction` off at
the template point values:

| source | whole body | brain | direction of the rescaling |
|---|---|---|---|
| mobile call | **× 8.71** | × 1.15 | 200 mm → 8 mm for the pocket (inward, large) |
| mobile data | × 1.81 | **× 3.53** | belly neutral; face 200 mm → 100 mm (inward) |
| cordless | × 1.04 | × 1.01 | 8 mm → 8 mm (essentially neutral) |
| gaming | × 0.45 | × 0.94 | 200 mm → 300 mm (outward); brain uses the hypotenuse |
| tablet | × 0.45 | × 0.45 | 200 mm → 300 mm (outward) |
| VR | × 0.44 | × 0.44 | 8 mm → 15 mm (outward) |

*(factor by which the dose changes when the correction is switched **on**, relative to off. Values
below 1 mean the correction lowers the dose, which is what an outward rescaling must do.)*

**What was NOT concluded.** The two anchors differ in antenna position as well as distance, so the
comparison conflates the two effects. The position effect can be isolated by comparing belly against
front-of-eyes, both simulated at 20 cm: for **whole body** the front-of-eyes mean is 0.55–1.02 of
the belly mean (median 0.70), i.e. a position effect of at most about 1.5×, well below the distance
effect. For the **brain** the same comparison gives 4.2–105.7 (median 8.9) — comparable to or far
larger than the distance effect, so the brain channel cannot be used as evidence here. Fitting a
single replacement exponent is therefore not supported by the data either.

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


**Status:** unavoidable given that the simulation grid and the network grid differ. Worth knowing
when a result leans on one of the widely-interpolated bands, in particular 5000 MHz — which is the
band that carries the WiFi 5 GHz contribution of every WiFi source in the model, including VR,
gaming, laptop and tablet.

Detail: `doc/SAR_IMPORT_NOTES.md` §3, and the worked example in `data-raw/import_sar.R` section 5.

---

## B. Proxy substitutions — sources with no dedicated simulation

GOLIAT provides three antenna geometries only: front of eyes (20 cm), belly (20 cm), ear (0.8 cm).
Every source that is not a phone has to borrow one.

| source | proxy used | reference distance | modelled distance | rationale |
|---|---|---|---|---|
| gaming (handheld console) | mean of 8 belly positions | 20 cm | 30 cm | device held in front of the torso |
| tablet | mean of 8 front-of-eyes positions | 20 cm | 30 cm | device held up in front of the face — the mildest rescaling in the model |
| VR headset | mean of 6 ear positions | 0.8 cm | 1.5 cm | only geometry in the right distance regime for a head-worn device |
| phone in pocket | mean of 8 belly positions | 20 cm | 0.8 cm | see A2 — the weakest of the four |

For VR the choice of the ear over the anatomically correct front-of-eyes is forced: rescaling
front-of-eyes down to a headset standoff makes the phantom absorb more than the radiated power,
which is impossible. At 2.4 GHz the absorbed fraction comes out at **493–522 %** if the standoff is
taken as 20 mm, and **756–800 %** at the 15 mm actually modelled. The proxy is non-physical at any
standoff below about 52 mm. The deterministic model also derived VR from the ear SAR. The cost is
that the source sits beside the temple rather than at the forehead, so the SAR distribution inside
the head differs from a real headset's by an amount we cannot bound.

The tablet is the counter-example worth noting: it uses the *same* front-of-eyes proxy that failed
for VR, and passes the absorbed-power check comfortably (2–4 % across all four phantoms). The
difference is purely the direction of the rescaling — outward from 20 to 30 cm instead of down to
1.5 cm. The severity of a proxy substitution is driven by how far the distance law is stretched, not
by which geometry is borrowed.

**Still to come:** laptop will face the same problem. ETAIN had dedicated "on the lap" and "on the
table" scenarios; GOLIAT does not reproduce them.

Detail: `doc/gaming_stochastification.md`, `doc/vr_stochastification.md`,
`doc/tablet_stochastification.md`.

---

## C. Data quality in the delivered SAR simulations

### C1. The phantoms disagree with each other far more at 700 and 835 MHz than above 1450 MHz

Whole-body SAR from the front-of-eyes geometry, mW/kg per 1 W, on the raw simulated grid:

| MHz | Duke | Ella | Thelonious | Eartha | spread (max/min) |
|---|---|---|---|---|---|
| **700** | 2.64 | **0.39** | 1.71 | 2.87 | **7.3×** |
| **835** | 2.34 | **0.40** | 4.24 | 2.32 | **10.7×** |
| 1450 | 1.15 | 1.33 | 2.80 | 2.01 | 2.4× |
| 2140 | 1.20 | 1.08 | 4.00 | 2.70 | 3.7× |
| 2450 | 1.18 | 1.43 | 4.34 | 2.85 | 3.7× |
| 3500 | 0.82 | 1.33 | 3.07 | 1.91 | 3.8× |
| 5200 | 0.66 | 0.98 | 2.26 | 1.53 | 3.4× |
| 5800 | 0.61 | 0.78 | 2.30 | 1.55 | 3.7× |

From 1450 MHz upward the four phantoms stay within a factor of 2.4–3.8 of each other, which is the
normal between-model variation for different body sizes. At the two lowest frequencies the spread
widens to 7–11×, driven almost entirely by **Ella sitting 4–7× below the other three**. Thelonious
adds a second symptom: his value jumps by +149 % from 700 to 835 MHz in the same geometry, where the
others move by at most ±13 %. Duke and Eartha are well behaved in absolute terms.

Ella's stated input power also deviates at exactly these two frequencies (813 / 636.9 mW against
267 / 228 for everyone else).

**A caution on how this is measured.** Normalising each phantom to its *own* high-frequency plateau
instead — as an earlier version of this entry did — makes Duke look like the outlier (2.8× his own
plateau at 700 MHz). That is an artefact: Duke's high-frequency values are simply the lowest of the
four, so his plateau is low and everything is large relative to it. The absolute comparison above is
the one that supports a conclusion.

Investigated as a possible import or normalisation error and **ruled out** as such — the import
reproduces Duke's existing values byte-for-byte, and for Duke, Thelonious and Eartha our
normalisation matches the institutes' own to the bit (§C4). This is understood to be the well-known
large uncertainty of SAR simulations at low frequencies. **No correction is applied.**

Affects the 700, 800 and 900 MHz model frequencies, which carry about 44 % of 4G use and half of 2G
and 3G each.

Detail: `doc/SAR_IMPORT_NOTES.md` §5.0–5.2.

### C2. One extreme value in the Thelonious belly data

`Thelonious_body_700_belly_left_vertical_sar` is 2.7 % of the same position's 1450 MHz value, where
the other seven belly positions sit at 18–80 % (center_vertical 41, center_horizontal 71,
left_horizontal 18, right_vertical 40, right_horizontal 65, up_vertical 42, up_horizontal 80).
It is the clear outlier, and consistently low at both 700 and 835 MHz, which argues for genuine weak
coupling rather than a numerical artefact. Kept as delivered.

Detail: `doc/SAR_IMPORT_NOTES.md` §5.2.

### C3. Output power distributions are truncated at their own mean

The WiFi power specifications use `trunc_lognormal` with `mean == max` (100 mW at 2.4 GHz, 200 mW at
5 GHz — the EU EIRP limits). The realised mean therefore comes out about 21 % below the nominal
value: 79.0 instead of 100, 158.0 instead of 200 (20 000 draws). This is consistent across mobile
call, mobile data, gaming, VR and tablet, so it is a model-wide convention rather than a local slip,
but it means the nominal means in the yaml are not the means that are actually drawn.

**Status:** open, deliberately not changed. Correcting it would raise the WiFi contribution of
several sources by about 27 %.

### C4. Ella's normalisation is the only one with no independent cross-check

Each institute ships a `<sheet>_normalized` companion in which it performed the 1 W division
itself, so our own normalisation can be checked against a second derivation. Since UGent's
consolidated workbook arrived (2026-09-17) that check covers Duke, Thelonious and Eartha, and all
three agree to the bit — except two known Duke cells at 1e-7, explained in
`doc/SAR_IMPORT_NOTES.md` §5.5.

**TP delivered Ella's `_normalized` sheets as empty placeholders** — every SAR column blank. Her
values therefore rest entirely on our own division by the stated `Input Power (mW)` column, with
nothing to compare against. This is uncomfortable precisely for Ella, because she is also the
phantom whose stated input power is anomalous at the two lowest frequencies (813 and 636.9 mW
against 267 and 228 for everyone else), which is the same place her whole-body SAR falls 4–7× below
the other three phantoms (§C1). Since the normalisation is a division by exactly that stated power,
a normalisation error and a genuine simulation property would look alike here, and we cannot
currently separate them.

**Status:** open. A question to TP is drafted in `doc/SAR_IMPORT_NOTES.md` §6. Low effort to close
if they can supply filled normalized sheets or confirm the power convention.

### C5. Body masses are not stored in the model

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
| `tblt_dur_*_sd` | 700 / 78 / 700 / 78 s | assumed at CV = 0.96, the top of the 0.90–0.96 range mobiledata's three non-zero duration spreads span; the *means* are the unchanged defaults |
| `tblt_dist_device` | 300 mm, sd 80, 200–500 | the 300 mm mean is a given; spread and bounds assumed. Also: it is *drawn*, and pinning it to a constant is a one-line change if that was the intent |
| `tblt_*_dutycycle_a0` | borrowed from mobiledata | the same physical quantity, fitted — but see below |

### D1. One borrowed Beta spread transplants badly: `tblt_5000_high_dutycycle`

A Beta's concentration `a0` is not scale-free. The `a0` values for the eight tablet duty cycles were
taken from mobiledata's fitted WiFi duty cycles, which is sound for seven of them because the means
agree closely. For 5 GHz high-activity the means do not: 0.145 here against 0.495 for mobiledata.
With `a0 = 0.4585` the shape parameters become *a* = 0.067 and *b* = 0.392, so the draws collapse
towards zero — median 0.00015 over 2000 draws, 65 % below 0.01 — while the mean stays at 0.145
because a thin tail reaches 1.

The **mean** dose is unaffected (a Beta preserves its mean); the variance this injects is not
physically motivated. Its weight is limited — the high-activity class is 5 % of modelled tablet time
and the 5 GHz band 42 % of traffic, so about 14 % of the 5 GHz output power. Left as delivered.
Candidate fixes: the house default `a0 = 100`, or floor `a0` where the distribution stays unimodal
(`a0 > 1/min(m, 1−m)`, i.e. `> 6.9` at m = 0.145).

**Update 2026-09-18 — a founded value now exists, but is not yet applied.** The parameter workbook
`data-raw/SDM_parameters_26062026.xlsx` gives this duty cycle as mean 0.14515 with **sd 0.09**,
which through `a0 = m(1−m)/sd² − 1` yields **`a0` = 14.32** — unimodal, and a measured spread rather
than a borrowed one. The workbook supplies matching sd values for all eight tablet duty cycles. Left
unchanged pending the discussion in `doc/PARAMETER_WORKBOOK_NOTES.md` §9.

Detail: `doc/tablet_stochastification.md`, `doc/PARAMETER_WORKBOOK_NOTES.md` §6.3.

---

## E. Code issues noticed in passing

- `R/mobilecall.R:82` contains a leftover `print(params$global$sim)` that floods the console on
  every call.
- `params$device$call$phone_positions` is read with `device` singular while the list key is
  `devices` — **10 occurrences** across three files: `R/mobilecall.R` (6, at lines 489, 509, 528,
  570, 962, 981), `R/cordless.R` (2, at 90 and 117) and `R/mobiledata.R` (2, at 509 and 543). It
  works only because R does partial matching on `$`; adding a real `device` element would silently
  turn every position weight into NULL.
- `tests/testthat/test-get-other-dose.R` calls `get_other_dose()`, a function that does not exist in
  the package, and passes a `duration_tracker` argument that `other_dose_wrapper()` never had. The
  file has been dead for some time.
- `params.yaml` and `params_template.yaml` disagree on the legacy VR SAR values by a factor of
  1.6–1.9 with nothing explaining it. The same applies to the legacy tablet SAR values (factor 1.12
  at brain 2.4 GHz, 1.96 at brain 5 GHz). All are now retired by the stochastic implementations.
- `tests/testthat/test-tablet.R` had reference values that no longer matched the code it tested: it
  expected `tablet_dose(brain) = 12.19` where the deterministic implementation returned 14.68, and
  its `tablet_sar` expectations were the `params_template.yaml` numbers while the calls ran against
  `params.yaml`. Fixed as part of the tablet stochastification, but worth knowing that the shipped
  testthat suite is not a reliable regression net — `test-get-cordless-dose.R` still calls
  `get_cordless_dose()`, which no longer exists either.
