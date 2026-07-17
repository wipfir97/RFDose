simulate_params <- function(tissue,
                            duration,
                            ear_prop,
                            headp_prop,
                            urbanicity,
                            use_5g,
                            travel_time,
                            headp_ear_num,
                            wifi_prop_home,
                            wifi_prop_work,
                            wifi_prop_travel,
                            sex,
                            age,
                            country,
                            mpd_dur_low,
                            mpd_dur_lowtomed,
                            mpd_dur_medtohigh,
                            mpd_dur_high,
                            dect_duration,
                            dect_ear_prop,
                            lptp_dur_low,
                            lptp_dur_lowtomed,
                            lptp_dur_medtohigh,
                            lptp_dur_high,
                            tblt_dur_low,
                            tblt_dur_lowtomed,
                            tblt_dur_medtohigh,
                            tblt_dur_high,
                            hotspot_duration,
                            smartwatch_duration,
                            tracker_duration,
                            vr_duration,
                            headphone_duration,
                            gaming_duration,
                            simulation,
                            params = load_params(version = simulation)){


  inputs <- as.list(environment())
  browser()

}

simulate_params("tissue",100,
                            0.5,
                            0.5,
                            "urban",
                            TRUE,
                simulation = "_template")


#' Draw a random value from a specified distribution
#'
#' Draws a single random value from one of the supported probability
#' distributions.
#'
#' @param dist_name Character string specifying the distribution.
#'   Supported values are `"trunc_norm"`, `"gamma"`, `"trunc_gamma"`,
#'   `"trunc_hurdle_gamma"` and `"dirichlet"`.
#' @param mean Mean of the distribution. For `"dirichlet"`, a numeric vector of
#'   mean proportions summing to 1.
#' @param sd Standard deviation of the distribution (not used for
#'   `"dirichlet"`).
#' @param p_zero Probability of drawing zero for `"trunc_hurdle_gamma"`.
#' @param min Lower truncation bound (only used for `"trunc_norm"`).
#' @param max Upper truncation bound (used for truncated distributions).
#' @param a0 Concentration parameter of the Dirichlet distribution.
#'
#' @return A single random draw from the selected distribution.
#' @export
evaluate_distribution <- function(dist_name,
                                  mean,
                                  sd,
                                  p_zero,
                                  min = NULL,
                                  max = NULL,
                                  a0,
                                  p_categorie1,
                                  categorie1,
                                  categorie2) {

  if (dist_name == "trunc_norm") {

    if (is.null(min) || is.null(max)) {
      stop("'min' and 'max' must be provided for a truncated normal distribution.")
    }

    return(
      r_truncnorm(
        mean = mean,
        sd = sd,
        min = min,
        max = max
      )
    )

  } else if (dist_name == "gamma") {

    return(
      r_gamma(
        mean = mean,
        sd = sd
      )
    )
  } else if (dist_name == "trunc_gamma"){
    return(
      r_trunc_gamma(
        mean = mean,
        sd = sd,
        max = max
      )
    )

  } else if (dist_name == "trunc_hurdle_gamma"){
    return(
      r_trunc_hurdle_gamma(
        mean = mean,
        sd = sd,
        p_zero = p_zero,
        max = max
      )
    )

  } else if (dist_name == "dirichlet"){
    return(
      r_dirichlet(mean,a0)
    )

  } else if (dist_name == "beta"){
    # The beta distr. is a special case of the Dirichlet distr. with two props.
    if (length(mean) == 2) stop("Input needs to be 2 values!")
    return(
      r_dirichlet(mean,a0)
      )

  } else if (dist_name == "bernoulli"){
    return(
      r_bernoulli(p_categorie1= p_categorie1,categorie1=categorie1 ,categorie2 =categorie2 )
    )

  } else if (dist_name == "trunc_lognormal"){
    return(
      r_trunc_lognormal(mean, sd, max = max)
    )

  } else {

    stop("Unsupported distribution. Choose 'truncnorm' or 'gamma'.")

  }
}
r_trunc_lognormal <- function(mean, sd, max = Inf)
#' Draw a random value from a truncated normal distribution
#'
#' Draws a single random value from a normal distribution truncated to a
#' specified range.
#'
#' @param mean Mean of the underlying normal distribution.
#' @param sd Standard deviation of the underlying normal distribution.
#' @param min Lower truncation bound.
#' @param max Upper truncation bound.
#'
#' @return A single random draw from the truncated normal distribution.
#' @export
r_truncnorm <- function(mean, sd, min, max) {
  if (sd <= 0) {
    stop("sd must be greater than 0.")
  }

  if (min >= max) {
    stop("min must be smaller than max.")
  }

  truncnorm::rtruncnorm(
    n = 1,
    a = min,
    b = max,
    mean = mean,
    sd = sd
  )
}


