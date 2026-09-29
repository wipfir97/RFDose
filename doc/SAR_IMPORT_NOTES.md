# SAR import notes

**Date:** 2026-09-14, substantially extended 2026-09-28
**Scope:** import of the simulated SAR values into `inst/extdata/params_stochastic.yaml` and
`inst/extdata/params_template.yaml`, for both campaigns.
**Status:** complete. Everything goes through one script, `data-raw/import_sar.R`. The
low-frequency behaviour described in §5 is understood to be an inherent property of SAR
simulations rather than a data or import error (§5.0), and the ear position naming is resolved
(§5.4).

Sections 1, 3 and 4 were rewritten on 2026-09-28, when the model frequency grid changed and the
ETAIN campaign was added. §5 and §6 predate that and describe the GOLIAT delivery only; nothing
in them was invalidated.

---

## 1. Summary

The yaml now carries **three** SAR sets side by side.

| | GOLIAT near field | ETAIN near field | GOLIAT far field |
|---|---|---|---|
| geometries | 3 (front of eyes, belly, ear), 22 antenna positions | 9 scenarios | plane waves, 12 incidence directions |
| frequencies | 700, 835, 1450, 2140, 2450, 3500, 5200, 5800 | the nine model bands exactly | 450, 700, 835, 1450, 2140, 2450, 3500, 5200, 5800 |
| phantoms | all four | Duke, Ella | all four |
| normalised to | 1 W input power | 1 W input power | 1 W/m² incident power density |
| onto the model grid | interpolated, 6 of 9 bands | nothing to do | nearest node per band |

All three are needed. In the **near field**, GOLIAT covers `gaming`, `virtual_reality` and
`hotspot`, for which ETAIN has no scenario, and supplies the child-to-adult ratios that will fill
Thelonious and Eartha on the ETAIN side; ETAIN has dedicated simulations for the laptop, Bluetooth
earbuds and a wrist device, which GOLIAT would otherwise approximate with a phone geometry. The
**far field** goes to GOLIAT outright, because it simulated all four phantoms there and so needs
no ratios at all. The reasoning is in `doc/SAR_REDESIGN.md`.

The far field is a different physical quantity from the other two. It is normalised to an incident
**power density** rather than to a radiated power, so its values answer "how much does this body
absorb from a field of 1 W/m²" while the near-field values answer "how much from a source
radiating 1 W". They are not comparable and must never be mixed; the `_farfield_` fragment in the
key marks the difference.

### The campaign is part of the key

```
Duke_body_goliat_2450_belly_center_vertical_sar
Duke_body_etain_2450_lap_sar
```

`<phantom>_<tissue>_<campaign>_<frequency>_<placement>_sar`.

The campaign segment is not there to avoid name collisions — the placement names of the two
campaigns are distinct anyway. It is there because **the two campaigns disagree**, by up to a
factor of two, and the disagreement grows with frequency (`doc/SAR_REDESIGN.md` §3.1). Where a
value came from has to be readable off the key rather than inferred from knowing which placement
names belong to which campaign.

`headp_else_sar` keeps its old shape without a campaign segment. It is a legacy placeholder,
always zero, belonging to neither campaign.

### How the key count works

| | per tissue | per phantom (body + brain) |
|---|---|---|
| yaml keys | 356 | **712** |
| real values, Duke and Ella | 267 | 534 |
| real values, Thelonious and Eartha | 208 | 416 |

- **356 keys per tissue** = 1 `headp_else_sar`
  + 22 GOLIAT near-field positions × 12 frequency tokens (9 model bands + 3 reserved) = 264
  + 10 GOLIAT far-field bands = 10
  + 9 ETAIN scenarios × 9 model bands = 81
- **198 GOLIAT near-field values per tissue** = 22 positions × 9 model bands, the same for every
  phantom.
- **10 GOLIAT far-field values per tissue**, for every phantom. Ten rather than nine because the
  ambient spectrum has a "below 700 MHz" bucket that the near-field grid does not; it is labelled
  450 after the node GOLIAT simulated for it. Three pairs of bands share a node, so three pairs of
  keys hold the same number — see §3c.
- **59 ETAIN values per tissue**, Duke and Ella only = 6 scenarios × 9 bands, plus the two earbud
  scenarios at 2450 and 5000 MHz only and the wrist at 2450 alone. Those three were simulated at
  fewer frequencies; the unsimulated combinations stay 0 rather than being interpolated across the
  gap (§3).
- **Thelonious and Eartha have all 81 ETAIN keys set to 0.** ETAIN simulated only Duke and Ella.
  Filling them from GOLIAT ratios is a separate step, still open — `doc/SAR_REDESIGN.md` Q3.
- The 3 reserved frequency tokens `xxxx`, `yyyy`, `zzzz` exist in the GOLIAT block only. They
  reserve a slot in the model's band list for future 5G/6G bands; duplicating them under both
  campaigns would reserve the same slot twice.

