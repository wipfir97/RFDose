# =============================================================================
# Import simulated SAR values from the phantom workbooks into the parameter yaml
# =============================================================================
#
# WHAT THIS REPLACES
#   R/sar_interpolation.R did this for Duke only. It read ONE hard-coded sheet at
#   a time (the `sheet` variable was edited by hand and the script re-run three
#   times), it relied on Excel having already normalised the values, and the
#   placement names it wrote were not yet the yaml key names -- that rename was
#   done by hand afterwards. It also lives in R/, which means it EXECUTES on every
#   devtools::load_all() and rewrites a csv in data/ as a side effect.
#   This script does the whole job for all four phantoms in one run.
#
#   Full write-up of the import, the data sources and their quirks:
#   doc/SAR_IMPORT_NOTES.md
#
# THE INTERPOLATION MECHANISM IS DELIBERATELY UNCHANGED.
#   Section 5 below uses the identical dplyr chain as the original
#   (complete -> arrange -> across(approx(rule = 1)) -> filter). This was verified
#   to be bit-for-bit identical to the original on all three of Duke's sheets, and
#   the whole pipeline reproduces Duke's 574 existing yaml values byte-for-byte
#   (see section 9).
#
# THE PIPELINE
#   1. read one sheet per phantom per position group          (section 4)
#   2. normalise every ROW to 1 W using that row's own power  (section 4)
#   3. interpolate onto the ten model frequencies             (section 5)
#   4. rename placements to the yaml key fragments            (section 3)
#   5. build the yaml lines and splice them into both files   (sections 6-8)
#
# HOW TO RUN
#   "C:/Program Files/R/R-4.4.3/bin/Rscript.exe" data-raw/import_sar.R
#   Nothing is written unless WRITE_YAML is TRUE. With WRITE_YAML = FALSE the
#   script still runs the full validation, which is the recommended dry run.
#
# WHEN NEW DATA ARRIVES
#   Add or edit one entry in SOURCES (section 2). Everything else adapts. If the
#   new workbook spells a column differently, extend COLPAT; if it names a
#   placement differently, extend rename_placement(). Both fail loudly rather
#   than guessing.
# =============================================================================

suppressMessages({library(readxl); library(dplyr); library(tidyr)})
options(stringsAsFactors = FALSE, warn = 1)

# =============================================================================
# 1. CONFIGURATION
# =============================================================================

REPO <- "c:/Users/kellfa/RFDose"
DATA <- file.path(REPO, "data-raw")   # the source workbooks live next to this script

YAML_FILES <- c(file.path(REPO, "inst/extdata/params_stochastic.yaml"),
                file.path(REPO, "inst/extdata/params_template.yaml"))

# Set to TRUE to actually modify the yaml files. FALSE = dry run + validation.
# Left at FALSE so that simply running the script is always safe; the validation
# in section 9 runs either way.
WRITE_YAML <- FALSE

# All four phantoms go through this one script, so the whole SAR table has a
# single, reproducible provenance. Duke was originally normalised inside Excel
# and imported by hand; regenerating him here changes 11 of his 574 lines:
#   - 6 brain values in the 7th significant digit, because two cells in his
#     workbook were typed in as rounded constants instead of formulas. Reading
#     the RAW sheets (as this script does) bypasses them, so these are corrections.
#   - 2 values in the last bit of a double, because Excel computed raw/P while
#     this script computes raw*1000/P. Now everything takes the same path.
#   - 4 lines of pure reordering: Duke_brain_goliat_5000_tilt1_sar sat after the
#     xxxx/yyyy/zzzz placeholders instead of before them, the only block in the
#     file where that was the case.
# See doc/SAR_IMPORT_NOTES.md 5.5.
PHANTOMS_TO_WRITE <- c("Duke", "Ella", "Thelonious", "Eartha")

# The nine frequencies the model uses. Changed from ten on 2026-09-28:
#   - 2400 -> 2450. 2400 MHz is the lower edge of the 2.4 GHz band, and neither
#     campaign simulated it; both simulated 2450, which lies inside the band.
#     The GOLIAT values at this band therefore stop being interpolated and
#     become native simulations.
#   - 1450 dropped. It was never in the deterministic model, ETAIN has no node
#     within 350 MHz of it, and f1450_4g_prop_mean was already 0.0, so it
#     carried no exposure.
# The result is identical to ETAIN's near-field grid, so the ETAIN import needs
# no interpolation and no substitution rule. See doc/SAR_REDESIGN.md Q4.
TARGET_FREQ <- c(700, 800, 900, 1800, 2100, 2450, 2600, 3500, 5000)

# Reserved slots for future 5G/6G bands. They stay 0 and are not touched here.
PLACEHOLDER_FREQ <- c("xxxx", "yyyy", "zzzz")

# yaml tissue name -> which column of the workbook feeds it
TISSUES <- c(body = "wholebody", brain = "brain")

