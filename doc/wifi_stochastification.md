# Stochastification of the WiFi exposure source

**Date:** 2026-09-29
**Code:** `R/wifi.R`, wiring in `R/total.R`, parameters in
`inst/extdata/params_stochastic.yaml` and `params_template.yaml`, tests in `tests/test_wifi.R`

**What it models:** exposure to the WiFi network the person is connected to or sitting next to.

---

## Where the line to far field runs

Not "a router I own" but **a network I am in**:

| | |
|---|---|
| `wifi` | the router at home, the network at the office, and the access point on a train or in a café while it is being used |
| `farfield` | networks and transmitters the person is merely surrounded by, without using them |

That is why the exposure duration counts home, work **and** the part of the travel time with WiFi
in use.

Structurally this is an ambient source like far field: power density × absorption × time. There is
no device against the body and therefore no distance correction.

### Is the same SAR counted twice?

`wifi` and `farfield` read the *same* GOLIAT far-field table, including at 2450 and 5000 MHz,
which the far-field spectrum also covers. That looks like double counting and is not.

**What is shared is the SAR, and a SAR value is a property of the body**, not of the source: "in a
field of 1 W/m², this body absorbs X W/kg". Duke absorbs 0.003474 W/kg per W/m² at 2450 MHz no
matter where the field comes from. What must not be counted twice is the **field**, and the two
sources supply different ones:

| power density at the WiFi bands | 2450 | 5000 | together |
|---|---|---|---|
| `farfield`, ambient | 0.0022 | 0.0022 | 0.0045 mW/m² |
| `wifi`, own network | 0.0180 | 0.0130 | 0.0310 mW/m² |

They are added, not duplicated. The own network supplies about seven times the ambient field at
these frequencies, which is what one would expect of a router in the same room.

**The strongest argument is how the far-field indoor level is built.** It is not an indoor
measurement at all. Per `MODEL_LIMITATIONS.md` §A4 the indoor levels are derived from *outdoor*
measurements through a 4.6 dB damping factor — `home_urb_pwr_CH` is base-station signal coming
through the wall. A router standing inside the flat cannot be contained in it; it is on the wrong
side of the wall.

**One caveat remains, for travel.** The transport level comes from measurements taken in public
transport, where a train's own WiFi would have been picked up. If the person then actively uses
that WiFi, it is counted again here. This concerns under 1 % of the WiFi duration, so it is noted
rather than corrected.

For scale: of the 41.2 mJ/kg/day the far field contributes for Duke in CH, 1.65 comes from the two
WiFi bands, against 3.83 from the own network.

---

## Before

```r
wifi_sar <- function(tissue, band, params) {
  tissue_params <- load_tissue_params_old(params, "wifi", tissue)
  sar <- tissue_params[[paste("wifi", band, "sar", sep = "_")]]
}
```

One scalar per tissue and band, the same for all four phantoms — a simulated child received the
adult's WiFi dose.

And `wifi.R` read five keys that exist only in the legacy `params.yaml`:
`global$home_prop`, `$outd_prop`, `$work_prop`, `$wifi_2_prop`, `$wifi_5_prop`. On a simulated
parameter set the function aborted. It worked only because `total.R` called it with `old_params`.
**It was the last source in that state.**

---

## What changed

### SAR: resolved by phantom

`wifi_sar()` now resolves the phantom with `determine_dummy()` and reads GOLIAT's far-field
tables at the two WiFi bands — the same values `farfield.R` uses:

```
<phantom>_<tissue>_goliat_{2450,5000}_farfield_sar   ÷ 1000
```

No new keys were needed; those tables arrived with the far-field conversion the day before.

**Using the same SAR values in two sources is not double counting.** A SAR value is a transfer
function of the *body* — "in a field of 1 W/m², this body absorbs X W/kg". What must not be
counted twice is the *field*, and the two sources supply different fields.

### Dead keys and band tokens

`global$environment_prop$*` replaces the three location keys, and `global$wifi_probs` the two band
shares. The band tokens change from `"2"`/`"5"` to `"2450"`/`"5000"`, which is what the rest of the
model has used since the frequency grid was realigned on 2026-09-28, and what lets one token build
all three key families — power, band share and SAR.

In the yaml, `wifi_2_pwr` and `wifi_5_pwr` become `wifi_2450_pwr` and `wifi_5000_pwr`. The old
`wifi_*_sar` entries are removed.

### A partial-matching bug fixed in passing

