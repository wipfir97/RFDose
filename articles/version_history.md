# version_history

``` r

library(RFDose)
```

**Information for users of version 1.0.0**

- `calculate_emf_doses` now uses the GOLIAT SAR values (average of four
  phantoms) by default instead of the ETAIN SAR values, so the doses
  differ from version 1.0.0
- To get the same doses as version 1.0.0, use the ETAIN SAR values:
  `calculate_emf_doses(data, tissue, sar_file = "etain")`
- `calculate_emf_doses` has a new optional input variable “sar_file” to
  choose the SAR values (see the [use example](#use-example))
- The inbuilt parameter file
  [`params.yaml`](https://wipfir97.github.io/RFDose/articles/inst/extdata/params.yaml)
  no longer contains SAR values: they are in separate SAR files
- New function `calculate_emf_doses_stochastic` gives the uncertainty of
  the doses (see [Stochastic dose
  calculation](#stochastic-dose-calculation))

**Information for users of previous test versions (0.2.0, 0.3.0)**

- The definition of the mpc_headp_prop input variable changed- please
  refer to the variable overview below
- `calculate_emf_doses` no longer returns a total dose, only
  source-specific doses
- `calculate_emf_doses` is now tissue-specific and has the additional
  required input variable “tissue”

## Version History

| Version | Description |
|----|----|
| 2.0.1 | Documentation: formulas and units corrected for all exposure sources; package manual ordered by exposure source. Unused arguments removed from [`mpc_bt_earset_msar()`](https://wipfir97.github.io/RFDose/reference/mpc_bt_earset_msar.md), [`mpc_bt_phone_msar()`](https://wipfir97.github.io/RFDose/reference/mpc_bt_phone_msar.md) and [`wifi_msar()`](https://wipfir97.github.io/RFDose/reference/wifi_msar.md) |
| 2.0.0 | SAR values from GOLIAT dosimetric simulations included: one file per phantom and one with their average (`inst/extdata/sar_goliat_*.yaml`). All SAR values are now taken from GOLIAT instead of ETAIN, except for the sources without a similar GOLIAT simulation (smartwatch, headphones, Bluetooth headset), which keep their ETAIN values. The average of the four phantoms is the default; the ETAIN SAR values remain available with `sar_file` (`sar_etain.yaml`). See [GOLIAT SAR values](#goliat-sar-values). Output power parameters updated with data from GOLIAT Task 1.2. First version of the stochastic dose model ([`calculate_emf_doses_stochastic()`](https://wipfir97.github.io/RFDose/reference/calculate_emf_doses_stochastic.md), see [Stochastic dose calculation](#stochastic-dose-calculation)) |
| 1.0.0 | Updated version based on finalized dose calculations in Jalilian et al. (manuscript in preparation) |
| 0.3.0 | Updated version with major changes in dose calculations (based on dose calculator 7.6). Based on dose calculator version 7.6 |
| 0.2.0 | Revised draft version with updated calculations, variables, and unit tests. Based on dose calculator version 7.3 |
| 0.1.0 | Initial draft version for internal use |
| 0.0.1 | Basic test version (not on Github) |
