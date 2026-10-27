## code to build the package manual (`doc/RFDose_<version>.pdf`) goes here
## Builds the PDF manual like R CMD Rd2pdf (devtools::build_manual()), but with
## the help topics in the order of `topic_groups` instead of alphabetically,
## each group starting on a new page under its heading.
## Run from the package root, after devtools::document(). Needs LaTeX (e.g.
## tinytex).

# Help topics, by group and in order. The package overview (RFDose-package)
# comes first. Every topic in man/ must be listed exactly once. Group names are
# LaTeX text: no special characters (& % $ # _ { } ~ ^ \).
topic_groups <- list(
  "Main functions" = c(
    "calculate_emf_doses", "calculate_emf_doses_stochastic", "total_dose"),
  "Mobile phone calls" = c(
    "mobilecall_dose", "mpc_msar",
    "mpc_pwr_native", "mpc_pwr_data", "mpc_pwr_wifi",
    "mpc_sar_native", "mpc_sar_data", "mpc_sar_wifi",
    "mpc_bt_phone_msar", "mpc_bt_earset_msar"),
  "Mobile data" = c(
    "mobiledata_dose", "mpd_msar",
    "mpd_pwr_data", "mpd_pwr_wifi",
    "mpd_sar_data", "mpd_sar_wifi"),
  "Cordless phone (DECT)" = c(
    "cordless_dose", "dect_msar", "dect_pwr", "dect_sar"),
  "Far-field sources" = c(
    "farfield_dose", "farfield_msar", "farfield_pwr", "farfield_sar"),
  "WiFi router" = c(
    "wifi_dose", "wifi_msar", "wifi_pwr", "wifi_sar"),
  "Laptop" = c(
    "laptop_dose", "laptop_msar", "laptop_pwr", "laptop_sar"),
  "Tablet" = c(
    "tablet_dose", "tablet_msar", "tablet_pwr", "tablet_sar"),
  "Other devices" = c(
    "other_dose_wrapper", "hotspot_dose",
    "smartwatch_dose", "smartwatch_phone_dose", "smartwatch_watch_dose",
    "vr_dose",
    "headphones_dose", "headphones_phone_dose", "headphones_earset_dose",
    "gaming_dose"),
  "Stochastic model" = c(
    "load_distributions", "load_input_distributions",
    "simulate_params", "simulate_inputs",
    "stochastic_doses", "summarise_doses",
    "list_distributions", "list_sar", "get_param", "set_params"),
  "Distributions" = c(
    "r_lognormal", "r_trunc_lognormal", "q_trunc_lognormal",
    "trunc_lognormal_mean", "trunc_lognormal_meanlog", "log_pnorm_between",
    "r_beta", "q_beta", "r_dirichlet",
    "q_around", "q_category", "q_shares"),
  "Helpers and data" = c(
    "act_pwr_props", "available_sar_files", "example_data",
    "fill_missing_variables", "load_params", "load_tissue_params",
    "location_props", "prepare_dose_data", "sar_file_path"),
  "Input checks" = c(
    "check_boolean_not_na", "check_character_not_na", "check_country",
    "check_duration", "check_headp_num", "check_numeric_not_na",
    "check_proportions", "check_shape", "check_tissue", "check_urbanicity")
)

version <- read.dcf("DESCRIPTION", fields = "Version")[1, 1]
output  <- file.path("doc", paste0("RFDose_", version, ".pdf"))

# LaTeX of the manual, as made by R CMD Rd2pdf (topics in alphabetical order)
build_dir <- tempfile("Rd2pdf")
log <- suppressWarnings(system2(
  file.path(R.home("bin"), "R"),
  c("CMD", "Rd2pdf", "--no-clean", "--no-preview", "--force", "--batch",
    paste0("--build-dir=", build_dir),
    paste0("--output=", tempfile(fileext = ".pdf")),
    shQuote(normalizePath("."))),
  stdout = TRUE, stderr = TRUE))
if (!is.null(attr(log, "status")) || !file.exists(file.path(build_dir, "Rd2.tex"))) {
  cat(log, sep = "\n")
  stop("R CMD Rd2pdf failed.")
}
tex <- readLines(file.path(build_dir, "Rd2.tex"), encoding = "UTF-8")

# Split into the head (title page, description, contents), one block per
# topic (from its \HeaderA line) and the tail (index)
starts     <- grep("^\\\\HeaderA\\{", tex)
tail_start <- grep("^\\\\printindex", tex)
head       <- tex[seq_len(starts[1] - 1)]
blocks     <- Map(function(from, to) tex[from:to], starts, c(starts[-1], tail_start) - 1)
names(blocks) <- gsub("\\_", "_", sub("^\\\\HeaderA\\{([^}]*)\\}.*", "\\1", tex[starts]),
                      fixed = TRUE)

