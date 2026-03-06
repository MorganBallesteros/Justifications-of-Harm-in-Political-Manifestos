# Purpose:
#   Run the full scoring pipeline from raw PDF files to a processed CSV output.
#
# Expected inputs:
#   - Raw PDFs stored in: data/raw/pdfs/
#
# Expected output:
#   - Scored CSV stored in: data/processed/manifesto_scores.csv
#
# Notes for reproducibility:
#   - This script uses input_type = "pdf", which requires the 'pdftools' package.
#   - The Quarto report can be rendered from the processed CSV without needing pdftools,as long as the CSV is already present in the repository.

# Load the scoring function (and its dependencies + helper functions)
source(here::here("Thesis", "score_manifestos.R"))

# Find all PDF files in the raw PDF directory.
# pattern = "\\.pdf$": match filenames ending in .pdf
# full.names = TRUE: return full relative paths, not just filenames
# ignore.case = TRUE: match .PDF as well as .pdf
pdf_paths <- list.files(
  "data/raw/pdfs",
  pattern = "\\.pdf$",
  full.names = TRUE,
  ignore.case = TRUE
)

# Define the marker list (the words/phrases you want to count).
# Morgan: You can replace this with your full marker dictionary later.
markers <- c("harm", "damage", "agent", "patient", "intention", "intentional", "preemptive", "defend", "protect", "self-defense", "forced to fight", "no longer ignore", "act of defense", "purified", "purify", "brutal steps should have been used", "need for jihaad", "reasons for jihaad", "need for war", "the struggle is imposed upon", "natural struggle", "cannot coexist")

# Run the main function in PDF mode:
# - input_type = "pdf": read and extract raw text from PDFs
# - segment = "document": treat each PDF as a single unit (one segment per doc)
# - output = "long": tidy output (doc × marker rows)
# - write_out = TRUE: export results to CSV for later analysis/reporting
# - quiet = FALSE: print progress messages while extracting/writing
res <- score_manifestos(
  input_type = "pdf",
  pdf_paths = pdf_paths,
  markers = markers,
  segment = "document",
  output = "long",
  write_out = TRUE,
  out_path = "data/processed/manifesto_scores.csv",
  quiet = FALSE
)

print(dplyr::glimpse(res$scores_long))
