# Parameter workbook notes — `SDM_parameters_26062026.xlsx`

**Date of this analysis:** 2026-09-18
**File analysed:** `data-raw/SDM_parameters_26062026.xlsx` (received 2026-09-17, dated 26 June 2026)
**Status:** analysis only. **Nothing in the code or the yaml files has been changed.** This document
exists so the findings can be discussed before anything is acted on.

---

## 1. What this workbook is

It is the specification behind the model's parameter values: for each exposure source, one row per
parameter giving a mean, sometimes a spread, the intended distribution family, the unit, who
provided the number, and a definition in words.

This matters because **the repository itself records almost no provenance**. `doc/params_reference.csv`
has `description` and `notes` columns, but only 41 of its 343 rows carry anything, and the tablet and
laptop rows are blank. Until now there was no documented answer to "where does this number come
from". This workbook is that answer.

**Providers named in the file:** *Hamed, literature* and *Hamed, expert* (the majority), *Adriana*
(4G/5G band probabilities), *Bram* (4G/5G output powers and duty cycles), *Robin* (device-to-body
distances), *input* (values that come in as study data), *wp1.5* (the SAR lookup tables), and
*GOLIAT* as the `reference` for the mobile-call durations and proportions.

---

## 2. Structure

Nine sheets, one per exposure source:

| sheet | rows | sheet | rows |
|---|---|---|---|
| `mobilecall` | 306 | `tablet` | 21 |
| `mobiledata` | 102 | `cordless` | 16 |
| `farfield` | 89 | `other` | 10 |
| `5gauto` | 30 | `wifi` | 3 |
| `laptop` | 24 | | |

Common columns: `variable_name`, `mean_default`, `sd_default`, `min_default`, `max_default`, `unit`,
`provider`, `distribution`, `personal_simulation`, `variable_definition`, `reference`, `comment`.
Two are spelled differently on one sheet each — `provider of data` on `mobilecall`,
`personal_simulation (yes/no)` on `mobiledata` — so they have to be matched by pattern, not by exact
name.

`personal_simulation` is the important structural column: **y** means the parameter is drawn per
person (a behavioural input), **n** means it is drawn once at population level (a device or physics
property). This is the same distinction the code makes between `global$input_stoch` and
`devices$…`.

`mobilecall` and `mobiledata` additionally carry `DDM_parameters` and `SDM_parameters` columns —
the deterministic and stochastic model's own variable names. `mobilecall`'s first column is headed
`variable_name (OLD)` and holds yet a third scheme (`p_mpc.ear_prop`, `pb_mpc.headph_fof_prop`),
which appears nowhere else.

---

## 3. Naming: the translation table

On the `mobiledata` sheet the `variable_name` column uses the naming of the person who compiled the
data while `DDM_parameters` / `SDM_parameters` give the model's, so the mapping can be read straight
off. (It is the only sheet where this works: `mobilecall`'s equivalent column holds the unrelated
`p_mpc.*` scheme, and the remaining sheets have no model-name column at all.) It resolves what
initially looks like a different design:

| workbook `variable_name` | model name | activity class |
|---|---|---|
| `brws_dcw2` | `wifi_2_low_dutycycle` | **low** |
| `voice_dcw2` | `wifi_2_lowmed_dutycycle` | **lowmed** |
| `video_dcw2` | `wifi_2_medhigh_dutycycle` | **medhigh** |
| `upload_dcw2` | `wifi_2_high_dutycycle` | **high** |

So `upload / video / browsing / voice` **is** the model's `high / medhigh / lowmed / low` scheme,
not a competing one. The `tablet` and `laptop` sheets use only the `variable_name` column, so they
appear to describe four named activities with Dirichlet-drawn proportions; read through this table
they describe exactly the four usage-intensity classes the model already implements.

Other sheets follow the same pattern with different spellings — `dectc_duration` → `dect_duration`,
`lptp_table_prop` → `tabl_prop`, `max_w2_op` → `wifi_2_pwr` / `tblt_2400_pwr`, `gen_male` →
`sex$male_prop`, `front_eyes_cen_ver_prop` → `front_of_eyes_center_vertical_prop`. None of these are
substantive differences, but they do mean a name-by-name comparison has to go through an alias list.

---

## 4. Completeness: only two sheets carry spreads

