# RFDose - Deterministic RF-EMF Dose Calculator

## 📦 About

RFDose implements the deterministic RF-EMF dose calculations developed in 
Jalilian et al. (publication in writing stage).

IMPORTANT for test users: with the update to 0.2.0, the R package is renamed to RFDose.
I will update this in the installation instructions as soon as possible. 

---

## 🧪 Development Status

### Version overview

| Version | Name | Status |
| --- | --- | --- |
| 0.0.1 | Basic test version (not on Github) | Completed |
| 0.1.0 | Initial draft version for internal use | Completed |
| 0.2.0 | Revised draft version with updated calculations and variables | Completed |
| 0.2.1 | Revised draft verison with unit tests | In progress |
| 0.3.0 | Updated draft version with age- and sex-specific input | In planning |



## 🛠️ Installation

This R package is currently hosted on a **private GitHub repository**. To install it, you need: 

- A GitHub account
- Access to the repository
- A personal access token (PAT) to authenticate your connection to GitHub

### Generate personal access token (PAT)

Follow these steps to generate a PAT:

1. Go to [https://github.com/settings/tokens](https://github.com/settings/tokens)
2. Click **Generate new token (classic)**
3. Set a name (e.g. `R package install`)
4. Under **Select scopes**, check `repo` (this allows access to private repositories)
5. Select an expiration (e.g. 30 days)
6. Click **Generate token**
7. **Copy the token immediately** (you cannot view it again later)

### Prerequisites

If you do not have the `remotes` package installed and loaded, please follow the steps below.

```{r}
# install "remotes" package (needed to install R packages from GitHub)
install.packages("remotes")
# load "remotes" package
library(remotes)
```

### Install ETAIN dose calculator

To install the R package, first set your PAT with this command:

```{r}
# Set your personal access token (replace YOUR_PAT with the token you generated and copied)
Sys.setenv(GITHUB_PAT = "YOUR_PAT")
```
To install the **most current development version (v.0.2.0)**, use this command:

```{r}
# Install the ETAIN dose calculator using your PAT
remotes::install_github("wipfir97/ETAINDoseCalculator@dev/0.2.0")
```

**Note that version 0.2.0 is not stable yet, i.e. there may be errors and bugs and some calculations may not work yet!**

If you want to use the older, stable version v.0.1.0 instead, use this command instead:

```{r}
# Install the ETAIN dose calculator using your PAT
remotes::install_github("wipfir97/ETAINDoseCalculator@v0.1.0")
```

---


## 🚀 Quick Start

For a quick start, you can load the in-build example data set:

```{r}
# Load package
library(ETAINDoseCalculator)
# Load example data
data(example_data)
# View example data
head(example_data)
```
To calculate the RF-EMF doses for each participant, run the following code:

```{r}
# Calculate example doses
calculate_emf_doses(example_data)
```

---


## 🔍 Documentation

### Exposure sources

We consider the following exposure sources in the dose calculations:

| Exposure | Abbreviation | Description |
| --- | --- | --- |
| Mobile calling | mpc | Voice calling using mobile phone, with or without App | 
| Mobile data | mpd | WiFi and mobile data use during mobile phone use |
| WiFi | wifi | WiFi router |
| Cordless Phone | dect | Cordless phone use |
| Laptop | lptp | Laptop use |
| Tablet | tblt | Tablet use |
| Far-field | farf | Far-field exposure |
| Other | othe | Other devices: smart watch, tracker, VR headset, hotspot, bluetooth headphones, smart home |

#### Variable overview (version 0.2.0)

| Name  | Unit | Type | Description | Notes |
| --- | --- | --- | --- | --- |
| use_5g | - | binary | Use of 5G | 🆕 |
| travel_time | s | numeric | Time spent commuting (public transport or car) per day | 🆕 |
| country | - | categorical | Austria:"AT", Belgium:"BE", France:"FR", Hungary:"HU", Italy:"IT", Netherlands:"NL", Poland:"PL", Spain:"ES", Switzerland:"CH", United Kingdom:"UK", unknown/other: "Other" | 🆕 |
| urbanicity | - | categorical | Urbanicity |  |
| headp_ear_num | - | numeric | Number of earphones worn during call (1 or 2) | 🆕 |
| mpc_duration | s | numeric | Duration of daily mobile phone call |  |
| mpc_ear_prop | - | proportion | ... |  |
| mpc_headp_prop | - | proportion | ... |  |
| dect_duration | s | numeric | ... |  |
| dect_ear_prop | - | proportion | ... |  |
| mpd_wifi_prop_home | --- | --- | Proportion of WiFi vs mobile data (3G, 4G, 5G) while using mobile phone AT HOME | 🆕 |
| mpd_wifi_prop_work | --- | --- | Proportion of WiFi vs mobile data (3G, 4G, 5G) while using mobile phone AT WORK/SCHOOL | 🆕 |
| mpd_wifi_prop_travel | --- | --- | Proportion of WiFi vs mobile data (3G, 4G, 5G) while using mobile phone WHILE COMMUTING | 🆕 |
| mpd_dur_low | s | numeric| Daily duration of low output power activities on mobile phone | 🆕 |
| mpd_dur_lowtomed | s | numeric | Daily duration of low-medium output power activities on mobile phone | 🆕 |
| mpd_dur_medtohigh | s | numeric | Daily duration of medium-high output power activities on mobile phone | 🆕 |
| mpd_dur_high | s | numeric | Daily duration of high output power activities on mobile phone | 🆕 |
| lptp_dur_low | s | numeric | Daily duration of low output power activities on laptop | 🆕 |
| lptp_dur_lowtomed | s | numeric | Daily duration of low-medium output power activities on laptop |🆕 |
| lptp_dur_medtohigh | s | numeric | Daily duration of medium-high output power activities on laptop |🆕 |
| lptp_dur_high | s | numeric | Daily duration of high output power activities on laptop | 🆕 |
| tblt_dur_low | s | numeric | Daily duration of low output power activities on tablet | 🆕 |
| tblt_dur_lowtomed | s | numeric | Daily duration of low-medium output power activities on tablet |🆕 |
| tblt_dur_medtohigh | s | numeric | Daily duration of medium-high output power activities on tablet |🆕 |
| tblt_dur_high | s | numeric | Daily duration of high output power activities on tablet | 🆕 |
| hotspot_duration | s |  |  |  |
| smartwatch_duration | s |  |  |  |
| tracker_duration | s |  |  |  |
| vr_duration | s |  |  |  |
| headphone_duration | s |  |  |  |
| gaming_duration | s |  |  |  |

---


### Input/user variables

For detailed information about the required input variables, please refer to the [input variable overview file](doc/user_variables.xlsx).

### Generated output variables

Detailed info to be added here.

### Parameters

Parameters are specified in [this YAML file](inst/extdata/params.yaml)

More detailed descriptions of each parameter, including units, can be found in the [parameter reference file](doc/params_reference.csv). **Note: this parameter reference file is continuously updated and not yet completed.**

Users may supply their own parameter file. It must be structured exactly like the in-built parameter file (containing same parameter names and hierarchy).

```{r}
# Supply own parameter file
print("Instructions on how to supply own parameter file will be added here")
```

### Missing data and default values

Default values are specified in [this YAML file](inst/extdata/defaultvariables.yaml)

Missing values in the dataset supplied by the user will be replaced with the values in this file. 

At the moment, there is no limit to how much missing data is allowed. **However, variables with more than 10% missing data will raise a warning message.**

Users may supply their own default values. The custom file must follow the same structure as the in-build default variable file (containing the same default value names).

```{r}
# Supply own default values
print("Instructions on how to supply own default values will be added here")
```
---

## 📃 License

License will be added here.

---

## 🙏 Contributors and Acknowledgements

Contributors will be listed here.

---

## 📚 References and Further Resources

Additional resources and references will be added here.

---
