# Open questions and decisions — Stochastic Dose Model

**Purpose:** one place to see everything that is currently undecided, unanswered or unresolved, so
it can be worked through in a meeting rather than rediscovered one item at a time. Grouped by **who
can answer it**, not by topic.

**Relation to the other documents:** this file holds the *questions*. The *analysis* behind each one
lives in `doc/MODEL_LIMITATIONS.md`, `doc/PARAMETER_WORKBOOK_NOTES.md`, `doc/SAR_IMPORT_NOTES.md` and
the per-source `doc/<source>_stochastification.md` files. Every entry points there.

**Status of this file:** living document. When an item is settled, move it to §F with the answer and
the date; do not delete it.

**Last updated:** 2026-09-22

---

## A. Blocking the work in progress

These stop current implementation until answered.

### A1. How far should the far-field rework go?

Far-field SAR for all four phantoms arrived 2026-09-17 (`data-raw/Final_Data_*_UGent_FF.xlsx`,
9 frequencies x 12 incidence directions, normalised to 1 W/m2). Not imported; nothing reads them.

Two independent decisions: **axis 1**, make the existing inputs stochastic (exposure levels,
time-at-location, country, urbanicity, travel time); **axis 2**, replace the single SAR scalar with
the phantom-resolved tables. Neither needs the other.

**The case for doing both:** the model draws sex and age per person, but one SAR value for everyone
means a simulated child gets the adult's far-field dose. Combining the ETAIN spectrum with the
GOLIAT phantoms gives, at Other/suburban, body 125 (Duke) / 147 (Ella) / **240 (Thelonious)** /
201 (Eartha) against today's 136 for all four. Far-field is the largest single contributor, so this
is a correction, not a refinement.

**No longer blocked.** B1 is resolved at EU level, so axis 2 is deliverable now. Seven of the ten
bands need interpolating onto the ETAIN grid, the same mechanism as `import_sar.R`; the newly
simulated 450 MHz fills the `<700` bucket that previously had to borrow the 700 MHz value.

Open sub-decisions: one spectrum or five (B1); average the 12 incidence directions or draw them
(spread across directions is a factor 1.5-4.7, growing with frequency); and whether to convert
`wifi.R` in the same release, since it shares the units and the SAR basis.

### A2. Tablet viewing distance — drawn or fixed? — *flagged, never answered*

The instruction was "always 30 cm in front of the face". That was read as settling the *position*
question (front of eyes rather than a belly mix), not as fixing the distance to a constant, so
`tblt_dist_device` is drawn around a mean of 300 mm (sd 80, bounds 200–500) like every other
distance in the model. Pinning it to exactly 300 mm is a one-line change.

Detail: `doc/tablet_stochastification.md`, "Assumptions to be revisited".

---

## B. Waiting on data from collaborators

### B1. Frequency composition of the ambient exposure, per environment — *Adriana*

**Largely resolved.** The EU-level spectrum is in
`data-raw/Input_dose_model_Final_ETAIN_nSAR.xlsx`, sheet `Farfield` row 5, attributed to
"Adriana_2023_EU": 0.08 / 0.04 / 0.15 / 0.17 / 0.23 / 0.15 / 0.02 / 0.07 / 0.07 / 0.02 over
<700 / 700 / 800 / 900 / 1800 / 2100 / 2450 / 2600 / 3500 / 5000 MHz, summing to 1. Verified: that
spectrum times ETAIN's per-band SAR reproduces its aggregated nSAR to seven digits. The spectrum is
markedly low-frequency — 1800 MHz alone carries 23 %, the two WiFi bands 4 % together.

Still missing is the **per-environment refinement**. The SDM workbook defines one set per
environment (indoor / outdoor_low / outdoor_high / trans_peak / trans_offpeak) and all 45 cells are
empty; ETAIN has one set for everything. Work can start with the single set.

### B2. Spreads for every source except mobile call and mobile data — *Hamed*

`SDM_parameters_26062026.xlsx` gives `sd`, `min` and `max` only for the `mobilecall` and
`mobiledata` sheets. For cordless, laptop, tablet, farfield, 5gauto, wifi and other those three
columns are **completely empty** — means and an intended distribution family only.

Every spread currently used for cordless, gaming, VR and tablet is therefore an assumption made
during implementation. They are listed in `doc/MODEL_LIMITATIONS.md` §D. Is a further delivery
expected, or should these stay as documented assumptions?

