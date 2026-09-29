# SAR source redesign — decisions of 2026-09-22

**Status:** decided in principle at the meeting of 2026-09-22. Not yet implemented. Several sub-questions below are still open and are listed in
`doc/OPEN_QUESTIONS.md` §A.
d
This document records what was decided, what the decisions resolve, what the data supports, and
what still has to be settled before the rework can start. It supersedes parts of
`doc/MODEL_LIMITATIONS.md` §A and §B — those entries stay in place until the rework lands, each
marked with a pointer here.

---

## 1. The decisions

### D1. No distance correction anywhere

`dist_law()` is removed from the model. Rescaling a simulated SAR value from the distance it was
simulated at to the distance the scenario assumes carries more uncertainty than it removes, and
there is no way to check whether a given rescaling is close enough to right. `MODEL_LIMITATIONS.md`
§A1 measures the problem: between the two simulated distances the data gives a factor 2.5–14.5 where
the inverse-square law predicts 216, and the two anchors differ in position as well as distance, so
even that comparison cannot isolate the distance effect.

**Consequence:** every source needs a simulation at, or acceptably near, its own geometry. That is
what D2 provides.

### D2. ETAIN is the SAR source wherever ETAIN simulated the scenario

The deterministic model used ETAIN's near-field simulations, which include dedicated scenarios for
the laptop on the lap and on a table, for Bluetooth earbuds and for a wrist-worn device. GOLIAT
simulated only three phone geometries, so every non-phone source in the stochastic model currently
borrows one of them. Going back to ETAIN for those sources removes the borrowing and the rescaling
in one step.

**Not yet settled:** whether the tablet also moves back to ETAIN (see Q2).

### D3. Child phantoms through GOLIAT ratios applied to ETAIN

ETAIN simulated Duke and Ella only. GOLIAT has all four phantoms. The plan is to form
child-to-adult ratios from GOLIAT — Thelonious against Duke, Eartha against Ella — and apply them to
the ETAIN values.

**Not yet settled:** at what resolution the ratios are formed, and how a GOLIAT geometry is paired
with an ETAIN scenario (see Q3). The measurements in §5 below show that a single ratio per phantom
pair is not defensible.

### D4. No interpolation onto unsimulated frequencies

Where a model band was not simulated, the value should come from the nearest simulated frequency, or
from an average of the two nearest, rather than from interpolation.

**Not yet settled:** which of those rules, and what to do about 1450 MHz (see Q4). Note that a
*distance-weighted* average of the two nearest nodes is linear interpolation — it is exactly what
`approx()` computes in `data-raw/import_sar.R` today — so it is not an alternative to interpolation
and would leave D4 unfulfilled.

### D5. (idea, not decided) Pool GOLIAT and ETAIN into a SAR distribution

For sources both datasets cover, the mean of the SAR distribution could be the average of GOLIAT's
per-position mean and ETAIN's value, with the spread taken from the GOLIAT positions plus the ETAIN
value. See Q5 for what that spread would and would not represent.

---

## 2. What the decisions resolve

| | limitation | resolved by |
|---|---|---|
| `MODEL_LIMITATIONS.md` §A1 | inverse-square law does not match the data | D1 — the law is gone |
| §A2 | phone-in-pocket substitutes a different geometry | D2 — ETAIN scenario 4 is an actual hip simulation |
| §A3 | seven of ten frequencies interpolated | D2 + D4 — the grid is now nine bands, all of which ETAIN simulated. GOLIAT still interpolates six, which is why it is the fallback |
| §B | proxy substitutions for every non-phone source | D2 — for laptop, earbuds and smartwatch; **not** for gaming, VR and hotspot (Q1) |
| `OPEN_QUESTIONS.md` §C8 | `height/2` belly-to-brain hypotenuse | D1 — no rescaling, so no hypotenuse |
| `OPEN_QUESTIONS.md` §E | `delta` hard-coded at 18 call sites | D1 — the call sites disappear |

These are the largest entries in both documents. The rework is substantial and touches sources
already converted (`mobilecall`, `mobiledata`, `cordless`, `gaming`, `virtual_reality`, `tablet`,
`laptop`), but it removes more open questions than it creates.

