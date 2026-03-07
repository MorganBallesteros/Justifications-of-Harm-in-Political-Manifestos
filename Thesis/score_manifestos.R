suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(stringr)
  library(readr)
  library(forcats)
  library(purr)
})
# score_manifestos.R
# Purpose:
#   Define the main wrangling/scoring function for manifesto texts.
#   Supports:
#     - input_type = "text": score texts already loaded in a data frame
#     - input_type = "pdf": extract text from PDFs, then score
#   Produces:
#     - tidy long output by default (doc_id × marker × prevalence)
#     - optional wide output (one marker per column)
#     - optional write-out to data/processed/
#
# Design choices:
#   - strong input validation (clear errors early)
#   - reproducible, relative-path output
#   - "segment" option illustrates tidy reshaping (document vs paragraph)

# Load helper functions (normalize_text, build_marker_regex)
source(here::here("Thesis", "manifesto_helpers.R"))

# ------------------------------------------------------------
# extract_pdf_text()
# ------------------------------------------------------------
# Extract full text from a PDF path by concatenating all pages.
#
# Why separate function:
#   - isolates PDF dependency (pdftools)
#   - keeps main function readable
#   - allows clear, early failure if pdftools isn't installed
# If pdftools isn't installed, stop with a clear installation instruction.
extract_pdf_text <- function(pdf_path) {
  if (!requireNamespace("pdftools", quietly = TRUE)) {
    stop("Install 'pdftools' for PDF mode: install.packages('pdftools')")
  }
  if (!file.exists(pdf_path)) stop(paste0("PDF not found: ", pdf_path))
  
  pages <- pdftools::pdf_text(pdf_path)
  paste(pages, collapse = "\n\n")
}

