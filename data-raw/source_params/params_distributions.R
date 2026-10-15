## code to prepare the distribution file (`inst/extdata/params_distributions.yaml`)
## Distributions of the non-SAR parameters, for the stochastic dose model, from
## the parameter Excel file. The file only gives the shape of each distribution:
## its mean is the parameter value in params.yaml, so run params.R first.

source("data-raw/source_params/reading_params_sources.R") # creates `params_copy`

params_yaml <- file.path("inst", "extdata", "params.yaml")
dists_yaml  <- file.path("inst", "extdata", "params_distributions.yaml")

rows <-as.data.frame(readxl::read_excel(params_copy, sheet = "params", col_types = "text", trim_ws = FALSE))
rows$row <- seq_len(nrow(rows)) + 1 # Excel row (row 1 is the header), for messages
rows <- rows[!is.na(rows$parameters), ]

# Path of each row, from its indentation (two characters per level), as in params.R
indent     <- attr(regexpr("^[ \u00a0]*", rows$parameters), "match.length")
rows$name  <- substring(rows$parameters, indent + 1)
rows$depth <- indent / 2
rows       <- rows[rows$name != "", ]
path       <- character(0)
rows$path  <- NA_character_
for (i in seq_len(nrow(rows))) {
  path         <- c(path[seq_len(rows$depth[i])], rows$name[i])
  rows$path[i] <- paste(path, collapse = " > ")
}

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
rows$m     <- as_number("mean")
rows$sd    <- as_number("sd")
rows$min   <- as_number("min")
rows$max   <- as_number("max")
rows$alpha <- as_number("alpha_a0")

# Distribution: first word of the column ("beta (a0 = alpha/mean)" is "beta"),
# missing if the cell is empty
rows$dist <- sub(" .*$", "", tolower(trimws(rows$Distribution)))
valid     <- c("lognormal", "trunc_lognormal", "beta", "dirichlet", "na")
if (any(!is.na(rows$dist) & !(rows$dist %in% valid))) {
  stop("Unknown distribution in row(s) ",
       paste(rows$row[!is.na(rows$dist) & !(rows$dist %in% valid)], collapse = ", "))
}
if (any(!is.na(rows$dist) & is.na(rows$m))) {
  stop("Distribution without a mean in row(s) ",
       paste(rows$row[!is.na(rows$dist) & is.na(rows$m)], collapse = ", "))
}

# Dirichlet group of each row (column "group")
if (!("group" %in% names(rows))) {
  stop("The Excel file has no column \"group\".")
}
rows$group <- trimws(rows$group)
rows$group[tolower(rows$group) %in% c("na", "-", "")] <- NA
if (any(!is.na(rows$group) & is.na(rows$m))) {
  stop("Group without a mean in row(s) ",
       paste(rows$row[!is.na(rows$group) & is.na(rows$m)], collapse = ", "))
}

# Value of a nested list at a path (NULL if there is none)
get_path <- function(x, key) {
  for (k in key) {
    if (!is.list(x) || !(k %in% names(x))) return(NULL)
    x <- x[[k]]
  }
  x
}
# Nested list with a value set at a path (creating the sections on the way)
set_path <- function(x, key, value) {
  if (length(key) == 1) {
    x[[key]] <- value
  } else {
    section     <- if (is.null(x[[key[1]]])) list() else x[[key[1]]]
    x[[key[1]]] <- set_path(section, key[-1], value)
  }
  x
}

# Fields each distribution needs, from the columns sd, min, max and alpha_a0
fields <- list(
  lognormal       = "sd",
  trunc_lognormal = c("sd", "min", "max"),
  beta            = "alpha",
  dirichlet       = "alpha",
  na              = character(0))