| sheet | `mean` filled | `sd` filled | `min` / `max` filled |
|---|---|---|---|
| `mobilecall` | 270 | 190 | 144 / 144 |
| `mobiledata` | 91 | 80 | 76 / 76 |
| `cordless` | 10 | **0** | **0 / 0** |
| `laptop` | 5 | **0** | **0 / 0** |
| `tablet` | 3 | **0** | **0 / 0** |
| `farfield` | 19 | **0** | **0 / 0** |
| `5gauto` | 9 | **0** | **0 / 0** |
| `wifi` | 3 | **0** | **0 / 0** |
| `other` | 10 | **0** | **0 / 0** |

**This is the central finding for the ongoing stochastification work.** For every source other than
mobile call and mobile data, the workbook gives a mean and an intended distribution family but *no
spread at all*. The sd, min and max columns are not merely sparse — they are completely empty.

Consequently the spreads used for cordless, gaming, VR and tablet are not specified anywhere: they
were assumed during implementation and are listed as placeholders in `doc/MODEL_LIMITATIONS.md` §D.
The workbook confirms that this was unavoidable rather than an oversight, and it identifies exactly
what is still missing.

---

## 5. How the Beta concentration parameters were derived

The yaml parameterises Beta distributions by a mean and a concentration `a0`; the workbook gives a
mean and an sd. The two are related by

```
a0 = mean * (1 - mean) / sd^2 - 1
```

This reproduces the yaml exactly where the means agree. Verified cases:

| parameter | workbook mean / sd | formula gives | yaml `a0` |
|---|---|---|---|
| `wifi_2_dutycycle` (call) | 0.02738 / 0.014 | 134.869 | **134.9** |
| `wifi_5_dutycycle` (call) | 0.04385 / 0.003 | 4657.575 | **4657.6** |
| `wifi_2_low_dutycycle` | 0.009 / 0.005 | 355.760 | **355.76** |
| `wifi_2_high_dutycycle` | 0.669 / 0.16 (yaml mean 0.670) | 7.6367 | **7.6367** |

The recipe is therefore established and can be applied wherever a mean and an sd are available. It
is worth recording explicitly, because nothing in the repository states it.

---

## 6. Discrepancies between the workbook and `params_stochastic.yaml`

Every workbook parameter with a numeric mean (279 of them) was matched against the yaml through an
alias list, comparing against **every** yaml location that carries the name — several parameters are
stored more than once (§6.4):

| outcome | count |
|---|---|
| agrees with the yaml | 146 |
| agrees with one of two stored copies, not the other | 46 |
| **agrees with no copy** | **20** (19 distinct; `data_5g_prop` appears on two sheets) |
| not matched by the alias list | 67 |

The 67 are *not* all missing from the model — mostly the workbook uses a name the alias list does
not cover. Thirteen were checked by hand — `dectc_duration`, `dectc_power`, `gen_male`/`gen_femal`,
`sex_male`/`sex_femal`, `age_adult`/`age_child`, `lptp_table_prop`, `lptp_lap_prop`, `mpd_dist_eye`,
`wifi_2_dutycycle`, `wifi_5_dutycycle` — and **all thirteen are present in the yaml under a
different name with an identical value**. The genuinely absent ones belong to sources that are still
deterministic (`lptp_duration`, the farfield and 5gauto parameters) or are structural rows rather
than parameters.

### 6.1 Mobile data durations differ by roughly a factor of two

| parameter | workbook | yaml | workbook / yaml |
|---|---|---|---|
| `mpd_dur_low` | 1880.74 | 3989.32 | 0.47 |
| `mpd_dur_lowtomed` | 2252.57 | 4916.97 | 0.46 |
| `mpd_dur_medtohigh` | 2354.78 | 5650.71 | 0.42 |
| `mpd_dur_high` | 0 | 0 | — |

The sd values also differ (3205 / 4001 / 4321 against 3663 / 4734 / 5113), as does one bound
(`mpd_dur_lowtomed` max 42000 in the workbook, 28830 in the yaml). Mobile data is the second largest
contributor to the total dose, so a factor of two on its durations is not a detail.

### 6.2 A specification the code does not implement

The workbook's comment on `mpd_dur_low` reads:

> *"The default mean values for these four durations are summed in the backend. Therefore, these four
> durations should be simulated according to their standard deviations, while ensuring that their sum
> always equals the input total duration."*