Detail: `doc/PARAMETER_WORKBOOK_NOTES.md` §4.

### B3. Ella's input power convention and her empty normalized sheets — *TP*

Two points, one message:

- The `*_normalized` sheets in Ella's workbook are present but entirely blank. We used the raw
  sheets and normalised ourselves. Was that intended?
- What does the `Input Power (mW)` column represent — forward/incident power at the feed, or
  accepted/radiated power?

**Why it matters:** Ella is the only phantom with no independent check on our normalisation, and she
is also the one whose stated input power is anomalous at exactly the two frequencies where her SAR
departs from the other three. A normalisation error and a genuine simulation property would look
alike.

Detail: `doc/MODEL_LIMITATIONS.md` §C4, `doc/SAR_IMPORT_NOTES.md` §6.

### B4. One extreme value in the Thelonious belly data — *UGent, low priority*

`Thelonious_body_700_belly_left_vertical_sar` is 2.7 % of the same position's 1450 MHz value, where
the other seven belly positions sit at 18–80 %. We assume genuine weak coupling for that
orientation rather than a run artefact; a confirmation would close the question. Unchanged by the
September 2026 head/trunk correction.

Detail: `doc/MODEL_LIMITATIONS.md` §C2, `doc/SAR_IMPORT_NOTES.md` §5.2.

---

## C. The parameter workbook disagrees with the implemented model

All of these come out of the systematic comparison in `doc/PARAMETER_WORKBOOK_NOTES.md` §6. Nothing
has been changed in response to any of them.

### C1. Is the workbook newer than the yaml, or older? — *answer this one first*

`SDM_parameters_26062026.xlsx` is dated 26 June 2026 and arrived in September. Several yaml values
look like they came from an earlier revision of the same file: the Beta `a0` recipe
(`a0 = mean(1−mean)/sd² − 1`) reproduces the yaml exactly wherever the means still agree, and
differs wherever they do not. Knowing the direction settles most of C2–C7 at once.

### C2. Mobile data durations differ by roughly a factor of two

Workbook 1881 / 2253 / 2355 s against yaml 3989 / 4917 / 5651 s for low / lowmed / medhigh. Mobile
data is the second largest contributor, so this is not a detail.

### C3. A specification the code does not implement

The workbook's comment on `mpd_dur_low` reads: *"these four durations should be simulated according
to their standard deviations, while ensuring that their sum always equals the input total
duration."* `simulate_params()` draws them independently, so the sum varies freely instead of being
pinned to the participant's reported total. The same applies to the tablet durations, which mirror
mobile data. Enforcing the constraint removes a real source of variance but honours the reported
total — a modelling decision, and a change to `simulate_params()` rather than to a parameter file.

### C4. Two competing sets of WiFi duty cycle means

The workbook's eight values are exactly the ones the tablet and laptop blocks carry; the mobile data
block in the yaml holds a different set. The 5 GHz high-activity entry differs by a factor of 3.4
(0.145 against 0.495). Adopt the workbook's set for mobile data too, or keep both?

**A small, well-founded fix hangs off this:** the workbook supplies the missing `sd` values for the
eight tablet duty cycles, which would replace the `a0` values borrowed from mobile data — including
the one that currently produces a near-degenerate U-shaped distribution
(`doc/MODEL_LIMITATIONS.md` §D1). It could be taken independently of the rest.

### C5. The 3G output powers exist twice, a factor of 56 apart

The workbook itself carries two value sets for the same quantity, one on each mobile sheet, and the
yaml reproduces both. Both copies are live: a 3G call over mobile data in a suburban indoor
environment uses 2.04 mW, a 3G data session in the same environment 114.02 mW. Mitigating factor:
3G carries only 2 % of data traffic.

### C6. A specified distance the code does not use

