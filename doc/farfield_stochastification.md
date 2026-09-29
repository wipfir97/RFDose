# Stochastification of the far-field exposure source

**Date:** 2026-09-29
**Code:** `R/farfield.R`, draws in `R/distributions.R`, wiring in `R/total.R`, import in
`data-raw/import_sar.R`, parameters in `inst/extdata/params_stochastic.yaml` and
`params_template.yaml`, tests in `tests/test_farfield.R`

**What it models:** exposure to the ambient radiofrequency field — everything radiated by
transmitters that are not the person's own devices, base stations above all.

---

## Why this source is different

Every other source in the model multiplies a device output power by a SAR value. The far field has
no device. It multiplies

| | |
|---|---|
| `pwr` | the ambient power density the person sits in, in mW/m², measured per country and environment |
| `sar` | how much of that field the body absorbs, in W/kg per W/m² |

and then by the whole day, because an ambient field cannot be switched off. There is no usage
duration to draw, and no distance correction — the source is by definition far away.

It is also the **largest single contributor to the total dose**, which is why the phantom
resolution below is a correction rather than a refinement.

---

## Before

```r
farfield_sar <- function(tissue, params) {
  tissue_params <- load_tissue_params_old(params, "farf", tissue)
  sar <- tissue_params[["sar"]]          # 0.004655 body, 0.005439 brain
}
```

One number per tissue, the same for every phantom, every frequency, every country. A simulated
child received exactly the adult's far-field dose.

`farfield_pwr()` read `params$global$home_prop` and its siblings — keys that exist only in the
legacy `params.yaml`. The function could not have run on a simulated parameter set at all; it
worked because `total.R` called it with `old_params`.

---

## What changed

### SAR: one scalar becomes forty

GOLIAT simulated the far field for **all four phantoms** — plane waves from 12 incidence
directions, 9 frequencies, normalised to an incident power density of 1 W/m². So unlike the
near-field sources, the far field needs no child-to-adult ratios: the children were simulated
directly. That is why this source could be converted while `doc/SAR_REDESIGN.md` Q3 is still open.

`data-raw/import_sar.R` gained a third reader (section 4c) and writes 80 new keys:

```
Duke_body_goliat_450_farfield_sar   5.344
Duke_body_goliat_700_farfield_sar   5.484
Duke_body_goliat_800_farfield_sar   5.091
Duke_body_goliat_900_farfield_sar   5.091   <- same node as 800
...
```

**The 12 directions are averaged.** The spread across them is a factor of 1.5 to 4.7, but a
person turns during the day, so drawing one direction would assert a fixed orientation over
24 hours.

**Three pairs of bands share a simulated node**, visible in the values above. GOLIAT did not
simulate 800, 900, 1800, 2100, 2600 or 5000 MHz, so each band takes its nearest node, in keeping
with the decision to stop interpolating. The yaml shows the duplication openly instead of hiding
it behind an interpolated value.

### The ambient field is not monochromatic

Weighting the nine simulated frequencies needs a spectrum. Adriana's EU-level composition supplies
it, from `Input_dose_model_Final_ETAIN_nSAR.xlsx`, sheet `Farfield`:

| <700 | 700 | 800 | 900 | 1800 | 2100 | 2450 | 2600 | 3500 | 5000 |
|---|---|---|---|---|---|---|---|---|---|
| 0.08 | 0.04 | 0.15 | 0.17 | **0.23** | 0.15 | 0.02 | 0.07 | 0.07 | 0.02 |

The spectrum is markedly low-frequency: 1800 MHz alone carries 23 %, the two WiFi bands 4 %
together.

It has ten buckets where the model grid has nine bands, because the lowest one is "below
700 MHz". GOLIAT simulated 450 MHz for exactly that purpose, and the key is labelled 450 after it.

**The weighting happens at run time, not at import.** The spectrum stays a visible parameter, so
when Adriana delivers the per-environment spectra the workbook foresees (`OPEN_QUESTIONS.md` B1)
that is a small change rather than a re-import. It is drawn from a Dirichlet with a0 = 100, the
house default for proportion sets.

