# ETAIN Dose Calculator - R Version

⚡ An R package for RF-EMF dose calculations

⚠️ Development status: work in progress ⌛

## 📦 About

📶 The ETAIN Dose Calculator ... 

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

## 🧪 Development Status

-  ✔️ Basic dose calculations implemented and validated
-  ✔️ YAML parameter file generated
-  ✔️ Added additional variable: high vs low data transfer activities
-  ⌛ Final validation of calculations in progress
-  ⌛ Customization of parameter file in progress
-  ⌛ Documentation of functions and input data in progress
-  ❗ Default values not implemented yet

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
| Other | other | Other devices: smart watch, tracker, VR headset, hotspot, bluetooth headphones, smart home |

### Input variables

| Name  | Unit | Type | Exposure | Description | Constraints | Default value | Status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| mpc_duration | s | numeric | Mobile calling | ... | >= 0 and <= 86400 | 425 | implemented |
| mpc_ear_prop | - | numeric | Mobile calling | ... | >= 0 and <= 1 | ... | implemented |
| mpc_headp_prop | - | numeric | Mobile calling | ... | >= 0 and <= 1 | ... | implemented |
| urbanicity | - | numeric | Multiple | ... | urban, suburban, or rural | suburban | implemented |
| ... | ... | ... | ... | ... | ... | ... | ... |

For detailed information about the required input variables, please refer to the [variable overview file](data/user_variables.xlsx).

### Generated output variables

### Parameters

Parameters are specified in this YAML file: 

The YAML file must be structured like this:

More detailed descriptions of each parameter, including units, can be found in the [parameter reference file](inst/extdata/params_reference.csv).

Parameters can be customized by ...

### Missing data and default values

Default values are specified in this YAML file:

Default values can be customized by ...

## 💬 Feedback

Please submit feedback to ...

## 📃 License

License will be added here.

## 🙏 Contributors and Acknowledgements

Contributors will be listed here.

## 📚 References and Further Resources

Additional resources and references will be added here.