#' Draw a random value from a Gamma distribution
#'
#' Draws a single random value from a Gamma distribution parameterized by its
#' mean and standard deviation.
#'
#' @param mean Mean of the Gamma distribution.
#' @param sd Standard deviation of the Gamma distribution.
#'
#' @return A single random draw from the Gamma distribution.
#' @export
r_gamma <- function(mean, sd) {
  if (mean <= 0) stop("mean must be greater than 0.")
  if (sd <= 0) stop("sd must be greater than 0.")

  shape <- (mean / sd)^2
  scale <- sd^2 / mean

  rgamma(
    n = 1,
    shape = shape,
    scale = scale
  )
}

#' Draw a random value from a truncated Gamma distribution
#'
#' Draws a single random value from a Gamma distribution truncated at an upper
#' bound.
#'
#' @param mean Mean of the underlying Gamma distribution.
#' @param sd Standard deviation of the underlying Gamma distribution.
#' @param max Upper truncation bound.
#'
#' @return A single random draw from the truncated Gamma distribution.
#' @export
r_trunc_gamma <- function(mean, sd, max = Inf) {
  if (mean <= 0) stop("mean must be greater than 0.")
  if (sd <= 0) stop("sd must be greater than 0.")

  shape <- (mean / sd)^2
  scale <- sd^2 / mean

  p_max <- pgamma(max, shape = shape, scale = scale)

  u <- runif(1, 0, p_max)

  qgamma(u, shape = shape, scale = scale)
}

#' Draw a random value from a truncated hurdle Gamma distribution
#'
#' Draws either zero with probability `p_zero` or a value from an upper
#' truncated Gamma distribution.
#'
#' @param mean Mean of the underlying Gamma distribution (not equivalent to the mean of
#' the final hurdle distribution because of the introduction of additional zeros there).
#' -> the mean characterizes the typical behaviour where the values are not set to zero.
#' @param sd Standard deviation of the underlying Gamma distribution.
#' @param p_zero Probability of returning zero.
#' @param max Upper truncation bound.
#'
#' @return A single random draw from the truncated hurdle Gamma distribution.
#' @export
r_trunc_hurdle_gamma <- function(mean, sd, p_zero, max = Inf) {
  if (mean <= 0) stop("mean must be greater than 0.")
  if (sd <= 0) stop("sd must be greater than 0.")

  is_positive <- rbinom(1, size = 1, prob = 1 - p_zero)

  if (!is_positive) {
    return(0)
  }

  r_trunc_gamma(mean, sd, max)
}



#' Draws a single vector of proportions from a Dirichlet distribution.
#'
#' @param mean Numeric vector of mean proportions. Values must be non-negative
#'   and sum to 1.
#' @param a0 Positive concentration parameter controlling the variability around
#'   the mean proportions.
#'
#' @return A numeric vector of proportions summing to 1.
#' @export
r_dirichlet <- function(mean, a0 = 100) {
  if (any(mean < 0)) stop("All mean values must be non-negative.")
  if (length(mean) < 2) stop("Needs at least 2 mean values.")
  if (!isTRUE(all.equal(sum(mean), 1, tolerance = 1e-8))) stop("The mean proportions must sum to 1.")
  if (a0 <= 0) stop("concentration must be greater than 0.")

  alpha <- a0 * mean
  as.numeric(MCMCpack::rdirichlet(1, alpha))
}





#' Draws either `categorie1` or `categorie2` according to a Bernoulli distribution.
#'
#' @param p_categorie1 Probability of drawing `categorie2`. Must be between 0 and 1.
#' @categorie1 should be a character
#' @categorie2 should be a character
#' @return A character string, either `categorie1` or `categorie2`.
#' @export
r_bernoulli <- function(p_categorie1,categorie1,categorie2) {

  if (p_categorie1 < 0 || p_categorie1 > 1) {
    stop("p_categorie1 must be between 0 and 1.")
  }

  if (rbinom(1, size = 1, prob = p_categorie1) == 1) {
    return(categorie1)
  } else {
    return(categorie2)
  }
}




#' Draw a random value from a truncated Lognormal distribution
#'
#' Draws a single random value from a Lognormal distribution truncated
#' at an upper bound.
#'
#' @param mean Mean of the Lognormal distribution on the original scale.
#' @param sd Standard deviation of the Lognormal distribution on the original scale.
#' @param max Upper truncation bound.
#'
#' @return A single random draw from the truncated Lognormal distribution.
#' @export
r_trunc_lognormal <- function(mean, sd, max = Inf) {

  if (mean <= 0) stop("mean must be greater than 0.")
  if (sd <= 0) stop("sd must be greater than 0.")

  # Convert original scale parameters to log-scale parameters
  sigma2 <- log(1 + (sd^2 / mean^2))

  sigma <- sqrt(sigma2)

  mu <- log(mean) - sigma2 / 2


  # Upper truncation probability
  p_max <- plnorm(
    max,
    meanlog = mu,
    sdlog = sigma
  )

  # Draw only below max
  u <- runif(1, 0, p_max)

  qlnorm(
    u,
    meanlog = mu,
    sdlog = sigma
  )
}



















#___________________________________________________________________________________________________________________
#trunc_normal


