# df <- data.frame(
#   country= "Other",
#   mpd_dur_low= 4860,
#   mpd_dur_lowtomed= 540,
#   mpd_dur_medtohigh= 4860,
#   mpd_dur_high= 540,
#   dect_duration= 204,
#   dect_ear_prop= 0.9,
#   lptp_dur_low= 1967,
#   lptp_dur_lowtomed= 219,
#   lptp_dur_medtohigh= 1967,
#   lptp_dur_high= 219,
#   tblt_dur_low= 728,
#   tblt_dur_lowtomed= 81,
#   tblt_dur_medtohigh= 728,
#   tblt_dur_high= 81,
#   hotspot_duration= 0,
#   smartwatch_duration= 0,
#   tracker_duration= 0,
#   vr_duration= 0,
#   headphone_duration= 0,
#   gaming_duration= 600,
#   sex= "male",
#   age= "adult",
#   use_5g= TRUE,
#   urb_prop= 0.4,
#   sub_prop= 0.5,
#   rur_prop= 0.1,
#   mpc_duration= 653.00,
#   mpc_ear_prop= 0.45,
#   speaker_prop= 0.32,
#   mpc_headp_prop= 0.23,
#   headp_ear_num= 2,
#   mpd_wifi_prop_home= 0.70,
#   mpd_wifi_prop_work= 0.47,
#   mpd_wifi_prop_travel= 0.31,
#   lptp_dur_low = 1967
# )
#test

df <- data.frame( country= "Other",
  lptp_dur_low= 1967,
  lptp_dur_lowtomed= 219,
  lptp_dur_medtohigh= 1967,
  lptp_dur_high= 219,
  tblt_dur_low= 728,
  tblt_dur_lowtomed= 81,
  tblt_dur_medtohigh= 728,
  tblt_dur_high= 81,
  hotspot_duration= 0,
  smartwatch_duration= 0,
  tracker_duration= 0,
  vr_duration= 0,
  headphone_duration= 0,
  gaming_duration= 600,
  urb_prop = 0.5,
  rur_prop =0.45,
  sub_prop = 0.05,
  sex= "male",
  age= "adult",
  mpc_ear_prop= 0.45
)




dose <- calculate_emf_doses(df,tissue = "brain", n_sim = 100, save=FALSE,save_path ="C:/Users/ardigi/Documents/Videos/Dose_model/dose_model/test_save/")




# Total dose
total_dose <- dose$call_dose + dose$data_dose

# 95th percentiles
q99_call <- quantile(dose$call_dose, 0.99)
q99_data <- quantile(dose$data_dose, 0.99)
q99_total <- quantile(total_dose, 0.99)

# Plot layout: 2 rows × 3 columns
par(mfrow = c(2, 3))

# -------------------------
# Histograms
# -------------------------
hist(
  dose$call_dose,
  probability = TRUE,
  breaks = 30,
  col = "lightblue",
  border = "white",
  main = "Call dose",
  xlab = "Dose"
)
lines(density(dose$call_dose), col = "red", lwd = 2)
abline(v = mean(dose$call_dose), col = "blue", lwd = 2, lty = 2)

hist(
  dose$data_dose,
  probability = TRUE,
  breaks = 30,
  col = "lightblue",
  border = "white",
  main = "Data dose",
  xlab = "Dose"
)
lines(density(dose$data_dose), col = "red", lwd = 2)
abline(v = mean(dose$data_dose), col = "blue", lwd = 2, lty = 2)

hist(
  total_dose,
  probability = TRUE,
  breaks = 30,
  col = "lightblue",
  border = "white",
  main = "Total dose",
  xlab = "Dose"
)
lines(density(total_dose), col = "red", lwd = 2)
abline(v = mean(total_dose), col = "blue", lwd = 2, lty = 2)

# -------------------------
# Horizontal boxplots with individual observations
# -------------------------
boxplot(
  dose$call_dose,
  horizontal = TRUE,
  col = "lightblue",
  main = "Call dose",
  xlab = "Dose",
  xylim = c(0, q99_call)
)
stripchart(
  dose$call_dose,
  method = "jitter",
  pch = 16,
  cex = 0.4,
  vertical = FALSE,
  add = TRUE
)

boxplot(
  dose$data_dose,
  horizontal = TRUE,
  col = "lightblue",
  main = "Data dose",
  xlab = "Dose",
  ylim = c(0, q99_data)
)
stripchart(
  dose$data_dose,
  method = "jitter",
  pch = 16,
  cex = 0.4,
  vertical = FALSE,
  add = TRUE
)

boxplot(
  total_dose,
  horizontal = TRUE,
  col = "lightblue",
  main = "Total dose",
  xlab = "Dose",
  ylim = c(0, q99_total)
)
stripchart(
  total_dose,
  method = "jitter",
  pch = 16,
  cex = 0.4,
  vertical = FALSE,
  add = TRUE
)

# Reset plot layout
par(mfrow = c(1, 1))