---

## 3. What ETAIN actually delivers

Two pairs of files in `data-raw/`, near field and far field, whole body and brain:

```
NF_SARwb_LessThan6GHz_WholeBody.xlsx    NF_SARosa_LessThan6GHz_Brain.xlsx
FF_SARwb_LessThan6GHz_WholeBody.xlsx    FF_SARosa_LessThan6GHz_Brain.xlsx
```

**Near field:** 9 scenarios, Duke and Ella held separately, in mW/kg per 1 W input power — the same
normalisation GOLIAT uses. Whole-body and brain share one (scenario, frequency) grid. Scenarios 1–6
are simulated at nine frequencies, 7 and 8 at 2450 and 5000 MHz, and 9 at 2450 MHz only.

**Far field:** 12 frequencies (100, 300, 500, 700, 800, 900, 1800, 2100, 2450, 2600, 3500, 5000) ×
12 incidence directions, Duke and Ella.

This is considerably more than `Input_dose_model_Final_ETAIN_nSAR.xlsx` suggests. That workbook
distils the database down to what the deterministic model consumed: one scalar per scenario, at
1.8 GHz for the cellular scenarios and 2.45 GHz for the WiFi and Bluetooth ones, with Duke and Ella
averaged together. The deterministic model therefore had **no frequency and no phantom resolution**
in its near-field SAR. The underlying database has both.

### 3.1 The two ETAIN deliveries disagree — settled 2026-09-28

> **Decided:** the near-field SAR comes from the simulation database,
> `NF_SARwb_LessThan6GHz_WholeBody.xlsx` and `NF_SARosa_LessThan6GHz_Brain.xlsx` (supervisor,
> 2026-09-28). The workbook is not used for near-field SAR. The comparison below is kept as the
> record of what that choice implies — above all that the SDM will **not** reproduce the
> deterministic model's numbers, and by how much. The decision covers the near field only; the far
> field is still Q6.

The workbook's scalars should be the simulation database read at the stated frequency. For two
scenarios they are. For the other seven they are not.

### What can be compared where

The workbook holds the two channels at different resolutions, which decides how far the comparison
reaches:

| channel | workbook sheet | frequencies | comparable |
|---|---|---|---|
| whole body | `SAR` | 1800 and 2450 only | those two |
| brain | `SAR_brain` | all nine | all nine |

`SAR_brain` is a full matrix — 10 scenarios × 9 frequencies × Duke and Ella, the same shape as the
simulation database. Note that its frequency columns are **not** in ascending order: they run 700,
800, 900, 1800, 2100, 2600, 3500, **2450**, 5000.

### The brain channel, all nine frequencies

Ratio simulation ÷ workbook, for the three scenarios whose brain SAR is large enough to be
meaningful:

| MHz | ear, Duke | ear, Ella | speaker, Duke | speaker, Ella | 30 cm, Duke | 30 cm, Ella |
|---|---|---|---|---|---|---|
| 700 | 0.96 | 1.06 | 1.09 | 1.25 | 1.05 | 1.09 |
| 800 | 0.98 | 1.12 | 1.08 | 1.22 | 1.05 | 1.09 |
| 900 | 0.99 | 1.15 | 1.07 | 1.18 | 1.03 | 1.06 |
| 1800 | 1.15 | 1.51 | 1.08 | 1.31 | 1.07 | 1.09 |
| 2100 | 1.31 | 1.74 | 1.13 | 1.22 | 1.10 | 1.06 |
| 2450 | 1.43 | 1.86 | 1.16 | 1.26 | 1.12 | 1.12 |
| 2600 | 1.42 | 1.86 | 1.16 | 1.31 | 1.15 | 1.15 |
| 3500 | 1.28 | 1.57 | 1.38 | 1.44 | 1.36 | 1.31 |
| 5000 | 1.31 | 2.01 | **2.02** | **1.93** | **1.95** | **1.97** |

**The divergence is systematic in frequency, not in geometry.** At 700–900 MHz the two artefacts
agree to within a few per cent. The gap then widens monotonically, and at 5000 MHz the database sits
roughly twice as high across all three scenarios. Ella diverges more than Duke throughout.