# =============================================================================
# 2. SOURCE INVENTORY
#    One entry per phantom. The sheet names are not consistent between the
#    providing institutes, hence the explicit mapping. Note "Ella_ ear" really
#    does contain a space after the underscore.
#
#    2026-09-17: Thelonious and Eartha switched to UGent's consolidated workbook
#    Final_Data_UGent_normalized.xlsx, which supersedes the two per-phantom files
#    Final_Data_UGent_{Thelonious,Eartha}_NF.xlsx. UGent's covering mail: the
#    earlier delivery "had a mix-up for the head and trunk SAR data".
#
#    That mix-up does NOT affect this import. Verified column by column against
#    the superseded files:
#      SAR_wholebody  identical (max rel. deviation 8e-13, floating point noise)
#      SAR_brain      identical (exactly 0)
#      input power, frequencies, placements   identical
#      SAR_head, SAR_trunk                    recomputed, factors 0.1x to 22x
#      psSAR10g_eyes/skin/brain               newly added
#    TISSUES below reads only wholebody and brain, so no yaml value changes.
#    The switch is made anyway so the repo points at the authoritative file, and
#    because the new workbook ships usable *_normalized sheets (validation C).
#
#    Naming changes that came with it, both absorbed by section 3b:
#      sheet      Thelonious_cheek -> Thelonious_ear
#      placement  cheek_1_base     -> cheek_1     (the descriptive suffixes are
#                                                  gone; the ordinal number is
#                                                  the identifier, as assumed in
#                                                  doc/SAR_IMPORT_NOTES.md 5.4)
# =============================================================================

SOURCES <- list(
  Duke = list(
    file   = "Duke_male_adult_NF.xlsx",
    sheets = c(fronteyes = "Duke_fronteyes", belly = "Duke_belly", ear = "Duke_ear")),
  Ella = list(
    file   = "Final_Data_TP_Ella_NF_normalized.xlsx",
    sheets = c(fronteyes = "Ella_front", belly = "Ella_belly", ear = "Ella_ ear")),
  Thelonious = list(
    file   = "Final_Data_UGent_normalized.xlsx",
    sheets = c(fronteyes = "Thelonious_fronteyes", belly = "Thelonious_belly",
               ear = "Thelonious_ear")),
  Eartha = list(
    file   = "Final_Data_UGent_normalized.xlsx",
    sheets = c(fronteyes = "Eartha_fronteyes", belly = "Eartha_belly",
               ear = "Eartha_ear"))
)

# =============================================================================
# 2b. ETAIN SOURCE INVENTORY                                   (added 2026-09-28)
#
#    The second SAR campaign. Two files, whole body and brain, each holding all
#    nine near-field scenarios for Duke and Ella side by side. Its frequencies
#    are exactly TARGET_FREQ, so nothing is interpolated -- section 5 asserts
#    that rather than assuming it.
#
#    Three differences from the GOLIAT workbooks:
#      - values are ALREADY per 1 W (column header "[mW/kg/W]"), so the
#        normalisation of section 4 must not be applied a second time. Verified
#        by the absorbed-power check in section 9: 6.7 % at 30 cm up to 91 % for
#        an earbud in the ear, and GOLIAT's ear at 1800 MHz agrees to within
#        4 percentage points.
#      - one row per (scenario, frequency) with the phantoms in COLUMNS, where
#        GOLIAT has one row per (frequency, placement) per phantom.
#      - the scenario column is written once per block and left blank below, so
#        it has to be filled down.
#
#    Only Duke and Ella were simulated. Thelonious and Eartha get the same key
#    grid filled with zeros; the child ratios that will populate them are a
#    separate step, see doc/SAR_REDESIGN.md Q3.
# =============================================================================

ETAIN_FILES <- c(wholebody = "NF_SARwb_LessThan6GHz_WholeBody.xlsx",
                 brain     = "NF_SARosa_LessThan6GHz_Brain.xlsx")

ETAIN_PHANTOMS <- c("Duke", "Ella")

# Scenario number -> yaml key fragment. The numbering is ETAIN's own and is
# confirmed by the data itself: scenario 1 has a brain SAR of 40.8 mW/kg/W at
# 1800 MHz and scenario 4 has 0.0007, which can only be the ear and the hip.
# Scenarios 7-9 exist at fewer frequencies, exactly as the campaign specifies.
ETAIN_POS_ORDER <- c(
  "1" = "ear",       # 45 deg tilted, 1 cm from the right ear   -> phone call
  "2" = "mouth10",   # vertical, 10 cm in front of the mouth    -> speaker mode
  "3" = "mouth30",   # vertical, 30 cm in front of the mouth    -> phone data
  "4" = "hip",       # vertical on the right hip, 1 cm          -> in pocket
  "5" = "lap",       # on the legs, phantom seated              -> laptop/tablet
  "6" = "table",     # 10 cm higher and 30 cm further than 5    -> laptop/tablet
  "7" = "earbud_r",  # next to the right ear, 1 mm              -> Bluetooth
  "8" = "earbud_l",  # next to the left ear, 1 mm               -> Bluetooth
  "9" = "wrist"      # horizontal on the right wrist, 1 mm      -> smartwatch
)

