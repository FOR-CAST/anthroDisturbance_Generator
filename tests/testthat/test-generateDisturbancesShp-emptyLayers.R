# Empty existing layers: a sector may have NO feature of a type yet (e.g., no wind turbines, no mines or no
# settlements in the study area). The layer is then a zero-row SpatVector. generateDisturbancesShp() has to skip
# what it cannot compute (e.g., the area of the existing features) and still generate or skip gracefully.
# Regression: with disturbanceRateRelatesToBufferedArea = TRUE, an empty existing layer failed in
# terra::aggregate() ("replacement has 1 rows, data has 0"), and the Enlarging branch did the same.

emptyCase <- function() {
  r <- terra::rast(nrows = 100, ncols = 100, xmin = 0, xmax = 10000, ymin = 0, ymax = 10000, vals = 1) # 10 km, 100 m cells
  terra::crs(r) <- "EPSG:3005"
  sa <- terra::as.polygons(terra::ext(r)); terra::crs(sa) <- terra::crs(r)
  square <- function(x, y, w) {
    terra::vect(sf::st_sfc(sf::st_polygon(list(rbind(c(x, y), c(x, y + w), c(x + w, y + w), c(x + w, y), c(x, y)))),
                           crs = 3005))
  }
  mining <- square(100, 100, 50); mining$Class <- "mining"
  mining <- mining[0, ]                                   # empty: same fields and CRS, no feature
  potentialMining <- square(1000, 1000, 6000); potentialMining$Potential <- 1L
  settlements <- square(4000, 4000, 500); settlements$Class <- "settlements"
  settlements <- settlements[0, ]                         # empty as well
  list(r = r, sa = sa,
       dl = list(mining = list(mining = mining, potentialMining = potentialMining),
                 settlements = list(settlements = settlements)))
}

dpRow <- function(dataName, dataClass, type, origin, rate = NA_real_, size = NA_character_) {
  data.table::data.table(dataName = dataName, dataClass = dataClass, disturbanceType = type, disturbanceRate = rate,
                         disturbanceSize = size, disturbanceOrigin = origin, disturbanceEnd = "",
                         disturbanceInterval = 1L, resolutionVector = 15L)
}

runShp <- function(case, dp, bufferedArea) {
  suppressWarnings(
    generateDisturbancesShp(
      disturbanceParameters = dp, disturbanceList = case$dl, rasterToMatch = case$r, studyArea = case$sa,
      fires = NULL, currentTime = 2020, firstTime = FALSE, growthStepGenerating = 1, growthStepEnlargingPolys = 1,
      growthStepEnlargingLines = 1, currentDisturbanceLayer = NULL, connectingBlockSize = NULL,
      disturbanceRateRelatesToBufferedArea = bufferedArea, outputsFolder = tempdir(), seismicLineGrids = 10,
      checkDisturbancesForBuffer = FALSE, runName = "test_empty", useRoadsPackage = FALSE,
      siteSelectionAsDistributing = character(0), probabilityDisturbance = NULL,
      maskWaterAndMountainsFromLines = FALSE, featuresToAvoid = NULL, altitudeCut = NULL, clusterDistance = 1000,
      distanceNewLinesFactor = 1.0, runClusteringInParallel = FALSE, useClusterMethod = FALSE, refinedStructure = FALSE
    )
  )
}

test_that("Generating from an EMPTY existing layer works when rates relate to the buffered area", {
  case <- emptyCase()
  expect_equal(nrow(case$dl$mining$mining), 0L)
  dp <- dpRow("mining", "potentialMining", "Generating", "mining", rate = 2, size = "100000")
  expect_no_error(out <- runShp(case, dp, bufferedArea = TRUE))
  mines <- out$individualLayers$mining$mining
  expect_s4_class(mines, "SpatVector")
  expect_gt(nrow(mines), 0L)
})

test_that("Generating from an EMPTY existing layer works when rates relate to the footprint", {
  case <- emptyCase()
  dp <- dpRow("mining", "potentialMining", "Generating", "mining", rate = 2, size = "100000")
  expect_no_error(out <- runShp(case, dp, bufferedArea = FALSE))
  mines <- out$individualLayers$mining$mining
  expect_s4_class(mines, "SpatVector")
  expect_gt(nrow(mines), 0L)
})

test_that("Enlarging an EMPTY existing layer is skipped without error", {
  case <- emptyCase()
  dp <- dpRow("settlements", "settlements", "Enlarging", "settlements", rate = 0.5)
  for (buffered in c(TRUE, FALSE)) {
    expect_no_error(out <- runShp(case, dp, bufferedArea = buffered))
    grown <- out$individualLayers[["settlements"]][["settlements"]]
    expect_true(is.null(grown) || nrow(grown) == 0L)
  }
})
