## code to prepare GOLIAT SAR data (`goliat_sar`) goes here

# GOLIAT simulation results (outside this repository)
goliat_file <- "C:/Users/loizni/OneDrive - Swiss TPH/Documents/Doctorat/goliat/dose_model/Final_Data_All_2026_LAST.xlsx"

# Frequencies (MHz) not simulated, linearly interpolated between the
# neighbouring simulated frequencies
interp_freqs <- c(900, 1800, 2600)

# Read from a temporary copy, so the file can stay open in Excel
goliat_copy <- tempfile(fileext = ".xlsx")
if (!file.copy(goliat_file, goliat_copy)) {
  stop("Cannot copy GOLIAT file: ", goliat_file)
}

phantoms <- c("Duke", "Ella", "Eartha", "Thelonious")

# Excel tabs: near field (NF, SAR for 1 W input power) and far field (FF, SAR
# for 1 W/m2 incident power density)
goliat_sheets <- data.frame(
  field   = rep(c("NF", "FF"), each = length(phantoms)),
  phantom = rep(phantoms, times = 2),
  sheet   = c(paste("NF", phantoms, "1W"), paste("FF", phantoms, "1W per m2")))

# Read one tab and add the interpolated frequencies
read_goliat_sheet <- function(field, phantom, sheet) {
  data <- readxl::read_excel(goliat_copy, sheet = sheet)
  simulated <- data.frame(
    field         = field,
    phantom       = phantom,
    frequency_mhz = data$frequency_mhz,
    # Ear placements are named "cheek_*" and "tilt_*" in the Excel file
    placement     = sub("^(cheek|tilt)_", "ear_\\1_", data$placement),
    SAR_wholebody = data$`SAR_wholebody (mW/kg)`,
    SAR_brain     = data$`SAR_brain (mW/kg)`)
  if (any(interp_freqs %in% simulated$frequency_mhz)) {
    stop("Tab '", sheet, "' already contains a frequency to interpolate.")
  }

  # Linear interpolation in frequency, per placement
  interpolated <- do.call(rbind, lapply(split(simulated, simulated$placement), function(d) {
    data.frame(
      field         = field,
      phantom       = phantom,
      frequency_mhz = interp_freqs,
      placement     = d$placement[1],
      SAR_wholebody = stats::approx(d$frequency_mhz, d$SAR_wholebody, xout = interp_freqs)$y,
      SAR_brain     = stats::approx(d$frequency_mhz, d$SAR_brain, xout = interp_freqs)$y)
  }))

  rows <- rbind(simulated, interpolated)
  rows[order(rows$frequency_mhz), ]
}

# One row per field x phantom x frequency x placement. SAR values in mW/kg
# (NF: for 1 W input power, FF: for 1 W/m2 incident power density).
goliat_sar <- do.call(rbind, Map(
  read_goliat_sheet, goliat_sheets$field, goliat_sheets$phantom, goliat_sheets$sheet))
rownames(goliat_sar) <- NULL