The remaining scenarios — hip, lap, table, wrist, earbuds — have brain SAR between 10⁻⁴ and
10⁻² mW/kg/W. Their ratios run from 0.00 to 21.7, but at those magnitudes a ratio is numerically
fragile and dosimetrically irrelevant; they contribute essentially nothing to the brain dose. They
are not evidence either way.

### The whole-body channel, at the two available frequencies

| scenario | 1800 and 2450 |
|---|---|
| 2 — 10 cm in front of the mouth | 0.99–1.01 |
| 3 — 30 cm in front of the mouth | 0.95–1.05 |
| 1 — at the ear, 1 cm | **1.56–1.96** |
| 4 — on the right hip, 1 cm | **0.57–0.75** |
| 5 — on the legs, seated (laptop lap) | **1.37–1.48** |
| 6 — table (laptop table) | **2.34–2.74** |
| 7, 8 — next to the ear, 1 mm (earbuds) | **1.29–1.55** |
| 9 — on the wrist, 1 mm | **0.74–0.83** |

Scenarios 2 and 3 agree here to within the workbook's one-decimal rounding — but the brain table
above shows they still differ by 3–16 % at low frequencies and about a factor of two at 5000 MHz. An
earlier reading of this table alone suggested that only body-contact scenarios disagree. The
frequency-resolved brain data does not support that; frequency is the stronger axis.

### What is ruled out

**A scenario numbering mix-up.** The brain channel identifies the scenarios unambiguously:
simulation scenario 1 has a brain SAR of 40.8 mW/kg/W at 1800 MHz and scenario 4 has 0.0007, which
can only be the ear and the hip respectively. The frequency coverage confirms the rest — scenarios 7
and 8 exist only at 2450 and 5000 MHz and scenario 9 only at 2450, exactly as the ETAIN scenario
table specifies.

**A different power normalisation.** If one artefact were normalised to accepted power and the other
to input power, the ratio would track the accepted-power column. It does not: the correlation is
−0.23 over the 26 comparable whole-body values, and scenario 6, which disagrees most, has almost
exactly the same accepted power as scenarios 2 and 3.

### What the choice implies

The deterministic model was built on the workbook; the SDM will be built on the database, for its
frequency resolution and its separate phantoms. **The two models will therefore not agree**, and the
gap is largest exactly where it is most visible: every scenario the redesign depends on — 1 for the
phone call, 5 and 6 for the laptop, 7 and 8 for earbuds, 9 for the smartwatch — is in the
disagreeing set, and 2450 and 5000 MHz, the two bands the WiFi sources use, are the worst frequencies.

Anyone comparing SDM against DDM output will see this. It is a deliberate choice, not a defect, and
should be stated whenever the two are compared.

The cause of the divergence remains unknown. A monotone, phantom-dependent gap that grows with
frequency would fit a difference in mesh resolution or in the antenna model between two versions of
the campaign, but that is conjecture. It no longer blocks the work, and it is worth asking the ETAIN
side at some point — if the workbook turns out to be a later correction rather than an earlier
version, the choice would need revisiting.

---

## 4. Mapping ETAIN scenarios to model sources

| ETAIN | simulation | model source |
|---|---|---|
| 1 | 45° tilted, 1 cm from the right ear | `mobilecall` at ear, `cordless` |
| 2 | vertical, 10 cm in front of the mouth | `mobilecall` speaker mode |
| 3 | vertical, 30 cm in front of the mouth | `mobiledata` |
| 4 | vertical on the right hip, 1 cm separation | `mobilecall` / `mobiledata` in pocket |
| 5 | vertical on the legs, phantom seated | `laptop` lap (and `tablet`? — Q2) |
| 6 | 10 cm higher and 30 cm further than 5 | `laptop` table (and `tablet`? — Q2) |
| 7, 8 | vertical next to the right / left ear, 1 mm | `headphones` (Bluetooth earbuds) |
| 9 | horizontal on the right wrist, 1 mm | `smartwatch` |

**Three sources have no ETAIN equivalent:** `gaming` (handheld console), `virtual_reality`
(head-mounted display) and `hotspot`. See Q1.

### The frequency grid