### Urbanicity became a category instead of a mixture

`simulate_params()` had always drawn urbanicity as three Dirichlet proportions. Nothing read them,
so it never showed. Far field is the first consumer, and reading them as a mixture turned out to
be wrong.

The model describes the average day of **one** person. That person lives in an urban, a suburban
or a rural area — not in a 40/50/10 mixture of the three. The yaml values are population shares
the category is drawn from. Weighting the exposure levels by them would have given every simulated
person the population average and averaged away exactly the between-person spread the model exists
to quantify:

| | dose spread, Duke, CH, 2000 draws |
|---|---|
| proportions mixed | 37.05 – 50.80 |
| category drawn | **25.51 – 58.55** |

Urban and rural far-field levels differ by about a factor of two, and that belongs in the output.

The draw is now categorical and the result is still stored as three proportions, exactly one of
which is 1. `farfield_pwr()` therefore weights over them and the weighting collapses to picking
one level — written that way so a genuine mixture could be substituted later without rewriting
the function.

### Dead keys

`global$home_prop`, `$work_prop` and `$outd_prop` are replaced by
`global$environment_prop$*`, which is where the Dirichlet actually puts them.

---

## Effect on the numbers

Spectrum-weighted far-field SAR, W/kg per W/m²:

| | whole body | vs the old scalar | brain |
|---|---|---|---|
| Duke | 0.004242 | −9 % | 0.004396 |
| Ella | 0.004913 | +6 % | 0.004771 |
| **Thelonious** | **0.008187** | **+76 %** | 0.006113 |
| **Eartha** | **0.006832** | **+47 %** | 0.005635 |

Two changes act at once on the dose, and they are worth separating. Duke, whole body, CH,
600 s travel:

| | dose |
|---|---|
| before | 41.88 |
| SAR resolved only | 38.17 |
| plus urbanicity weighted | 41.21 |

For an adult the two nearly cancel. For the children they do not:

| | dose | before |
|---|---|---|
| Thelonious | 79.53 | 41.88 |
| Eartha | 66.37 | 41.88 |

---

## Validation

`tests/test_farfield.R` reproduces `farfield_sar()` from the yaml keys by hand for all four
phantoms and both tissues, and asserts:

- the ten spectrum weights sum to 1, otherwise the weighted SAR is not an average at all
- both children absorb more per kilogram than the matching adult
- supplying an urbanicity reproduces picking that single level
- the location proportions keep their total as travel time varies

The importer gained validation E, which checks the far-field SAR against the scalar it replaces
and aborts if it is more than a factor of five away.

Over 2000 draws the inputs land on their specifications: mean travel time 1706 s against the
1728 s implied by `travel_prop_mean = 0.02`, and urbanicity 0.394 / 0.507 / 0.098 against
0.4 / 0.5 / 0.1.

---

## What is deliberately not modelled

**The exposure levels are point values, not drawn.** The parameter workbook specifies Gamma
distributions for them but leaves every mean empty, and its environment scheme — indoor,
outdoor_low, outdoor_high, trans_peak, trans_offpeak, workplace — does not match the
home/work/out/travel × urban/suburban/rural × 11 countries the code uses. See
`OPEN_QUESTIONS.md` C9 and B1. The values remain the per-country measurements from ETAIN.

**One spectrum for every environment.** The workbook foresees a separate frequency composition for
indoor, outdoor and transport. All 45 cells are empty, so Adriana's single EU-level set is used
everywhere.

**Travel time is not given its own distribution, by design.** The four location proportions must
sum to 1, which is what the Dirichlet in `global$environment_prop` enforces. A separate draw for
travel time would break that constraint. It remains an optional input to `simulate_params()`; when
it is not supplied, `travel_prop_mean = 0.02` applies — about 29 minutes a day.

Note that `total.R` still hard-codes `sample$travel_time <- 600` for the sources that are not yet
converted, which is 10 minutes. The two disagree by a factor of nearly three. The 600 s sits in the
block marked *"delete this section when everything is stochastic"* and disappears source by source.
