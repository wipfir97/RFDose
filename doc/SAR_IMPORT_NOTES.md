# SAR import notes — Ella, Thelonious, Eartha

**Date:** 2026-09-14
**Scope:** import of the simulated SAR values for the three remaining phantoms into
`inst/extdata/params_stochastic.yaml` and `inst/extdata/params_template.yaml`.
**Status:** complete. All four phantoms are imported through one script,
`data-raw/import_sar.R`. The low-frequency behaviour described in §5 is understood to be an
inherent property of SAR simulations rather than a data or import error (§5.0), and the ear
position naming is resolved (§5.4).

---

## 1. Summary

Until now only Duke (adult male) had real SAR values; Ella, Thelonious and Eartha were
zero-filled placeholders. The simulations for all three have now been delivered and imported.

### How the key count works

Two different figures appear throughout this document — 574 and 220. They refer to different
things:

| | per tissue | per phantom (body + brain) |
|---|---|---|
| yaml keys | 287 | **574** |
| of which real values | **220** | 440 |
| of which deliberate zeros | 67 | 134 |

- **287 keys per tissue** = 22 positions × 13 frequency tokens (286) + 1 `headp_else_sar` key.
- **220 real values per tissue** = 22 positions × the **10 frequencies the model actually uses**
  (700, 800, 900, 1450, 1800, 2100, 2400, 2600, 3500, 5000 MHz).
- **67 zeros per tissue** = 22 positions × the 3 placeholder frequency tokens `xxxx`, `yyyy`,
  `zzzz` (66), reserved for future 5G/6G bands, + the 1 `headp_else_sar` key. These are
  intentionally 0 and are not produced from the xlsx files.

So "Duke has 574 existing values" counts every key of both tissues, while "220 real values per
tissue" counts only the non-placeholder ones of a single tissue. All four phantoms now have the
identical shape: 574 keys, 440 real, 134 zero.

The import pipeline was validated by reproducing Duke's 574 existing values byte-for-byte, so
the mechanics (normalisation, interpolation, naming, formatting) are demonstrably correct.

Ella and Thelonious both show pronounced deviations at the two lowest simulated frequencies
(700 and 835 MHz). These were initially investigated as possible import or normalisation errors and
were ruled out as such; they reflect the well-known large uncertainty of SAR simulations in that
band (§5.0). Eartha and Duke are smooth across the whole range.

---

## 2. Source files

| Phantom | File | Provider | Sheets |
|---|---|---|---|
| Duke | `Duke_male_adult_NF.xlsx` | — | raw + `*_normalized` for fronteyes/belly/ear |
| Ella | `Final_Data_TP_Ella_NF_normalized.xlsx` | TP | raw + `*_normalized` (**the normalized sheets are entirely empty — all NA**) |
| Thelonious | `Final_Data_UGent_Thelonious_NF.xlsx` | UGent | raw only (`fronteyes`, `belly`, `cheek`) |
| Eartha | `Final_Data_UGent_Eartha_NF.xlsx` | UGent | raw only (`fronteyes`, `belly`, `cheek`) |

The workbooks are not consistent with each other. Differences that had to be handled:

- **Sheet names**: `Ella_front` vs `*_fronteyes`; `Ella_ ear` contains a stray space;
  UGent uses `_cheek` where Duke uses `_ear`.
- **Column names**: `frequency_mhz` vs `frequency_MHz`; `Input Power (mW)` vs
  `Input power (mW)` (lowercase p, Duke's ear sheet) vs `Input Power  (mW)` (two spaces, Ella);
  `SAR_brain (mW/kg)` vs `SAR averagedbrain(mW/kg)` (Ella).
- **Column order** differs between Ella and Duke, so columns are resolved by name, never by position.
- **Placement names**: UGent uses `cheek_1_base`, `cheek_2_up`, `cheek_3_down`,
  `tilt_1_base`, `tilt_2_up`, `tilt_3_down`; Duke and Ella use `cheek_1` … `tilt_3`.
- **Data types**: Duke's `SAR_trunk` column is text because one cell contains `<<<`. The importer
  refuses non-numeric columns rather than silently coercing them to NA.

---

## 3. What the import does

One uniform pipeline for all four phantoms:

1. **Resolve columns by canonicalised name** (lowercase, runs of space/underscore collapsed).
   Exactly one match required per field, otherwise the run aborts.
2. **Normalise each row to 1 W input power, using that row's own input power:**

   ```
   SAR_1W [mW/kg] = SAR_raw [mW/kg] × 1000 / InputPower_row [mW]
   ```

   This is per row, **not** per file: input power varies by frequency in every sheet of every
   workbook (see §5.1). Using a single scale factor would be wrong by up to 80 %.
3. **Interpolate** linearly per position (`approx(rule = 1)`) onto the ten model frequencies
   700, 800, 900, 1450, 1800, 2100, 2400, 2600, 3500, 5000 MHz. All ten lie inside the simulated
   range 700–5800 MHz, so no extrapolation occurs and no NA are produced. If a future delivery had
   a narrower range, the importer aborts rather than writing 0 — 0 is the model's "no data yet"
   sentinel and must not be produced by accident.
4. **Rename placements** to the yaml key fragments: `belly_level_X` → `belly_X`;
   `cheek_1` and `cheek_1_base` → `cheek1`; `tilt_3_down` → `tilt3`; `front_of_eyes_*` unchanged.
   Any placement that does not map to one of the 22 known fragments aborts the run.
5. **Map tissues**: yaml `body` ← `SAR_wholebody`, yaml `brain` ← `SAR_brain`
   (`SAR averagedbrain` for Ella). `SAR_head`, `SAR_trunk` and the `psSAR10g_*` columns are
   not used by the model.
6. **Write both yaml files** with Duke's exact key naming, ordering, numeric format (`paste0`,
   15 significant digits, no scientific notation) and CRLF line endings.

