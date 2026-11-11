# Cells within a circle of radius nPix pixels around each focal cell, focal cell excluded.
# Returns a data.table with one row per pair: "from" (the focal cell) and "to" (the adjacent cell).
# Used by generateDisturbances() to grow a new disturbance from its first pixel.
circleNeighbours <- function(rasterToMatch, cells, nPix) {
  nb <- terra::focalMat(x = rasterToMatch, d = nPix * terra::res(rasterToMatch)[1],
                        type = "circle")
  # terra::adjacent() counts every cell of the matrix that is not 0 or NA as adjacent (unlike
  # raster::adjacent(), which counted only the 1s): cells outside the circle must be 0, and so
  # must the focal cell in the centre.
  nb[nb > 0] <- 1
  nb[ceiling(nrow(nb)/2), ceiling(ncol(nb)/2)] <- 0
  adj <- terra::adjacent(x = rasterToMatch, cells = cells, directions = nb, pairs = TRUE,
                         include = FALSE)
  # Keep the order raster::adjacent() used -- focal cell by focal cell, then column by column of
  # the matrix -- because generateDisturbances() samples rows of this table: with the same seed,
  # it then picks the same cells as before. (terra lists the cells by cell number instead.)
  rcFrom <- terra::rowColFromCell(rasterToMatch, adj[, "from"])
  rcTo <- terra::rowColFromCell(rasterToMatch, adj[, "to"])
  posInMatrix <- (rcTo[, 2] - rcFrom[, 2]) * nrow(nb) + (rcTo[, 1] - rcFrom[, 1])
  adj <- adj[order(match(adj[, "from"], cells), posInMatrix), , drop = FALSE]
  data.table::as.data.table(adj)
}