The import pipeline is validated by reproducing every GOLIAT value already in the yaml
byte-for-byte — 530 of 530 for Duke — so the mechanics (normalisation, interpolation, naming,
formatting) are demonstrably correct.

Ella and Thelonious both show pronounced deviations at the two lowest simulated frequencies
(700 and 835 MHz). These were initially investigated as possible import or normalisation errors and
were ruled out as such; they reflect the well-known large uncertainty of SAR simulations in that
band (§5.0). Eartha and Duke are smooth across the whole range.

---

## 1b. Where the simulations come from, and at what distance

The stochastic model uses the **GOLIAT** SAR campaign; the deterministic model used **ETAIN**
(Yoda database). The two differ in both scenarios and frequencies, which is why the values have to
be interpolated (§3).

GOLIAT simulated three antenna positions, at these separations from the body — this is the source
of the `dist_ref` values used throughout the model:

| scenario | separation | positions |
|---|---|---|
| Front of eyes | **20 cm** | center / left / right / down × vertical / horizontal |
| Belly | **20 cm** | center / left / right / up × vertical / horizontal |
| Ear | **0.8 cm** | cheek_1–3, tilt_1–3 |

So `dist_ref = 200` (front_of_eyes, belly) and `dist_ref = 8` (ear) in `mobilecall.R`,
`mobiledata.R`, `cordless.R` and `gaming.R` are correct. Note that the code comment at
`cordless.R:99` and `mobilecall.R:498` reads "because **eye** simulations ware at 8 mm" — that is a
typo for **ear**; the 8 mm belongs to the ear scenario, as the table above shows.

Phantoms in the GOLIAT campaign: Duke (36), Ella (26), Eartha (8), Thelonious (6); SAR below 6 GHz,
near- and far-field, whole-body and brain.

**Consequence for any source that is not a phone.** GOLIAT provides only these three geometries.
Every other exposure source therefore has to borrow one of them as a proxy — gaming uses the belly
positions, and a VR headset will have to choose between front_of_eyes (right anatomy, but simulated
at 20 cm) and ear (wrong anatomy, but the only scenario in the right distance regime at 0.8 cm).
The same question will arise for laptop and tablet, which under ETAIN had dedicated lap and table
scenarios that GOLIAT does not reproduce.

**One discrepancy to keep in mind:** the GOLIAT frequency list on the source slide reads 700, 835,
1450, 2140, 2450, 5200, 5800, but the delivered workbooks contain **3500 MHz as well**, for every
phantom and position. The slide appears to be incomplete rather than the data being wrong.

## 2. Source files

| Phantom | File | Provider | Sheets |
|---|---|---|---|
| Duke | `Duke_male_adult_NF.xlsx` | — | raw + `*_normalized` for fronteyes/belly/ear |
| Ella | `Final_Data_TP_Ella_NF_normalized.xlsx` | TP | raw + `*_normalized` (**the normalized sheets are entirely empty — all NA**) |
| Thelonious | `Final_Data_UGent_normalized.xlsx` | UGent | raw + `*_normalized` (`fronteyes`, `belly`, `ear`) |
| Eartha | `Final_Data_UGent_normalized.xlsx` | UGent | raw + `*_normalized` (`fronteyes`, `belly`, `ear`) |

Thelonious and Eartha now come from one consolidated UGent workbook. It replaced the two
per-phantom files `Final_Data_UGent_{Thelonious,Eartha}_NF.xlsx` on 2026-09-17 — see §5.6 for what
that correction did and did not change.

The workbooks are not consistent with each other. Differences that had to be handled:

- **Sheet names**: `Ella_front` vs `*_fronteyes`; `Ella_ ear` contains a stray space;
  UGent's superseded files used `_cheek` where Duke uses `_ear` (the consolidated workbook uses
  `_ear`).
