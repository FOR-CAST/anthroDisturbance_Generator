## Run the module's unit tests, from the module root: Rscript tests/run-tests.R [file filter]
## The tests call the helpers in R/ directly, so this sources them and attaches the packages their
## unqualified calls come from (data.table, digest, foreach, reproducible, sf, terra, tictoc), plus
## sp, which test-saveDisturbances.R calls unqualified, and sets the `Paths` the helpers write to.
## Every test is skip_on_cran(), so NOT_CRAN is set here. Used by .github/workflows/test-module.yaml.
## The module simulation tests need SpaDES.core and the module's reqdPkgs; the workflow installs them.
## Tests use at most 2 cores, as CRAN asks; TEST_CORES raises that, to 4 at most, for a longer run.
## R starts OpenMP and BLAS before this script runs, so the limits must be in the environment R
## starts with: without them, the script runs itself again in a new R process that has them. It
## does so once (RUN_TESTS_RERUN marks the new process): an Renviron file that R reads at start-up,
## such as ~/.Renviron, can set the limit again, so the new process sets the limits back instead.
asked <- suppressWarnings(as.integer(Sys.getenv("TEST_CORES")))
cores <- if (is.na(asked)) 2L else min(4L, max(1L, asked))
limits <- c("OMP_THREAD_LIMIT", "OMP_NUM_THREADS", "OPENBLAS_NUM_THREADS", "MKL_NUM_THREADS")
limit <- suppressWarnings(as.integer(Sys.getenv("OMP_THREAD_LIMIT")))
if (is.na(limit) || limit > cores) {
  if (!nzchar(Sys.getenv("RUN_TESTS_RERUN"))) {
    status <- system2(
      file.path(R.home("bin"), "R"),
      shQuote(commandArgs(trailingOnly = FALSE)[-1L]),
      env = c(paste0(limits, "=", cores), "RUN_TESTS_RERUN=true")
    )
    quit(save = "no", status = status)
  }
  values <- rep(as.character(cores), length(limits))
  names(values) <- limits
  do.call(Sys.setenv, as.list(values))
}
Sys.setenv(NOT_CRAN = "true")
suppressPackageStartupMessages({
  library(testthat)
  library(mockery)
  library(sp)
  library(data.table)
  library(digest)
  library(foreach)
  library(reproducible)
  library(sf)
  library(terra)
  library(tictoc)
})
data.table::setDTthreads(cores)
Paths <- list(inputPath = tempdir(), outputPath = tempdir())
for (f in list.files("R", "[.]R$", full.names = TRUE)) {
  source(f)
}
args <- commandArgs(trailingOnly = TRUE)
testthat::test_dir(
  file.path("tests", "testthat"),
  filter = if (length(args)) args[[1L]] else NULL,
  reporter = "summary",
  stop_on_failure = TRUE
)
