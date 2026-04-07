# Purpose:
# Run the full scoring pipeline from raw manifesto text files (.txt preferred, .pdf fallback)
#
# Expected inputs:
#   - Raw text files stored in: Thesis/data/raw/
#   - Marker dictionary stored in: Thesis/data/markers/marker_dictionary.csv
#
# Expected outputs:
#   - Marker-level scores: Thesis/data/processed/manifesto_scores_markers.csv
#   - Group-level scores: Thesis/data/processed/manifesto_scores_groups.csv
#   - Category-level scores: Thesis/data/processed/manifesto_scores_categories.csv
#   - Segment-level derived indicator:
#       Thesis/data/processed/role_model_glorification_segments.csv
#   - Document-level derived indicator:
#       Thesis/data/processed/role_model_glorification_docs.csv
#
# Notes for reproducibility:
#   - This script uses input_type = "txt" (primary input mode)
#   - The thesis Rmd can read the processed CSV files without re-extracting PDFs.
#   - Scoring is done at the paragraph level so co-occurrence indicators can be built
#     within segments rather than only at the whole-document level.

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(here)
})

# ------------------------------------------------------------
# Load scoring function
# ------------------------------------------------------------
source(here::here("score_manifestos.R"))

# ------------------------------------------------------------
# Read marker dictionary
# ------------------------------------------------------------
marker_dict <- readr::read_csv(
  here::here("data", "markers", "marker_dictionary.csv"),
  show_col_types = FALSE
)

# Basic validation
required_cols <- c("marker", "marker_group", "marker_category")
missing_cols <- setdiff(required_cols, names(marker_dict))

if (length(missing_cols) > 0) {
  stop(
    paste(
      "marker_dictionary.csv is missing required columns:",
      paste(missing_cols, collapse = ", ")
    )
  )
}

# Extract marker vector for scoring
markers <- marker_dict$marker

if (length(markers) == 0) {
  stop("No markers found in marker_dictionary.csv.")
}

# ------------------------------------------------------------
# Find all TXT files
# ------------------------------------------------------------
nonlong_dir <- here::here("data", "raw")
long_dir    <- here::here("data", "longitudinal")

txt_paths_nonlong <- list.files(
  nonlong_dir,
  pattern = "\\.txt$",
  full.names = TRUE,
  recursive = TRUE,
  ignore.case = TRUE
)

txt_paths_long <- list.files(
  long_dir,
  pattern = "\\.txt$",
  full.names = TRUE,
  recursive = TRUE,
  ignore.case = TRUE
)

txt_paths <- c(txt_paths_nonlong, txt_paths_long)

cat("Non-longitudinal directory:", nonlong_dir, "\n")
cat("Longitudinal directory:", long_dir, "\n")
cat("TXT files found (non-longitudinal):", length(txt_paths_nonlong), "\n")
cat("TXT files found (longitudinal):", length(txt_paths_long), "\n")
cat("TXT files found (total):", length(txt_paths), "\n")

if (length(txt_paths) == 0) {
  stop("No .txt files found in Thesis/data/raw or Thesis/data/longitudinal.")
}


# ------------------------------------------------------------
# Run scoring at the paragraph level
# ------------------------------------------------------------
res <- score_manifestos(
  input_type = "txt",
  txt_paths = txt_paths,
  markers = markers,
  segment = "paragraph",
  output = "long",
  write_out = FALSE,
  quiet = FALSE
)

# Marker-level scored output
scores_long <- res$scores

# ------------------------------------------------------------
# Annotate scored rows with group/category metadata
# ------------------------------------------------------------
scores_annotated <- scores_long %>%
  dplyr::left_join(marker_dict, by = "marker")

# Check for unmatched markers
if (any(is.na(scores_annotated$marker_group) | is.na(scores_annotated$marker_category))) {
  warning("Some scored markers did not match the dictionary.")
  print(
    scores_annotated %>%
      dplyr::filter(is.na(marker_group) | is.na(marker_category)) %>%
      dplyr::distinct(marker)
  )
}

