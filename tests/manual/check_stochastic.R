## Manual check of the stochastic dose calculation (calculate_emf_doses_stochastic)
## Run from the package root: source("tests/manual/check_stochastic.R")
## Prints checks of the drawn parameters and of the doses, and plots the doses
## of every draw. Not part of the automated tests (tests/testthat/test-stochastic.R).

devtools::load_all(quiet = TRUE)

n      <- 100         # number of draws
tissue <- "brain"       # or "body"
data   <- example_data  # or your own data
set.seed(1)

# Stochastic doses ============================================================
result  <- calculate_emf_doses_stochastic(data, tissue = tissue, n = n, keep_draws = TRUE)
summary <- result$summary
doses   <- result$doses  # row x draw x exposure source
draws   <- result$params # draw x parameter

# 1. Drawn parameters: their mean must be the value of the parameter file =====
params <- load_params()
specs  <- list_distributions(load_distributions())
## The first columns of the draws are the parameters, the others the SAR values (see 3.)
param_draws  <- draws[, names(specs)]
check_params <- data.frame(
  parameter    = names(specs),
  distribution = vapply(specs, function(spec) spec$distribution, character(1)),
  value        = vapply(specs, function(spec) get_param(params, spec$key), numeric(1)),
  mean_draws   = colMeans(param_draws),
  sd_draws     = apply(param_draws, 2, stats::sd),
  row.names    = NULL)
# deviation of the mean of the draws, in standard errors (|z| > 4: very unlikely by chance)
check_params$z <- with(check_params, ifelse(sd_draws > 0, (mean_draws - value) / (sd_draws / sqrt(n)), 0))

cat("\n1. Drawn parameters (", ncol(param_draws), "): mean of the draws vs value in the parameter file\n", sep = "")
print(table(check_params$distribution))
cat("Largest deviations:\n")
print(head(check_params[order(-abs(check_params$z)), ], 10), row.names = FALSE, digits = 4)
cat(sum(abs(check_params$z) > 4), "parameter(s) with |z| > 4 (expected: 0)\n")

# 2. Dirichlet groups: proportions sum to 1 in every draw ====================
groups <- vapply(specs, function(spec) {
  if (spec$distribution == "dirichlet") as.character(spec$group) else NA_character_
}, character(1))
cat("\n2. Dirichlet groups: largest deviation of the sum from 1 over all draws\n")
for (group in unique(stats::na.omit(groups))) {
  sums <- rowSums(draws[, names(groups)[groups %in% group], drop = FALSE])
  cat(sprintf("  %-22s %.2e\n", group, max(abs(sums - 1))))
}

# 3. SAR values: mean of the draws = value of the SAR file, sd = 25% of it ====
sar       <- list_sar(params)
sar_draws <- draws[, sar$name, drop = FALSE]
check_sar <- data.frame(
  sar        = sar$name,
  value      = sar$value,
  mean_draws = colMeans(sar_draws),
  sd_rel     = apply(sar_draws, 2, stats::sd) / sar$value,
  row.names  = NULL)
check_sar$z <- with(check_sar, (mean_draws - value) / (sd_rel * value / sqrt(n)))
## SAR values with the same value for the same tissue come from the same simulation
simulation <- paste(sar$tissue, sprintf("%.17g", sar$value))
together   <- vapply(split(sar$name, simulation), function(columns) {
  all(sar_draws[, columns] == sar_draws[, columns[1]])
}, logical(1))

cat("\n3. SAR values (", nrow(sar), ", from ", length(together),
    " simulations): mean of the draws vs value of the SAR file\n", sep = "")
cat(sprintf("Standard deviation of the draws / value: %.3f to %.3f (expected: about 0.25)\n",
            min(check_sar$sd_rel), max(check_sar$sd_rel)))
cat(sum(abs(check_sar$z) > 4), "SAR value(s) with |z| > 4 (expected: 0)\n")
cat("SAR values of the same simulation drawn together:", all(together), "\n")

# 4. Doses: finite, non-negative, and deterministic dose within the draws ====
cat("\n4. Doses (mJ/kg/day,", tissue, ")\n")
cat("All doses finite and >= 0:", all(is.finite(doses) & doses >= 0), "\n")
summary$mean_vs_det <- summary$mean / summary$deterministic
summary$det_in_95   <- summary$deterministic >= summary$q2.5 & summary$deterministic <= summary$q97.5
print(summary, row.names = FALSE, digits = 3)
cat("Deterministic dose outside the 95% interval of the draws:",
    sum(!summary$det_in_95 & summary$deterministic > 0), "of", sum(summary$deterministic > 0), "\n")

# 5. Plots ====================================================================
sources <- dimnames(doses)[[3]]
total   <- apply(doses, c(1, 2), sum) # row x draw
old_par <- par(no.readonly = TRUE)

## Total dose of each row: draws, deterministic dose (red) and 95% interval (dashed)
par(mfrow = c(1, nrow(total)))
for (row in seq_len(nrow(total))) {
  s <- summary[summary$row == row & summary$dose == "total_dose", ]
  hist(total[row, ], breaks = 40, col = "grey85", border = "white",
       main = paste("Row", row), xlab = "Total dose (mJ/kg/day)")
  abline(v = s$deterministic, col = "red", lwd = 2)
  abline(v = c(s$q2.5, s$q97.5), lty = 2)
}

## Spread of each exposure source: dose of every draw / deterministic dose (row 1)
par(mfrow = c(1, 1), mar = c(5, 8, 3, 1))
det_1  <- summary[summary$row == 1 & summary$dose %in% sources, ]
used   <- det_1$dose[det_1$deterministic > 0]
ratios <- sweep(matrix(doses[1, , used], ncol = length(used), dimnames = list(NULL, used)),
                2, det_1$deterministic[match(used, det_1$dose)], "/")
boxplot(ratios, horizontal = TRUE, las = 1, log = "x", col = "grey85",
        main = "Row 1: dose of each draw / deterministic dose", xlab = "Ratio (log scale)")
abline(v = 1, col = "red", lwd = 2)

par(old_par)
