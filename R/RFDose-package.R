#' RFDose: Deterministic and Stochastic RF-EMF Dose Calculator
#'
#' Calculates the daily dose of radiofrequency electromagnetic fields (RF-EMF)
#' absorbed by the brain or the whole body, in mJ/kg/day, for each person of a
#' cohort. The doses are calculated from the self-reported use of wireless
#' devices and the environment of each person, for eight exposure sources:
#' mobile phone calls, mobile data, cordless phone, far-field sources, WiFi
#' router, laptop, tablet and other devices. Use [calculate_emf_doses()] for
#' the doses and [calculate_emf_doses_stochastic()] for their uncertainty.
#'
#' @section Main changes in version 2.0.0:
#' * SAR values from the GOLIAT dosimetric simulations replace the ETAIN SAR
#'   values: one SAR file per phantom (Duke, Ella, Eartha, Thelonious) and one
#'   with their average, which is the default. Smartwatch, headphones and
#'   Bluetooth headset keep their ETAIN values, as GOLIAT has no similar
#'   simulation. The argument `sar_file` chooses the SAR values by name (see
#'   [available_sar_files()]), e.g. `sar_file = "goliat_average"`. The ETAIN
#'   SAR values of version 1.0.0 remain available.
#' * Output power parameters updated with data from GOLIAT Task 1.2: 4G and 5G
#'   output powers and duty cycles of the mobile phone. The parameters and
#'   default values are taken from one Excel file that documents the source of
#'   each value; the parameters of version 1.0.0 are kept in
#'   `params_v1.0.yaml`. The default value of `use_5g` is now TRUE.
#' * First version of the stochastic dose model, [calculate_emf_doses_stochastic()].
#'
#' @section Stochastic dose model:
#' [calculate_emf_doses_stochastic()] estimates the uncertainty of the doses.
#' It repeats the dose calculation `n` times (default: 1000). In each draw,
#' three kinds of values vary around the values of the deterministic
#' calculation:
#' * Parameters: output powers, duty cycles, proportions and far-field power
#'   densities, with the distributions of `params_distributions.yaml`
#'   (lognormal or truncated lognormal for powers, beta for duty cycles and
#'   single proportions, Dirichlet for proportions that sum to 1). The mean of
#'   each distribution is the value of the parameter in `params.yaml`. See
#'   [simulate_params()].
#' * SAR values: lognormal around their value, with a relative standard
#'   deviation of 25% (argument `sar_sd`). SAR values from the same simulation
#'   are drawn together, and SAR values of 0 stay 0.
#' * Inputs: durations, proportions, urbanicity and commuting time, with the
#'   distributions of `input_distributions.yaml` (truncated lognormal with a
#'   relative standard deviation of 20% for durations, beta or Dirichlet for
#'   proportions, categorical for urbanicity). Each input is drawn around its
#'   value in the data, or around its default value if missing. Durations of 0
#'   stay 0. See [simulate_inputs()]; `draw_inputs = FALSE` keeps the inputs
#'   fixed.
#'
#' All rows are calculated with the same parameter draws, and the inputs of a
#' row are drawn around its own values, so the doses of a row do not depend on
#' the other rows. For each row and exposure source, and for the total dose,
#' the result gives the deterministic dose, the mean and standard deviation of
#' the doses of all draws, and their quantiles (default: median and 95%
#' interval). Give a `seed` for reproducible results.
#'
#' @seealso [calculate_emf_doses()], [calculate_emf_doses_stochastic()],
#' [available_sar_files()], [load_params()]
"_PACKAGE"
