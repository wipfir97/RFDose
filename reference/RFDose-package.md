# RFDose: Deterministic and Stochastic RF-EMF Dose Calculator

Calculates the daily dose of radiofrequency electromagnetic fields
(RF-EMF) absorbed by the brain or the whole body, in mJ/kg/day, for each
person of a cohort, from the self-reported use of wireless devices and
the environment of each person. A deterministic model gives the doses
([`calculate_emf_doses()`](https://wipfir97.github.io/RFDose/reference/calculate_emf_doses.md))
and a stochastic model their uncertainty
([`calculate_emf_doses_stochastic()`](https://wipfir97.github.io/RFDose/reference/calculate_emf_doses_stochastic.md)).

## Deterministic dose model

[`calculate_emf_doses()`](https://wipfir97.github.io/RFDose/reference/calculate_emf_doses.md)
calculates the doses of each row of the data (one person) for eight
exposure sources: mobile phone calls, mobile data, cordless phone,
far-field sources, WiFi router, laptop, tablet and other devices
(smartwatch, VR headset, hotspot, Bluetooth headphones and portable
gaming consoles). The dose of a source is its momentary SAR (mSAR, in
mW/kg) times the exposure time (in s/day):

- Near-field sources (devices used close to the body): the mSAR is the
  normalized SAR (nSAR, in W/kg per W of output power) times the output
  power of the device (in mW), including its duty cycle.

- Far-field sources (mobile phone base stations and broadcast stations)
  and WiFi router: the mSAR is the nSAR (in W/kg per W/m\\^2\\ of
  incident power density) times the power density (in mW/m\\^2\\).

Output powers, power densities and nSAR values are averaged over the
networks, frequency bands, places, activities and positions of the
device, weighted by their shares (see the source functions, e.g.
[`mobilecall_dose()`](https://wipfir97.github.io/RFDose/reference/mobilecall_dose.md)).
The calculation uses three kinds of values:

- Inputs: the columns of the data (durations of use, proportions,
  urbanicity, country, commuting time, use of 5G), as in
  [example_data](https://wipfir97.github.io/RFDose/reference/example_data.md).
  Missing values are replaced by default values
  (`defaultvariables.yaml`).

- Parameters: output powers, duty cycles, proportions and far-field
  power densities (`params.yaml`, or your own file with the argument
  `params`).

- SAR values: from a SAR file (argument `sar_file`): GOLIAT values
  averaged over four phantoms by default, one phantom, or ETAIN (see
  [`available_sar_files()`](https://wipfir97.github.io/RFDose/reference/available_sar_files.md)).

The result has one column per exposure source with its dose in mJ/kg/day
for the chosen tissue (argument `tissue`: "brain" or "body").

## Stochastic dose model

[`calculate_emf_doses_stochastic()`](https://wipfir97.github.io/RFDose/reference/calculate_emf_doses_stochastic.md)
estimates the uncertainty of the doses. It repeats the deterministic
calculation `n` times (default: 1000), each time with the parameters,
SAR values and inputs drawn around their values:

- Parameters: with the distributions of `params_distributions.yaml`
  (lognormal or truncated lognormal for powers, beta for duty cycles and
  single proportions, Dirichlet for proportions that sum to 1), whose
  mean is the value of the parameter. See
  [`simulate_params()`](https://wipfir97.github.io/RFDose/reference/simulate_params.md).

- SAR values: lognormal, with a relative standard deviation of 25%
  (argument `sar_sd`). SAR values from the same simulation are drawn
  together, and SAR values of 0 stay 0.

- Inputs: durations, proportions, urbanicity and commuting time, with
  the distributions of `input_distributions.yaml` (truncated lognormal
  with a relative standard deviation of 20% for durations, beta or
  Dirichlet for proportions, categorical for urbanicity). Durations of 0
  stay 0. See
  [`simulate_inputs()`](https://wipfir97.github.io/RFDose/reference/simulate_inputs.md);
  `draw_inputs = FALSE` keeps the inputs fixed.

All rows are calculated with the same parameter draws, and the inputs of
a row are drawn around its own values, so the doses of a row do not
depend on the other rows. For each row and exposure source, and for the
total dose, the result gives the deterministic dose, the mean and
standard deviation of the doses of all draws, and their quantiles
(default: median and 95% interval). Give a `seed` for reproducible
results.

## See also

[`calculate_emf_doses()`](https://wipfir97.github.io/RFDose/reference/calculate_emf_doses.md),
[`calculate_emf_doses_stochastic()`](https://wipfir97.github.io/RFDose/reference/calculate_emf_doses_stochastic.md),
[`available_sar_files()`](https://wipfir97.github.io/RFDose/reference/available_sar_files.md),
[`load_params()`](https://wipfir97.github.io/RFDose/reference/load_params.md)

## Author

**Maintainer**: Irina Wipf <irina.wipf@swisstph.ch>

Authors:

- Irina Wipf <irina.wipf@swisstph.ch>

- Nicolas Loizeau <nicolas.loizeau@swisstph.ch>

- Gianni Ardielli

- Fabrice Keller

Other contributors:

- Hamed Jalilian \[contributor\]

- Martin Röösli \[contributor\]