- **Column names**: `frequency_mhz` vs `frequency_MHz`; `Input Power (mW)` vs
  `Input power (mW)` (lowercase p, Duke's ear sheet) vs `Input Power  (mW)` (two spaces, Ella);
  `SAR_brain (mW/kg)` vs `SAR averagedbrain(mW/kg)` (Ella).
- **Column order** differs between Ella and Duke, so columns are resolved by name, never by position.
- **Placement names**: UGent's superseded files used `cheek_1_base`, `cheek_2_up`, `cheek_3_down`,
  `tilt_1_base`, `tilt_2_up`, `tilt_3_down`; Duke, Ella and the consolidated UGent workbook use
  `cheek_1` … `tilt_3`. The importer still strips the suffixes, so both spellings work.
- **Data types**: Duke's `SAR_trunk` column is text because one cell contains `<<<`. The importer
  refuses non-numeric columns rather than silently coercing them to NA.

---

## 3. What the import does

### 3a. GOLIAT — one uniform pipeline for all four phantoms

1. **Resolve columns by canonicalised name** (lowercase, runs of space/underscore collapsed).
   Exactly one match required per field, otherwise the run aborts.
2. **Normalise each row to 1 W input power, using that row's own input power:**

   ```
   SAR_1W [mW/kg] = SAR_raw [mW/kg] × 1000 / InputPower_row [mW]
   ```

   This is per row, **not** per file: input power varies by frequency in every sheet of every
   workbook (see §5.1). Using a single scale factor would be wrong by up to 80 %.
3. **Interpolate** linearly per position (`approx(rule = 1)`) onto the nine model frequencies
   700, 800, 900, 1800, 2100, 2450, 2600, 3500, 5000 MHz. All nine lie inside the simulated
   range 700–5800 MHz, so no extrapolation occurs and no NA are produced. If a future delivery had
   a narrower range, the importer aborts rather than writing 0 — 0 is the model's "no data yet"
   sentinel and must not be produced by accident.

   GOLIAT hits only **three** of the nine bands exactly — 700, 2450 and 3500 — so six are
   interpolated. Its node at 1450 MHz no longer lands on a model band. That conflicts with the
   decision to stop interpolating, and is why GOLIAT is now the fallback rather than the primary
   source: see `doc/SAR_REDESIGN.md` §4.
4. **Rename placements** to the yaml key fragments: `belly_level_X` → `belly_X`;
   `cheek_1` and `cheek_1_base` → `cheek1`; `tilt_3_down` → `tilt3`; `front_of_eyes_*` unchanged.
   Any placement that does not map to one of the 22 known fragments aborts the run.
5. **Map tissues**: yaml `body` ← `SAR_wholebody`, yaml `brain` ← `SAR_brain`
   (`SAR averagedbrain` for Ella). `SAR_head`, `SAR_trunk` and the `psSAR10g_*` columns are
   not used by the model.
6. **Write both yaml files** with Duke's exact key naming, ordering, numeric format (`paste0`,
   15 significant digits, no scientific notation) and CRLF line endings.

### 3b. ETAIN — read as simulated, nothing derived

ETAIN needs a different reader: one row per (scenario, frequency) with the phantoms in *columns*,
where GOLIAT has one row per (frequency, placement) per phantom, and the scenario number is written
once per block and left blank below it. Two steps of 3a are deliberately **not** applied.

**No normalisation.** The ETAIN columns are already per 1 W input power — the header says
`[mW/kg/W]`. Dividing again would shrink every value by roughly a factor of 500 and nothing
downstream would notice, which is what validation D exists to catch (§4).

**No interpolation.** The nine ETAIN frequencies *are* the nine model bands, so there is nothing to
interpolate. The script asserts that rather than assuming it: any ETAIN frequency that is not a
model band aborts the run, because `build_block()` would otherwise drop it silently.

Running ETAIN through the generic `interpolate()` would actively corrupt it. Its scenarios do not
all cover the same frequencies — the earbuds were simulated at 2450 and 5000 MHz only, the wrist at
2450 alone — so `complete()` would insert the other seven bands as NA and `approx()` would then
*invent* an earbud value at 2600 and 3500 MHz by interpolating across the gap, and leave NA below
2450. Those combinations were never simulated and stay 0.

**Scenario numbering.** ETAIN's own, and confirmed by the data rather than taken on trust: scenario
1 has a brain SAR of 40.8 mW/kg/W at 1800 MHz and scenario 4 has 0.0007, which can only be the ear
and the hip respectively. The frequency coverage confirms the rest — 7 and 8 exist at two
frequencies, 9 at one, exactly as the campaign specifies.

| scenario | key fragment | model source it will serve |
|---|---|---|
| 1 — 45° tilted, 1 cm from the right ear | `ear` | `mobilecall` at ear, `cordless` |
| 2 — vertical, 10 cm in front of the mouth | `mouth10` | `mobilecall` speaker mode |
| 3 — vertical, 30 cm in front of the mouth | `mouth30` | `mobiledata` |
| 4 — vertical on the right hip, 1 cm | `hip` | phone in pocket |
| 5 — on the legs, phantom seated | `lap` | `laptop` on the lap |
| 6 — 10 cm higher, 30 cm further than 5 | `table` | `laptop` on a table |
| 7, 8 — next to the right / left ear, 1 mm | `earbud_r`, `earbud_l` | `headphones` |
| 9 — horizontal on the right wrist, 1 mm | `wrist` | `smartwatch` |

**No source reads these keys yet.** The values are in the yaml; switching the sources over is a
later step and depends on three open questions — `doc/SAR_REDESIGN.md` Q1, Q2 and Q3.

### 3c. GOLIAT far field — averaged over direction, mapped onto the spectrum

