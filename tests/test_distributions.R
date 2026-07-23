



test_params <-simulate_params(country = "Italy",
                              simulation = "_sim1")



params_template = yaml::read_yaml(system.file("extdata", paste0("params_template.yaml"), package = "RFDose"))


#plot replicates_______________________________________________________






x <- replicate(
  1000,
  simulate_params(country = "Italy",
                  simulation = "_sim1"),
  simplify = FALSE
)

duration <- sapply(x, \(z) z$global$input_stoch$duration$mpc_duration)

hist(duration, probability = TRUE, breaks = 30,
     col = "lightblue", border = "white",
     main = "Duration", xlab = "Duration")
lines(density(duration), col = "red", lwd = 2)
abline(v = mean(duration), col = "blue", lty = 2, lwd = 2)
abline(v = params_template$global$input_stoch$duration$mpc_duration, col = "darkgreen", lty = 2, lwd = 2)




ear_prop <- sapply(x, \(z) z$global$input_stoch$call_mode_prop$mpc_ear_prop)

hist(ear_prop, probability = TRUE, breaks = 30,
     col = "lightblue", border = "white",
     main = "Ear proportion", xlab = "Ear proportion")
lines(density(ear_prop), col = "red", lwd = 2)
abline(v = mean(ear_prop), col = "blue", lty = 2, lwd = 2)
abline(v = params_template$global$input_stoch$call_mode_prop$mpc_ear_prop, col = "darkgreen", lty = 2, lwd = 2)


headp_prop <- sapply(x, \(z) z$global$input_stoch$call_mode_prop$mpc_headp_prop)

hist(headp_prop, probability = TRUE, breaks = 30,
     col = "lightblue", border = "white",
     main = "Headphone proportion", xlab = "Headphone proportion")
lines(density(headp_prop), col = "red", lwd = 2)
abline(v = mean(headp_prop), col = "blue", lty = 2, lwd = 2)
abline(v = params_template$global$input_stoch$call_mode_prop$mpc_headp_prop, col = "darkgreen", lty = 2, lwd = 2)


speaker_prop <- sapply(x, \(z) z$global$input_stoch$call_mode_prop$speaker_prop)

hist(speaker_prop, probability = TRUE, breaks = 30,
     col = "lightblue", border = "white",
     main = "Speaker proportion", xlab = "Speaker proportion")
lines(density(speaker_prop), col = "red", lwd = 2)
abline(v = mean(speaker_prop), col = "blue", lty = 2, lwd = 2)
abline(v = params_template$global$input_stoch$call_mode_prop$speaker_prop, col = "darkgreen", lty = 2, lwd = 2)


urb_prop <- sapply(x, \(z) z$global$input_stoch$urbanicity$urb_prop)

hist(urb_prop, probability = TRUE, breaks = 30,
     col = "lightblue", border = "white",
     main = "Urban proportion", xlab = "Urban proportion")
lines(density(urb_prop), col = "red", lwd = 2)
abline(v = mean(urb_prop), col = "blue", lty = 2, lwd = 2)
abline(v = params_template$global$input_stoch$urbanicity$urb_prop, col = "darkgreen", lty = 2, lwd = 2)


sub_prop <- sapply(x, \(z) z$global$input_stoch$urbanicity$sub_prop)

hist(sub_prop, probability = TRUE, breaks = 30,
     col = "lightblue", border = "white",
     main = "Suburban proportion", xlab = "Suburban proportion")
lines(density(sub_prop), col = "red", lwd = 2)
abline(v = mean(sub_prop), col = "blue", lty = 2, lwd = 2)
abline(v = params_template$global$input_stoch$urbanicity$sub_prop, col = "darkgreen", lty = 2, lwd = 2)


rur_prop <- sapply(x, \(z) z$global$input_stoch$urbanicity$rur_prop)

hist(rur_prop, probability = TRUE, breaks = 30,
     col = "lightblue", border = "white",
     main = "Rural proportion", xlab = "Rural proportion")
