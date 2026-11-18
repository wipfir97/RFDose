# RFDose

**Deterministic and Stochastic RF-EMF Dose Calculator**

## What is RFDose?

RFDose is an R package that estimates personal exposure to
radiofrequency electromagnetic fields (RF-EMF). It is based on the
RF-EMF dose model of Jalilian et al. (publication in review stage as of
November 2026). We are currently preparing a short publication on
`RFDose`, which will contain further background information.

![Overview of the RFDose package
workflow](reference/figures/overview.svg)

Overview of the RFDose package workflow

## How Do I Use RFDose?

### Installation

`{r} # Install package remotes::install_github("wipfir97/RFDose") # Load package library(RFDose)`

### Quick Start

Load the example data set, which contains data from 3 hypothetical study
participants.

For a quick start, you can load the in-build example data set. Each row
corresponds to one person, with 3 hypothetical data points.

`{r} # Load example data data(example_data) # View example data head(example_data)`

Calculate RF-EMF doses in mJ/kg/day for each row by using the
[`calculate_emf_doses()`](https://wipfir97.github.io/RFDose/reference/calculate_emf_doses.md)
function and specifying a tissue (currently supported: “brain” and
“body”(=overall exposure of the whole body)). By default, the
calculations use the GOLIAT SAR values, averaged over four phantoms (see
[GOLIAT SAR values](#goliat-sar-values)).

`{r} # Calculate example doses calculate_emf_doses(example_data, tissue = "brain") # brain dose calculate_emf_doses(example_data, tissue = "body") # body dose`

### Further Uses

- [Select and edit SAR values and
  parameters](https://wipfir97.github.io/RFDose/articles/deterministic_calculations.html).
- Estimate uncertainty in dose estimates using [stochastic dose
  calculations](https://wipfir97.github.io/RFDose/articles/stochastic_calculations.html).

For detailed information about the package functions, please refer to
the [package
manual](https://wipfir97.github.io/RFDose/doc/RFDose_2.0.1.pdf) and the
[package documentation website](https://wipfir97.github.io/RFDose/)

## How can I contribute to `RFDose`?

Please check our [contributing
guide](https://wipfir97.github.io/RFDose/CONTRIBUTING.md) if you would
like to contribute to `RFDose`.

## Where can I learn more?

- Detailed background on the RF-EMF dose model by Jalilian et
  al. (manuscript in preparation)
- The short research paper on the `RFDOSE` package (manuscript in
  preparation)
- The [online version](https://swisstph.shinyapps.io/rfdose-online/) of
  `RFDose`
- The [GOLIAT project website](https://projectgoliat.eu/)
- The [ETAIN project website](https://www.etainproject.eu/)

## How can I use and cite RFDose?

License: [MIT license](http://opensource.org/licenses/MIT)

The author list is not complete yet. Once finalized, the citation will
be added here.

## Who contributed to RFDose?

Contributors will be listed in the `RFDose` research paper.

`RFDose` was developed as part of the
[GOLIAT](https://projectgoliat.eu/) and
[ETAIN](https://www.etainproject.eu/) consortia.