Changed on 2026-09-28 from ten bands to nine, so that it matches ETAIN exactly. Before, ETAIN hit
eight of ten and GOLIAT three; the two misses were 2400 MHz, the lower edge of the 2.4 GHz band
that neither campaign simulated, and 1450 MHz, which ETAIN has no node within 350 MHz of. Both
were removed — see Q4 for why neither cost anything.

| | |
|---|---|
| model | 700, 800, 900, 1800, 2100, 2450, 2600, 3500, 5000 |
| ETAIN | 700, 800, 900, 1800, 2100, 2450, 2600, 3500, 5000 |
| GOLIAT | 700, 835, ~~1450~~, 2140, 2450, 3500, 5200, 5800 |

**ETAIN now hits all nine exactly**, so nothing on the ETAIN side is interpolated. GOLIAT hits
three — 700, 2450 and 3500 — and its 1450 MHz node no longer lands on a model band.

GOLIAT's remaining gaps matter in two places. For `gaming`, `virtual_reality` and `hotspot` they
barely bite: those sources need only the two WiFi bands, and GOLIAT has 2450 exactly while its
5200 MHz node sits 200 MHz from the model's 5000, worth about 0.5 % — measured from GOLIAT's own
slope between 5200 and 5800, which is −0.24 % per 100 MHz. For the **child ratios** they bite
properly: those are needed at all nine bands and can only come from GOLIAT. That is Q3.

---

## 5. How stable are the GOLIAT child-to-adult ratios?

Measured on the SAR tables in `params_stochastic.yaml`, restricted to the three frequencies GOLIAT
actually simulated on the model grid (700, 1450, 3500), so no interpolated value enters. Each cell
is the median across the positions of that geometry, with the range in brackets.

**Whole body**

| | 700 | 1450 | 3500 |
|---|---|---|---|
| Thelonious / Duke, belly | 0.69 [0.03–0.94] | 2.05 [1.42–2.43] | 2.91 [2.41–3.31] |
| Thelonious / Duke, ear | 3.59 [3.01–4.60] | 2.97 [2.14–3.75] | 2.08 [1.60–2.84] |
| Thelonious / Duke, front of eyes | 0.66 [0.25–0.83] | 2.43 [2.33–2.53] | 3.59 [3.35–4.13] |
| Eartha / Ella, belly | 6.96 [1.97–8.70] | 1.46 [1.08–1.74] | 1.59 [1.24–1.76] |
| Eartha / Ella, ear | 5.69 [3.72–7.38] | 4.32 [2.66–14.76] | 2.27 [1.28–2.99] |
| Eartha / Ella, front of eyes | 7.51 [6.70–7.84] | 1.51 [1.39–1.59] | 1.46 [0.92–1.88] |

**Brain**

| | 700 | 1450 | 3500 |
|---|---|---|---|
| Thelonious / Duke, belly | 36.09 [1.99–88.78] | 8.40 [6.16–16.92] | 58.52 [21.82–114.43] |
| Thelonious / Duke, ear | 5.67 [4.07–9.63] | 1.18 [0.68–1.98] | 0.67 [0.39–0.79] |
| Thelonious / Duke, front of eyes | 4.92 [1.67–5.96] | 2.12 [1.99–2.47] | 4.70 [3.75–5.33] |
| Eartha / Ella, belly | 9.80 [2.33–14.48] | 3.23 [1.91–6.54] | 2.34 [1.76–4.83] |
| Eartha / Ella, ear | 3.73 [2.59–5.80] | 3.66 [0.84–16.92] | 0.46 [0.22–1.56] |
| Eartha / Ella, front of eyes | 5.56 [3.79–6.95] | 1.39 [1.27–1.60] | 4.63 [2.38–9.87] |

Four things follow.

**A single ratio per phantom pair is not defensible.** At 3500 MHz the Thelonious/Duke brain ratio is
58.5 through the belly geometry and 0.67 through the ear geometry — a factor of 87 between two cells
of the same table.

**The frequency dependence is real and runs in opposite directions for the two pairs.** The
Thelonious/Duke whole-body ratio rises with frequency, the Eartha/Ella one falls. This is measured at
natively simulated frequencies, so it is not an interpolation artefact.