A separate campaign product: plane waves from 12 incidence directions at 9 frequencies, for all
four phantoms, one file each (`Final_Data_<phantom>_UGent_FF.xlsx`). Read by `read_farfield()`,
section 4c.

**Normalised to 1 W/m² of incident power density**, not to a radiated power, so section 4's
division must not be applied. The reader refuses to continue if any row quotes a different power
density.

**The 12 directions are averaged.** The spread across them is a factor of 1.5 to 4.7, growing with
frequency, but a person turns during the day; drawing one direction would assert a fixed
orientation over 24 hours.

**Each band takes its nearest simulated node**, since the model no longer interpolates:

| band | 450 | 700 | 800 | 900 | 1800 | 2100 | 2450 | 2600 | 3500 | 5000 |
|---|---|---|---|---|---|---|---|---|---|---|
| node | 450 | 700 | 835 | 835 | 2140 | 2140 | 2450 | 2450 | 3500 | 5200 |

Three pairs therefore share a node and the yaml holds the same number twice. That is deliberate:
it shows where a band rests on a neighbour's simulation instead of hiding it behind an
interpolated value. GOLIAT's nodes at 1450 and 5800 MHz go unused here.

The weighting across bands happens at **run time**, in `farfield_sar()`, not at import — the
spectrum stays a visible parameter. See `doc/farfield_stochastification.md`.

### 3d. Two traps worth knowing before editing the script

**`splice()` no longer compares the two files line for line.** It used to, and that was valid while
every re-import wrote the same number of keys. The grid change of 2026-09-28 breaks that assumption
— 1450 vanishes, 2400 becomes 2450 — so the check is now the stronger statement it was standing in
for: strip the SAR key lines of the phantoms being written from both the old and the new file, and
the remainder must be identical and in the same order. That still guarantees nothing outside those
key runs moved.

**Scientific notation must never reach the yaml, and the guard against it is not cosmetic.**
YAML 1.1 only recognises a float in exponent form if the mantissa carries a decimal point:

```yaml
k: 2e-06      # read back as the CHARACTER STRING "2e-06"
k: 2.0e-06    # read back as a number
```

R's `paste0()` produces the first form. Five ETAIN brain values — hip, lap, table and wrist, down to
about 1e-9 — would have been written that way and would have come back as text, with no error
anywhere. `fmt()` therefore writes any such value in full decimal instead. It also formats **one
value at a time**: given a vector, `format()` chooses a single layout for all of it and pads every
element to the decimal places the smallest one needs, writing digits past what a double can carry.

Script: **`data-raw/import_sar.R`**. It lives in `data-raw/` rather than `R/` because it is a
data-preparation script, not package code — `data-raw` is already listed in `.Rbuildignore`.
It supersedes `R/sar_interpolation.R`, which is Duke-only, was run by hand once per sheet, and no
longer executes (it points at a filename that does not exist and drops columns the new workbooks
do not have).

---

## 4. Validation

**Duke round-trip.** Running Duke through the pipeline and comparing against the values already in
the yaml. The figure was 574 / 574 when the grid had ten bands and the keys carried no campaign
segment; it is **530 / 530** on the nine-band grid, and it stayed at 530 / 530 across the campaign
rename, which is what showed the rename changed no value.

- Reading Duke's delivered `*_normalized` sheets (the path the original script used):
  byte-identical, max relative deviation 4.7e-15.
- Recomputing from Duke's **raw** sheets: 8 differences, explained in §5.5.

This confirms the interpolation, the placement renaming, the tissue mapping and the numeric
formatting are exactly what produced Duke's existing numbers.

Because the check matches on key names, it has to survive a rename while one is in flight. It
therefore strips the campaign segment from both sides before matching; keys that exist on only one
side — the 1450 and 2400 keys that the grid change removed — simply do not merge and are skipped.
Once the yaml carries the new names the stripping is a no-op and the check is exact again.

**Normalisation cross-check against the institutes (validation C, added 2026-09-17).** Each
workbook ships a `<sheet>_normalized` companion in which the institute did the 1 W division itself.
The importer now compares its own per-row normalisation against those sheets:

| phantom | fronteyes | belly | ear |
|---|---|---|---|
| Duke | 1.8e-15 | 0 | **1.1e-07** (2 cells) |
| Ella | *empty sheet* | *empty sheet* | *empty sheet* |
| Thelonious | 0 | 0 | 0 |
| Eartha | 0 | 0 | 0 |

*(max relative deviation between our normalisation and theirs)*

Duke's two ear brain cells are the rounded constants described in §5.5 — expected, and the reason
the run aborts only above 1e-6 rather than at exact equality. Everything else agrees to the bit.

