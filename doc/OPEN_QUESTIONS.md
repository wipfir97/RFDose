# Open questions and decisions — Stochastic Dose Model

**Purpose:** one place to see everything that is currently undecided, unanswered or unresolved, so
it can be worked through in a meeting rather than rediscovered one item at a time. Grouped by **who
can answer it**, not by topic.

**Relation to the other documents:** this file holds the *questions*. The *analysis* behind each one
lives in `doc/MODEL_LIMITATIONS.md`, `doc/PARAMETER_WORKBOOK_NOTES.md`, `doc/SAR_IMPORT_NOTES.md` and
the per-source `doc/<source>_stochastification.md` files. Every entry points there.

**Status of this file:** living document. When an item is settled, move it to §F with the answer and
the date; do not delete it.

**Last updated:** 2026-09-18

---

## A. Blocking the work in progress

These stop current implementation until answered.

### A1. Which SAR geometry should the laptop borrow? — *asked, awaiting reply*

GOLIAT simulated three geometries, all of them phone positions: front of eyes (20 cm), belly
(20 cm), ear (0.8 cm). The deterministic model used two dedicated ETAIN scenarios, "on the lap" and
"on the table", and unlike tablet and gaming — whose values turned out to be copies of the
phone-in-front-of-face numbers — the laptop values are genuinely its own and are reused nowhere
else. Neither remaining geometry describes a laptop.

A refinement emerged after the question was sent: the WiFi antennas sit in the screen bezel, so in
**both** scenarios the source is at roughly sternum height with a nearly horizontal path to the
body. That argues for the **belly** geometry in both cases, differing only in distance, rather than
front-of-eyes for the table case. It also means every laptop distance (30–60 cm) and the 20 cm
reference are all in the far field at both bands, so the distance law is on firmer ground here than
anywhere else in the model.

**Why it matters:** laptop is by a wide margin the largest whole-body contributor among the WiFi
devices — 173 mJ/kg/day at the deterministic point values, against 13 for tablet on the same basis.

Detail: the plan and the candidate numbers are in the working notes; §B of
`doc/MODEL_LIMITATIONS.md` records the general proxy problem.

### A2. How far should the far-field rework go?

Far-field SAR simulations for all four phantoms arrived on 2026-09-17 (four `*_FF.xlsx` files in
`data-raw/`, 9 frequencies × 12 incidence directions, already normalised to 1 W/m²). They are **not
imported** and nothing in the code reads them.

This splits into two genuinely independent decisions:

| | what | needs the new data? |
|---|---|---|
| axis 1 | make the existing inputs stochastic — ambient exposure levels, time-at-location proportions, country | no |
| axis 2 | replace the single SAR scalar with phantom-, frequency- and direction-resolved tables | yes |

**The argument for coupling them:** the model already draws sex and age per person, but with one SAR
value for everyone a simulated child receives exactly the adult's far-field dose. The new data says
a child absorbs 1.7–2.1× more per unit incident power. Far-field is the single largest contributor
to the total dose, so this is a substantive correction rather than a refinement.

**The complication:** using the frequency resolution requires the frequency composition of the
ambient exposure, which is missing (see B1). Averaging over frequencies instead is possible but the
frequency dependence is as strong as the phantom effect (factor 2.2 against 1.9), and a flat average
would *lower* the adult doses by about 16 % as an artefact of the weighting. A conservative middle
option is to apply only the phantom ratios and keep today's overall level as the Duke reference.

Detail: `doc/farfield_notes.md` does not exist yet; the analysis is in the working notes.

### A3. Tablet viewing distance — drawn or fixed? — *flagged, never answered*

The instruction was "always 30 cm in front of the face". That was read as settling the *position*
question (front of eyes rather than a belly mix), not as fixing the distance to a constant, so
`tblt_dist_device` is drawn around a mean of 300 mm (sd 80, bounds 200–500) like every other
distance in the model. Pinning it to exactly 300 mm is a one-line change.

Detail: `doc/tablet_stochastification.md`, "Assumptions to be revisited".

---

## B. Waiting on data from collaborators

### B1. Frequency composition of the ambient far-field exposure — *Adriana*

The measured exposure levels are one number per country × environment (`home_sub_pwr_Other: 0.27`
mW/m² and so on). To use the new frequency-resolved far-field SAR we need to know how that level
splits across bands. The parameter workbook already defines the structure —
`frq7/8/9/18/21/24/26/35/50_ff_<environment>_prop`, Dirichlet, attributed to Adriana — but **every
value is empty**. This blocks the full version of A2.

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

### C8. The far-field environment scheme does not match the code

The workbook splits the day into *indoor / outdoor_low / outdoor_high / trans_peak / trans_offpeak /
workplace*; `R/farfield.R` uses *home / work / out / travel*. The workbook merges home and work into
"indoor" and splits outdoors and transport in two. The two schemes do not map onto each other, and
the frequency proportions of B1 are defined per workbook environment.

---

## D. Accepted approximations — no action planned, but worth knowing

These are documented and deliberately left as they are. Listed here only so a supervisor can
reopen one if they disagree with the call.

| | what | where |
|---|---|---|
| D1 | The inverse-square distance law does not match the data between the two simulated distances (measured 2.5–14.5× where it predicts 216×) | `MODEL_LIMITATIONS.md` §A1 |
| D2 | The phone-in-pocket case rescales the belly geometry from 20 cm to 8 mm — the largest rescaling in the model, applied to the largest whole-body source | §A2 |
| D3 | Seven of the ten model frequencies are interpolated, two across gaps above 1000 MHz | §A3 |
| D4 | Phantoms disagree 7–11× at 700 and 835 MHz, against 2.4–3.8× above 1450 MHz; no correction applied | §C1 |
| D5 | WiFi output power distributions are truncated at their own mean, so the realised mean is 21 % below nominal | §C3 |
| D6 | All placeholder parameters for VR, gaming and tablet — durations, duty cycles, distances, concentrations | §D |

---

## E. Code issues — no decision needed, just work

- **Three sources still read parameter keys that exist only in the legacy `params.yaml`** and error
  out on a simulated parameter set: `R/laptop.R:156` (`global$wifi_2_prop`), `R/farfield.R:66-68`
  and `R/wifi.R:18-20` (`global$home_prop` and siblings, which live under
  `global$environment_prop` everywhere else). Harmless today because `total.R` calls them with
  `old_params`; it falls due at stochastification.
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
| 2026-09-18 | Do the corrected UGent SAR files change the model? | No. The correction was confined to `SAR_head` and `SAR_trunk`, which this model never reads; `SAR_wholebody` and `SAR_brain` are unchanged. `SAR_IMPORT_NOTES.md` §5.6 |
| 2026-09-17 | Are the UGent ear positions mapped correctly by ordinal number? | Yes — confirmed independently when UGent dropped the `_base`/`_up`/`_down` suffixes. `SAR_IMPORT_NOTES.md` §5.4 |
| 2026-09-16 | Which position should the tablet use? | Front of eyes throughout, at 30 cm. `tablet_stochastification.md` |
| 2026-09-15 | Are the low-frequency SAR deviations an import error? | No — inherent simulation uncertainty at low frequencies. No correction applied. `SAR_IMPORT_NOTES.md` §5.0 |