# ------------------------------------------------------------
# Marker-level output
# ------------------------------------------------------------
marker_scores <- scores_annotated %>%
  dplyr::select(
    doc_id,
    corpus,
    author,
    segment_id,
    marker,
    marker_group,
    marker_category,
    count,
    word_count,
    prevalence
  )

# ------------------------------------------------------------
# Group-level output
# Prevalence is recomputed from summed counts, not averaged from marker prevalences
# ------------------------------------------------------------
group_scores <- scores_annotated %>%
  dplyr::group_by(doc_id, corpus, author, segment_id, marker_group, marker_category) %>%
  dplyr::summarise(
    count = sum(count, na.rm = TRUE),
    word_count = max(word_count, na.rm = TRUE),
    prevalence = (count / word_count) * 1000,
    .groups = "drop"
  )

# ------------------------------------------------------------
# Category-level output
# ------------------------------------------------------------
category_scores <- scores_annotated %>%
  dplyr::group_by(doc_id, corpus, author, segment_id, marker_category) %>%
  dplyr::summarise(
    count = sum(count, na.rm = TRUE),
    word_count = max(word_count, na.rm = TRUE),
    prevalence = (count / word_count) * 1000,
    .groups = "drop"
  )

# ------------------------------------------------------------
# Derived indicator:
# violent reference + role model status within the same segment
# ------------------------------------------------------------
role_model_glorification_segments <- scores_annotated %>%
  dplyr::group_by(doc_id, corpus, author, segment_id) %>%
  dplyr::summarise(
    has_violent_reference = any(marker_group == "violent_reference" & count > 0, na.rm = TRUE),
    has_role_model_status = any(marker_group == "role_model_status" & count > 0, na.rm = TRUE),
    violent_reference_count = sum(count[marker_group == "violent_reference"], na.rm = TRUE),
    role_model_status_count = sum(count[marker_group == "role_model_status"], na.rm = TRUE),
    word_count = max(word_count, na.rm = TRUE),
    role_model_glorification = has_violent_reference & has_role_model_status,
    .groups = "drop"
  )

role_model_glorification_docs <- role_model_glorification_segments %>%
  dplyr::group_by(doc_id, corpus, author) %>%
  dplyr::summarise(
    any_role_model_glorification = any(role_model_glorification, na.rm = TRUE),
    n_glorification_segments = sum(role_model_glorification, na.rm = TRUE),
    total_violent_reference_count = sum(violent_reference_count, na.rm = TRUE),
    total_role_model_status_count = sum(role_model_status_count, na.rm = TRUE),
    .groups = "drop"
  )

# ------------------------------------------------------------
# Ensure processed output directory exists
# ------------------------------------------------------------
processed_dir <- here::here("data", "processed")
dir.create(processed_dir, recursive = TRUE, showWarnings = FALSE)

# ------------------------------------------------------------
# Write outputs
# ------------------------------------------------------------
readr::write_csv(
  marker_scores,
  here::here("data", "processed", "manifesto_scores_markers.csv")
)

readr::write_csv(
  group_scores,
  here::here("data", "processed", "manifesto_scores_groups.csv")
)

readr::write_csv(
  category_scores,
  here::here("data", "processed", "manifesto_scores_categories.csv")
)

readr::write_csv(
  role_model_glorification_segments,
  here::here("data", "processed", "role_model_glorification_segments.csv")
)

readr::write_csv(
  role_model_glorification_docs,
  here::here("data", "processed", "role_model_glorification_docs.csv")
)

# ------------------------------------------------------------
# Console checks
# ------------------------------------------------------------
cat("\nWrote processed files to:\n", processed_dir, "\n\n")

cat("Marker-level rows:", nrow(marker_scores), "\n")
cat("Group-level rows:", nrow(group_scores), "\n")
cat("Category-level rows:", nrow(category_scores), "\n")
cat("Role-model glorification segment rows:", nrow(role_model_glorification_segments), "\n")
cat("Role-model glorification doc rows:", nrow(role_model_glorification_docs), "\n\n")

print(dplyr::glimpse(marker_scores))
print(dplyr::glimpse(group_scores))
print(dplyr::glimpse(category_scores))
print(dplyr::glimpse(role_model_glorification_docs))