# The 22 position fragments as they appear in the yaml keys. Any placement that
# does not map into this set aborts the run.
POS_ORDER <- c(
  paste0("front_of_eyes_", c("center_horizontal","center_vertical",
                             "down_horizontal","down_vertical",
                             "left_horizontal","left_vertical",
                             "right_horizontal","right_vertical")),
  paste0("cheek", 1:3), paste0("tilt", 1:3),
  paste0("belly_", c("center_horizontal","center_vertical",
                     "left_horizontal","left_vertical",
                     "right_horizontal","right_vertical",
                     "up_horizontal","up_vertical"))
)
FREQ_ORDER <- c(as.character(TARGET_FREQ), PLACEHOLDER_FREQ)

# =============================================================================
# 3. NAME HANDLING
# =============================================================================

# --- 3a. column names -------------------------------------------------------
# The institutes spell the same column differently. Real variants in the data:
#   frequency_mhz            vs  frequency_MHz
#   "Input Power (mW)"       vs  "Input power (mW)" (Duke's ear sheet, lowercase p)
#                            vs  "Input Power  (mW)" (Ella, two spaces)
#   "SAR_brain (mW/kg)"      vs  "SAR averagedbrain(mW/kg)" (Ella)
# Column ORDER also differs (Ella has trunk before brain), so columns must be
# resolved by name, never by position.
canon <- function(nm) {
  nm <- tolower(nm)
  nm <- gsub("[ _]+", "_", nm)
  gsub("^_|_$", "", nm)
}

COLPAT <- c(
  freq      = "^frequency",
  power     = "^input_power",
  placement = "^placement$",
  wholebody = "^sar_wholebody",
  # matches sar_brain AND "sar averagedbrain"; anchored so it cannot catch
  # pssar10g_brain
  brain     = "^sar_(averaged)?brain"
)

pick_col <- function(df, pattern, what, sheet) {
  hit <- grep(pattern, canon(names(df)))
  if (length(hit) != 1L)
    stop(sprintf("sheet '%s': expected exactly 1 column matching %s (%s), found %d: %s",
                 sheet, what, pattern, length(hit), paste(names(df)[hit], collapse = " | ")))
  names(df)[hit]
}

# --- 3b. placement names ----------------------------------------------------
# The original script wrote the placement verbatim; the rename to the yaml key
# fragment was a manual step. It is explicit here.
#   belly_level_center_vertical -> belly_center_vertical   (drop the "level_")
#   cheek_1                     -> cheek1                  (Duke, Ella)
#   cheek_1_base                -> cheek1                  (UGent)
#   tilt_3_down                 -> tilt3                   (UGent)
#   front_of_eyes_*             -> unchanged
#
# The UGent suffixes (_base/_up/_down) are mapped by ordinal number. This is
# correct because the phantom placements are standardised setups in the modelling
# software, so the same number denotes the same geometry across institutes and the
# suffixes are only a descriptive addition. See doc/SAR_IMPORT_NOTES.md 5.4.
rename_placement <- function(p) {
  out <- sub("^belly_level_", "belly_", p)
  out <- sub("^(cheek|tilt)_([123])(_base|_up|_down)?$", "\\1\\2", out)
  bad <- !out %in% POS_ORDER
  if (any(bad))
    stop("placement(s) did not map to a known yaml position fragment: ",
         paste(unique(paste0(p[bad], " -> ", out[bad])), collapse = ", "))
  out
}

# =============================================================================
# 4. READ ONE SHEET AND NORMALISE IT TO 1 W
#
#    SAR_1W [mW/kg] = SAR_raw [mW/kg] * 1000 / InputPower_row [mW]
#
#    PER ROW, not per sheet. The input power is not constant: it varies with
#    frequency in every sheet of every workbook. Duke/Thelonious/Eartha use
#    267/228/106/78/74/55/53/54 mW at 700/835/1450/2140/2450/3500/5200/5800 MHz;
#    Ella uses 813/636.9/131.7/85.5/72.5/58/64.5/64.9. Applying a single scale
#    factor would be wrong by up to 80 %.
#
#    ORDER MATTERS: normalise first, THEN interpolate. Doing it the other way
#    round (interpolate the raw SAR, then divide by an interpolated power)
#    changes the result by about 2 %. Duke's original pipeline also normalised
#    first, because Excel had already done it in the *_normalized sheets.
# =============================================================================

