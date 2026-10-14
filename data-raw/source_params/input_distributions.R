## code to prepare the input distribution file (`inst/extdata/input_distributions.yaml`) goes here
## Distributions of the input variables, for the stochastic dose model, from the
## tab "defaultvariables" of the parameter Excel file. Every input with a
## distribution is drawn around its value: the value given in the input data, or
## else its default value (defaultvariables.yaml, so run defaultvariables.R
## first). The file only gives the shape of each distribution.

source("data-raw/source_params/reading_params_sources.R") # creates `params_copy`

defaults_yaml <- file.path("inst", "extdata", "defaultvariables.yaml")
dists_yaml    <- file.path("inst", "extdata", "input_distributions.yaml")

# Values of categorical inputs. The Excel tab gives the probability of each
# drawn value, for each given value, in rows "<given>_<drawn>_prop", with the
# first three letters of the drawn value (e.g. urban_sub_prop).
categories <- list(urbanicity = c("urban", "suburban", "rural"))

# Dirichlet groups, used as long as the Excel tab has no column "group". The
# inputs of a group are shares of a whole, whose rest is a further share (e.g.
# the speaker mode of calls: 1 - mpc_ear_prop - mpc_headp_prop).
listed_groups <- c(mpc_ear_prop = "call_mode", mpc_headp_prop = "call_mode")

# Standard deviation relative to the value, for inputs whose default is 0 (and
# their sd in the Excel tab therefore 0): 20 % of the value, as for the others
zero_default_sd_rel <- 0.2

rows <- as.data.frame(readxl::read_excel(params_copy, sheet = "defaultvariables", col_types = "text"))
rows$row <- seq_len(nrow(rows)) + 1 # Excel row (row 1 is the header), for messages
rows <- rows[!is.na(rows$parameters), ]
rows$parameters <- trimws(rows$parameters)

# Numbers of a column ("na", "-" and empty cells are missing)
as_number <- function(column) {
  x <- rows[[column]]
  x[tolower(trimws(x)) %in% c("na", "-", "")] <- NA
  value <- suppressWarnings(as.numeric(x))
  if (any(!is.na(x) & is.na(value))) {
    stop("Column ", column, " is not a number in row(s) ",
         paste(rows$row[!is.na(x) & is.na(value)], collapse = ", "))
  }
  value
}
rows$m     <- suppressWarnings(as.numeric(rows$mean)) # the default; text for categorical inputs
rows$sd    <- as_number("sd")
rows$min   <- as_number("min")
rows$max   <- as_number("max")
rows$alpha <- as_number("alpha_a0")

# Distribution: first word of the column ("beta (a0 = alpha/mean)" is "beta")
rows$dist <- sub(" .*$", "", tolower(trimws(rows$Distribution)))
valid     <- c("lognormal", "trunc_lognormal", "beta", "dirichlet", "categorical", "na")
if (any(!is.na(rows$dist) & !(rows$dist %in% valid))) {
  stop("Unknown distribution in row(s) ",
       paste(rows$row[!is.na(rows$dist) & !(rows$dist %in% valid)], collapse = ", "))
}

# Probabilities of the categorical inputs, given -> drawn value
probability_rows <- unlist(lapply(categories, function(values) {
  as.vector(outer(values, substr(values, 1, 3), paste, "prop", sep = "_"))
}))
if (!all(probability_rows %in% rows$parameters)) {
  stop("Missing probabilities: ", paste(setdiff(probability_rows, rows$parameters), collapse = ", "))
}
probability <- function(given, drawn) {
  value <- rows$m[rows$parameters == paste(given, substr(drawn, 1, 3), "prop", sep = "_")]
  if (length(value) != 1 || is.na(value) || value < 0 || value > 1) {
    stop("Probability of ", drawn, " given ", given, " must be a number between 0 and 1.")
  }
  value
}

# Input variables (their default values), as written by defaultvariables.R
defaults <- yaml::read_yaml(defaults_yaml)
inputs   <- rows[!(rows$parameters %in% probability_rows), ]
if (!setequal(inputs$parameters, names(defaults))) {
  stop("The tab \"defaultvariables\" and ", defaults_yaml, " have different inputs: ",
       "run defaultvariables.R first.")
}

# Dirichlet group of each input
inputs$group <- if ("group" %in% names(inputs)) trimws(inputs$group) else unname(listed_groups[inputs$parameters])