lines(density(rur_prop), col = "red", lwd = 2)
abline(v = mean(rur_prop), col = "blue", lty = 2, lwd = 2)
abline(v = params_template$global$input_stoch$urbanicity$rur_prop, col = "darkgreen", lty = 2, lwd = 2)



headp_num <- sapply(x, \(z) z$global$input_stoch$headp_num)

hist(headp_num, probability = TRUE, breaks = seq(0.5, 2.5, 1),
     col = "lightblue", border = "white",
     main = "Headphone number", xlab = "Headphone number")



home_prop <- sapply(x, \(z) z$global$environment_prop$home_prop)

hist(home_prop, probability = TRUE, breaks = 30,
     col = "lightblue", border = "white",
     main = "Home proportion", xlab = "Home proportion")
lines(density(home_prop), col = "red", lwd = 2)
abline(v = mean(home_prop), col = "blue", lty = 2, lwd = 2)
abline(v = params_template$global$environment_prop$home_prop, col = "darkgreen", lty = 2, lwd = 2)


outd_prop <- sapply(x, \(z) z$global$environment_prop$outd_prop)


hist(outd_prop, probability = TRUE, breaks = 30,
     col = "lightblue", border = "white",
     main = "Outdoor proportion", xlab = "Outdoor proportion")
lines(density(outd_prop), col = "red", lwd = 2)
abline(v = mean(outd_prop), col = "blue", lty = 2, lwd = 2)
abline(v = params_template$global$environment_prop$outd_prop, col = "darkgreen", lty = 2, lwd = 2)


work_prop <- sapply(x, \(z) z$global$environment_prop$work_prop)

hist(work_prop, probability = TRUE, breaks = 30,
     col = "lightblue", border = "white",
     main = "Work proportion", xlab = "Work proportion")
lines(density(work_prop), col = "red", lwd = 2)
abline(v = mean(work_prop), col = "blue", lty = 2, lwd = 2)
abline(v = params_template$global$environment_prop$work_prop, col = "darkgreen", lty = 2, lwd = 2)



travel_prop <- sapply(x, \(z) z$global$environment_prop$travel_prop)

hist(travel_prop, probability = TRUE, breaks = 30,
     col = "lightblue", border = "white",
     main = "Travel proportion", xlab = "Travel proportion")
lines(density(travel_prop), col = "red", lwd = 2)
abline(v = mean(travel_prop), col = "blue", lty = 2, lwd = 2)
abline(v = params_template$global$environment_prop$travel_prop, col = "darkgreen", lty = 2, lwd = 2)



wifi_home <- sapply(x, \(z) z$global$input_stoch$wifi_environment_probs$mpd_wifi_prop_home)

hist(wifi_home, probability = TRUE, breaks = 30,
     col = "lightblue", border = "white",
     main = "WiFi proportion at home", xlab = "Proportion")
lines(density(wifi_home), col = "red", lwd = 2)
abline(v = mean(wifi_home), col = "blue", lty = 2, lwd = 2)
abline(v = params_template$global$input_stoch$wifi_environment_probs$mpd_wifi_prop_home, col = "darkgreen", lty = 2, lwd = 2)



wifi_work <- sapply(x, \(z) z$global$input_stoch$wifi_environment_probs$mpd_wifi_prop_work)

hist(wifi_work, probability = TRUE, breaks = 30,
     col = "lightblue", border = "white",
     main = "WiFi proportion at work", xlab = "Proportion")
lines(density(wifi_work), col = "red", lwd = 2)
abline(v = mean(wifi_work), col = "blue", lty = 2, lwd = 2)
abline(v = params_template$global$input_stoch$wifi_environment_probs$mpd_wifi_prop_work, col = "darkgreen", lty = 2, lwd = 2)


wifi_travel <- sapply(x, \(z) z$global$input_stoch$wifi_environment_probs$mpd_wifi_prop_travel)