`simulate_params()` draws the four durations **independently**, in a loop, with no constraint linking
them. Their sum therefore varies freely from draw to draw instead of being pinned to the
participant's reported total. The same applies to the tablet durations, which were implemented by
mirroring the mobile data block.

Whether the constraint is wanted is a modelling decision — enforcing it removes a real source of
variance but honours the reported total — but the code and the specification currently disagree.

### 6.3 Two competing sets of WiFi duty cycle means

| parameter | workbook | yaml (`data`) | yaml (`tblt`, `lptp`) |
|---|---|---|---|
| `wifi_2_low_dutycycle` | 0.009 | 0.009 ✓ | 0.009 |
| `wifi_2_lowmed_dutycycle` | 0.025 | 0.022 | 0.025 |
| `wifi_2_medhigh_dutycycle` | 0.176 | 0.138 | 0.176 |
| `wifi_2_high_dutycycle` | 0.669 | 0.670 ≈ | 0.669 |
| `wifi_5_low_dutycycle` | 0.03055 | 0.024 | 0.03055 |
| `wifi_5_lowmed_dutycycle` | 0.052275 | 0.039 | 0.052275 |
| `wifi_5_medhigh_dutycycle` | 0.064 | 0.054 | 0.064 |
| `wifi_5_high_dutycycle` | **0.14515** | **0.495** | 0.14515 |

The workbook's values are exactly the ones the tablet and laptop blocks carry — the deterministic
model's WiFi duty cycles. The mobile data block in the yaml holds a different set. So the workbook
endorses the tablet/laptop numbers, and mobile data is the odd one out. The 5 GHz high-activity
entry differs by a factor of 3.4.

This also resolves an open item: `doc/MODEL_LIMITATIONS.md` §D1 records that the tablet
implementation borrowed `a0 = 0.4585` for `tblt_5000_high_dutycycle` from mobile data, where it was
fitted at a mean of 0.495, and that at the tablet mean of 0.145 it produces a near-degenerate
U-shaped distribution. The workbook supplies the matching sd of 0.09, which gives `a0 = 14.32` and a
well-behaved unimodal Beta. **Not applied** — see §9.

Implied `a0` from the workbook for all eight, for reference:

| | mean | sd | `a0` | currently in `tblt` |
|---|---|---|---|---|
| 2400 low | 0.009 | 0.005 | 355.76 | 355.76 |
| 2400 lowmed | 0.025 | 0.011 | 200.45 | 176.82 |
| 2400 medhigh | 0.176 | 0.25 | 1.32 | 1.41 |
| 2400 high | 0.669 | 0.16 | 7.65 | 7.64 |
| 5000 low | 0.03055 | 0.03 | 31.91 | 80.05 |
| 5000 lowmed | 0.052275 | 0.04 | 29.96 | 38.00 |
| 5000 medhigh | 0.064 | 0.06 | 15.64 | 26.63 |
| 5000 high | 0.14515 | 0.09 | **14.32** | **0.4585** |

### 6.4 The 3G output powers exist twice, with values differing by up to 80×

This looked at first like a workbook-versus-yaml disagreement. It is not. The **workbook itself**
carries two different value sets for the same physical quantity, one on each mobile sheet, and the
yaml faithfully reproduces both:

| parameter | `mobilecall` sheet → `devices$call$data_pwr` | `mobiledata` sheet → `devices$data$pwr` | ratio |
|---|---|---|---|
| `data_3g_urb_out_pwr` | 0.01 | 0.78 | 78 |
| `data_3g_sub_out_pwr` | 0.87 | 48.64 | 56 |
| `data_3g_travel_pwr` | 0.87 | 48.64 | 56 |
| `data_3g_sub_ind_pwr` | 2.04 | 114.02 | 56 |
| `data_3g_rur_ind_pwr` | 6.28 | 167.11 | 27 |
| `data_3g_rur_out_pwr` | 2.68 | 71.29 | 27 |
| `data_3g_urb_ind_pwr` | 0.605 | 1.84 | 3 |

Both copies are live: `R/mobilecall.R:636` reads `devices$call$data_pwr` for a voice call carried
over mobile data, and `R/mobiledata.R` reads `devices$data$pwr` for a data session. So a phone
transmitting on 3G in a suburban indoor environment is modelled at 2.04 mW if the traffic is a call
and 114.02 mW if it is a data session — a factor of 56 for what should be the same radio behaviour.
The `sd` values are duplicated in the same way and differ by the same factors.