This check only became possible for Thelonious and Eartha with the consolidated workbook; before
that, only Duke's normalisation was verifiable against an independent derivation. **Ella remains the
one phantom with no cross-check at all**, because TP delivered her `_normalized` sheets as empty
placeholders. Her values rest entirely on our own division by the stated input power — which is
also the phantom with the anomalous 813 / 636.9 mW powers at 700 and 835 MHz (§5.1).

**ETAIN absorbed power (validation D, added 2026-09-28).** The check that ETAIN is not normalised
a second time. It is physical: at 1 W of input power the body cannot absorb more than 1 W, so
SAR [mW/kg/W] × mass [kg] / 1000 must stay below 1.

| | Duke | Ella |
|---|---|---|
| absorbed fraction, across all scenarios and frequencies | 0.034 – 0.910 | 0.036 – 0.885 |

The largest is the earbud in the ear, the smallest the antenna 30 cm in front of the mouth — the
ordering a reader would predict. The run aborts if any value reaches 1 **or if the maximum falls
below 0.01**: a wrongly divided value would come out around 0.0001, so the test catches the error
by the values being far too small, not only by their exceeding 1.

As an independent cross-check across campaigns, GOLIAT's ear geometry at 1800 MHz absorbs 75.8 %
of the radiated power and ETAIN's ear scenario 78.8 %. Two separate campaigns landing within four
percentage points is good evidence that both are on the same 1 W normalisation.

**Far field against the value it replaces (validation E, added 2026-09-29).** The far field is
normalised to an incident power density, not to a radiated power, so the "absorbed fraction below
1" argument of validation D does not apply — a body intercepts a cross-section of the wave, and
how much that is depends on area, not on a source output. What the check does instead is compare
the order of magnitude against the scalar the deterministic model used, which came from ETAIN's
own far-field set (4.655 mW/kg per W/m² whole body, 5.439 brain), and abort beyond a factor of
five. Duke lands within 10 % of it, which is the evidence that the units are right; the children
come out 47 to 76 % higher, which is the correction the resolution exists to make.

**Idempotence.** Re-running the importer on an already-imported yaml reports `0 lines changed` and
leaves both files byte-identical. A non-zero diff on a re-run therefore means the source data
changed, not that the script is noisy.

**Other checks:** both yaml files parse; the zeros are exactly the `xxxx`/`yyyy`/`zzzz` placeholder
bands, the two `headp_else` keys, the ETAIN scenario/frequency combinations that were never
simulated, and the whole ETAIN block for Thelonious and Eartha; no NA; no negative SAR; heights
preserved (Duke 1770, Ella 1630, Eartha 1360, Thelonious 1160 mm); no scientific notation anywhere
in either file; Monte Carlo runs with free sex/age produce 0 zero-doses out of 200 (before the
phantoms were imported, ≈ 65 %).

---

## 5. Observations and limitations

### 5.0 Interpretation of the low-frequency deviations

Sections 5.1 and 5.2 document large deviations at 700 and 835 MHz for Ella and Thelonious. These
were investigated first as suspected errors in the delivered data, in our normalisation, or in the
import. **That has been ruled out**, on two grounds:

- The import itself is verified: the same pipeline reproduces Duke's 574 existing values
  byte-for-byte (§4), and the interpolation was shown to be bit-identical to the previous
  implementation.
- SAR simulations are known to carry substantial uncertainty and between-model variation, and this
  is most pronounced at the low frequencies — 700 and 800 MHz in particular. The deviations we see
  are therefore an **inherent limitation of the underlying simulations**, not a defect introduced
  downstream.

This is consistent with the pattern in the data: Duke and Ella come from different institutes with
different antenna and feed models, and Ella's stated input power differs from everyone else's
precisely at 700 and 835 MHz while converging with the others from 1450 MHz upward. A differing
low-frequency source model shifts every simulated position together, which is what we observe.

**Consequence for the model:** the values are kept as imported. No correction factor is applied —
inventing one would substitute our assumption for the simulation. The material point for the
stochastic dose model is that SAR at 700–900 MHz should be treated as carrying markedly larger
uncertainty than at higher frequencies (see §7 for how this might be represented).

### 5.1 Ella — whole-body SAR is much lower at 700 and 835 MHz

Ella's stated input power differs from everyone else's, and only at the bottom of the band:

| MHz | 700 | 835 | 1450 | 2140 | 2450 | 3500 | 5200 | 5800 |
|---|---|---|---|---|---|---|---|---|
| Duke / Thelonious / Eartha | 267 | 228 | 106 | 78 | 74 | 55 | 53 | 54 |
| **Ella** | **813** | **636.9** | 131.7 | 85.5 | 72.5 | 58 | 64.5 | 64.9 |

After normalisation, each phantom's whole-body SAR relative to **its own** 1450–5800 MHz plateau
(median over all 22 positions; a physically smooth phantom stays near 1):

