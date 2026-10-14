###############################################################################
#' Calculate RF-EMF doses with their uncertainty for ALL samples
#'
#' Stochastic version of [RFDose::calculate_emf_doses()]: calculates the doses
#' of each row many times, each time with other parameter values and input
#' values drawn from their distributions, and summarises the doses of all draws.
#'
#' @details
#' The parameter sets are drawn with [RFDose::simulate_params()]: parameters
#' with a distribution (see [RFDose::load_distributions()]) and the SAR values
#' vary around their value in the parameter and SAR files; all other parameters
#' keep their values. Every row is calculated with the same parameter sets.
#'
#' The inputs are drawn with [RFDose::simulate_inputs()]: inputs with a
#' distribution (see [RFDose::load_input_distributions()]) vary around their
#' value in `data`, or around their default value if missing; all other inputs
#' keep their values.
#'
#' The doses of a row do not depend on the other rows. Use [set.seed()] before
#' for reproducible results.
#'
#' @param data A data frame. Must have the exact same columns as the provided example dataset.
#' Columns must not be missing. Missing values will be replaced with default values.
#' @param tissue Tissue for which to calculate dose (default: "brain" or "body")
#' @param n Number of parameter sets (draws)
#' @param params (experimental) Path to a parameter file in .yaml format, as for
#' [RFDose::calculate_emf_doses()]. Its values are the means of the distributions.
#' @param distributions (experimental) Path to a distribution file in .yaml
#' format, with the structure of the internal distribution file
#' (`params_distributions.yaml`). Optional; if not specified, the default
#' distributions are used.
#' @param input_distributions (experimental) Path to an input distribution file
#' in .yaml format, with the structure of the internal input distribution file
#' (`input_distributions.yaml`). Optional; if not specified, the default input
#' distributions are used.
#' @param default_value_file List of default values to replace missing values (optional).
#' @param sar_file (experimental) Path to a .yaml file with SAR values, as for
#' [RFDose::calculate_emf_doses()].
#' @param sar_sd Standard deviation of the SAR values, relative to their value
#' (default: 25%). With 0, the SAR values are not drawn.
#' @param draw_inputs If FALSE, the inputs are not drawn.
#' @param probs Probabilities of the quantiles of the doses (default: median and
#' 95% interval)
#' @param keep_draws If TRUE, also return the doses and parameters of every draw.
#'
#' @returns A data frame with one row per row of `data` and dose, in mJ/kg/day:
#' * `row`: row of `data`
#' * `dose`: exposure source (as the columns of [RFDose::calculate_emf_doses()]),
#'   or `total_dose` for their sum
#' * `deterministic`: dose with the parameter values of the parameter file, as
#'   calculated by [RFDose::calculate_emf_doses()]
#' * `mean`, `sd`: mean and standard deviation of the doses of all draws
#' * one column per quantile of the doses of all draws (e.g. `q2.5`, `q50`, `q97.5`)
#'
#' With `keep_draws = TRUE`, a list with this data frame (`summary`), the doses
#' of every draw (`doses`, an array row x draw x exposure source), the drawn
#' parameters and SAR values (`params`, a matrix draw x parameter) and the drawn
#' inputs (`inputs`, a list of matrices row x draw, one per input).
#'
#' @export
#' @seealso [RFDose::calculate_emf_doses()], [RFDose::simulate_params()]
calculate_emf_doses_stochastic <- function(
    data,
    tissue,
    n                  = 1000,
    params              = NULL,
    distributions       = NULL,
    input_distributions = NULL,
    default_value_file  = NULL,
    sar_file            = NULL,
    sar_sd              = 0.25,
    draw_inputs         = TRUE,
    probs               = c(0.025, 0.5, 0.975),
    keep_draws          = FALSE) {
  if (!is.numeric(probs) || anyNA(probs) || any(probs < 0 | probs > 1)) {
    stop("probs must be numbers between 0 and 1.")
  }
  # Parameter and distribution files ==========================================
  params        <- load_params(path = params, sar_path = sar_file)
  distributions <- load_distributions(path = distributions)
  input_distributions <- load_input_distributions(path = input_distributions)
  # Default values ============================================================
  data    <- prepare_dose_data(data = data, default_value_file = default_value_file)
  samples <- lapply(seq_len(nrow(data)), function(i) as.list(data[i, , drop = FALSE]))

  # Doses with the parameter values of the parameter file =====================
  ## (warnings are raised here, and not again for every draw)
  raised        <- character(0)
  deterministic <- withCallingHandlers(
    do.call(rbind, lapply(samples, function(sample) {
      total_dose(sample, tissue = tissue, params = params)
    })),
    warning = function(w) raised <<- c(raised, conditionMessage(w)))

  # Doses with drawn parameter sets and inputs ================================
  ## (inputs drawn after the parameters, so the parameter draws do not depend on them)
  draws  <- simulate_params(n, params = params, distributions = distributions, sar_sd = sar_sd)
  inputs <- if (draw_inputs) simulate_inputs(n, data, input_distributions) else NULL
  doses  <- stochastic_doses(samples, tissue = tissue, params = params, draws = draws,
                             inputs = inputs, known_warnings = raised)

  summary <- summarise_doses(deterministic, doses, probs = probs)
  if (keep_draws) {
    return(list(summary = summary, doses = doses, params = draws, inputs = inputs))
  }
  return(summary)
}

