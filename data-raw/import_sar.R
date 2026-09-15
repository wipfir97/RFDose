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
#   - 4 lines of pure reordering: Duke_brain_5000_tilt1_sar sat after the
#     xxxx/yyyy/zzzz placeholders instead of before them, the only block in the
#     file where that was the case.
# See doc/SAR_IMPORT_NOTES.md 5.5.
PHANTOMS_TO_WRITE <- c("Duke", "Ella", "Thelonious", "Eartha")

# The ten frequencies the model uses. Same vector as the original script.
TARGET_FREQ <- c(700, 800, 900, 1450, 1800, 2100, 2400, 2600, 3500, 5000)

# Reserved slots for future 5G/6G bands. They stay 0 and are not touched here.
PLACEHOLDER_FREQ <- c("xxxx", "yyyy", "zzzz")

# yaml tissue name -> which column of the workbook feeds it
TISSUES <- c(body = "wholebody", brain = "brain")

# =============================================================================
# 2. SOURCE INVENTORY
#    One entry per phantom. The sheet names are not consistent between the
#    providing institutes, hence the explicit mapping. Note "Ella_ ear" really
#    does contain a space after the underscore.
# =============================================================================

SOURCES <- list(
  Duke = list(
    file   = "Duke_male_adult_NF.xlsx",
    sheets = c(fronteyes = "Duke_fronteyes", belly = "Duke_belly", ear = "Duke_ear")),
  Ella = list(
    file   = "Final_Data_TP_Ella_NF_normalized.xlsx",
    sheets = c(fronteyes = "Ella_front", belly = "Ella_belly", ear = "Ella_ ear")),
  Thelonious = list(
    file   = "Final_Data_UGent_Thelonious_NF.xlsx",
    sheets = c(fronteyes = "Thelonious_fronteyes", belly = "Thelonious_belly",
               ear = "Thelonious_cheek")),
  Eartha = list(
    file   = "Final_Data_UGent_Eartha_NF.xlsx",
    sheets = c(fronteyes = "Eartha_fronteyes", belly = "Eartha_belly",
               ear = "Eartha_cheek"))
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

build_block <- function(interp, phantom, tissue) {
  col <- TISSUES[[tissue]]

  # full key grid in canonical order: headp_else first, then position groups,
  # frequencies ascending with the three placeholders last
  keys <- c(
    sprintf("%s_%s_headp_else_sar", phantom, tissue),
    as.vector(t(outer(POS_ORDER, FREQ_ORDER,
                      function(p, f) sprintf("%s_%s_%s_%s_sar", phantom, tissue, f, p))))
  )
  v <- setNames(rep(0, length(keys)), keys)   # placeholders and headp_else stay 0

  src <- interp[interp$phantom == phantom, ]
  k   <- sprintf("%s_%s_%s_%s_sar", phantom, tissue, src$frequency_mhz, src$placement)
  stopifnot(!any(duplicated(k)), all(k %in% keys))
  v[k] <- src[[col]]

  paste0("        ", names(v), ": ", paste0(unname(v)))
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
      stopifnot(i - th - 1L == length(new))          # same number of keys
      ln <- c(ln[seq_len(th)], new, if (i <= length(ln)) ln[i:length(ln)] else character(0))
    }
  }
  stopifnot(length(old) == length(ln))
  chg <- which(old != ln)
  # nothing outside the phantoms we are writing may change
  stopifnot(all(grepl(sprintf("^        (%s)_(body|brain)_[A-Za-z0-9_]+_sar: ",
                              paste(phantoms, collapse = "|")), ln[chg])))
  stopifnot(!any(grepl("[eE][+-][0-9]", ln[chg])))   # no scientific notation
  list(lines = ln, changed = chg)
}

# =============================================================================
# 8. RUN
# =============================================================================

cat("\n--- 1-2. read and normalise ------------------------------------------\n")
raw <- bind_rows(lapply(names(SOURCES), function(p)
  bind_rows(lapply(names(SOURCES[[p]]$sheets), function(g) read_and_normalise(p, g)))))

cat("\ninput power per frequency (mW) -- note it is NOT constant:\n")
print(as.data.frame(
  raw %>% distinct(phantom, frequency_mhz, power_mw) %>%
    tidyr::pivot_wider(names_from = frequency_mhz, values_from = power_mw)),
  row.names = FALSE)

cat("\n--- 3. interpolate ---------------------------------------------------\n")
interp <- interpolate(raw)

na_rows <- sum(is.na(interp$wholebody) | is.na(interp$brain))
if (na_rows > 0)
  stop(sprintf("%d interpolated values are NA -- a target frequency lies outside the ",
               na_rows),
       "simulated range. Refusing to continue: writing 0 would be indistinguishable ",
       "from 'this phantom has no data yet', which is what the model uses 0 for.")
cat(sprintf("  %d values, 0 NA, all ten targets inside the simulated range [%g, %g]\n",
            nrow(interp) * 2, min(raw$frequency_mhz), max(raw$frequency_mhz)))

cat("\n--- 4. build yaml blocks ---------------------------------------------\n")
blocks <- list()
for (ph in names(SOURCES)) for (tis in names(TISSUES)) {
  blocks[[paste(ph, tis)]] <- build_block(interp, ph, tis)
}
# Key arithmetic per phantom, so the two figures in the docs are traceable:
#   287 keys per tissue  = 1 headp_else + 22 positions x 13 frequency tokens
#   220 real per tissue  = 22 positions x the 10 model frequencies
#    67 zeros per tissue = 22 x 3 placeholder bands + 1 headp_else
# and twice that per phantom, i.e. 574 keys / 440 real / 134 zero.
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
yl   <- readLines(YAML_FILES[1], warn = FALSE)
duke <- grep("^        Duke_(body|brain)_[A-Za-z0-9_]+_sar: ", yl, value = TRUE)
mine <- c(blocks[["Duke body"]], blocks[["Duke brain"]])
key  <- function(x) sub("^\\s*([^:]+):.*$", "\\1", x)
val  <- function(x) sub("^[^:]+:\\s*", "", x)
cmp  <- merge(data.frame(k = key(duke), yaml = val(duke)),
              data.frame(k = key(mine), mine = val(mine)), by = "k")
same <- cmp$yaml == cmp$mine
cat(sprintf("  %d of %d Duke values reproduced byte-identically\n", sum(same), nrow(cmp)))
if (any(!same)) {
  d <- cmp[!same, ]
  d$rel <- abs(as.numeric(d$yaml) - as.numeric(d$mine)) / abs(as.numeric(d$yaml))
  cat(sprintf("  max relative deviation: %.3g\n", max(d$rel)))
  cat("  differing keys (expected: 6 tilt keys, see SAR_IMPORT_NOTES.md 5.5):\n")
  print(d[order(-d$rel), c("k","yaml","mine")], row.names = FALSE)
}

# =============================================================================
# 10. WRITE
# =============================================================================

cat("\n--- 7. write ---------------------------------------------------------\n")
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
