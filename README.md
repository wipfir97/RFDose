# ETAIN Dose Calculator - R Version

⚡ An R package for RF-EMF dose calculations

---

## 📦 About

📶 The Dose Calculator ... 


---

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

To install the R package, please follow the steps below.

```{r}
# Set your personal access token (replace YOUR_PAT with the token you generated and copied)
Sys.setenv(GITHUB_PAT = "YOUR_PAT")
# Install the ETAIN dose calculator using your PAT
remotes::install_github("wipfir97/ETAINDoseCalculator")
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

## 🧪 Development Status

### Version overview

| Version | Name | Status |
| --- | --- | --- |
| 0.0.1 | Basic test version (not on Github) | Completed |
| 0.1.0 | Initial draft version | Completed |
| 0.2.0 | Revised draft version with updated calculations and variables | In development |


| Revision | Status | Version |
| --- | --- | --- |
| Implement basic dose calculations | Completed | 0.0.1 |
| Add default values for missing data | Completed | 0.1.0 |
| Add customizable parameter and default value input option | Completed | 0.1.0 |
| Update calculations and parameters | In progress | 0.2.0 |
| Add additional input variables | Planned | 0.2.0 |
| Validation of calculations | Planned | 0.2.0 |
| Completion of function and parameter documentation | Planned | 0.2.0 |

### Upcoming new variables in version 0.2.0

| Name  | Unit | Type | Exposure | Description | Assumptions | Constraints | Default value | Status | Required? |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| comp_5g | - | binary | --- | Ownership of 5G compatible phone | --- | --- | --- | --- | --- |
| bt_headp_pref | - | binary | --- | Using 1 or both headphones | --- | --- | --- | --- | --- |
| mpd_dur_low | s | numeric | --- | --- | --- | --- | --- | --- | --- |
| mpd_dur_lowtomed | s | numeric | --- | --- | --- | --- | --- | --- | --- |
| mpd_dur_medtohigh | s | numeric | --- | --- | --- | --- | --- | --- | --- |
| mpd_dur_high | s | numeric | --- | --- | --- | --- | --- | --- | --- |
| wifi_dur (will have different name) | --- | --- | --- | --- | --- | --- | --- | --- | --- |

### Variables to be removed in version 0.2.0

- smarthome_duration: to be removed
- wifi_duration: to be replaced
- mpd_high_dt_prop: to be replaced

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

### Input variables

At the moment (version 0.1.0), **all input variables are optional**. 

| Name  | Unit | Type | Exposure | Description | Assumptions | Constraints | Default value | Status | Required? |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| mpc_duration | s | numeric | Mobile calling | Daily duration of mobile phone calls (with or without app) | ... | >= 0 and <= 86400 | 425 | implemented | no |
| mpc_ear_prop | - | numeric | Mobile calling | Proportion of time the mobile phone is held against head during mobile calls | Mobile phone used with headphones or in speaker mode in remaining time | >= 0 and <= 1 | 0.66 | implemented | no |
| mpc_headp_prop | - | numeric | Mobile calling | Proportion of time headphones are used during mobile phone calls when mobile phone is NOT held against the ear. | 0.5 | >= 0 and <= 1 | Mobile phone used in speaker mode in remaining time while NOT held against head | implemented | no |
| urbanicity | - | character | Far-field, mobile data | Urbanicity of participant's home | Home urbanicity and work urbanicity is the same | urban, suburban, or rural | suburban | implemented | no |
| mpd_duration | s | numeric | Mobile data | Daily duration of data use on mobile phone | ... | >= 0 and <= 86400 | 10800 | implemented | no |
| mpd_wifi_prop | - | numeric | Mobile data | Proportion of time mobile phone is connected to wifi during data use | Mobile data (3G/4G/5G) used in the remaining time | >= 0 and <= 1 | 0.5 | implemented | no |
| mpd_high_dt_prop | - | numeric | Mobile data | Proportion of time spend with high data transfer activities during data use on mobile phone | Low data transfer activities done during remaining time | >= 0 and <= 1 | 0.5 | implemented | yes |
| dect_duration | s | numeric | Cordless phone | Daily call duration of DECT/cordless phone calls | ... | >= 0 and <= 86400 | 204 | implemented | no |
| dect_ear_prop | - | numeric | Cordless phone | Proportion of time DECT/cordless phone is held against ear during call | Cordless phone used in speaker mode in the remaining time | >= 0 and <= 1 | 0.9 | implemented | no |
| lptp_duration | s | numeric | Laptop | Daily duration of laptop use | ... | >= 0 and <= 86400 | 4371 | implemented | no |
| tblt_duration | s | numeric | Tablet | Daily duration of tablet use | ... | >= 0 and <= 86400 | 1617 | implemented | no |
| wifi_duration | s | numeric | WiFi router | Daily duration of being in proximity to WiFi router | ... | >= 0 and <= 86400 | 59400 | implemented | no |
| hotspot_duration | s | numeric | Other (Mobile hotspot) | Daily duration of using mobile phone as hotspot | ... | >= 0 and <= 86400 | 0 | implemented | no |
| smartwatch_duration | s | numeric | Other (Smartwatch) | Daily duration of wearing smartwatch on wrist | ... | >= 0 and <= 86400 | 0 | implemented | no |
| tracker_duration | s | numeric | Other (Activity tracker) | Daily duration of wearing tracker on arm | ... | >= 0 and <= 86400 | 0 | implemented | no |
| smarthome_duration | s | numeric | Other (Smarthome) | Daily duration spent in a smarthome | ... | >= 0 and <= 86400 | 0 | implemented | no |
| vr_duration | s | numeric | Other (Virtual reality headset) | Daily durarion of virtual reality headset use | ... | >= 0 and <= 86400 | 0 | implemented | no |
| headphone_duration | s | numeric | Other (Bluetooth headphones) | Daily duration of using bluetooth headphones (all types of usage except for mobile phone call) | ... | >= 0 and <= 86400 | 8280 | implemented | no |

For detailed information about the required input variables, please refer to the [input variable overview file](doc/user_variables.xlsx).

### Generated output variables

| Name  | Unit | Type | Exposure | Tissue | Description | 
| --- | --- | --- | --- | --- | --- |
| **brain_dotal_dose** | mJ/kg/day | numeric | All exposures | ... | ... |
| **body_dotal_dose** | mJ/kg/day | numeric | All exposures | ... | ... |
| brain_call_dose | mJ/kg/day | numeric | Mobile calling | ... | ... | 
| body_call_dose | mJ/kg/day | numeric | Mobile calling | ... | ... | 
| brain_data_dose | mJ/kg/day | numeric | Mobile data | ... | ... | 
| body_data_dose | mJ/kg/day | numeric | Mobile data | ... | ... |
| brain_dect_dose | mJ/kg/day | numeric | Cordless phone | ... | ... |
| body_dect_dose | mJ/kg/day | numeric | Cordless phone | ... | ... |
| brain_farf_dose | mJ/kg/day | numeric | Farfield | ... | ... | 
| body_farf_dose | mJ/kg/day | numeric | Farfield | ... | ... |
| brain_wifi_dose | mJ/kg/day | numeric | WiFi router | ... | ... | 
| body_wifi_dose | mJ/kg/day | numeric | Wifi router | ... | ... |
| brain_lptp_dose | mJ/kg/day | numeric | Laptop | ... | ... | 
| body_lptp_dose | mJ/kg/day | numeric | Laptop | ... | ... |
| brain_tblt_dose | mJ/kg/day | numeric | Tablet | ... | ... | 
| body_tblt_dose | mJ/kg/day | numeric | Tablet | ... | ... |
| brain_othe_dose | mJ/kg/day | numeric | Other | ... | ... | 
| body_othe_dose | mJ/kg/day | numeric | Other | ... | ... |

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

## 💬 Feedback

Please submit feedback to ...

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