The 4G and 5G copies agree apart from rounding (the `call` block keeps full precision, e.g.
77.8985184 against the `data` block's 77.899); one exception, `data_5g_urb_ind_pwr_sd`, differs by
3.6 % (13.405 against 13.905). So the large split is confined to 3G.

**Mitigating factor:** 3G carries only 2 % of data traffic (`data_3g_prop` = 0.02), so the dose
impact is small. But it is a specification inconsistency that the model has inherited faithfully,
and it is not documented anywhere.

Across the whole yaml, 110 numeric leaf names occur more than once and 41 of those carry differing
values. Most are benign — `dect_ear_sar` under both `brain` and `body`, for example, where the
parent key disambiguates. The `call`/`data` power split is the one case where the same name, at the
same conceptual level, holds genuinely different numbers.

### 6.5 Remaining differences

| parameter | workbook | yaml | note |
|---|---|---|---|
| `data_4g_high_dutycycle` | 1 | 0.85 | a duty cycle of exactly 1 means continuous transmission |
| `data_5g_high_dutycycle` | 1 | 0.85 | as above |
| `data_3g_medhigh_dutycycle` | 0.592 | 0.542 | |
| `data_3g_lowmed_dutycycle` | 0.5446 | 0.505 | |
| `data_3g_high_dutycycle` | 0.8109 | 0.783 | |
| `data_5g_prop` | 0.315 | 0.32 | rounding, probably immaterial |
| `headp_else_prop` | 0.333 | 0.334 | rounding, immaterial |
| `headp_ear_num` | 2 | 0.95 | see below |
| `vr_duration` | 0 | 100 | see below |

Together with the eight WiFi duty cycles of §6.3 and the three `mpd_dur_*` of §6.1, these are the
complete set of 20 parameters where the workbook matches no value stored in the yaml.

**`headp_ear_num`.** The workbook gives mean 2, sd 0.35, bounds 0–2, with the comment *"this can not
be decimal, should be 0, 1 (14 %), or 2 (86 %)"*. The yaml draws it from a Beta with mean 0.95 and
`a0` 18, which produces a continuous value in [0, 1]. A Beta cannot represent a count of 0, 1 or 2
earpieces, and the workbook's own stated mean of 2 is inconsistent with its own comment (0.14 × 1 +
0.86 × 2 = 1.86). All three descriptions disagree; this needs clarifying at the source.

**`vr_duration`.** The workbook gives 0, which matches every default file in the repository. The
yaml's 100 s is the placeholder introduced during the VR stochastification, and is already recorded
as such in `doc/MODEL_LIMITATIONS.md` §D — a population mean of 0 would make the VR source
unreachable and untestable. Not a conflict so much as a known gap in the underlying data.

### 6.6 A specified distance that the code does not use

The workbook has `mpd_dist_eye` = 200 mm, defined as *"distance of mobile phone to the eyes during
mobile phone online activities"*. The yaml duly contains `mpd_dist_face` with mean 200, sd 100,
bounds 80–300.

**`mpd_dist_face` is read nowhere in the package.** `R/mobiledata.R:551` rescales the front-of-face
SAR using `params$devices$call$mpc_distance$mpc_dist_speaker` instead — the *mobile call* speaker
distance, mean **100 mm**. So the front-of-face geometry for mobile data is currently modelled at
half the specified distance, using a parameter borrowed from another source, while the parameter
intended for it sits unused.

Under the current distance law, `((200+6)/(100+6))²`, this is a factor of **3.78** on the
front-of-face contribution — in the direction of over-estimating it.

### 6.7 Smaller anomalies in the workbook itself

- **`mpd_dist_eye` bounds are min 80, max 30** — the maximum is below the minimum. The yaml has 300,
  so whoever transcribed it read the intent correctly; the workbook cell is a typo.
- **The same WiFi power parameter is specified three different ways on three sheets:**

  | sheet | mean | sd | min | max | distribution |
  |---|---|---|---|---|---|
  | `mobilecall` | 100 / 200 | 30 / 60 | 0.001 | **100 / 200** | truncated lognormal |
  | `mobiledata` | 100 / 200 | 30 / 60 | 0.001 | **1** | normal |
  | `tablet`, `laptop` | 100 / 200 | *blank* | *blank* | *blank* | normal |

  A maximum of **1** for a power in mW is nonsensical — that is the generic [0.001, 1] bound used on
  the Beta proportion rows, applied to a power row by mistake. The `mobilecall` sheet has the
  sensible bounds. The distribution family also disagrees: `truncated lognormal` on `mobilecall`,
  `normal` on the other three. The yaml uses `trunc_lognormal` with max = mean throughout, which
  matches the `mobilecall` row (and is itself the subject of `doc/MODEL_LIMITATIONS.md` §C3).
  Several `mobiledata` entries are additionally hedged as `"Truncated lognormal?"` with a question
  mark.