read_and_normalise <- function(phantom, group, verbose = TRUE) {
  src   <- SOURCES[[phantom]]
  sheet <- src$sheets[[group]]
  df    <- suppressMessages(read_excel(file.path(DATA, src$file), sheet = sheet))

  cols <- vapply(names(COLPAT), function(k) pick_col(df, COLPAT[[k]], k, sheet), character(1))

  # Guards. readxl types a whole column as character if a single cell holds text
  # -- Duke's SAR_trunk really is character because one cell contains "<<<".
  # Silently coercing would turn such a value into NA, so we refuse instead.
  for (nm in c("freq", "power", "wholebody", "brain")) {
    v <- df[[cols[[nm]]]]
    if (!is.numeric(v))
      stop(sprintf("sheet '%s': column '%s' (%s) is %s, not numeric",
                   sheet, cols[[nm]], nm, class(v)[1]))
    if (anyNA(v))
      stop(sprintf("sheet '%s': column '%s' has %d NA", sheet, cols[[nm]], sum(is.na(v))))
  }
  plc <- df[[cols[["placement"]]]]
  pwr <- df[[cols[["power"]]]]
  if (any(pwr <= 0))            stop(sprintf("sheet '%s': non-positive input power", sheet))
  if (anyNA(plc) || any(!nzchar(plc))) stop(sprintf("sheet '%s': blank placement", sheet))
  if (any(duplicated(paste(df[[cols[["freq"]]]], plc))))
    stop(sprintf("sheet '%s': duplicate (frequency, placement)", sheet))

  out <- tibble(
    phantom       = phantom,
    group         = group,
    frequency_mhz = as.numeric(df[[cols[["freq"]]]]),
    placement     = rename_placement(plc),
    power_mw      = as.numeric(pwr),           # kept only for the report below
    wholebody     = as.numeric(df[[cols[["wholebody"]]]]) * 1000 / as.numeric(pwr),
    brain         = as.numeric(df[[cols[["brain"]]]])     * 1000 / as.numeric(pwr)
  )
  if (verbose)
    cat(sprintf("  %-11s %-9s sheet=%-24s rows=%3d positions=%d freqs=%d\n",
                phantom, group, paste0("'", sheet, "'"), nrow(out),
                n_distinct(out$placement), n_distinct(out$frequency_mhz)))
  out
}

# =============================================================================
# 4b. READ THE ETAIN CAMPAIGN                                  (added 2026-09-28)
#
#    Returns the same tidy shape as read_and_normalise() so that everything
#    downstream -- interpolation, key building, splicing -- treats the two
#    campaigns identically. No normalisation: see the note in section 2b.
# =============================================================================

read_etain <- function(verbose = TRUE) {
  one <- function(tissue_col, file) {
    df <- suppressMessages(read_excel(file.path(DATA, file), sheet = 1))
    names(df)[1:4] <- c("scen", "freq", "Duke", "Ella")
    # the scenario number is written once per block and blank below it
    df$scen <- tidyr::fill(data.frame(s = df$scen), s)$s
    df <- df[!is.na(df$freq), ]
    for (nm in c("freq", ETAIN_PHANTOMS)) {
      if (!is.numeric(df[[nm]]))
        stop(sprintf("ETAIN file '%s': column '%s' is %s, not numeric",
                     file, nm, class(df[[nm]])[1]))
      if (anyNA(df[[nm]]))
        stop(sprintf("ETAIN file '%s': column '%s' has %d NA",
                     file, nm, sum(is.na(df[[nm]]))))
    }
    bad <- !as.character(df$scen) %in% names(ETAIN_POS_ORDER)
    if (any(bad))
      stop("ETAIN scenario(s) not in ETAIN_POS_ORDER: ",
           paste(unique(df$scen[bad]), collapse = ", "))
    if (any(duplicated(paste(df$scen, df$freq))))
      stop(sprintf("ETAIN file '%s': duplicate (scenario, frequency)", file))
    out <- tidyr::pivot_longer(df[, c("scen", "freq", ETAIN_PHANTOMS)],
                               cols = all_of(ETAIN_PHANTOMS),
                               names_to = "phantom", values_to = tissue_col)
    out$placement <- unname(ETAIN_POS_ORDER[as.character(out$scen)])
    out[, c("phantom", "freq", "placement", tissue_col)]
  }
  wb <- one("wholebody", ETAIN_FILES[["wholebody"]])
  br <- one("brain",     ETAIN_FILES[["brain"]])
  # the two files must describe exactly the same (phantom, frequency, scenario)
  # grid, otherwise a join would silently drop or duplicate rows
  k <- function(d) paste(d$phantom, d$freq, d$placement)
  if (!setequal(k(wb), k(br)) || nrow(wb) != nrow(br))
    stop("the ETAIN whole-body and brain files do not cover the same grid")
  out <- merge(wb, br, by = c("phantom", "freq", "placement"))
  out <- tibble(
    phantom       = out$phantom,
    group         = "etain",
    frequency_mhz = as.numeric(out$freq),
    placement     = out$placement,
    power_mw      = NA_real_,        # already per 1 W, nothing to divide by
    wholebody     = as.numeric(out$wholebody),
    brain         = as.numeric(out$brain)
  )
  if (verbose)
    for (ph in ETAIN_PHANTOMS) {
      s <- out[out$phantom == ph, ]
      cat(sprintf("  %-11s %-9s files=%-24s rows=%3d scenarios=%d freqs=%d\n",
                  ph, "etain", "'NF_SARwb / NF_SARosa'", nrow(s),
                  n_distinct(s$placement), n_distinct(s$frequency_mhz)))
    }
  out
}

# =============================================================================
# 5. INTERPOLATION  --  the mechanism of R/sar_interpolation.R, unchanged
#
#    For each placement:
#      complete()  adds the target frequencies that were not simulated, as NA rows
#                  (frequencies that WERE simulated are not duplicated)
#      arrange()   sorts so the NA rows sit between their neighbours
#      approx()    uses the non-NA rows as interpolation nodes and fills the holes
#                  linearly. rule = 1 -> NA outside the simulated range.
#      filter()    drops the helper frequencies again, keeping only the ten targets
#
#    Worked example, placement belly_center_vertical, target 1800 MHz:
#      node 1450 MHz = 2.11772388847773
#      node 2140 MHz = 2.04041745974355
#      w = (1800-1450)/(2140-1450) = 0.5072464
#      2.11772388847773 + w*(2.04041745974355 - 2.11772388847773)
#        = 2.07851048259807   <- exactly what stands in the yaml today
# =============================================================================

