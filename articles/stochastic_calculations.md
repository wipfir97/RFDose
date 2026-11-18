# Stochastic Calculations

``` r

library(RFDose)
```

[`calculate_emf_doses_stochastic()`](https://wipfir97.github.io/RFDose/reference/calculate_emf_doses_stochastic.md)
gives the uncertainty of the doses. It calculates the doses of each row
`n` times (default: 1000), each time with parameters, SAR values and
input values drawn from their distributions (see [Uncertainty in the
stochastic model](#uncertainty-in-the-stochastic-model)), and summarises
the doses of all draws. It takes the same arguments as
[`calculate_emf_doses()`](https://wipfir97.github.io/RFDose/reference/calculate_emf_doses.md),
including `sar_file`. Give a `seed` for reproducible results: the same
seed and arguments give the same draws.

## How to use stochastic calculations

``` r

# Calculate example doses with their uncertainty
result <- calculate_emf_doses_stochastic(
  example_data, 
  tissue = "brain", 
  n = 1000, 
  seed = 1)
head(result)
#>   sample_id row      dose deterministic       mean         sd      q2.5
#> 1     TEST1   1 call_dose     73.158702  75.357657 44.1154544 22.257444
#> 2     TEST1   1 data_dose    203.099513 207.172960 79.6143357 99.613949
#> 3     TEST1   1 dect_dose     87.012757  84.171673 50.7442908 20.036082
#> 4     TEST1   1 farf_dose    160.649754 157.821709 65.5701609 45.433573
#> 5     TEST1   1 wifi_dose      2.804097   2.795889  0.7220588  1.710858
#> 6     TEST1   1 lptp_dose     11.419562  11.236501  4.1954528  5.009065
#>          q50      q97.5
#> 1  65.971687 186.105093
#> 2 192.077063 404.876663
#> 3  72.585983 208.906906
#> 4 151.360612 304.949104
#> 5   2.684747   4.469926
#> 6  10.532281  21.167345
```

The result has one row per row of `data` and exposure source, plus the
total dose (`total_dose`), in mJ/kg/day:

     sample_id row       dose deterministic  mean    sd  q2.5   q50 q97.5
         TEST1   1  call_dose          73.2  75.4  44.1  22.3  66.0 186.1
         TEST1   1  data_dose         203.1 207.2  79.6  99.6 192.1 404.9
         ...
         TEST1   1 total_dose         565.0 565.9 119.0 367.6 551.3 828.0

| Column | Description |
|----|----|
| sample_id, row | ID (if `data` has a column `sample_id`) and row number in `data` |
| dose | Exposure source (as the columns of [`calculate_emf_doses()`](https://wipfir97.github.io/RFDose/reference/calculate_emf_doses.md)), or `total_dose` for their sum |
| deterministic | Dose with the values of the parameter file, as calculated by [`calculate_emf_doses()`](https://wipfir97.github.io/RFDose/reference/calculate_emf_doses.md) |
| mean, sd | Mean and standard deviation of the doses of all draws |
| q2.5, q50, q97.5 | Median and 95% interval of the doses of all draws (other quantiles with `probs`) |

Options:

- `sar_sd`: standard deviation of the SAR values, relative to their
  value (default: 0.25). With 0, the SAR values are not drawn
- `draw_inputs = FALSE`: the input values are not drawn, so the
  uncertainty comes from the parameters and SAR values only
- `distributions`, `input_distributions`: own distribution files (YAML),
  with the structure of the inbuilt files
  [`params_distributions.yaml`](https://wipfir97.github.io/RFDose/articles/inst/extdata/params_distributions.yaml)
  and
  [`input_distributions.yaml`](https://wipfir97.github.io/RFDose/articles/inst/extdata/input_distributions.yaml)
- `keep_draws = TRUE`: also returns the doses, parameters and inputs of
  every draw
- `seed`: random seed for reproducible draws (as
  [`set.seed()`](https://rdrr.io/r/base/Random.html) before, but without
  changing the random state of the session)

The calculation takes about 25 seconds for the 3 rows of the example
data with 1000 draws, and grows with the number of rows and draws.

``` r

# Uncertainty from the parameters and SAR values only, with the GOLIAT SAR values (average of the four phantoms)
calculate_emf_doses_stochastic(
  example_data, 
  tissue = "brain", 
  sar_file = "goliat_average", 
  draw_inputs = FALSE)
#>    sample_id row       dose deterministic       mean          sd        q2.5
#> 1      TEST1   1  call_dose     73.158702  72.215576  35.1646519  27.1499544
#> 2      TEST1   1  data_dose    203.099513 202.086090  60.5350162 114.9547918
#> 3      TEST1   1  dect_dose     87.012757  84.795450  45.8983002  22.1033202
#> 4      TEST1   1  farf_dose    160.649754 161.453186  47.1746656  90.1353746
#> 5      TEST1   1  wifi_dose      2.804097   2.793875   0.7446702   1.6469238
#> 6      TEST1   1  lptp_dose     11.419562  11.639946   4.5542665   5.2758454
#> 7      TEST1   1  tblt_dose     25.701292  25.939662   9.9242767  11.5669796
#> 8      TEST1   1 other_dose      1.150865   1.120026   0.6710756   0.2621386
#> 9      TEST1   1 total_dose    564.996543 562.043810  98.2032502 391.0003879
#> 10     TEST2   2  call_dose     27.852704  27.406919  12.8188069  10.1968105
#> 11     TEST2   2  data_dose      0.000000   0.000000   0.0000000   0.0000000
#> 12     TEST2   2  dect_dose    221.805593 216.172707 116.7786295  56.6332273
#> 13     TEST2   2  farf_dose     38.330466  38.628013  11.2727586  21.3282929
#> 14     TEST2   2  wifi_dose      2.804097   2.793875   0.7446702   1.6469238
#> 15     TEST2   2  lptp_dose      0.000000   0.000000   0.0000000   0.0000000
#> 16     TEST2   2  tblt_dose      0.000000   0.000000   0.0000000   0.0000000
#> 17     TEST2   2 other_dose    163.734543 162.136425  98.9047723  32.6398497
#> 18     TEST2   2 total_dose    454.527403 447.137940 160.1543026 199.7421328
#> 19     TEST3   3  call_dose    170.978687 168.010733  89.0937910  55.3275800
#> 20     TEST3   3  data_dose      0.000000   0.000000   0.0000000   0.0000000
#> 21     TEST3   3  dect_dose     22.508494  21.946891  11.7420609   5.8238504
#> 22     TEST3   3  farf_dose    231.515576 233.491633  69.2614245 130.9705699
#> 23     TEST3   3  wifi_dose      2.804097   2.793875   0.7446702   1.6469238
#> 24     TEST3   3  lptp_dose      0.000000   0.000000   0.0000000   0.0000000
#> 25     TEST3   3  tblt_dose      0.000000   0.000000   0.0000000   0.0000000
#> 26     TEST3   3 other_dose      4.693819   4.620667   1.4536136   2.6549985
#> 27     TEST3   3 total_dose    432.500673 430.863798 113.8487129 256.3632031
#>            q50      q97.5
#> 1   63.8341233 159.477294
#> 2  192.6641813 344.987290
#> 3   75.2665652 195.163183
#> 4  152.5849927 272.645615
#> 5    2.7045570   4.464348
#> 6   10.9169692  22.907090
#> 7   24.0432840  50.983048
#> 8    0.9876443   2.611331
#> 9  552.5630222 780.816300
#> 10  24.5142350  56.824231
#> 11   0.0000000   0.000000
#> 12 191.9674842 497.869771
#> 13  36.9866078  63.888720
#> 14   2.7045570   4.464348
#> 15   0.0000000   0.000000
#> 16   0.0000000   0.000000
#> 17 142.6405888 398.636396
#> 18 427.5312354 796.018784
#> 19 147.8732011 393.619405
#> 20   0.0000000   0.000000
#> 21  19.5959681  50.076983
#> 22 223.4876917 386.596207
#> 23   2.7045570   4.464348
#> 24   0.0000000   0.000000
#> 25   0.0000000   0.000000
#> 26   4.4120425   7.797385
#> 27 417.0592342 677.845517
```

## Uncertainty in the stochastic model

[`calculate_emf_doses_stochastic()`](https://wipfir97.github.io/RFDose/reference/calculate_emf_doses_stochastic.md)
draws three kinds of values. Each distribution is centred on the value
used by the deterministic calculation, and only its shape is given in
the distribution files:

| Drawn values | Distributions | File |
|----|----|----|
| Parameters (260): output powers, duty cycles, proportions, far-field power densities | Lognormal and truncated lognormal (powers), beta (duty cycles, single proportions), Dirichlet (proportions that sum to 1, drawn together); mean = value in `params.yaml` | [`params_distributions.yaml`](https://wipfir97.github.io/RFDose/articles/inst/extdata/params_distributions.yaml) |
| SAR values | Lognormal around their value, with a relative standard deviation of 25% (`sar_sd`). SAR values from the same simulation are drawn together; SAR values of 0 stay 0 | \- |
| Inputs (27): durations, proportions, urbanicity, commuting time | Truncated lognormal for durations (relative standard deviation 20%, between 0 and 86400 s), beta and Dirichlet for proportions, categorical for urbanicity (given value kept with probability 0.8); centred on the value in `data`, or on the default value if missing. Durations of 0 stay 0 | [`input_distributions.yaml`](https://wipfir97.github.io/RFDose/articles/inst/extdata/input_distributions.yaml) |

Every row is calculated with the same parameter sets, and the inputs of
a row are drawn around its own values, so the doses of a row do not
depend on the other rows. The distribution files are generated from the
same Excel file as the parameters and default values
(`data-raw/source_params/`).
