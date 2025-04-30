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
-  ⌛ Final validation of calculations in progress
-  ⌛ Customization of parameter file in progress
-  ⌛ Documentation of functions and input data in progress
-  ❗ Default values not implemented yet

## 🔍 Documentation

Please refer to ...

## 💬 Feedback

Please submit feedback to ...

## 📃 License

License will be added here.

## 🙏 Contributors and Acknowledgements

Contributors will be listed here.

## 📚 References and Further Resources

Additional resources and references will be added here.
