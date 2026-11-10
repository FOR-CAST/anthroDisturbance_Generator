# tests/testthat/test-unwrapTerraList.R
# --- Helpers ---------------------------------------------------------------

# A flat zip laid out like the one on Zenodo: theList.rds (layer file names by sector and class)
# plus one .rds file per wrapped SpatVector
make_toy_distlist_zip <- function(dir) {
  poly <- terra::vect("POLYGON ((0 0, 1 0, 1 1, 0 1, 0 0))", crs = "EPSG:3857")
  line <- terra::vect("LINESTRING (0 0, 2 2)", crs = "EPSG:3857")
  base::saveRDS(terra::wrap(poly), file.path(dir, "polyLayer01.rds"))
  base::saveRDS(terra::wrap(line), file.path(dir, "lineLayer02.rds"))
  theList <- list(mining = list(potentialMining = "polyLayer01.rds"),
                  roads = list(roads = "lineLayer02.rds"))
  base::saveRDS(theList, file.path(dir, "theList.rds"))
  files <- c("theList.rds", "polyLayer01.rds", "lineLayer02.rds")
  withr::with_dir(dir, utils::zip("disturbanceList.zip", files, flags = "-q"))
  files
}

# --- Tests -----------------------------------------------------------------

testthat::test_that("unwrapTerraList() reads an extracted list when terra is attached", {
  testthat::skip_on_cran()
  testthat::skip_if(Sys.which("zip") == "", "no zip program")
  # A SpaDES module attaches its reqdPkgs. Attach terra only if it is not attached yet, so the
  # test leaves the search path as it found it (local_package() detaches on exit)
  if (!"package:terra" %in% search()) withr::local_package("terra")
  gp <- withr::local_tempdir()
  make_toy_distlist_zip(gp)
  # theList.rds and the layers are already in generalPath (e.g., a second run)
  out <- unwrapTerraList(terraList = "theList.rds", generalPath = gp)
  testthat::expect_named(out, c("mining", "roads"))
  testthat::expect_s4_class(out$mining$potentialMining, "SpatVector")
  testthat::expect_identical(terra::geomtype(out$roads$roads), "lines")
})

testthat::test_that("unwrapTerraList() extracts the archive into generalPath, where it reads the layers", {
  testthat::skip_on_cran()
  testthat::skip_if(Sys.which("zip") == "", "no zip program")
  testthat::skip_if_not_installed("reproducible")
  if (!"package:terra" %in% search()) withr::local_package("terra")
  # unwrapTerraList() calls prepInputs(), which a module finds attached with its reqdPkgs
  if (!"package:reproducible" %in% search()) withr::local_package("reproducible")
  withr::local_options(reproducible.destinationPath = NULL)
  gp <- withr::local_tempdir()
  files <- make_toy_distlist_zip(gp)
  unlink(file.path(gp, files)) # only disturbanceList.zip is left in generalPath
  withr::local_dir(withr::local_tempdir()) # the working directory is not generalPath
  # The archive is already in generalPath, so nothing needs to be downloaded
  out <- unwrapTerraList(terraList = "https://example.invalid/disturbanceList.zip",
                         generalPath = gp)
  testthat::expect_named(out, c("mining", "roads"))
  testthat::expect_s4_class(out$roads$roads, "SpatVector")
})

testthat::test_that("the default disturbanceList is the .rds archive on Zenodo, not Google Drive", {
  testthat::skip_on_cran()
  modFile <- testthat::test_path("..", "..", "anthroDisturbance_Generator.R")
  txt <- paste(readLines(modFile), collapse = "\n")
  block <- regmatches(txt, regexpr('(?s)expectsInput\\(objectName = "disturbanceList".*?sourceURL = "[^"]*"',
                                   txt, perl = TRUE))
  url <- sub('.*sourceURL = "([^"]*)"$', "\\1", block)
  testthat::expect_false(grepl("drive.google.com", url, fixed = TRUE))
  testthat::expect_match(url, "^https://zenodo.org/records/[0-9]+/files/disturbanceList.zip$")
})