interpolate <- function(d) {
  d %>%
    group_by(phantom, group, placement) %>%
    complete(frequency_mhz = TARGET_FREQ) %>%
    arrange(frequency_mhz, .by_group = TRUE) %>%
    mutate(across(
      all_of(c("wholebody", "brain")),
      ~ approx(x    = frequency_mhz[!is.na(.x)],
               y    = .x[!is.na(.x)],
               xout = frequency_mhz,
               rule = 1)$y)) %>%
    filter(frequency_mhz %in% TARGET_FREQ) %>%
    ungroup()
}

# =============================================================================
# 6. YAML LINES
#    Format must match Duke's existing lines exactly: 8 spaces of indent, one
#    space after the colon, and paste0() for the number. paste0() gives R's
#    15-significant-digit representation, which is what produced every existing
#    value. Do NOT substitute as.character(): its behaviour for doubles changed
#    in R 4.3 and it is no longer equivalent in general.
# =============================================================================

#    Since 2026-09-28 the campaign is part of the key:
#      <phantom>_<tissue>_<campaign>_<frequency>_<placement>_sar
#    The two campaigns disagree by up to a factor of two (doc/SAR_REDESIGN.md
#    3.1), so which one a value came from has to be readable off the key rather
#    than inferred from the placement name. headp_else keeps its old shape --
#    it is a legacy placeholder belonging to neither campaign.
#
#    The three reserved 5G/6G placeholder bands exist in the GOLIAT block only.
#    They are a slot reservation in the model's band list, not campaign data,
#    and duplicating them under both campaigns would reserve the same slot twice.

build_block <- function(interp, phantom, tissue) {
  col <- TISSUES[[tissue]]

  grid <- function(campaign, positions, freqs)
    as.vector(t(outer(positions, freqs,
                      function(p, f) sprintf("%s_%s_%s_%s_%s_sar",
                                             phantom, tissue, campaign, f, p))))

  keys <- c(
    sprintf("%s_%s_headp_else_sar", phantom, tissue),
    grid("goliat", POS_ORDER, FREQ_ORDER),
    grid("etain", unname(ETAIN_POS_ORDER), as.character(TARGET_FREQ))
  )
  v <- setNames(rep(0, length(keys)), keys)   # placeholders and headp_else stay 0

  src <- interp[interp$phantom == phantom, ]
  camp <- ifelse(src$group == "etain", "etain", "goliat")
  k <- sprintf("%s_%s_%s_%s_%s_sar",
               phantom, tissue, camp, src$frequency_mhz, src$placement)
  stopifnot(!any(duplicated(k)), all(k %in% keys))
  v[k] <- src[[col]]

  paste0("        ", names(v), ": ", fmt(unname(v)))
}

# Number formatting. paste0() is kept for every value it can render plainly,
# because that is what produced all existing yaml values and validation B
# reproduces them byte for byte.
#
# ETAIN's brain values for the hip, lap, table and wrist scenarios reach down to
# about 1e-7, where paste0() switches to scientific notation -- and that cannot
# go into the yaml. YAML 1.1 only recognises a float in exponent form if the
# mantissa carries a decimal point, so "2e-06" is read back as the CHARACTER
# STRING "2e-06" while "2.0e-06" is read as a number. A SAR value silently
# turning into text is exactly the kind of failure the guard in splice() exists
# to prevent, so the value is written in full decimal instead.
# format() must be called one value at a time: given a vector it chooses a
# single layout for all of it and pads every element to the decimal places the
# smallest one needs, which writes digits past what a double can carry.
fmt <- function(x) {
  s   <- paste0(x)
  sci <- grepl("[eE][+-]?[0-9]", s)
  if (any(sci))
    s[sci] <- vapply(x[sci],
                     function(z) trimws(format(z, scientific = FALSE, digits = 15)),
                     character(1))
  s
}

# =============================================================================
# 7. SPLICE INTO A YAML FILE
#    Locates each phantom's body:/brain: key run by scanning for the headers,
#    replaces it in place, and asserts that nothing outside those runs moved.
#    Written as binary with CRLF to match the existing files.
# =============================================================================