hist(wifi_travel, probability = TRUE, breaks = 30,
     col = "lightblue", border = "white",
     main = "WiFi proportion during travel", xlab = "Proportion")
lines(density(wifi_travel), col = "red", lwd = 2)
abline(v = mean(wifi_travel), col = "blue", lty = 2, lwd = 2)
abline(v = params_template$global$input_stoch$wifi_environment_probs$mpd_wifi_prop_travel, col = "darkgreen", lty = 2, lwd = 2)


#=========================
# Calltype proportions
#=========================
native_prop <- sapply(x, \(z) z$devices$call$call_type$native_prop)

hist(native_prop, probability = TRUE, breaks = 30,
     col = "lightblue", border = "white",
     main = "Native proportion", xlab = "Proportion")
lines(density(native_prop), col = "red", lwd = 2)
abline(v = mean(native_prop), col = "blue", lty = 2, lwd = 2)
abline(v = params_template$devices$call$call_type$native_prop, col = "darkgreen", lty = 2, lwd = 2)

wifi_prop <- sapply(x, \(z) z$devices$call$call_type$wifi_prop)

hist(wifi_prop, probability = TRUE, breaks = 30,
     col = "lightblue", border = "white",
     main = "Wifi proportion", xlab = "Proportion")
lines(density(wifi_prop), col = "red", lwd = 2)
abline(v = mean(wifi_prop), col = "blue", lty = 2, lwd = 2)
abline(v = params_template$devices$call$call_type$wifi_prop, col = "darkgreen", lty = 2, lwd = 2)

data_prop <- sapply(x, \(z) z$devices$call$call_type$data_prop)

hist(data_prop, probability = TRUE, breaks = 30,
     col = "lightblue", border = "white",
     main = "data proportion", xlab = "Proportion")
lines(density(data_prop), col = "red", lwd = 2)
abline(v = mean(data_prop), col = "blue", lty = 2, lwd = 2)
abline(v = params_template$devices$call$call_type$data_prop, col = "darkgreen", lty = 2, lwd = 2)





#=========================
# Native band proportions
#=========================

native_2g_prop <- sapply(x, \(z) z$devices$call$native_band_props$native_2g_prop)

hist(native_2g_prop, probability = TRUE, breaks = 30,
     col = "lightblue", border = "white",
     main = "Native 2G proportion", xlab = "Proportion")
lines(density(native_2g_prop), col = "red", lwd = 2)
abline(v = mean(native_2g_prop), col = "blue", lty = 2, lwd = 2)
abline(v = params_template$devices$call$native_band_props$native_2g_prop, col = "darkgreen", lty = 2, lwd = 2)


native_3g_prop <- sapply(x, \(z) z$devices$call$native_band_props$native_3g_prop)

hist(native_3g_prop, probability = TRUE, breaks = 30,
     col = "lightblue", border = "white",
     main = "Native 3G proportion", xlab = "Proportion")
lines(density(native_3g_prop), col = "red", lwd = 2)
abline(v = mean(native_3g_prop), col = "blue", lty = 2, lwd = 2)
abline(v = params_template$devices$call$native_band_props$native_3g_prop, col = "darkgreen", lty = 2, lwd = 2)


native_4g_prop <- sapply(x, \(z) z$devices$call$native_band_props$native_4g_prop)

hist(native_4g_prop, probability = TRUE, breaks = 30,
     col = "lightblue", border = "white",
     main = "Native 4G proportion", xlab = "Proportion")
lines(density(native_4g_prop), col = "red", lwd = 2)
abline(v = mean(native_4g_prop), col = "blue", lty = 2, lwd = 2)
abline(v = params_template$devices$call$native_band_props$native_4g_prop, col = "darkgreen", lty = 2, lwd = 2)


native_5g_prop <- sapply(x, \(z) z$devices$call$native_band_props$native_5g_prop)