| MHz | Duke | Ella | Thelonious | Eartha |
|---|---|---|---|---|
| 700 | 1.76 | **0.29** | **0.50** | 1.16 |
| 835 | 1.58 | **0.39** | 1.28 | 0.96 |
| 1450 | 1.06 | 1.07 | 0.91 | 1.04 |
| 2140 | 1.12 | 0.97 | 1.33 | 1.35 |
| 2450 | 1.17 | 1.20 | 1.35 | 1.38 |
| 3500 | 0.94 | 1.03 | 1.09 | 0.96 |
| 5200 | 0.68 | 0.85 | 0.80 | 0.80 |
| 5800 | 0.68 | 0.80 | 0.76 | 0.77 |

Ella jumps by a factor **2.7 between 835 and 1450 MHz** within her own dataset. Duke's largest
step anywhere is 1.06. From 1450 MHz upward Ella sits at 0.95–1.37 × Duke, which is entirely
sensible for a 1630 mm adult female against a 1770 mm adult male.

Crucially, **the depression is uniform across all three position groups**, which is the signature
of a scale factor rather than a simulation artefact:

| group | Ella @700 | Ella @835 |
|---|---|---|
| belly | 0.28 | 0.39 |
| ear | 0.41 | 0.34 |
| front of eyes | 0.32 | 0.33 |

Concrete example (the cell that triggered this investigation):

```
Duke_body_goliat_700_front_of_eyes_center_horizontal_sar: 2.62029276910084
Ella_body_goliat_700_front_of_eyes_center_horizontal_sar: 0.365682656826568   <- 7.2x lower
Thelonious_body_goliat_700_front_of_eyes_center_horizontal_sar: 2.00027691317228
Eartha_body_goliat_700_front_of_eyes_center_horizontal_sar: 2.7811346750176
```

**Interpretation (see §5.0):** this is attributed to the low-frequency behaviour of TP's antenna
and feed model, which differs from the model used for Duke. The uniformity across position groups
supports this: a differing source model shifts all positions together, whereas a numerical problem
in individual runs would scatter. The differing input power at exactly these two frequencies is part
of the same picture. **No correction is applied.**

For reference, solving for the power that would place Ella's 700/835 MHz points on her own trend
gives ≈ 125 and ≈ 146 mW, i.e. factors of 6.5 and 4.4 relative to the stated values — not a single
constant, which is one reason a mechanical rescaling would not be defensible.

**Affected model frequencies:** 700, 800 and 900 MHz for Ella (700 is a simulated node, 800 is
interpolated from 700/835, 900 from 835/1450). 1450 MHz and above are unaffected. These bands are
not negligible — they carry ≈ 44 % of 4G use and half of 2G and 3G each — so any conclusion that
leans on Ella's low-band exposure should carry that caveat.

### 5.2 Thelonious — scattered low-frequency values and one extreme value

Thelonious uses the same input-power ladder as Duke, so **his problem is not a normalisation
issue** — it is in the SAR values themselves. His pattern is also different from Ella's: not a
uniform depression, but scatter that varies by position group and by individual position.

Relative to his own 1450 MHz value, per position (whole body):

| group | range at 700 MHz | range at 835 MHz |
|---|---|---|
| ear | 0.70 – 0.85 | 0.84 – 0.91 |
| front of eyes | 0.32 – 0.93 | 1.14 – 2.04 |
| belly | **0.03 – 0.80** | **0.03 – 1.76** |

For comparison, Duke's positions within a group agree closely with each other (his ear group spans
0.595–0.637 at 700 MHz). Thelonious's belly group spans a factor of 29.

**One value stands out particularly:**

```
Thelonious_body_goliat_700_belly_left_vertical_sar:  0.0690872710400414
Thelonious_body_1450_belly_left_vertical_sar: 2.5403036125566
```

That is 2.7 % of the same position's 1450 MHz value, where the neighbouring belly positions sit at
40–80 %. It is also the single smallest whole-body value in the entire imported dataset (raw
0.0184 mW/kg at 700 MHz, against 0.49–0.68 for the other belly positions).

Two readings are possible and we cannot separate them here. It is consistently low at **both** 700
and 835 MHz (2.7 % and 3.3 %), which argues against a one-off convergence failure and for a genuine
weak-coupling geometry — a vertically held device at the left belly may couple very poorly at low
frequency. Given §5.0, the value is kept. It is noted here because it is extreme enough that a
sanity check with UGent is cheap insurance if that position ever drives a result.

### 5.3 Eartha — no problems found

Eartha's curve is smooth (largest step between neighbouring frequencies 1.29), her low-frequency
values sit at 0.96–1.16 of her own plateau, and her ratio to Duke (1.8–2.2 above 1450 MHz) matches
the mass-scaling expectation for a 1360 mm child. Nothing to flag.