x <- replicate(
  100000,
  evaluate_distribution(
    dist_name = "trunc_norm",
    mean = 200,
    sd = 100,
    min = 50,
    max = 350
  )
)

hist(
  x,
  breaks = 30,
  probability = TRUE,
  col = "lightblue",
  border = "white",
  main = "Truncated normal Distribution",
  xlab = "Value"
)

lines(density(x), lwd = 2, col = "red")
abline(v = mean(x), col = "blue", lwd = 2, lty = 2)





#___________________________________________________________________________________________________________________
#trunc_gamma


x <- replicate(
  100000,
  evaluate_distribution(
    dist_name = "trunc_gamma",
    mean = 200,
    sd = 100,
    max = 350
  )
)

hist(
  x,
  breaks = 30,
  probability = TRUE,
  col = "lightblue",
  border = "white",
  main = "Truncated Gamma Distribution",
  xlab = "Value"
)

lines(density(x), lwd = 2, col = "red")
abline(v = mean(x), col = "blue", lwd = 2, lty = 2)






#___________________________________________________________________________________________________________________
#trunc_hurdle_gamma


x <- replicate(
  100000,
  evaluate_distribution(
    dist_name = "trunc_hurdle_gamma",
    mean = 5,
    sd = 4,
    p_zero = 0.2,
    max = 12
  )
)

hist(
  x,
  breaks = 50,
  probability = TRUE,
  col = "lightblue",
  border = "white",
  main = "Truncated hurdle Gamma Distribution",
  xlab = "Value"
)

lines(density(x), lwd = 2, col = "red")

abline(v = mean(x), col = "blue", lwd = 2, lty = 2)





#___________________________________________________________________________________________________________________
#visualize_gamma

set.seed(123)

# 1000 Ziehungen
x <- t(replicate(
  1000,
  r_dirichlet(
    mean = c(0.4, 0.5, 0.1),
    a0 = 100
  )
))

# Spalten benennen
colnames(x) <- c("urban", "suburban", "rural")

# Erste Ziehungen ansehen
head(x)

# Mittelwerte prüfen
colMeans(x)

# Standardabweichungen prüfen
apply(x, 2, sd)

par(
  mfrow = c(1, 3),
  oma = c(0, 0, 3, 0)   # oberer äußerer Rand
)

hist(
  x[, 1],
  breaks = 30,
  probability = TRUE,
  main = "Urban",
  xlab = "Proportion",
  col = "lightblue"
)
abline(v = mean(x[, 1]), col = "red", lwd = 2)

hist(
  x[, 2],
  breaks = 30,
  probability = TRUE,
  main = "Suburban",
  xlab = "Proportion",
  col = "lightblue"
)
abline(v = mean(x[, 2]), col = "red", lwd = 2)

hist(
  x[, 3],
  breaks = 30,
  probability = TRUE,
  main = "Rural",
  xlab = "Proportion",
  col = "lightblue"
)
abline(v = mean(x[, 3]), col = "red", lwd = 2)
title("Dirichlet Distribution", outer = TRUE, cex.main = 1.5)
par(mfrow = c(1, 1))




#___________________________________________________________________________________________________________________
#visualize_bernoulli


# Anzahl der Ziehungen
n <- 1000

# Parameter für Bernoulli-Test
p_categorie1 <- 0.7
categorie1 <- "Headphone"
categorie2 <- "No Headphone"

# 1000 Ziehungen
results <- replicate(
  n,
  evaluate_distribution(
    dist_name = "bernoulli",
    mean = NULL,
    sd = NULL,
    p_zero = NULL,
    min = NULL,
    max = NULL,
    a0 = NULL,
    p_categorie1 = p_categorie1,
    categorie1 = categorie1,
    categorie2 = categorie2
  )
)

# Häufigkeiten zählen
counts <- table(results)

# Ausgabe
counts

# Relative Häufigkeiten
proportions <- prop.table(counts)
proportions

# Balkendiagramm
barplot(
  counts,
  main = paste0("Bernoulli simulation (n=", n, ")"),
  ylab = "Number of draws",
  xlab = "Category",
  col = "steelblue"
)

#___________________________________________________________________________________________________________________
# truncated lognormal

x <- replicate(
  100000,
  evaluate_distribution(
    dist_name = "trunc_lognormal",
    mean = 200,
    sd = 100,
    p_zero = NULL,
    min = NULL,
    max = 350,
    a0 = NULL,
    p_categorie1 = NULL,
    categorie1 = NULL,
    categorie2 = NULL
  )
)

hist(
  x,
  breaks = 30,
  probability = TRUE,
  col = "lightblue",
  border = "white",
  main = "Truncated Lognormal Distribution",
  xlab = "Value"
)

lines(density(x), lwd = 2, col = "red")
abline(v = mean(x), col = "blue", lwd = 2, lty = 2)

# Optional: Mittelwert und SD anzeigen
cat("Mean:", mean(x), "\n")
cat("SD:", sd(x), "\n")
cat("Max:", max(x), "\n")