# Distribution of each parameter =============================================
params <- yaml::read_yaml(params_yaml)
dists  <- list()
notes  <- character(0) # parameters kept fixed or fields ignored, to check in the Excel file
for (i in which(!is.na(rows$m))) {
  key   <- strsplit(rows$path[i], " > ", fixed = TRUE)[[1]]
  where <- sprintf("Row %d (%s)", rows$row[i], rows$path[i])
  m     <- rows$m[i]
  dist  <- rows$dist[i]

  # The mean of the distribution is the value in params.yaml: same as in the Excel file
  value <- get_path(params, key)
  if (!is.numeric(value) || length(value) != 1) {
    stop(where, " is not a parameter in params.yaml: run params.R first.")
  }
  if (!isTRUE(all.equal(as.numeric(value), m, tolerance = 1e-12))) {
    stop(where, " has mean ", m, " in the Excel file but ", value,
         " in params.yaml: run params.R first.")
  }

  if (is.na(dist)) {
    notes <- c(notes, paste(where, "has no distribution: not drawn."))
    next
  }
  needed  <- fields[[dist]]
  ignored <- setdiff(c("sd", "min", "max", "alpha")[!is.na(unlist(rows[i, c("sd", "min", "max", "alpha")]))],
                     needed)
  if (length(ignored) > 0) {
    notes <- c(notes, paste0(where, ": ", paste(sub("alpha", "alpha_a0", ignored), collapse = ", "),
                             " ignored for distribution ", dist, "."))
  }
  if (dist == "na") next
  if (any(is.na(unlist(rows[i, needed])))) {
    stop(where, ": distribution ", dist, " needs ",
         paste(sub("alpha", "alpha_a0", needed), collapse = ", "), ".")
  }

  # The sd is written relative to the mean, so it also fits other means (e.g.
  # in another parameter file)
  spec <- switch(dist,
    lognormal = {
      if (m <= 0 || rows$sd[i] <= 0) stop(where, ": lognormal needs mean > 0 and sd > 0.")
      list(distribution = "lognormal", sd_rel = rows$sd[i] / m)
    },
    trunc_lognormal = {
      if (rows$sd[i] <= 0) stop(where, ": trunc_lognormal needs sd > 0.")
      if (!(rows$min[i] >= 0 && rows$min[i] < m && m < rows$max[i])) {
        stop(where, ": trunc_lognormal needs 0 <= min < mean < max.")
      }
      list(distribution = "trunc_lognormal", sd_rel = rows$sd[i] / m,
           min = rows$min[i], max = rows$max[i])
    },
    beta = {
      if (m < 0 || m > 1 || rows$alpha[i] <= 0) stop(where, ": beta needs 0 <= mean <= 1 and alpha > 0.")
      if (m == 0 || m == 1) {
        notes <- c(notes, paste0(where, ": beta with mean ", m, " is a fixed value, not drawn."))
        NULL
      } else {
        list(distribution = "beta", alpha = rows$alpha[i])
      }
    },
    dirichlet = {
      if (is.na(rows$group[i])) stop(where, ": dirichlet needs a group.")
      if (m < 0 || m > 1 || rows$alpha[i] <= 0) stop(where, ": dirichlet needs 0 <= mean <= 1 and a0 > 0.")
      list(distribution = "dirichlet", group = rows$group[i], a0 = rows$alpha[i])
    })
  if (!is.null(spec)) dists <- set_path(dists, key, spec)
}

# Dirichlet groups ===========================================================
# The parameters of a group are drawn together, so their means must sum to 1.
# Members with mean 0 and no distribution stay 0; groups without any drawn
# member are not drawn at all.
for (group in unique(stats::na.omit(rows$group))) {
  members <- rows[!is.na(rows$group) & rows$group == group, ]
  drawn   <- members$dist %in% "dirichlet"
  total   <- sum(members$m)
  if (!any(drawn)) {
    if (abs(total - 1) > 1e-9) notes <- c(notes, sprintf("Group %s: means sum to %.10g.", group, total))
    next
  }
  if (abs(total - 1) > 1e-9) {
    stop(sprintf("Group %s: means sum to %.10g, not 1.", group, total))
  }
  if (any(!drawn & members$m != 0)) {
    stop("Group ", group, " has drawn and fixed parameters: ",
         paste(members$path[!drawn & members$m != 0], collapse = ", "))
  }
  if (sum(drawn) < 2) {
    stop("Group ", group, " has fewer than two drawn parameters.")
  }
  if (length(unique(members$alpha[drawn])) != 1) {
    stop("Group ", group, " has different values of a0.")
  }
}

# Write the file =============================================================
header <- c(
  "# Distributions of the non-SAR parameters, for the stochastic dose model.",
  "# Generated by data-raw/source_params/params_distributions.R from",
  "# params_sources.xlsx, do not edit by hand.",
  "# The mean of each distribution is the parameter value (params.yaml), so only",
  "# its shape is given here. Parameters not listed here are not drawn.",
  "#   lognormal:       sd_rel (standard deviation relative to the mean)",
  "#   trunc_lognormal: sd_rel, min, max",
  "#   beta:            alpha (a0 = alpha/mean)",
  "#   dirichlet:       a0, group (drawn together, the parameters of a group sum to 1)")
# Numbers written with 15 significant digits
write_number <- function(x) structure(as.character(x), class = "verbatim")
writeLines(
  c(header, sub("\n$", "", yaml::as.yaml(dists, handlers = list(numeric = write_number)))),
  dists_yaml)

# Must read back as written (e.g. numbers must not be read as text)
if (!isTRUE(all.equal(yaml::read_yaml(dists_yaml), dists, tolerance = 1e-12))) {
  stop(dists_yaml, " does not read back as written.")
}

specs  <- rapply(dists, identity, classes = "character", how = "unlist")
counts <- table(specs[grepl("distribution$", names(specs))])
message("Written ", dists_yaml, ": ",
        paste(names(counts), counts, sep = " ", collapse = ", "), ", in ",
        length(unique(specs[grepl("group$", names(specs))])), " groups.")
if (length(notes) > 0) {
  warning("To check in the Excel file:\n", paste(notes, collapse = "\n"), call. = FALSE)
}