hist(native_5g_prop, probability = TRUE, breaks = 30,
     col = "lightblue", border = "white",
     main = "Native 5G proportion", xlab = "Proportion")
lines(density(native_5g_prop), col = "red", lwd = 2)
abline(v = mean(native_5g_prop), col = "blue", lty = 2, lwd = 2)
abline(v = params_template$devices$call$native_band_props$native_5g_prop, col = "darkgreen", lty = 2, lwd = 2)


#=========================
# Native duty cycle
#=========================

native_2g_dutycycle <- sapply(x, \(z) z$devices$call$native_dutycycle$native_2g_dutycycle)

hist(native_2g_dutycycle, probability = TRUE, breaks = 30,
     col = "lightblue", border = "white",
     main = "Native 2G duty cycle", xlab = "Duty cycle")
lines(density(native_2g_dutycycle), col = "red", lwd = 2)
abline(v = mean(native_2g_dutycycle), col = "blue", lty = 2, lwd = 2)
abline(v = params_template$devices$call$native_dutycycle$native_2g_dutycycle, col = "darkgreen", lty = 2, lwd = 2)


native_3g_dutycycle <- sapply(x, \(z) z$devices$call$native_dutycycle$native_3g_dutycycle)

hist(native_3g_dutycycle, probability = TRUE, breaks = 30,
     col = "lightblue", border = "white",
     main = "Native 3G duty cycle", xlab = "Duty cycle")
lines(density(native_3g_dutycycle), col = "red", lwd = 2)
abline(v = mean(native_3g_dutycycle), col = "blue", lty = 2, lwd = 2)
abline(v = params_template$devices$call$native_dutycycle$native_3g_dutycycle, col = "darkgreen", lty = 2, lwd = 2)


native_4g_dutycycle <- sapply(x, \(z) z$devices$call$native_dutycycle$native_4g_dutycycle)

hist(native_4g_dutycycle, probability = TRUE, breaks = 30,
     col = "lightblue", border = "white",
     main = "Native 4G duty cycle", xlab = "Duty cycle")
lines(density(native_4g_dutycycle), col = "red", lwd = 2)
abline(v = mean(native_4g_dutycycle), col = "blue", lty = 2, lwd = 2)
abline(v = params_template$devices$call$native_dutycycle$native_4g_dutycycle, col = "darkgreen", lty = 2, lwd = 2)


#=========================
# Native power
#=========================

native_2g_sub_ind_pwr <- sapply(x, \(z) z$devices$call$native_pwr$native_2g_sub_ind_pwr)

hist(native_2g_sub_ind_pwr, probability = TRUE, breaks = 30,
     col = "lightblue", border = "white",
     main = "Native 2G suburban indoor power", xlab = "Power")
lines(density(native_2g_sub_ind_pwr), col = "red", lwd = 2)
abline(v = mean(native_2g_sub_ind_pwr), col = "blue", lty = 2, lwd = 2)
abline(v = params_template$devices$call$native_pwr$native_2g_sub_ind_pwr, col = "darkgreen", lty = 2, lwd = 2)


native_3g_rur_ind_pwr <- sapply(x, \(z) z$devices$call$native_pwr$native_3g_rur_ind_pwr)

hist(native_3g_rur_ind_pwr, probability = TRUE, breaks = 30,
     col = "lightblue", border = "white",
     main = "Native 3G rural indoor power", xlab = "Power")
lines(density(native_3g_rur_ind_pwr), col = "red", lwd = 2)
abline(v = mean(native_3g_rur_ind_pwr), col = "blue", lty = 2, lwd = 2)
abline(v = params_template$devices$call$native_pwr$native_3g_rur_ind_pwr, col = "darkgreen", lty = 2, lwd = 2)

native_4g_travel_pwr <- sapply(x, \(z) z$devices$call$native_pwr$native_4g_travel_pwr)