`total.R` read `sim_params$global$input_stoc$...` — no `h`. It resolved anyway, because R's `$`
does partial matching on lists, and it fed three sources including this one. Three lines, one
character each. `MODEL_LIMITATIONS.md` §E has been tracking this class of bug.

---

## The SAR choice, and what it gives up

This is the part worth reading before anyone revisits it.

**ETAIN simulated an intermediate-field router.** Its workbook has a scenario labelled
*"Intermediate field / Emulating an indoor WiFi router"*, a 2.45 GHz dipole in front of Duke and
Ella. Whole body 5.1 and 5.49 mW/kg/W, roughly **50 % above** the far-field value at the same
frequency. ETAIN's own note in the same file: *"At the moment 5 GHz intermediate is not available
and we need to take far field value for it."* Their design was intermediate field where simulated,
far field as a stopgap.

**The deterministic model implemented that.** `params.yaml` holds 0.005295 and 0.00133 at
2.4 GHz — exactly those intermediate-field numbers.

**The stochastic yaml had already replaced them** with far-field values (0.003556, 0.00261819) at
some point, without a record. An earlier entry in `OPEN_QUESTIONS.md` §F described `params.yaml` as
holding "the older band-independent value"; that was wrong and has been corrected.

**We now use far field deliberately, for three reasons.**

The physical one comes first: a router is typically one to five metres away. At 2.45 GHz that is
**8 to 40 wavelengths**, and at 5 GHz twice as many — already the far field. The intermediate field
extends to roughly two or three wavelengths, about 30 cm at 2.45 GHz. ETAIN's scenario does not
state its distance, but if it is a few decimetres it models someone sitting beside the router
rather than the normal case.

The second: the intermediate-field value exists at one frequency only, for two phantoms only. Using
it would mean mixing regimes across the two bands and losing the child resolution that is the whole
point of the conversion.

The third: it exists only in `Input_dose_model_Final_ETAIN_nSAR.xlsx`, the distilled workbook that
Q7 decided against in favour of the simulation databases.

**What this gives up** is quantified: if a person does sit close to their router, absorption at
2.4 GHz is about 50 % higher than this model assumes. That is the residue of
`MODEL_LIMITATIONS.md` §A5, which is now a distance assumption rather than a regime error.

---

## Effect on the numbers

SAR in W/kg per W/m²:

| | body 2450 | body 5000 | brain 2450 | brain 5000 |
|---|---|---|---|---|
| before, one value for all | 0.003556 | 0.002402 | 0.002618 | 0.000556 |
| Duke | 0.003474 | 0.002430 | 0.001954 | 0.000187 |
| Ella | 0.003780 | 0.002759 | 0.002279 | 0.000404 |
| Thelonious | 0.007149 | 0.004469 | 0.004649 | 0.001146 |
| Eartha | 0.005896 | 0.003926 | 0.003559 | 0.000783 |

Dose, whole body, against the previous single value:

| | | |
|---|---|---|
| Duke | −1 % | the old scalar was itself a far-field value |
| Ella | +9 % | |
| **Thelonious** | **+97 %** | |
| **Eartha** | **+65 %** | |

**The brain channel moves further: Duke −29 %.** That is larger than a rounding difference and
needs saying plainly. The old value came from ETAIN's far-field set, the new one from GOLIAT's. The
two campaigns agree on whole body to within 2 % but differ by 29 % on brain. This fits the pattern
seen throughout the model — the brain channel is the less reliable one in every comparison between
the campaigns. Anyone comparing WiFi brain doses against the old model will see this, and it comes
from the change of campaign, not from an error.

---

## Validation

`tests/test_wifi.R` reproduces `wifi_dose()` by hand from the yaml for all four phantoms and both
tissues, and asserts:

- both children absorb more per kilogram than the matching adult, in both bands
- `wifi_sar()` reads the same far-field table as `farfield_sar()`, so the two cannot drift apart
- using WiFi while travelling increases the dose
- the function runs on a simulated parameter set — the thing it could not do before

---

## What is deliberately not modelled

**The power densities are point values.** 0.018 and 0.013 mW/m², HERMES3 personal measurements,
each the mean of a home and a school value. The parameter workbook's `wifi` sheet lists only
`router_duration`, `wifi2_prop` and `wifi5_prop` — no spread for the levels.

Note that these levels already average a home and a school environment, which is consistent with a
duration that counts home and work.

**`router_duration: 59616` from the workbook is not used.** It equals exactly the home share of the
day, so the specification assumes the router at home only. The code counts home, work and travel
WiFi, which matches the definition above and the levels' own composition.