splice <- function(path, blocks, phantoms) {
  old <- readLines(path, warn = FALSE)
  ln  <- old
  for (ph in phantoms) {
    dh <- grep(sprintf("^    %s:\\s*$", ph), ln)
    stopifnot(length(dh) == 1L)
    for (tis in names(TISSUES)) {
      th <- grep(sprintf("^      %s:\\s*$", tis), ln)
      th <- th[th > dh][1]
      stopifnot(!is.na(th))
      i <- th + 1L
      keyre <- sprintf("^        %s_%s_[A-Za-z0-9_]+_sar: ", ph, tis)
      while (i <= length(ln) && grepl(keyre, ln[i])) i <- i + 1L
      new <- blocks[[paste(ph, tis)]]
      ln <- c(ln[seq_len(th)], new, if (i <= length(ln)) ln[i:length(ln)] else character(0))
    }
  }
  # Safety. Until 2026-09-28 this compared the two files line for line, which
  # worked because every re-import wrote the same number of keys. The frequency
  # grid change of that date drops 1450 MHz and renames 2400 to 2450, so the
  # block length legitimately differs and that comparison no longer applies.
  # The check below is the stronger statement it was standing in for: strip the
  # SAR key lines of the phantoms being written from both files, and what is
  # left must be identical and in the same order.
  sarre <- sprintf("^        (%s)_(body|brain)_[A-Za-z0-9_]+_sar: ",
                   paste(phantoms, collapse = "|"))
  stopifnot(identical(old[!grepl(sarre, old)], ln[!grepl(sarre, ln)]))
  chg <- which(grepl(sarre, ln))
  stopifnot(!any(grepl("[eE][+-][0-9]", ln[chg])))   # no scientific notation
  list(lines = ln, changed = chg)
}

# =============================================================================
# 8. RUN
# =============================================================================

cat("\n--- 1-2. read and normalise ------------------------------------------\n")
raw <- bind_rows(lapply(names(SOURCES), function(p)
  bind_rows(lapply(names(SOURCES[[p]]$sheets), function(g) read_and_normalise(p, g)))))

etain <- read_etain()
raw   <- bind_rows(raw, etain)

cat("\ninput power per frequency (mW) -- note it is NOT constant:\n")
print(as.data.frame(
  raw %>% filter(group != "etain") %>%
    distinct(phantom, frequency_mhz, power_mw) %>%
    tidyr::pivot_wider(names_from = frequency_mhz, values_from = power_mw)),
  row.names = FALSE)

cat("\n--- 3. interpolate ---------------------------------------------------\n")

# GOLIAT only. ETAIN must NOT go through interpolate(): its scenarios do not all
# cover the same frequencies -- the earbuds were simulated at 2450 and 5000 MHz
# only, the wrist at 2450 alone -- so complete() would insert the other target
# frequencies as NA and approx() would then invent an earbud value at 2600 and
# 3500 MHz by interpolating across the gap, and leave NA below 2450. Those
# combinations were not simulated and stay 0, which build_block() does anyway.
goliat <- raw %>% filter(group != "etain")
etain  <- raw %>% filter(group == "etain")

interp <- interpolate(goliat)

# The claim that the model grid equals ETAIN's grid is checked, not assumed.
# If ETAIN ever delivers a frequency the model does not carry, that value would
# be silently dropped by build_block(), so refuse instead.
extra <- setdiff(unique(etain$frequency_mhz), TARGET_FREQ)
if (length(extra) > 0)
  stop("ETAIN simulated frequencies that are not model bands: ",
       paste(sort(extra), collapse = ", "),
       ". Either the grid or ETAIN_POS_ORDER needs updating.")

interp <- bind_rows(interp, etain)

na_rows <- sum(is.na(interp$wholebody) | is.na(interp$brain))
if (na_rows > 0)
  stop(sprintf("%d interpolated values are NA -- a target frequency lies outside the ",
               na_rows),
       "simulated range. Refusing to continue: writing 0 would be indistinguishable ",
       "from 'this phantom has no data yet', which is what the model uses 0 for.")
cat(sprintf("  GOLIAT %d values interpolated onto the %d model bands [%g, %g]\n",
            sum(interp$group != "etain") * 2, length(TARGET_FREQ),
            min(goliat$frequency_mhz), max(goliat$frequency_mhz)))
cat(sprintf("  ETAIN  %d values taken as simulated, no interpolation needed\n",
            nrow(etain) * 2))

cat("\n--- 4. build yaml blocks ---------------------------------------------\n")
blocks <- list()
for (ph in names(SOURCES)) for (tis in names(TISSUES)) {
  blocks[[paste(ph, tis)]] <- build_block(interp, ph, tis)
}
# Key arithmetic per tissue, so the figures in the docs are traceable:
#   346 keys  = 1 headp_else
#             + 22 GOLIAT positions x 12 frequency tokens (9 bands + 3 reserved)
#             +  9 ETAIN scenarios  x  9 bands
#   real, Duke and Ella: 198 GOLIAT (22 x 9) + 59 ETAIN (6 scenarios x 9 bands,
#   plus 2 earbud scenarios x 2 bands and the wrist at 2450 alone)
#   Thelonious and Eartha have the same 81 ETAIN keys, all zero until the child
#   ratios are applied -- see doc/SAR_REDESIGN.md Q3.
for (ph in names(SOURCES)) {
  both  <- c(blocks[[paste(ph, "body")]], blocks[[paste(ph, "brain")]])
  zeros <- sum(grepl(": 0$", both))
  cat(sprintf("  %-11s per tissue: %3d keys, %3d real, %2d zero  |  per phantom: %3d / %3d / %3d\n",
              ph, length(both)/2, (length(both) - zeros)/2, zeros/2,
              length(both), length(both) - zeros, zeros))
}