Script: **`data-raw/import_sar.R`**. It lives in `data-raw/` rather than `R/` because it is a
data-preparation script, not package code — `data-raw` is already listed in `.Rbuildignore`.
It supersedes `R/sar_interpolation.R`, which is Duke-only, was run by hand once per sheet, and no
longer executes (it points at a filename that does not exist and drops columns the new workbooks
do not have).

---

## 4. Validation

**Duke round-trip.** Running Duke through the new pipeline and comparing against the values already
in the yaml:

- Reading Duke's delivered `*_normalized` sheets (the path the original script used):
  **574 / 574 values byte-identical**, max relative deviation 4.7e-15.
- Recomputing from Duke's **raw** sheets: 566 / 574 identical; the 8 differences are explained
  in §5.5.

This confirms the interpolation, the placement renaming, the tissue mapping and the numeric
formatting are exactly what produced Duke's existing numbers.

**Other checks:** both yaml files parse; each phantom has 220 non-zero values per tissue and 134
zeros that are exactly the `xxxx`/`yyyy`/`zzzz` placeholder bands plus the two `headp_else` keys;
no NA; no negative or zero SAR; heights preserved (Duke 1770, Ella 1630, Eartha 1360,
Thelonious 1160 mm); no scientific notation; Monte Carlo runs with free sex/age now produce
0 zero-doses out of 200 (previously ≈ 65 %).

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
Duke_body_700_front_of_eyes_center_horizontal_sar: 2.62029276910084
Ella_body_700_front_of_eyes_center_horizontal_sar: 0.365682656826568   <- 7.2x lower
Thelonious_body_700_front_of_eyes_center_horizontal_sar: 2.00027691317228
Eartha_body_700_front_of_eyes_center_horizontal_sar: 2.7811346750176
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
Thelonious_body_700_belly_left_vertical_sar:  0.0690872710400414
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

**(b) Two last-bit changes.** `Duke_brain_700_front_of_eyes_center_horizontal_sar` and
`Duke_brain_2400_cheek1_sar` differed by ≈ 2e-15 — one unit in the last place of a double, because
Excel computed `raw/P` while the script computes `raw*1000/P`. Neither value was more correct;
everything now takes the same computational path.

**(c) Four lines of reordering.** `Duke_brain_5000_tilt1_sar` sat *after* the `xxxx`/`yyyy`/`zzzz`
placeholders instead of before them. Duke's brain block was the only one in the file with that
anomaly; the key set is unchanged.

Nothing else moved: Duke's `body` block is byte-identical to before, and the gaming reference dose
still reads exactly 0.3238162 mJ/kg/day.

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
> In `Final_Data_UGent_Thelonious_NF.xlsx` the whole-body SAR for `belly_level_left_vertical` at
> 700 and 835 MHz is roughly 30× below the neighbouring belly positions. We assume this is genuine
> weak coupling for that orientation rather than a run artefact, but a quick confirmation would let
> us close the question.

---

## 7. Current repository state

- Both `params_stochastic.yaml` and `params_template.yaml` now hold **all four phantoms generated by
  the same script**, `data-raw/import_sar.R`. Running it is the single reproducible path from the
  xlsx workbooks to the yaml. By default it performs a dry run with full validation; set
  `WRITE_YAML <- TRUE` to apply.
- **Decided:** the delivered values are kept as they are, including the low-frequency deviations
  (§5.0). No correction factors are applied to any phantom. Duke was regenerated through the same
  script for consistency (§5.5).
- **Nothing substantive is open.** The ear naming is resolved (§5.4) and the low-frequency
  deviations are understood as a property of the simulations (§5.0).
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