### 5.4 UGent ear position naming — resolved

UGent label the ear positions `cheek_1_base`, `cheek_2_up`, `cheek_3_down`, `tilt_1_base`,
`tilt_2_up`, `tilt_3_down`, whereas the Duke and Ella workbooks only number them `cheek_1` …
`tilt_3`. The model expects `cheek1` … `tilt3`, and **the import maps them by ordinal number**
(`cheek_1_base` → `cheek1`).

**Resolution:** the phantom placements are standardised setups in the modelling software, so the
same number denotes the same geometry across institutes; the UGent suffixes are a descriptive
addition to the same numbering, not a different scheme. The ordinal mapping is therefore correct.

This is consistent with the data: Duke, Thelonious and Eartha all reproduce the same within-triplet
ordering (cheek2 > cheek1 > cheek3, tilt2 > tilt1 > tilt3), which is what standardised geometries
should give. Ella departs from that ordering, but her placements are literally named `cheek_1` …
`cheek_3` and need no mapping at all, so her deviation is anatomical variation rather than a
labelling difference.

**For the record, had the mapping been wrong** the impact would have been bounded. The ear
positions are weighted unevenly — `cheek1` 0.5, `cheek2` 0.1, `cheek3` 0.1, `tilt1` 0.15,
`tilt2` 0.075, `tilt3` 0.075 — so only the position mapped to `cheek1` (and to a lesser extent
`tilt1`) matters: positions 2 and 3 carry equal weight within each family and swapping them changes
nothing at all. A permuted cheek triplet would have shifted the weighted ear brain SAR by −4.0 % to
+2.8 % for Thelonious and ±1.7 % for Eartha.

### 5.5 Duke — regenerated through the same script (11 lines changed)

Duke's numbers originally came from a different route: normalisation was done inside Excel and the
import was run by hand, one sheet at a time. To give the whole table a single, reproducible
provenance, he was regenerated through `data-raw/import_sar.R` like the other three. Because the
script reads the **raw** sheets and normalises in R, it bypasses the Excel layer entirely.

11 of Duke's 574 lines changed, in three categories:

**(a) Six corrected values.** Two cells in the `Duke_ear_normalized` sheet had been typed in as
rounded 7-digit constants (`21.78583` and `24.08108` at 3500 MHz, tilt_1 and tilt_2) instead of
being left as formulas — visible in the old file, where they stood out among 15-digit neighbours.
The correct values are 21.7858322855703 and 24.0810817745663. Because 3500 MHz is simultaneously a
model frequency, the upper bracket for 2600 MHz and the lower bracket for 5000 MHz, two bad cells
propagated into six keys: `Duke_brain_{2600,3500,5000}_{tilt1,tilt2}_sar`. Relative correction
≈ 1e-7; `SAR_wholebody` in the same sheet was unaffected, so `body` did not change at all.

**(b) Two last-bit changes.** `Duke_brain_goliat_700_front_of_eyes_center_horizontal_sar` and
`Duke_brain_2400_cheek1_sar` differed by ≈ 2e-15 — one unit in the last place of a double, because
Excel computed `raw/P` while the script computes `raw*1000/P`. Neither value was more correct;
everything now takes the same computational path.

**(c) Four lines of reordering.** `Duke_brain_goliat_5000_tilt1_sar` sat *after* the `xxxx`/`yyyy`/`zzzz`
placeholders instead of before them. Duke's brain block was the only one in the file with that
anomaly; the key set is unchanged.

Nothing else moved: Duke's `body` block is byte-identical to before, and the gaming reference dose
still reads exactly 0.3238162 mJ/kg/day.

### 5.6 UGent head/trunk correction (2026-09-17) — no effect on the model

UGent delivered `Final_Data_UGent_normalized.xlsx`, superseding the two per-phantom files. The
covering mail: the earlier delivery *"had a mix-up for the head and trunk SAR data, which you had
already received back in December."*

Every column was compared against the superseded files, position by position and frequency by
frequency, after stripping the placement suffixes:

| column | status |
|---|---|
| `SAR_wholebody` | unchanged, max relative deviation **8.3e-13** |
| `SAR_brain` | unchanged, deviation **exactly 0** |
| input power, frequencies, placements | unchanged |
| `SAR_head` | **recomputed**, factors 0.10× to 17× |
| `SAR_trunk` | **recomputed**, factors 0.10× to 23× |
| `psSAR10g_eyes`, `psSAR10g_skin`, `psSAR10g_brain` | **newly added** |

The head and trunk factors vary per row, frequency and position, so this is a genuine
recomputation rather than a rescaling or a swapped pair of columns. Two things were explicitly
ruled out: the phantoms were **not** swapped with each other (cross-comparing new Thelonious against
old Eartha gives deviations of 100–3600 %), and head/trunk were **not** simply exchanged.