# =============================================================================
# 9. VALIDATION -- reproduce Duke's existing yaml values
#    This is the acceptance test. Duke's numbers were produced by the original
#    pipeline; if this script cannot reproduce them, it is wrong.
# =============================================================================

cat("\n--- 5. validation A: the interpolation IS the original mechanism -----\n")
# Section 5 above is the dplyr chain of R/sar_interpolation.R. This check runs the
# ORIGINAL in its original form -- on the *_normalized sheets, with num_cols taken
# as "every numeric column except frequency_mhz", exactly as the old script did --
# and compares it against section 5 fed the identical values. If someone ever
# refactors interpolate(), this fails.
mechanism_ok <- TRUE
for (sheet in c("Duke_fronteyes_normalized", "Duke_belly_normalized", "Duke_ear_normalized")) {
  d <- suppressMessages(read_excel(file.path(DATA, SOURCES$Duke$file), sheet = sheet))
  d <- dplyr::select(d, -`Average_brain (W/kg)`, -`Average_WB (W/kg)`)
  d$`SAR_trunk (mW/kg)` <- suppressWarnings(as.numeric(d$`SAR_trunk (mW/kg)`))

  # (a) the original chain, verbatim
  nc <- d %>% select(where(is.numeric), -frequency_mhz) %>% names()
  a <- d %>% group_by(placement) %>%
    complete(frequency_mhz = TARGET_FREQ) %>%
    arrange(frequency_mhz, .by_group = TRUE) %>%
    mutate(across(all_of(nc),
                  ~ approx(x = frequency_mhz[!is.na(.x)], y = .x[!is.na(.x)],
                           xout = frequency_mhz, rule = 1)$y)) %>%
    filter(frequency_mhz %in% TARGET_FREQ) %>% ungroup() %>%
    arrange(placement, frequency_mhz)

  # (b) section 5 of this script, same input values
  b <- d %>% transmute(phantom = "Duke", group = sheet, placement, frequency_mhz,
                       wholebody = `SAR_wholebody (mW/kg)`,
                       brain     = `SAR_brain (mW/kg)`) %>%
    interpolate() %>% arrange(placement, frequency_mhz)

  same <- identical(a$`SAR_wholebody (mW/kg)`, b$wholebody) &&
          identical(a$`SAR_brain (mW/kg)`,     b$brain)
  cat(sprintf("  %-28s %3d values  bit-identical: %s\n", sheet, nrow(b) * 2, same))
  mechanism_ok <- mechanism_ok && same
}
if (!mechanism_ok)
  stop("the interpolation no longer matches the mechanism of R/sar_interpolation.R")

cat("\n--- 6. validation B: reproduce Duke's existing yaml values -----------\n")
# Compares this script's output against what already stands in the yaml, so it
# only covers keys present in both. Two renames have happened since it was
# written, and it must survive the transition run in each direction:
#   2026-09-28a  the frequency grid changed, so the 1450 and 2400 keys vanish
#                and 2450 appears -- those simply do not merge and are skipped
#   2026-09-28b  the campaign segment was added, so every GOLIAT key changed
#                name while keeping its value
# The campaign segment is therefore stripped from both sides before matching.
# Once the yaml carries the new names this is a no-op and the check is exact
# again; while a rename is in flight it still compares the values.
yl   <- readLines(YAML_FILES[1], warn = FALSE)
duke <- grep("^        Duke_(body|brain)_[A-Za-z0-9_]+_sar: ", yl, value = TRUE)
mine <- c(blocks[["Duke body"]], blocks[["Duke brain"]])
key   <- function(x) sub("^\\s*([^:]+):.*$", "\\1", x)
val   <- function(x) sub("^[^:]+:\\s*", "", x)
strip <- function(k) sub("^(Duke_(body|brain))_(goliat|etain)_", "\\1_", k)
cmp  <- merge(data.frame(k = strip(key(duke)), yaml = val(duke)),
              data.frame(k = strip(key(mine)), mine = val(mine)), by = "k")
same <- cmp$yaml == cmp$mine
cat(sprintf("  %d of %d Duke values reproduced byte-identically\n", sum(same), nrow(cmp)))
if (any(!same)) {
  d <- cmp[!same, ]
  d$rel <- abs(as.numeric(d$yaml) - as.numeric(d$mine)) / abs(as.numeric(d$yaml))
  cat(sprintf("  max relative deviation: %.3g\n", max(d$rel)))
  cat("  differing keys (expected: 6 tilt keys, see SAR_IMPORT_NOTES.md 5.5):\n")
  print(d[order(-d$rel), c("k","yaml","mine")], row.names = FALSE)
}