###############################################################################
#' Calculate doses for drawn parameter sets
#'
#' Calculates the doses of each sample with each parameter set and its drawn
#' inputs.
#'
#' @param samples List of samples (input values of a single observation each),
#' as for [RFDose::total_dose()]
#' @param tissue Tissue for which to calculate dose (default: "brain" or "body")
#' @param params Parameter list, as returned by [RFDose::load_params()]
#' @param draws Drawn parameter sets, as returned by [RFDose::simulate_params()]
#' @param inputs Drawn inputs, as returned by [RFDose::simulate_inputs()]
#' (optional). If NULL, the inputs of the samples are used in every draw.
#' @param known_warnings Warning messages that were already raised. Other
#' warnings are raised once, with the number of times they occurred.
#'
#' @returns Array of doses in mJ/kg/day: sample x draw x exposure source.
stochastic_doses <- function(samples, tissue, params, draws, inputs = NULL,
                             known_warnings = character(0)) {
  keys     <- strsplit(colnames(draws), ".", fixed = TRUE)
  doses    <- NULL
  raised   <- character(0)
  withCallingHandlers(
    for (d in seq_len(nrow(draws))) {
      drawn <- set_params(params, draws[d, ], keys)
      for (i in seq_along(samples)) {
        sample <- samples[[i]]
        for (input in names(inputs)) {
          sample[[input]] <- inputs[[input]][i, d]
        }
        dose <- tryCatch(
          total_dose(sample, tissue = tissue, params = drawn),
          error = function(e) {
            stop("Row ", i, ", draw ", d, ": ", conditionMessage(e), call. = FALSE)
          })
        if (is.null(doses)) {
          doses <- array(NA_real_, dim = c(length(samples), nrow(draws), length(dose)),
                         dimnames = list(NULL, NULL, names(dose)))
        }
        doses[i, d, ] <- dose
      }
    },
    warning = function(w) {
      raised <<- c(raised, conditionMessage(w))
      invokeRestart("muffleWarning")
    })

  new_warnings <- raised[!(raised %in% known_warnings)]
  for (text in unique(new_warnings)) {
    warning(text, " (", sum(new_warnings == text), " times in ", nrow(draws),
            " draws)", call. = FALSE)
  }
  doses
}

###############################################################################
#' Summarise the doses of all draws
#'
#' @param deterministic Matrix of doses with the parameter values of the
#' parameter file: sample x exposure source
#' @param doses Array of doses with drawn parameter sets: sample x draw x
#' exposure source, as returned by [RFDose::stochastic_doses()]
#' @param probs Probabilities of the quantiles
#'
#' @returns Data frame with one row per sample and dose (each exposure source
#' and their sum, `total_dose`).
summarise_doses <- function(deterministic, doses, probs) {
  n_samples <- dim(doses)[1]
  sources   <- dimnames(doses)[[3]]
  summaries <- lapply(c(sources, "total_dose"), function(source) {
    if (source == "total_dose") {
      x   <- matrix(apply(doses, c(1, 2), sum), nrow = n_samples)
      det <- rowSums(deterministic[, sources, drop = FALSE])
    } else {
      x   <- matrix(doses[, , source], nrow = n_samples)
      det <- deterministic[, source]
    }
    quantiles <- matrix(t(apply(x, 1, stats::quantile, probs = probs, names = FALSE)),
                        nrow = n_samples, dimnames = list(NULL, paste0("q", 100 * probs)))
    data.frame(
      row           = seq_len(n_samples),
      dose          = source,
      deterministic = unname(det),
      mean          = rowMeans(x),
      sd            = apply(x, 1, stats::sd),
      quantiles,
      check.names   = FALSE)
  })
  result <- do.call(rbind, summaries)
  result <- result[order(result$row), ]
  rownames(result) <- NULL
  result
}