**700 MHz behaves differently from the rest.** Several ratios invert there. This is the same
anomaly `MODEL_LIMITATIONS.md` §C1 records — the phantoms disagree far more below 1000 MHz than
above 1450 MHz, with Ella the outlier — so the low bands will need separate treatment whatever
scheme is chosen.

**The brain ratios are the weak channel, as everywhere else in this model.** Their spread within a
single geometry and frequency reaches a factor of 5, and across geometries a factor of 87. Pairing an
ETAIN scenario with a GOLIAT geometry that does not match it will not give a usable brain ratio.

The extreme low value in the whole-body table, `body_700_belly_left_vertical_sar` at 0.026, is not a
single corrupt cell: the 800 and 900 MHz values of the same position continue the pattern at 0.032
and 0.147. It is a genuine low-frequency feature of that position in Thelonious, and is related to
§B4 of `OPEN_QUESTIONS.md`.

---

## 6. Open sub-questions

Carried into `doc/OPEN_QUESTIONS.md` §A.

**Q1 — What happens to `gaming`, `virtual_reality` and `hotspot`?** No ETAIN scenario matches a
handheld console, a head-mounted display or a portable hotspot. Either they keep a GOLIAT geometry
without any distance correction, accepting the geometry mismatch and holding to D1; or they keep the
distance correction, which contradicts D1 for three sources; or they are treated more crudely. The
first option is the consistent one, and for VR the GOLIAT ear geometry at 0.8 cm is in the right
distance regime to begin with.

**Q2 — Which geometry for the tablet?** ETAIN labels scenarios 5 and 6 "Laptop, tablet" and the
deterministic model used them, which puts the tablet on the lap or on a table. The stochastic
implementation chose front-of-eyes at 300 mm on the argument that a tablet is held up to be looked
at. Both usages are real; the question is which the model should represent, and whether the answer
should differ from the laptop's.

**Q3 — At what resolution are the child ratios formed?** §5 rules out one scalar per phantom pair.
The minimum is one ratio per (geometry, frequency, tissue). Still to settle: which GOLIAT geometry
rather than at its lower edge. The band at **1450 MHz is dropped**: it was never in the
deterministic model, and `f1450_4g_prop_mean` in the yaml is already `0.0`, so it carries no
exposure and the remaining six 4G proportions already sum to 1. Removing it changes no dose and
needs no renormalisation; it also clears a degenerate Dirichlet component with α = 0.

The model therefore computes at **nine** bands — 700, 800, 900, 1800, 2100, 2450, 2600, 3500,
5000 — and that set is **identical to ETAIN's near-field grid**. No substitution rule is needed on
the ETAIN side at all, which is what D4 was asking for.

**Q5 — When may GOLIAT and ETAIN values be pooled?** **Answered 2026-09-28 (supervisor):** only
where both campaigns simulated the *same scenario*; otherwise the average has no meaning. The
proposed form for the 5 GHz band was
`0.5 * etain_5000 + 0.25 * goliat_5200 + 0.25 * goliat_5800`.

Measured against the data, that condition is far more restrictive than it looks. Of the nine ETAIN
scenarios, only the phone at the ear has a genuine GOLIAT counterpart (ETAIN 1 cm against GOLIAT
0.8 cm; they differ by 26 % on Duke's whole body at 5 GHz, reasonable agreement for two independent
campaigns). Every other pairing compares different exposures — most starkly the laptop, where
ETAIN's dedicated "antenna on the legs, phantom seated" scenario and GOLIAT's belly geometry differ
by a factor of 5, and applying the formula would pull the dedicated simulation down by 40 % toward
the proxy that D2 exists to remove.

And the one valid pairing cannot use the formula: the ear scenario serves the **cellular** bands,
where the 5 GHz question does not arise, and GOLIAT's ear nodes overlap the model's cellular bands
at only 700 and 3500 MHz. Averaging at those two while using ETAIN alone at the other five would
put an unphysical step in the frequency response of one source.

**What follows, still to be confirmed with the supervisor:** the pooling rule has no clean
application, and the simpler rule below is what his own condition implies.

