# RFDose - Deterministic and Stochastic RF-EMF Dose Calculator

## About

RFDose implements the deterministic RF-EMF dose calculations developed in Jalilian et al. (publication in writing stage). Version 2.0.0 is based on the most up-to-date dose calculations (October 2026). It also includes a first version of a stochastic dose model, which estimates the uncertainty of the doses (see [Stochastic dose calculation](#stochastic-dose-calculation)).

For detailed information about the package functions, please refer to the [package manual](./doc/RFDose_2.0.0.pdf). We are also preparing a short publication on `RFDose`, which will contain further background information. 

**Information for users of version 1.0.0**

* `calculate_emf_doses` now uses the GOLIAT SAR values (average of four phantoms) by default instead of the ETAIN SAR values, so the doses differ from version 1.0.0
* To get the same doses as version 1.0.0, use the ETAIN SAR values: `calculate_emf_doses(data, tissue, sar_file = "etain")`
* `calculate_emf_doses` has a new optional input variable "sar_file" to choose the SAR values (see the [use example](#use-example))
* The inbuilt parameter file [`params.yaml`](inst/extdata/params.yaml) no longer contains SAR values: they are in separate SAR files
* New function `calculate_emf_doses_stochastic` gives the uncertainty of the doses (see [Stochastic dose calculation](#stochastic-dose-calculation))

**Information for users of previous test versions (0.2.0, 0.3.0)**

* The definition of the mpc\_headp\_prop input variable changed- please refer to the variable overview below
* `calculate_emf_doses` no longer returns a total dose, only source-specific doses
* `calculate_emf_doses` is now tissue-specific and has the additional required input variable "tissue"

\---


## Installation and Use Example

### Install RFDose

Install `RFDose` using the `remotes` R package.

```{r}
# Install package
remotes::install_github("wipfir97/RFDose")
# Load package
library(RFDose)
```

### Use Example

Load the example data set, which contains data from 3 hypothetical samples.

For a quick start, you can load the in-build example data set. Each row corresponds to one person, with 3 hypothetical data points. 

```{r}
# Load example data
data(example_data)
# View example data
head(example_data)
```

Calculate RF-EMF doses in mJ/kg/day for each row by using the `calculate_emf_doses()` function and specifying a tissue (currently supported: "brain" and "body"(=overall exposure of the whole body)). By default, the calculations use the GOLIAT SAR values, averaged over four phantoms (see [GOLIAT SAR values](#goliat-sar-values)).

```{r}
# Calculate example doses
calculate_emf_doses(example_data, tissue = "brain") # brain dose
calculate_emf_doses(example_data, tissue = "body")  # body dose
```

Use your own parameters by providing a custom file. This file must be in YAML format and follow the same structure as the [inbuilt parameter file](inst/extdata/params.yaml), which contains all parameters except SAR values. SAR values may be added to the file (with the structure of the [inbuilt SAR files](inst/extdata/sar_goliat_average.yaml)); otherwise the default SAR values (GOLIAT, average of four phantoms) are used.

*Note that the R package does not currently check the structure of custom parameter files, so mismatches may result in faulty calculations.*

```{r}
# Calculate example doses with own parameter file
calculate_emf_doses(
  example_data, 
  tissue = "brain", 
  params = "path_to_my_file/my_params.yaml")
```

To change only the SAR values, provide a YAML file containing SAR values, following the same structure as the [inbuilt SAR files](inst/extdata/sar_goliat_average.yaml). All other parameters keep their default values (or the values of `params`, if supplied), except device parameters that the SAR file sets itself (e.g. placement proportions that go with its SAR values).

The package includes these SAR files, which `sar_file` takes by name (`available_sar_files()` lists them):

|Name|SAR values|File in `inst/extdata/`|
|-|-|-|
|`"goliat_average"`|GOLIAT, average of the four phantoms (default)|`sar_goliat_average.yaml`|
|`"goliat_duke"`, `"goliat_ella"`, `"goliat_eartha"`, `"goliat_thelonious"`|GOLIAT, one phantom|`sar_goliat_<phantom>.yaml`|
|`"etain"`|ETAIN|`sar_etain.yaml`|

Each of these files also sets the laptop and headphone placement proportions that go with its SAR values. The assumptions behind the GOLIAT files are described in [GOLIAT SAR values](#goliat-sar-values).

```{r}
# Calculate example doses with the GOLIAT SAR values, average of the four phantoms (default)
calculate_emf_doses(
  example_data, 
  tissue = "brain", 
  sar_file = "goliat_average")

# Calculate example doses with the SAR values of one GOLIAT phantom
calculate_emf_doses(
  example_data, 
  tissue = "brain", 
  sar_file = "goliat_duke")

# Calculate example doses with own SAR file
calculate_emf_doses(
  example_data, 
  tissue = "brain", 
  sar_file = "path_to_my_file/my_sar.yaml")
```

Behind the scenes, `calculate_emf_doses()` calls various source-specific dose functions, which calculate the individual contributions of different sources (e.g. mobile phone calls). These functions may be used individually. 

### Stochastic dose calculation

`calculate_emf_doses_stochastic()` gives the uncertainty of the doses. It calculates the doses of each row `n` times (default: 1000), each time with parameters, SAR values and input values drawn from their distributions (see [Uncertainty in the stochastic model](#uncertainty-in-the-stochastic-model)), and summarises the doses of all draws. It takes the same arguments as `calculate_emf_doses()`, including `sar_file`. Use `set.seed()` before for reproducible results.

```{r}
# Calculate example doses with their uncertainty
set.seed(1)
calculate_emf_doses_stochastic(example_data, tissue = "brain", n = 1000)
```

The result has one row per row of `data` and exposure source, plus the total dose (`total_dose`), in mJ/kg/day:

```
 sample_id row       dose deterministic  mean    sd  q2.5   q50 q97.5
     TEST1   1  call_dose          73.2  75.4  44.1  22.3  66.0 186.1
     TEST1   1  data_dose         203.1 207.2  79.6  99.6 192.1 404.9
     ...
     TEST1   1 total_dose         565.0 565.9 119.0 367.6 551.3 828.0
```

|Column|Description|
|-|-|
|sample\_id, row|ID (if `data` has a column `sample_id`) and row number in `data`|
|dose|Exposure source (as the columns of `calculate_emf_doses()`), or `total_dose` for their sum|
|deterministic|Dose with the values of the parameter file, as calculated by `calculate_emf_doses()`|
|mean, sd|Mean and standard deviation of the doses of all draws|
|q2.5, q50, q97.5|Median and 95% interval of the doses of all draws (other quantiles with `probs`)|

Options:

* `sar_sd`: standard deviation of the SAR values, relative to their value (default: 0.25). With 0, the SAR values are not drawn
* `draw_inputs = FALSE`: the input values are not drawn, so the uncertainty comes from the parameters and SAR values only
* `distributions`, `input_distributions`: own distribution files (YAML), with the structure of the inbuilt files [`params_distributions.yaml`](inst/extdata/params_distributions.yaml) and [`input_distributions.yaml`](inst/extdata/input_distributions.yaml)
* `keep_draws = TRUE`: also returns the doses, parameters and inputs of every draw

The calculation takes about 25 seconds for the 3 rows of the example data with 1000 draws, and grows with the number of rows and draws.

```{r}
# Uncertainty from the parameters and SAR values only, with the GOLIAT SAR values (average of the four phantoms)
calculate_emf_doses_stochastic(
  example_data, 
  tissue = "brain", 
  sar_file = "goliat_average", 
  draw_inputs = FALSE)
```

\---

## How can I contribute to `RFDose`?

Information on how to contribute to `RFDose` will be added here. 

## Background

For detailed information and scientific background, please refer to the manuscript by Jalilian et al. (manuscript in preparation, will be linked here once published).

### Exposure sources

We consider the following RF-EMF exposure sources:

|Exposure|Abbreviation|Description|
|-|-|-|
|Mobile calling|mpc|Voice calling using mobile phone, with or without App|
|Mobile data|mpd|WiFi and mobile data use on mobile phone|
|WiFi|wifi|WiFi router|
|Cordless Phone|dect|Cordless phone (=DECT phone) use|
|Laptop|lptp|Laptop use|
|Tablet|tblt|Tablet use|
|Far-field|farf|Far-field exposure from mobile phone base stations and broadcast stations|
|Other|other|Other devices: smartwatch, VR headset, hotspot, bluetooth headphones, and gaming consoles|

### Calculation

```bash
total_dose()
├── mobilecall_dose()     
│    └── mobilecall_dose()
│         ├── mobilecall_nsar()
│         └── mobilecall_pwr()
├── mobiledata_dose()   
├── cordless_dose() 
├── laptop_dose()
├── tablet_dose()
├── other_dose_wrapper()
├── wifi_dose()
└── farfield_dose()
```

### Variables

An overview of the included variables is shown below.

For the activity variables (mpd, laptop, tablet)

* low output power activities: sending e-mails, browsing intenet, scrolling/chatting on social media
* low-medium output power activities: online gaming, music streaming, voice messaging
* medium-high output power activities: watching or uploading videos on social media, video calls, video streaming
* high output power activities: uploading large files

|Name|Unit|Type|Contraints|Description|Used for source(s)|
|-|-|-|-|-|-|
|use\_5g|-|logical|TRUE or FALSE|Use of 5g (mobile phone only)|mpc, mpd|
|travel\_time|s|numeric|>=0 and <=59350|Time spent commuting (public transport or car) per day|mpc, mpd, far-field, wifi|
|country|-|character|must exactly match one of the listed options|Austria:"AT", Belgium:"BE", France:"FR", Hungary:"HU", Italy:"IT", Netherlands:"NL", Poland:"PL", Spain:"ES", Switzerland:"CH", United Kingdom:"UK", unknown/other: "Other"|farfield|
|urbanicity|-|character|"rural", "suburban" or "urban"|Urbanicity of participant's home ("rural", "suburban", "urban")|mpd, farfield|
|headp\_ear\_num|-|numeric|0, 1 or 2|Number of earphones worn during call|mpc|
|mpc\_duration|s|numeric|>=0 and <= 86400|Daily duration of mobile phone calls (with or without app)|mpc|
|mpc\_ear\_prop|-|numeric|>=0 and <=1|Proportion of time the mobile phone is held against head during mobile calls|mpc|
|mpc\_headp\_prop|-|proportion|>=0 and <=1|Proportion of time headphones are used during mobile phone calls|mpc|
|dect\_duration|s|numeric|>=0 and <= 86400|Daily call duration of DECT/cordless phone calls|dect|
|dect\_ear\_prop|-|numeric|>=0 and <=1|Proportion of time DECT/cordless phone is held against ear during call|dect|
|mpd\_wifi\_prop\_home|-|numeric|>=0 and <=1|Proportion of WiFi vs mobile data (3G, 4G, 5G) while using mobile phone AT HOME|mpc, mpd|
|mpd\_wifi\_prop\_work|-|numeric|>=0 and <=1|Proportion of WiFi vs mobile data (3G, 4G, 5G) while using mobile phone AT WORK/SCHOOL|mpc, mpd|
|mpd\_wifi\_prop\_travel|-|numeric|>=0 and <=1|Proportion of WiFi vs mobile data (3G, 4G, 5G) while using mobile phone WHILE COMMUTING|mpc, mpd, wifi|
|mpd\_dur\_low|s|numeric|>=0 and <= 86400|Daily duration of low output power activities on mobile phone|mpd|
|mpd\_dur\_lowtomed|s|numeric|>=0 and <= 86400|Daily duration of low-medium output power activities on mobile phone|mpd|
|mpd\_dur\_medtohigh|s|numeric|>=0 and <= 86400|Daily duration of medium-high output power activities on mobile phone|mpd|
|mpd\_dur\_high|s|numeric|>=0 and <= 86400|Daily duration of high output power activities on mobile phone|mpd|
|lptp\_dur\_low|s|numeric|>=0 and <= 86400|Daily duration of low output power activities on laptop|lptp|
|lptp\_dur\_lowtomed|s|numeric|>=0 and <= 86400|Daily duration of low-medium output power activities on laptop|lptp|
|lptp\_dur\_medtohigh|s|numeric|>=0 and <= 86400|Daily duration of medium-high output power activities on laptop|lptp|
|lptp\_dur\_high|s|numeric|>=0 and <= 86400|Daily duration of high output power activities on laptop|lptp|
|tblt\_dur\_low|s|numeric|>=0 and <= 86400|Daily duration of low output power activities on tablet|tblt|
|tblt\_dur\_lowtomed|s|numeric|>=0 and <= 86400|Daily duration of low-medium output power activities on tablet|tblt|
|tblt\_dur\_medtohigh|s|numeric|>=0 and <= 86400|Daily duration of medium-high output power activities on tablet|tblt|
|tblt\_dur\_high|s|numeric|>=0 and <= 86400|Daily duration of high output power activities on tablet|tblt|
|hotspot\_duration|s|numeric|>=0 and <= 86400|Daily duration of using mobile phone as hotspot|other|
|smartwatch\_duration|s|numeric|>=0 and <= 86400|Daily duration of wearing smartwatch on wrist|other|
|vr\_duration|s|numeric|>=0 and <= 86400|Daily durarion of virtual reality headset use|other|
|headphone\_duration|s|numeric|>=0 and <= 86400|Daily duration of using bluetooth headphones (all types of usage except for mobile phone call)|other|
|gaming\_duration|s|numeric|>=0 and <= 86400|Daily duration of using portable gaming devices (eg. Nintendo Switch, Steamdeck, etc.)|other|

\---

### Parameters

Parameters are specified in YAML files: [`params.yaml`](./inst/extdata/params.yaml) for all parameters except SAR values, and a SAR file for the SAR values ([`sar_goliat_average.yaml`](./inst/extdata/sar_goliat_average.yaml) by default, see [GOLIAT SAR values](#goliat-sar-values)). Parameters are obtained from measurements, dosimetric simulations, and literature- more detailed descriptions of each parameter, including units and data sources, will be included in Jalilian et al. (manuscript in preparation).

### Missing data and default values

`RFDose` currently handles missing values by replacing them with default values, which are derived from survey responses of the ongoing [GOLIAT consortium studies](https://projectgoliat.eu/).

Default values are specified in [this YAML file](./inst/extdata/defaultvariables.yaml)

### Output

`calculate_emf_doses` returns a data frame containing the original data columns, as well as one additional column per source with its dose contribution in mJ/kg/day for the chosen tissue:

|Column|Source|
|-|-|
|call\_dose|Mobile phone calls (mpc)|
|data\_dose|Mobile data (mpd)|
|dect\_dose|Cordless phone (dect)|
|farf\_dose|Far-field (farf)|
|wifi\_dose|WiFi router (wifi)|
|lptp\_dose|Laptop (lptp)|
|tblt\_dose|Tablet (tblt)|
|other\_dose|Other devices: smartwatch, VR headset, hotspot, Bluetooth headphones, and gaming consoles (other)|

The doses depend on the SAR values used (GOLIAT by default, see [GOLIAT SAR values](#goliat-sar-values)).

### Uncertainty in the stochastic model

`calculate_emf_doses_stochastic()` draws three kinds of values. Each distribution is centred on the value used by the deterministic calculation, and only its shape is given in the distribution files:

|Drawn values|Distributions|File|
|-|-|-|
|Parameters (260): output powers, duty cycles, proportions, far-field power densities|Lognormal and truncated lognormal (powers), beta (duty cycles, single proportions), Dirichlet (proportions that sum to 1, drawn together); mean = value in `params.yaml`|[`params_distributions.yaml`](inst/extdata/params_distributions.yaml)|
|SAR values|Lognormal around their value, with a relative standard deviation of 25% (`sar_sd`). SAR values from the same simulation are drawn together; SAR values of 0 stay 0|-|
|Inputs (27): durations, proportions, urbanicity, commuting time|Truncated lognormal for durations (relative standard deviation 20%, between 0 and 86400 s), beta and Dirichlet for proportions, categorical for urbanicity (given value kept with probability 0.8); centred on the value in `data`, or on the default value if missing. Durations of 0 stay 0|[`input_distributions.yaml`](inst/extdata/input_distributions.yaml)|

Every row is calculated with the same parameter sets, and the inputs of a row are drawn around its own values, so the doses of a row do not depend on the other rows. The distribution files are generated from the same Excel file as the parameters and default values (`data-raw/source_params/`).

## GOLIAT SAR values

The GOLIAT SAR files (`inst/extdata/sar_goliat_*.yaml`) contain SAR values from GOLIAT dosimetric simulations, used instead of the ETAIN SAR values ([`sar_etain.yaml`](inst/extdata/sar_etain.yaml)). There is one file per phantom (Duke, Ella, Eartha, Thelonious) and one with the average of the four phantoms (`sar_goliat_average.yaml`), which is the default. The files are generated by [`data-raw/source-sar-goliat/sar_goliat.R`](data-raw/source-sar-goliat/sar_goliat.R) from the GOLIAT results file (`Final_Data_All_2026_LAST.xlsx`, not included in this repository), which is read by [`data-raw/source-sar-goliat/reading_raw_goliat_sar.R`](data-raw/source-sar-goliat/reading_raw_goliat_sar.R).

### Placements

|Placement|Description|Simulated positions|GOLIAT name|
|-|-|-|-|
|ear|Phone at the ear (0.8 cm)|6 (cheek 1-3, tilt 1-3)|`cheek_*`, `tilt_*`|
|front|Phone in front of the face (20 cm)|8 (center, left, right, down; vertical and horizontal)|`front_of_eyes_*`|
|else|Phone at belly height (20 cm)|8 (center, left, right, up; vertical and horizontal)|`belly_level_*`|
|far field|Plane wave, per 1 W/m² incident power density|12 incidences (±x, ±y, ±z; 2 polarizations)|`x/y/z_pos/neg_phi/theta`|

Each SAR value is the mean over all positions of a placement, per phantom:

* brain: `SAR_brain`, body: `SAR_wholebody`
* GOLIAT values (mW/kg for 1 W input power, or for 1 W/m² in the far field) are divided by 1000, giving W/kg/W (far field: W/kg per W/m²)
* average file: mean of the four phantom values

### Frequencies

|Band|Frequencies in MHz (share)|
|-|-|
|2G|900 (50%), 1800 (50%)|
|3G|900 (50%), 2140 (50%)|
|4G|700 (4%), 835 (19%), 900 (21%), 1800 (28%), 2140 (19%), 2600 (9%)|
|5G|3500|
|WiFi 2.4 GHz|2450|
|WiFi 5 GHz|5200 (50%), 5800 (50%)|
|Far-field sources|450 (8%), 700 (4%), 835 (15%), 900 (17%), 1800 (23%), 2140 (15%), 2450 (2%), 2600 (7%), 3500 (7%), 5200 (1%), 5800 (1%)|

900, 1800 and 2600 MHz were not simulated: their SAR values are linearly interpolated between the neighbouring simulated frequencies.

### Devices

|Device|Option|Placement|Frequencies|
|-|-|-|-|
|Mobile phone calls (native and data calls, identical)|Phone at ear|ear|2G-5G|
||Speaker|front|2G-5G|
||With headphones|else (face and pocket: SAR set to 0)|2G-5G|
|Calls over WiFi|Ear, speaker, headphones|Same as mobile phone calls|WiFi 2.4 and 5 GHz|
|Bluetooth, phone side|Phone during headset use|else (face and pocket: SAR set to 0)|WiFi 2.4 GHz|
|Bluetooth headset (`bt_headp_sar`)|-|ETAIN value kept|-|
|Mobile data|Phone use|front|3G-5G, WiFi 2.4 and 5 GHz|
|Cordless phone (DECT)|Phone at ear|ear|1800|
||Speaker|front|1800|
|Tablet|Use|front|WiFi 2.4 and 5 GHz|
|Laptop|On a table|else|WiFi 2.4 and 5 GHz|
||On the legs|Not simulated: SAR set to 0|-|
|VR headset|Use|ear|WiFi 2.4 and 5 GHz|
|Gaming|Use|front|WiFi 2.4 and 5 GHz|
|Hotspot|Use|else|WiFi 2.4 GHz|
|WiFi router|Exposure|far field (all 12 incidences)|WiFi 2.4 and 5 GHz|
|Far-field sources|Exposure|far field (all 12 incidences)|Far-field sources|
|Smartwatch, headphones|-|ETAIN values kept|-|

### Usage proportions

The default parameter file [`params.yaml`](inst/extdata/params.yaml) contains the GOLIAT usage proportions: GOLIAT has only one simulation for these uses (belly height, 20 cm), so its proportion is 1 and the uses that were not simulated are set to 0. The ETAIN SAR file ([`sar_etain.yaml`](inst/extdata/sar_etain.yaml)) sets the original ETAIN proportions, which replace them when it is used.

|Parameter|GOLIAT|ETAIN|
|-|-|-|
|Laptop on the legs / on a table (`legs_prop`, `tabl_prop`)|0 / 1|0.2 / 0.8|
|Phone at the face / in a pocket / elsewhere during headphone and Bluetooth calls (`headp_face_prop`, `headp_pock_prop`, `headp_else_prop`)|0 / 0 / 1|0.333 / 0.333 / 0.333|

## License and Citation

License: [MIT license](http://opensource.org/licenses/MIT)

The author list is not complete yet. Citation will be added here. 

## Contributors and Acknowledgements

Contributors will be listed here.

\---

## Version History

|Version|Description|
|-|-|
|2.0.0|SAR values from GOLIAT dosimetric simulations included: one file per phantom and one with their average (`inst/extdata/sar_goliat_*.yaml`). All SAR values are now taken from GOLIAT instead of ETAIN, except for the sources without a similar GOLIAT simulation (smartwatch, headphones, Bluetooth headset), which keep their ETAIN values. The average of the four phantoms is the default; the ETAIN SAR values remain available with `sar_file` (`sar_etain.yaml`). See [GOLIAT SAR values](#goliat-sar-values). Output power parameters updated with data from GOLIAT Task 1.2. First version of the stochastic dose model (`calculate_emf_doses_stochastic()`, see [Stochastic dose calculation](#stochastic-dose-calculation))|
|1.0.0|Updated version based on finalized dose calculations in Jalilian et al. (manuscript in preparation)|
|0.3.0|Updated version with major changes in dose calculations (based on dose calculator 7.6). Based on dose calculator version 7.6|
|0.2.0|Revised draft version with updated calculations, variables, and unit tests. Based on dose calculator version 7.3|
|0.1.0|Initial draft version for internal use|
|0.0.1|Basic test version (not on Github)|

\---

## References and Further Resources

* Will be added here: research paper on `RFDOSE`
* Will be added here: link to Shiny interface of `RFDose`
* Will be added here: link to publication by Jalilian et al.
* [GOLIAT project website](https://projectgoliat.eu/)
* [ETAIN project website](https://www.etainproject.eu/)


\---