# ------------------------------------------------------------
# score_manifestos()
# ------------------------------------------------------------
# Main scoring/wrangling function.
#
# Key outputs:
#   scores_out: either long or wide scored table
#   scores_long: always the long (tidy) table
#   doc_summary: one row per doc (and optional category) summary
#   problems: documents that had missing/empty text
score_manifestos <- function(input_type = c("text", "pdf"),
                             text_df = NULL,
                             pdf_paths = NULL,
                             doc_id_col = "doc_id",
                             text_col = "text",
                             markers,
                             category_col = NULL,
                             segment = c("document", "paragraph"),
                             per = 1000,
                             output = c("long", "wide"),
                             write_out = FALSE,
                             out_path = "Thesis/data/processed/manifesto_scores.csv",
                             quiet = TRUE) {
  
  # Normalize argument choices to safe values.
  # match.arg() also provides automatic validation for allowed options.
  input_type <- match.arg(input_type)
  segment <- match.arg(segment)
  output <- match.arg(output)
  
  # ----------------------------
  # Control flow #1: validation
  # ----------------------------
  if (missing(markers) || is.null(markers)) stop("Provide markers (character vector).")
  if (!is.character(markers)) stop("markers must be a character vector.")
  if (length(markers) == 0) stop("markers is empty.")
  
  # ----------------------------
  # Input mode A: input_type == "text"
  # ----------------------------
  if (input_type == "text") {
    if (is.null(text_df) || !is.data.frame(text_df)) stop("text_df must be a data frame.")
    if (!doc_id_col %in% names(text_df)) stop("doc_id_col not found in text_df.")
    if (!text_col %in% names(text_df)) stop("text_col not found in text_df.")
    docs <- tibble::as_tibble(text_df)
  } else {
    # ----------------------------
    # Input mode B: input_type == "pdf"
    # ----------------------------
    # Validate pdf_paths input
    if (is.null(pdf_paths) || !is.character(pdf_paths) || length(pdf_paths) == 0) {
      stop("For input_type='pdf', provide pdf_paths (character vector).")
    }
    
    # Derive doc_ids from filenames by stripping .pdf
    # basename(): remove directory; str_replace(): remove extension
    doc_ids <- stringr::str_replace(basename(pdf_paths), "\\.pdf$", "")
    texts <- character(length(pdf_paths))
    
    # ----------------------------
    # Control flow #2: loop over PDFs
    # ----------------------------
    # Extract PDF text one-by-one so errors can be tied to a specific file.
    for (i in seq_along(pdf_paths)) {
      texts[i] <- extract_pdf_text(pdf_paths[i])
      if (!quiet) message("Extracted: ", doc_ids[i])
    }
    
    # Build a tibble that matches the expected text_df structure.
    # Use quasiquotation (!!) so doc_id_col/text_col can be customized by the user.
    docs <- tibble::tibble(
      !!doc_id_col := doc_ids,
      !!text_col := texts
    )
  }
  
  # ----------------------------
  # Normalize text (stringr) + missing handling
  # ----------------------------
  docs <- docs %>%
    mutate(
      !!text_col := purrr::map_chr(.data[[text_col]], normalize_text),
      has_text = !is.na(.data[[text_col]]) & str_length(.data[[text_col]]) > 0
    )
  
  # Track documents that could not be scored (missing or empty text).
  problems <- docs %>%
    filter(!has_text) %>%
    transmute(!!doc_id_col := .data[[doc_id_col]], problem = "missing_or_empty_text")
  
  # Only keep documents with usable text for scoring
  docs_scoring <- docs %>% filter(has_text)
  
  # ----------------------------
  # Reshape non-tidy text -> tidy segments
  # ----------------------------
  # Goal:
  #   Create a tidy table where each row is one "unit" of scoring text.
  #   segment == "document": one row per doc
  #   segment == "paragraph": multiple rows per doc, one paragraph per row
  if (segment == "document") {
    segments_df <- docs_scoring %>%
      transmute(
        !!doc_id_col := .data[[doc_id_col]],
        segment_id = 1L,
        segment_text = .data[[text_col]],
        across(any_of(category_col), ~ .x)
      )
  } else {
    # Paragraph segmentation:
    # - split on blank lines (common paragraph separators in extracted text)
    # - unnest into multiple rows (tidy)
    segments_df <- docs_scoring %>%
      transmute(
        !!doc_id_col := .data[[doc_id_col]],
        raw_segments = str_split(.data[[text_col]], "\\n\\s*\\n+"),
        across(any_of(category_col), ~ .x)
      ) %>%
      tidyr::unnest_longer(raw_segments, indices_to = "segment_id", values_to = "segment_text") %>%
      mutate(segment_text = str_squish(segment_text)) %>%
      filter(!is.na(segment_text), segment_text != "")
  }
  
  # Word counts per segment
  segments_df <- segments_df %>%
    mutate(word_count = str_count(segment_text, "\\b[[:alnum:]]+\\b"))
  
  # ----------------------------
  # Count markers (tidy long table)
  # ----------------------------
  # Strategy:
  #   Loop over markers; for each marker, compute counts and prevalence for every segment.
  #   Store each marker’s results in a list, then bind_rows() into a tidy long table.
  counts_list <- vector("list", length(markers))
  
  for (j in seq_along(markers)) {
    m <- markers[j]
    # Build a safe whole-word regex for this marker
    pat <- build_marker_regex(m)
    
    # Create a tidy table for this marker:
    # one row per (doc_id × segment_id) with marker name, count, word_count, prevalence
    counts_list[[j]] <- segments_df %>%
      transmute(
        !!doc_id_col := .data[[doc_id_col]],
        segment_id,
        marker = m,
        # Count occurrences using regex; ignore_case adds case-insensitivity
        count = str_count(segment_text, regex(pat, ignore_case = TRUE)),
        word_count,
        across(any_of(category_col), ~ .x)
      ) %>%
      # Prevalence is scaled count per 'per' words (default 1000 words)
      mutate(prevalence = if_else(word_count > 0, (count / word_count) * per, NA_real_)) 
  }
  
  # Combine per-marker tables into one long tidy scoring table
  scores_long <- bind_rows(counts_list)
  
  # ----------------------------
  # Factor prep
  # ----------------------------
  # If the user supplied category_col and it exists, convert it to a factor and reorder levels by frequency (common for plotting).
  if (!is.null(category_col) && category_col %in% names(scores_long)) {
    scores_long <- scores_long %>%
      mutate(
        # base R factor()
        !!category_col := factor(.data[[category_col]]),
        !!category_col := forcats::fct_infreq(.data[[category_col]])
      )
  }
  
  # ----------------------------
  # dplyr pipelines: a simple summary
  # ----------------------------
  doc_summary <- scores_long %>%
    group_by(across(any_of(c(doc_id_col, category_col)))) %>%
    summarize(
      total_words = max(word_count, na.rm = TRUE),
      mean_prev = mean(prevalence, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    arrange(desc(total_words))
  
  # ----------------------------
  # tidyr reshape output: long vs wide
  # ----------------------------
  scores_out <- if (output == "wide") {
    scores_long %>%
      select(any_of(c(doc_id_col, "segment_id", category_col)), marker, prevalence) %>%
      pivot_wider(names_from = marker, values_from = prevalence)
  } else {
    scores_long
  }
  
  # ----------------------------
  # Control flow #3: optional write-out
  # ----------------------------
  if (write_out) {
    dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)
    readr::write_csv(scores_out, out_path)
    if (!quiet) message("Wrote: ", out_path)
  }
  
  # Return list
  list(
    scores = scores_out,
    scores_long = scores_long,
    doc_summary = doc_summary,
    problems = problems
  )
}