**`TISSUES` maps only `wholebody` → `body` and `brain` → `brain`, so the corrected columns are
never read.** The import was re-run anyway, so that the yaml demonstrably derives from the
authoritative file. The result:

- 427 lines changed in each yaml, all of them `Thelonious_body_*` (219) and `Eartha_body_*` (208)
- **no `brain` line changed**, and Duke and Ella were untouched
- maximum relative change **8.3e-13**, median 8.3e-14, no line above 1e-9

That is the floating-point noise from the last table above, surfacing in the 15-digit yaml output:
the regenerated workbook stores the same numbers with marginally different binary rounding. It is
twelve orders of magnitude below the uncertainty of the simulations themselves and changes no
result. It was absorbed once so that future re-runs stay at a clean zero diff.

The correction also removed the `_base`/`_up`/`_down` placement suffixes, which independently
confirms the reading in §5.4: the ordinal number is the identifier and the suffixes were
descriptive only.

---

## 6. Questions for the data providers

The low-frequency deviations are **not** raised as errors (§5.0), and the ear naming is resolved
(§5.4). What remains are documentation questions only.

**To TP (Ella) — for documentation only:**
> Two small points for our records: (a) what does the `Input Power (mW)` column represent —
> forward/incident power at the feed, or accepted/radiated power? We normalise all phantoms to 1 W
> and would like to state the convention correctly. (b) The `*_normalized` sheets in the workbook
> are present but entirely empty; we used the raw sheets and normalised ourselves. Was that
> intended?

**Optional, low priority (UGent):**
> In `Final_Data_UGent_normalized.xlsx`, sheet `Thelonious_belly`, the whole-body SAR for
> `belly_level_left_vertical` at 700 and 835 MHz is roughly 30× below the neighbouring belly
> positions. We assume this is genuine weak coupling for that orientation rather than a run
> artefact, but a quick confirmation would let us close the question. (Unchanged by the
> September 2026 head/trunk correction — see §5.6.)

---

## 7. Current repository state

- Both `params_stochastic.yaml` and `params_template.yaml` now hold **all four phantoms generated by
  the same script**, `data-raw/import_sar.R`. Running it is the single reproducible path from the
  xlsx workbooks to the yaml. By default it performs a dry run with full validation; set
  `WRITE_YAML <- TRUE` to apply.
- **Decided:** the delivered values are kept as they are, including the low-frequency deviations
  (§5.0). No correction factors are applied to any phantom. Duke was regenerated through the same
  script for consistency (§5.5).
- **Nothing substantive is open.** The ear naming is resolved (§5.4, independently confirmed by
  UGent dropping the suffixes in §5.6) and the low-frequency deviations are understood as a
  property of the simulations (§5.0).
- **UGent's September 2026 correction touched only `SAR_head` and `SAR_trunk`**, which this import
  does not read. The values the model uses are unchanged; see §5.6. The importer now also
  cross-checks its own 1 W normalisation against the institutes' `_normalized` sheets for three of
  the four phantoms (§4).
- **Worth considering for the model itself:** the project's purpose is to propagate uncertainty, and
  SAR simulation uncertainty at 700–900 MHz is now known to be large. At present the SAR value is
  deterministic once the phantom is drawn — the only SAR-side variation comes from the position
  weights and the distance draw. Representing the simulation uncertainty explicitly, e.g. as a
  frequency-dependent multiplicative distribution on the SAR lookup, would make that limitation part
  of the model output instead of a caveat in a text file.
- `R/sar_interpolation.R` has been **deleted**. Beyond being unable to read the newer workbooks, it
  was a top-level script sitting in `R/`, so it executed on every `devtools::load_all()` — re-reading
  a 9 MB xlsx, rewriting a csv in `data/` as a load-time side effect, and leaking `df`, `df_interp`,
  `ziel_freq`, `sheet` and `prefix` into the package namespace. Its interpolation chain survives as
  the reference implementation in validation A of `data-raw/import_sar.R`, which fails if the two
  ever diverge. Its three `*_interpol.csv` intermediates were removed with it, as was a byte-for-byte
  duplicate of Duke's workbook that sat in the repository root.
- The source workbooks now live in `data-raw/` next to the script that reads them, rather than in
  `data/`. `data/` is a special directory in an R package — reserved for datasets in `.rda`/`.csv`
  format that ship with the build — so xlsx files there were both non-standard and needlessly
  included in the built package. `data-raw` is already listed in `.Rbuildignore`.
- Follow-ups now unblocked: the test scripts (`test_cordless.R`, `test_mobilcall.R`,
  `test_gaming.R`, `test_calculate_emf_doses.R`) pin `sex="male"`/`age="adult"` only to force Duke
  and can now be parameterised over all four phantoms. The comment and zero-warning in
  `R/gaming.R` referring to "only Duke" are stale.