- **`travel_prop`** has unit `proportion` but max 86400 (seconds in a day).
- The `distribution` column is blank for a number of rows that clearly need one, including
  `lptp_duration` and `tblt_duration`.

---

## 7. What the workbook does not contain

- **No device distance for tablet or laptop.** Distances exist only for mobile call
  (`mpc_dist_ear` 8 mm, `mpc_dist_speaker` 100 mm), mobile data (`mpd_dist_eye` 200 mm) and cordless
  (`mp_ear_dist`, value blank). The 300 mm tablet viewing distance has no entry here. For context,
  the specified phone-to-eyes distance is 200 mm, so 300 mm for a tablet is consistent with it
  rather than in conflict.
- **No duty cycle or activity-proportion values for tablet and laptop** — the rows exist and name the
  distribution family, but every numeric cell is empty.
- **No gaming sheet at all.** Portable gaming consoles do not appear anywhere in the workbook.
- **Nothing on VR beyond `vr_duration` = 0** in the `other` sheet.
- **No SAR values.** Those rows say `lookup table`, provider `wp1.5`, and point at the phantom
  simulations documented separately in `doc/SAR_IMPORT_NOTES.md`.
- **No smartwatch, hotspot or headphone parameters beyond durations and position proportions.**

---

## 8. Consequences for the recently stochastified sources

**Tablet.** The activity structure implemented matches the specification once the naming is
translated (§3). The eight duty cycle means match the workbook exactly. The four durations sum to
1618 s against the workbook's `tblt_duration` of 1617 s — the same total. Two things the workbook
would change if adopted: the eight `a0` values (§6.3), and the sum constraint on the durations
(§6.2). The 300 mm distance and the duration spreads remain unspecified.

**VR and gaming.** Absent from the workbook, so every parameter for both remains an assumption. This
confirms the entries in `doc/MODEL_LIMITATIONS.md` §D rather than changing them.

**Cordless.** Means agree (`dect_duration` 204 s, `dect_pwr` 250 mW, duty cycle 0.04). The workbook
adds an ear-orientation and ear-alignment structure (`mp_ear_ori_til` / `mp_ear_ori_cek` at 0.5/0.5,
`mp_ear_ali_*` as a Dirichlet) that the model does not have — it uses a single `dect_ear_prop` of
0.9 instead.

---

## 9. Questions for discussion

Nothing has been changed. These are the decisions the findings call for, in rough priority order:

1. **Is the workbook newer than the yaml, or older?** It is dated 26 June 2026 and arrived in
   September. Several yaml values look like they came from an earlier revision of the same file
   (§5 shows the `a0` recipe reproducing exactly where the means still agree). Knowing the direction
   settles most of §6 at once.
2. **Mobile data durations (§6.1)** — factor two on a major contributor. Which set is current?
3. **The sum constraint (§6.2)** — should the four activity durations be conditioned to sum to the
   reported total? This affects mobile data, tablet and laptop alike, and is a change to
   `simulate_params()` rather than to a parameter file.
4. **WiFi duty cycles (§6.3)** — adopt the workbook's set for mobile data too, or keep the two sets?
   The tablet `a0` fix is a small, well-founded improvement that could be taken independently.
5. **The unused `mpd_dist_face` (§6.6)** — is modelling the phone-in-front-of-face at 100 mm rather
   than the specified 200 mm intended?
6. **`headp_ear_num` (§6.5)** — the workbook, its own comment and the yaml give three different
   answers.
7. **The duplicated 3G powers (§6.4)** — should a 3G call over mobile data and a 3G data session
   really use output powers a factor of 56 apart? The split is in the specification itself, not
   introduced by the model.
8. **Spreads for the remaining sources (§4)** — cordless, laptop, tablet, farfield, 5gauto, wifi and
   other have none. Is a further delivery expected, or should these stay as documented assumptions?