# Distribution of each input ==================================================
dists <- list()
notes <- character(0)
for (i in seq_len(nrow(inputs))) {
  name  <- inputs$parameters[i]
  where <- sprintf("Row %d (%s)", inputs$row[i], name)
  m     <- inputs$m[i]
  dist  <- inputs$dist[i]

  if (is.na(dist)) {
    notes <- c(notes, paste(where, "has no distribution: not drawn."))
    next
  }
  spec <- switch(dist,
    na = NULL,
    lognormal = ,
    trunc_lognormal = {
      truncated <- dist == "trunc_lognormal"
      if (is.na(m) || is.na(inputs$sd[i]) || m < 0 || inputs$sd[i] < 0) {
        stop(where, ": ", dist, " needs a default and an sd, 0 or more.")
      }
      if (m > 0) {
        sd_rel <- inputs$sd[i] / m
      } else {
        sd_rel <- zero_default_sd_rel
        notes  <- c(notes, sprintf("%s: default 0, sd %g %% of a given value.", where, 100 * sd_rel))
      }
      spec <- list(distribution = dist, sd_rel = sd_rel)
      if (truncated) {
        if (is.na(inputs$min[i]) || is.na(inputs$max[i]) ||
            !(inputs$min[i] >= 0 && inputs$min[i] <= m && m < inputs$max[i])) {
          stop(where, ": trunc_lognormal needs 0 <= min <= default < max.")
        }
        spec <- c(spec, list(min = inputs$min[i], max = inputs$max[i]))
      }
      spec
    },
    beta = {
      if (is.na(m) || m < 0 || m > 1 || is.na(inputs$alpha[i]) || inputs$alpha[i] <= 0) {
        stop(where, ": beta needs 0 <= default <= 1 and alpha > 0.")
      }
      list(distribution = "beta", alpha = inputs$alpha[i])
    },
    dirichlet = {
      if (is.na(inputs$group[i])) stop(where, ": dirichlet needs a group.")
      if (is.na(m) || m < 0 || m > 1 || is.na(inputs$alpha[i]) || inputs$alpha[i] <= 0) {
        stop(where, ": dirichlet needs 0 <= default <= 1 and a0 > 0.")
      }
      list(distribution = "dirichlet", group = inputs$group[i], a0 = inputs$alpha[i])
    },
    categorical = {
      values <- categories[[name]]
      if (is.null(values)) stop(where, ": no values listed for the categorical input.")
      if (!(inputs$mean[i] %in% values)) stop(where, ": the default is not one of ", paste(values, collapse = ", "))
      probs <- lapply(stats::setNames(values, values), function(given) {
        p <- vapply(stats::setNames(values, values), function(drawn) probability(given, drawn), numeric(1))
        if (abs(sum(p) - 1) > 1e-9) stop("Probabilities of ", name, " given ", given, " sum to ", sum(p), ", not 1.")
        as.list(p)
      })
      list(distribution = "categorical", probs = probs)
    })
  if (!is.null(spec)) dists[[name]] <- spec
}

# Dirichlet groups: shares of a whole, so their defaults sum to 1 at most (the
# rest is a further share) ====================================================
for (group in unique(stats::na.omit(inputs$group))) {
  members <- inputs[!is.na(inputs$group) & inputs$group == group, ]
  if (any(members$dist != "dirichlet")) {
    stop("Group ", group, " has inputs without a dirichlet distribution.")
  }
  if (sum(members$m) > 1 + 1e-9) {
    stop(sprintf("Group %s: defaults sum to %.10g, more than 1.", group, sum(members$m)))
  }
  if (length(unique(members$alpha)) != 1) {
    stop("Group ", group, " has different values of a0.")
  }
}

# Write the file =============================================================
header <- c(
  "# Distributions of the input variables, for the stochastic dose model.",
  "# Generated by data-raw/source_params/input_distributions.R from the tab",
  "# \"defaultvariables\" of params_sources.xlsx, do not edit by hand.",
  "# Each input is drawn around its value (the given value, or else its default),",
  "# so only the shape of each distribution is given. Inputs not listed here are",
  "# not drawn.",
  "#   trunc_lognormal: sd_rel (standard deviation relative to the value), min, max",
  "#   beta:            alpha (a0 = alpha/value)",
  "#   dirichlet:       a0, group (shares of a whole, drawn together with their rest)",
  "#   categorical:     probs (probability of each value, for each given value)")
# Numbers written with 15 significant digits
write_number <- function(x) structure(as.character(x), class = "verbatim")
writeLines(
  c(header, sub("\n$", "", yaml::as.yaml(dists, handlers = list(numeric = write_number)))),
  dists_yaml)

# Must read back as written (e.g. numbers must not be read as text)
if (!isTRUE(all.equal(yaml::read_yaml(dists_yaml), dists, tolerance = 1e-12))) {
  stop(dists_yaml, " does not read back as written.")
}

counts <- table(vapply(dists, function(spec) spec$distribution, character(1)))
message("Written ", dists_yaml, ": ", paste(names(counts), counts, sep = " ", collapse = ", "), ".")
if (length(notes) > 0) {
  message("Notes:\n", paste(notes, collapse = "\n"))
}