hist(native_4g_travel_pwr, probability = TRUE, breaks = 30,
     col = "lightblue", border = "white",
     main = "Native 4G travel power", xlab = "Power")
lines(density(native_4g_travel_pwr), col = "red", lwd = 2)
abline(v = mean(native_4g_travel_pwr), col = "blue", lty = 2, lwd = 2)
abline(v = params_template$devices$call$native_pwr$native_4g_travel_pwr, col = "darkgreen", lty = 2, lwd = 2)


#=========================
# Position proportions
#=========================

headp_face_prop <- sapply(x, \(z) z$devices$call$position_props$headp_face_prop)

hist(headp_face_prop, probability = TRUE, breaks = 30,
     col = "lightblue", border = "white",
     main = "Headphone face proportion", xlab = "Proportion")
lines(density(headp_face_prop), col = "red", lwd = 2)
abline(v = mean(headp_face_prop), col = "blue", lty = 2, lwd = 2)
abline(v = params_template$devices$call$position_props$headp_face_prop, col = "darkgreen", lty = 2, lwd = 2)


headp_pock_prop <- sapply(x, \(z) z$devices$call$position_props$headp_pock_prop)

hist(headp_pock_prop, probability = TRUE, breaks = 30,
     col = "lightblue", border = "white",
     main = "Headphone pocket proportion", xlab = "Proportion")
lines(density(headp_pock_prop), col = "red", lwd = 2)
abline(v = mean(headp_pock_prop), col = "blue", lty = 2, lwd = 2)
abline(v = params_template$devices$call$position_props$headp_pock_prop, col = "darkgreen", lty = 2, lwd = 2)


headp_else_prop <- sapply(x, \(z) z$devices$call$position_props$headp_else_prop)

hist(headp_else_prop, probability = TRUE, breaks = 30,
     col = "lightblue", border = "white",
     main = "Headphone other position proportion", xlab = "Proportion")
lines(density(headp_else_prop), col = "red", lwd = 2)
abline(v = mean(headp_else_prop), col = "blue", lty = 2, lwd = 2)
abline(v = params_template$devices$call$position_props$headp_else_prop, col = "darkgreen", lty = 2, lwd = 2)


#=========================
# MPC distances
#=========================

mpc_dist_ear <- sapply(x, \(z) z$devices$call$mpc_distance$mpc_dist_ear)

hist(mpc_dist_ear, probability = TRUE, breaks = 30,
     col = "lightblue", border = "white",
     main = "MPC ear distance", xlab = "Distance (mm)")
lines(density(mpc_dist_ear), col = "red", lwd = 2)
abline(v = mean(mpc_dist_ear), col = "blue", lty = 2, lwd = 2)
abline(v = params_template$devices$call$mpc_distance$mpc_dist_ear, col = "darkgreen", lty = 2, lwd = 2)


mpc_dist_speaker <- sapply(x, \(z) z$devices$call$mpc_distance$mpc_dist_speaker)

hist(mpc_dist_speaker, probability = TRUE, breaks = 30,
     col = "lightblue", border = "white",
     main = "MPC speaker distance", xlab = "Distance (mm)")
lines(density(mpc_dist_speaker), col = "red", lwd = 2)
abline(v = mean(mpc_dist_speaker), col = "blue", lty = 2, lwd = 2)
abline(v = params_template$devices$call$mpc_distance$mpc_dist_speaker, col = "darkgreen", lty = 2, lwd = 2)


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
    mean = 653.00,
    sd = 1940/5,
    p_zero = 0.35,
    max = 14400
  )
)

hist(
  x,
  breaks = 50,
  probability = TRUE,
  col = "lightblue",
  border = "white",
  main = "Truncated hurdle Gamma Distribution (Duration)",
  xlab = "Value"
)

lines(density(x), lwd = 2, col = "red")

abline(v = mean(x), col = "blue", lwd = 2, lty = 2)





#___________________________________________________________________________________________________________________
#visualize_gamma


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