listed  <- c("RFDose-package", unlist(topic_groups, use.names = FALSE))
missing <- setdiff(names(blocks), listed)
unknown <- setdiff(listed, names(blocks))
if (length(missing)) {
  stop("Topic(s) not in topic_groups: ", paste(missing, collapse = ", "))
}
if (length(unknown)) {
  stop("Topic(s) in topic_groups without a help page: ", paste(unknown, collapse = ", "))
}
if (anyDuplicated(listed)) {
  stop("Topic(s) listed twice: ", paste(unique(listed[duplicated(listed)]), collapse = ", "))
}

# Description on the title page: \AsIs keeps the line breaks of DESCRIPTION
# and makes spaces unbreakable; \RFDflow takes the special characters as they
# are like \AsIs, but lets the text flow up to the margin (justified, without
# \raggedright)
desc  <- seq(grep("^\\\\begin\\{description\\}", head), grep("^\\\\end\\{description\\}", head))
block <- gsub("\\AsIs{", "\\RFDflow{", head[desc], fixed = TRUE)
block <- block[block != "\\raggedright{}"]

# Declaration on generative AI use (field Config/AI-declaration of
# DESCRIPTION): under its own title, right after the description
inner <- block[-c(1, length(block))]
items <- split(inner, cumsum(grepl("^\\\\item\\[", inner)))
label <- sub("^\\\\item\\[([^]]*)\\].*", "\\1", vapply(items, `[`, "", 1))
ai    <- which(label == "Config/AI-declaration")
if (length(ai)) {
  items[[ai]][1] <- sub("[Config/AI-declaration]", "[Declaration on generative AI use]",
                        items[[ai]][1], fixed = TRUE)
  rest  <- seq_along(items)[-ai]
  items <- items[append(rest, ai, after = match(which(label == "Description"), rest))]
}
head <- c(head[seq_len(desc[1] - 1)], block[1], unlist(items, use.names = FALSE),
          block[length(block)], head[-seq_len(desc[length(desc)])])

# Added to the preamble:
# * Long code terms (e.g. file and function names) are not hyphenated and ran
#   past the margin: a line may break after an underscore (with a small
#   penalty, so only where needed), and lines may be a bit looser
# * \RFDflow (above)
# * The group heading: new page, heading in the text, entry in the contents
#   and in the PDF bookmarks, with the topics of the group nested under it
group_command <- c(
  "\\makeatletter",
  "\\DeclareRobustCommand{\\_}{\\ifmmode\\nfss@text{\\textunderscore}\\else\\textunderscore\\penalty50\\relax\\fi}",
  "\\setlength{\\emergencystretch}{5em}",
  "\\def\\RFDflow{\\bgroup\\let\\do\\@makeother\\Rd@AsIs@dospecials\\@noligs\\parskip\\z@skip\\Rd@AsIsX}",
  "\\newcounter{RFDgroup}",
  "\\newcommand{\\RFDgroup}[1]{%",
  "  \\clearpage\\stepcounter{RFDgroup}%",
  "  \\ifthenelse{\\boolean{Rd@use@hyper}}%",
  "    {\\myaddcontentsline{toc}{chapter}{#1}\\pdfbookmark[0]{#1}{RFDgroup.\\theRFDgroup}}%",
  "    {\\addcontentsline{toc}{chapter}{#1}}%",
  "  \\noindent{\\Large\\bfseries #1}\\par\\nopagebreak",
  "  \\vspace{1ex}\\hrule\\nopagebreak\\vspace{3ex}}",
  "\\makeatother")
begin <- grep("^\\\\begin\\{document\\}", head)
head  <- c(head[seq_len(begin - 1)], group_command, head[begin:length(head)])

body <- c(
  blocks[["RFDose-package"]],
  unlist(lapply(names(topic_groups), function(group) {
    c(paste0("\\RFDgroup{", group, "}"), unlist(blocks[topic_groups[[group]]]))
  }), use.names = FALSE))
writeLines(c(head, body, tex[tail_start:length(tex)]),
           file.path(build_dir, "Rd2.tex"), useBytes = TRUE)

# Compile again, without the auxiliary files of the alphabetical version
unlink(file.path(build_dir, paste0("Rd2.", c("aux", "toc", "idx", "ind", "ilg", "out", "pdf"))))
compile <- function(dir) {
  old <- setwd(dir)
  on.exit(setwd(old))
  tools::texi2pdf("Rd2.tex", index = TRUE, quiet = TRUE)
}
compile(build_dir)

if (!file.copy(file.path(build_dir, "Rd2.pdf"), output, overwrite = TRUE)) {
  stop("Cannot write ", output)
}
unlink(build_dir, recursive = TRUE)
message("Manual written to ", output)