cat("\n--- 7. validation C: our 1 W normalisation vs the institutes' own ----\n")
# Every workbook ships a "<sheet>_normalized" companion in which the institute
# normalised to 1 W itself. Section 4 does that division independently, so the
# two must agree. Until UGent's consolidated workbook arrived this check was only
# possible for Duke; it now covers three of the four phantoms.
#
# Ella is the exception: TP shipped her _normalized sheets as empty placeholders
# (every SAR column blank), so there is nothing to compare against and our own
# normalisation is the only derivation of her values.
#
# Duke is expected to show ~1e-7 in exactly 2 of his ear brain cells. Those two
# cells were typed into his workbook as rounded constants rather than formulas;
# this script reads the RAW sheet and so bypasses them. See SAR_IMPORT_NOTES 5.5.
NORM_TOL <- 1e-6   # above this the two derivations genuinely disagree
norm_ok  <- TRUE
for (ph in names(SOURCES)) {
  for (grp in names(SOURCES[[ph]]$sheets)) {
    raw_sheet <- SOURCES[[ph]]$sheets[[grp]]
    nrm_sheet <- paste0(raw_sheet, "_normalized")
    path      <- file.path(DATA, SOURCES[[ph]]$file)

    if (!nrm_sheet %in% excel_sheets(path)) {
      cat(sprintf("  %-11s %-9s no _normalized companion -- skipped\n", ph, grp))
      next
    }
    d <- suppressMessages(read_excel(path, sheet = nrm_sheet))
    cols <- vapply(names(COLPAT), function(k) pick_col(d, COLPAT[[k]], k, nrm_sheet),
                   character(1))
    theirs <- tibble(
      placement     = rename_placement(d[[cols[["placement"]]]]),
      frequency_mhz = as.numeric(d[[cols[["freq"]]]]),
      wholebody     = suppressWarnings(as.numeric(d[[cols[["wholebody"]]]])),
      brain         = suppressWarnings(as.numeric(d[[cols[["brain"]]]]))
    ) %>% arrange(placement, frequency_mhz)

    if (all(is.na(theirs$wholebody)) && all(is.na(theirs$brain))) {
      cat(sprintf("  %-11s %-9s _normalized sheet is empty -- skipped\n", ph, grp))
      next
    }
    ours <- read_and_normalise(ph, grp, verbose = FALSE) %>%
      arrange(placement, frequency_mhz)
    stopifnot(identical(ours$placement,     theirs$placement),
              identical(ours$frequency_mhz, theirs$frequency_mhz))

    dev  <- c(abs(ours$wholebody / theirs$wholebody - 1),
              abs(ours$brain     / theirs$brain     - 1))
    worst <- max(dev, na.rm = TRUE)
    cat(sprintf("  %-11s %-9s %3d values  max rel. deviation %8.2e  (%d above 1e-12)  %s\n",
                ph, grp, length(dev), worst, sum(dev > 1e-12, na.rm = TRUE),
                if (worst < NORM_TOL) "ok" else "MISMATCH"))
    norm_ok <- norm_ok && worst < NORM_TOL
  }
}
if (!norm_ok)
  stop("our 1 W normalisation disagrees with an institute's _normalized sheet")

# =============================================================================
# 9d. VALIDATION D: the ETAIN values are not normalised twice  (added 2026-09-28)
#
#    The GOLIAT sheets hold raw SAR and section 4 divides by the input power.
#    The ETAIN files are already per 1 W, so section 4b must NOT divide again.
#    A second division would shrink every value by a factor of roughly 500, and
#    nothing else in the pipeline would notice.
#
#    The check is physical: at 1 W of input power the body cannot absorb more
#    than 1 W, so SAR [mW/kg/W] * mass [kg] / 1000 must stay below 1. A wrongly
#    divided value would come out around 0.0001 instead of the tenths seen for a
#    device in contact with the body, so the test also catches the error by
#    being far too small, not only by exceeding 1.
#
#    Masses are the IT'IS figures for the Virtual Population phantoms. They are
#    not stored in the model -- see doc/MODEL_LIMITATIONS.md C5 -- so they are
#    repeated here.
# =============================================================================

cat("\n--- 7d. validation D: ETAIN absorbed power is physical ---------------\n")
PHANTOM_MASS_KG <- c(Duke = 70.2, Ella = 57.3, Thelonious = 18.6, Eartha = 29.0)
et_ok <- TRUE
for (ph in ETAIN_PHANTOMS) {
  s <- etain[etain$phantom == ph, ]
  fr <- s$wholebody * PHANTOM_MASS_KG[[ph]] / 1000
  worst <- s$placement[which.max(fr)]
  cat(sprintf("  %-11s absorbed fraction %.3f to %.3f  (largest: %s)\n",
              ph, min(fr), max(fr), worst))
  if (max(fr) >= 1 || max(fr) < 0.01) et_ok <- FALSE
}
if (!et_ok)
  stop("ETAIN absorbed fractions are outside the plausible range -- the values ",
       "are probably normalised twice, or not at all")

# =============================================================================
# 10. WRITE
# =============================================================================

cat("\n--- 8. write ---------------------------------------------------------\n")
if (!WRITE_YAML) {
  cat("  WRITE_YAML is FALSE -- dry run, nothing written.\n")
  cat("  Set WRITE_YAML <- TRUE at the top to apply.\n")
} else {
  for (path in YAML_FILES) {
    r <- splice(path, blocks, PHANTOMS_TO_WRITE)
    con <- file(path, open = "wb"); writeLines(r$lines, con, sep = "\r\n"); close(con)
    cat(sprintf("  %s: %d lines changed (%s)\n", basename(path), length(r$changed),
                paste(PHANTOMS_TO_WRITE, collapse = ", ")))
  }
}
cat("\ndone\n")