> Each source takes the campaign that simulated its scenario directly — ETAIN for `mobilecall`,
> `mobiledata`, `cordless`, `laptop`, `tablet`, `headphones` and `smartwatch`; GOLIAT for `gaming`,
> `virtual_reality` and `hotspot`, whose 5 GHz value is the mean of GOLIAT's 5200 and 5800 MHz nodes
> because ETAIN has no scenario for them. GOLIAT additionally supplies the child ratios everywhere.

A separate concern survives whichever rule is chosen: a spread computed over pooled GOLIAT and ETAIN
values would mix variability across antenna positions within one study with disagreement between two
studies, and would be reported as the former.

**Q6 — Far field: ETAIN or GOLIAT?** **Answered and implemented 2026-09-29: GOLIAT.** It is the
one place where the D2 logic does not apply. GOLIAT delivered far-field simulations for **all four
phantoms** (9 frequencies × 12 incidence directions), so no child ratios are needed and Q3 does
not block it; ETAIN has three more frequencies but only Duke and Ella.

`farfield` is therefore the first source converted under this redesign, while the near-field
sources still wait on Q1, Q2 and Q3. The 12 directions are averaged, the nine simulated
frequencies are weighted by Adriana's EU spectrum at run time, and each model band takes its
nearest simulated node rather than an interpolation. Detail:
`doc/farfield_stochastification.md`.

One finding came out of it that reaches further than the far field. `simulate_params()` had always
drawn **urbanicity** as three Dirichlet proportions, and nothing had ever read them. Read as a
mixture they are wrong: the model describes one person's average day, and that person lives in one
kind of area. Weighting the exposure levels by 0.4 / 0.5 / 0.1 gave every simulated person the
population average and narrowed the dose spread from 25.5–58.6 to 37.1–50.8. The draw is now
categorical.

**Q7 — Which of the two ETAIN deliveries should the model be built on?** **Answered 2026-09-28:**
the simulation database, `data-raw/NF_SARwb_LessThan6GHz_WholeBody.xlsx` and
`data-raw/NF_SARosa_LessThan6GHz_Brain.xlsx`. Not
`data-raw/Input_dose_model_Final_ETAIN_nSAR.xlsx`, which the deterministic model uses. §3.1 records
what the two differ by and what the choice implies. The answer covers the **near field only** — the
far field is Q6.

---

## 7. Sequence

Not decided at the meeting; proposed here. Q7 is answered, so the import is unblocked.

1. ~~Settle Q4 and realign the model frequency grid.~~ **Done 2026-09-28.** `TARGET_FREQ` in
   `data-raw/import_sar.R` now holds the nine bands, both yaml files were re-imported onto them,
   the `_2400_` identifiers were renamed to `_2450_` throughout code, parameters and tests, and the
   1450 MHz component was removed from the 4G band mix. The GOLIAT values at 2450 are now native
   simulations rather than interpolated. Only the laptop reference values moved, by −7.5 % on the
   brain and +0.3 % on the whole body.
2. Write the ETAIN import as a second script alongside `data-raw/import_sar.R`, keeping the GOLIAT
   tables in place — both are needed, GOLIAT for the ratios and for the sources of Q1.
3. Settle Q3 and implement the ratio step.
4. Convert the sources in dependency order, least entangled first: `headphones` and `smartwatch`
   (one ETAIN scenario each, no distance correction today), then `laptop` and `tablet`, then
   `cordless`, then `mobilecall` and `mobiledata`, which carry the most call sites.
5. Remove `dist_law()` and its 18 hard-coded `delta` literals once no caller remains.

This track is independent of the remaining stochastification. `dist_law()` is called by exactly the
seven sources already converted — `cordless`, `gaming`, `laptop`, `mobilecall`, `mobiledata`,
`tablet`, `virtual_reality` — and by none of the seven still deterministic. The two lines of work do
not collide, and making an input stochastic does not depend on where its SAR value comes from.

**One rule for the meantime:** add no new distance parameters. `lptp_dist_*`, `tblt_dist_device`,
`gaming_dist_pc` and the VR standoff are all removed in step 5.

Steps 2 and 3 can start on scenarios 2 and 3, the two the artefacts agree on, if there is pressure
to begin before Q7 comes back.