The workbook defines `mpd_dist_eye` = 200 mm ("distance of mobile phone to the eyes during mobile
phone online activities") and the yaml duly contains `mpd_dist_face` with that value — but it is
**read nowhere**. `R/mobiledata.R:551` uses the mobile *call* speaker distance of 100 mm instead.
Under the current distance law that is a factor of 3.78 on the front-of-face contribution, in the
direction of over-estimating it.

### C7. `headp_ear_num` — three sources, three answers

The workbook gives mean 2 with bounds 0–2; its own comment says *"this can not be decimal, should be
0, 1 (14 %), or 2 (86 %)"*, which implies 1.86; the yaml draws it from a Beta with mean 0.95, which
can only produce values in [0, 1]. A Beta cannot represent a count of earpieces.

### C8. The belly-proxy brain geometry assumes a standing user, and `height/2` is too large

Four sources rescale a belly SAR value to the brain through the hypotenuse
`sqrt((height/2)² + d²)` against `sqrt((height/2)² + 200²)`: `mobilecall` (2 places),
`mobiledata` (1), `gaming` (1) and now `laptop` (1). Two separate problems sit in that `height/2`.

**It does not match the anatomy.** The navel sits at roughly 0.60 of stature and the brain centre at
roughly 0.94, so the belly-to-brain offset is about `height/3`, not `height/2`. For Duke the
convention says 885 mm where anatomy says about 600 mm — an overestimate of roughly 50 %, in every
source that uses it.

**It assumes the simulation and the modelled scenario share the same offset.** `height/2` appears in
both numerator and denominator, so the formula only rescales the *horizontal* component. That is
right when the modelled scenario matches the simulated one (phone at the belly, standing). It is not
right for a laptop, where the antenna sits in the screen bezel about 20 cm above belly height, nor
for a handheld console held at chest level. Deriving the antenna-to-brain distance directly for a
seated laptop user gives 444–633 mm against the convention's 614–988 mm.

**Size of the effect, measured on laptop:** the antenna-height correction alone is worth about +35 %
on the brain dose; using directly derived distances is worth about ×2.8.

**Why it was left alone.** The brain channel through a belly proxy is the least trustworthy part of
the model — §A1 of `doc/MODEL_LIMITATIONS.md` measures the bare position effect for the brain at a
factor of 4.2 to 105.7 — so a 2.8× refinement sits below the noise of the method that computes it.
And a correct treatment needs the simulation's own geometry, which is documented nowhere; we infer a
standing phantom with the antenna at belly height from the position names and the Virtual Population
postures, but that is an inference.

**The question:** keep the convention for all four sources, correct `height/2` to something
anatomical for all four, or introduce separate simulation and scenario offsets? It should be decided
once for all belly proxies, not per source.

Detail: `doc/laptop_stochastification.md`, "What is deliberately not modelled".

### C9. The far-field environment scheme does not match the code

The workbook splits the day into *indoor / outdoor_low / outdoor_high / trans_peak / trans_offpeak /
workplace*; `R/farfield.R` uses *home / work / out / travel*. The workbook merges home and work into
"indoor" and splits outdoors and transport in two. The two schemes do not map onto each other, and
the frequency proportions of B1 are defined per workbook environment.

---

## D. Accepted approximations — no action planned, but worth knowing

These are documented and deliberately left as they are. Listed here only so a supervisor can
reopen one if they disagree with the call.

Section numbers in the last column refer to **`doc/MODEL_LIMITATIONS.md`**, not to this file.

| | what | in MODEL_LIMITATIONS.md |
|---|---|---|
| D1 | The inverse-square distance law does not match the data between the two simulated distances (measured 2.5–14.5× where it predicts 216×) | §A1 |
| D2 | The phone-in-pocket case rescales the belly geometry from 20 cm to 8 mm — the largest rescaling in the model, applied to the largest whole-body source | §A2 |
| D3 | Seven of the ten model frequencies are interpolated, two across gaps above 1000 MHz | §A3 |
| D4 | Phantoms disagree 7–11× at 700 and 835 MHz, against 2.4–3.8× above 1450 MHz; no correction applied | §C1 |
| D5 | WiFi output power distributions are truncated at their own mean, so the realised mean is 21 % below nominal | §C3 |
| D6 | All placeholder parameters for VR, gaming, tablet and laptop — durations, duty cycles, distances, concentrations | §D |

---

## E. Code issues — no decision needed, just work

- **Two sources still read parameter keys that exist only in the legacy `params.yaml`** and error
  out on a simulated parameter set: `R/farfield.R:66-68` and `R/wifi.R:18-20`
  (`global$home_prop` and siblings, which live under `global$environment_prop` everywhere else).
  Harmless today because `total.R` calls them with `old_params`; it falls due at stochastification.
  (`R/laptop.R` was the third until 2026-09-21.)
- **`delta` is hard-coded 18 times and appears in no yaml.** The near-field offset in `dist_law()`
  is written as a literal `6` at every call site: `mobilecall` (9), `mobiledata` (3), `cordless` (2),
  `gaming` (2), `tablet` (1), `virtual_reality` (1), plus laptop's two. It only bites below about
  10 cm — it changes the result by 65 % at 8 mm, 6 % at 100 mm and nothing at the 200 mm reference —
  so for tablet, laptop and gaming it is irrelevant, and for the ear, the VR standoff and the
  pant-pocket case it is decisive. Since §A1 of `doc/MODEL_LIMITATIONS.md` identifies `delta` as the
  most plausible lever for improving the distance law (the data would want about 100 mm, not 6),
  testing any alternative currently means editing 18 lines. It belongs in the yaml.
- `R/mobilecall.R:82` contains a leftover `print(params$global$sim)` that floods the console.
- `params$device$call$phone_positions` is read with `device` singular at 10 places across
  `R/mobilecall.R`, `R/cordless.R` and `R/mobiledata.R`. It works only through partial matching.
- Two stale labels in `R/total.R`: mobile data (line 181) and cordless (line 234) are marked
  `DETERMINISTIC` but both are called with `sim_params`.
- `tests/testthat/test-get-other-dose.R` and `test-get-cordless-dose.R` call functions that no
  longer exist. The shipped testthat suite is not a reliable regression net.
- Body masses are not stored in the yaml, only heights. `tests/test_vr.R` and `tests/test_tablet.R`
  hard-code the IT'IS figures for the absorbed-power check.
- `params.yaml` and `params_template.yaml` disagree on the legacy SAR values of VR (factor 1.6–1.9),
  tablet (1.12–1.96) and laptop (0.33–2.52, and in opposite directions for brain and body) with
  nothing explaining it. All are retired as each source is converted.

---

## F. Recently settled

| date | question | answer |
|---|---|---|
| 2026-09-22 | Do `wifi.R` and `farfield.R` double-count WiFi? | No. Adriana's campaign measured outdoors and in public indoor spaces only, so it never captured a participant's own router. `farfield.R` covers other people's transmitters, `wifi.R` the person's own — disjoint sets, correctly additive. `MODEL_LIMITATIONS.md` §A4 |
| 2026-09-22 | Are `wifi_2_pwr` 0.018 / `wifi_5_pwr` 0.013 a total already split 58/42, making the dose a factor 1.84 too low? | No. They are HERMES3 personal measurements, the mean of a home and a school value per band (0.01496/0.02167 and 0.00931/0.01653). The apparent 58/42 split is an artefact of rounding to two decimals — the unrounded ratio is 1.418, the band split 1.381. |
| 2026-09-22 | Where do the far-field exposure levels and the WiFi SAR constants come from? | `data-raw/Input_dose_model_Final_ETAIN_nSAR.xlsx`. The per-country levels are in sheet `Farfield` verbatim; the WiFi SAR are that sheet's far-field per-band values at 2450 and 5000 MHz. The 0.017/0.016 predecessors were 0.08/0.077 V/m converted via E²/377. |
| 2026-09-22 | Does `params.yaml` disagreeing with the other two on the WiFi SAR indicate an accident? | No — the reverse of what was assumed. `params_stochastic.yaml` and `params_template.yaml` carry the frequency-resolved far-field values at the actual WiFi bands; `params.yaml` still has the older band-independent ETAIN value. The newer files are the correct ones. |
| 2026-09-21 | Which SAR geometry should the laptop borrow? | Both positions from the belly mean, distinguished only by distance — lap 200 mm, table 450 mm. Deliberately kept simple: the seated posture is not modelled and the brain keeps the `height/2` hypotenuse. `laptop_stochastification.md` |
| 2026-09-18 | Do the corrected UGent SAR files change the model? | No. The correction was confined to `SAR_head` and `SAR_trunk`, which this model never reads; `SAR_wholebody` and `SAR_brain` are unchanged. `SAR_IMPORT_NOTES.md` §5.6 |
| 2026-09-17 | Are the UGent ear positions mapped correctly by ordinal number? | Yes — confirmed independently when UGent dropped the `_base`/`_up`/`_down` suffixes. `SAR_IMPORT_NOTES.md` §5.4 |
| 2026-09-16 | Which position should the tablet use? | Front of eyes throughout, at 30 cm. `tablet_stochastification.md` |
| 2026-09-15 | Are the low-frequency SAR deviations an import error? | No — inherent simulation uncertainty at low frequencies. No correction applied. `SAR_IMPORT_NOTES.md` §5.0 |
