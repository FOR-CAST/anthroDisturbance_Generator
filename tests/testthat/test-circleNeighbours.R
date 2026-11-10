# test-circleNeighbours.R
# circleNeighbours() picks the cells a new disturbance can grow into: those within a circle of nPix
# pixels around its first pixel. Expected cells are worked out from row/column offsets alone.

expectedNeighbours <- function(r, focal, nPix) {
  rc <- terra::rowColFromCell(r, focal)
  all_rc <- expand.grid(row = seq_len(nrow(r)), col = seq_len(ncol(r)))
  d2 <- (all_rc$row - rc[1, 1])^2 + (all_rc$col - rc[1, 2])^2
  keep <- d2 > 0 & d2 <= nPix^2
  sort(terra::cellFromRowCol(r, all_rc$row[keep], all_rc$col[keep]))
}

make_rtm <- function() {
  terra::rast(nrows = 30, ncols = 40, xmin = 0, xmax = 40 * 250, ymin = 0, ymax = 30 * 250,
              crs = "EPSG:3978", vals = 1)
}

testthat::test_that("neighbours are the cells within the circle, not the whole square around it", {
  r <- make_rtm()
  focal <- terra::cellFromRowCol(r, 15, 20)
  for (nPix in c(1, 2, 3, 5, 10)) {
    out <- circleNeighbours(r, cells = focal, nPix = nPix)
    testthat::expect_named(out, c("from", "to"))
    testthat::expect_true(all(out$from == focal))
    testthat::expect_equal(sort(out$to), expectedNeighbours(r, focal, nPix), info = paste("nPix", nPix))
  }
  # nPix = 1 is the 4 rook neighbours; nPix = 2 adds the diagonals and the cells 2 away
  testthat::expect_equal(nrow(circleNeighbours(r, focal, 1)), 4L)
  testthat::expect_equal(nrow(circleNeighbours(r, focal, 2)), 12L)
})

testthat::test_that("neighbours stop at the raster edge and corner, without wrapping", {
  r <- make_rtm()
  corner <- 1
  edge <- terra::cellFromRowCol(r, 1, 20)
  for (focal in c(corner, edge)) {
    out <- circleNeighbours(r, cells = focal, nPix = 3)
    testthat::expect_equal(sort(out$to), expectedNeighbours(r, focal, 3))
    testthat::expect_false(anyNA(out$to))
  }
})

testthat::test_that("rows are in raster::adjacent()'s order: by focal cell, then column by column", {
  # generateDisturbances() samples rows of this table, so the order decides which cells a given seed
  # picks. Expected order: focal cells as given; within each, the circle's cells column by column.
  r <- make_rtm()
  cells <- terra::cellFromRowCol(r, c(15, 1, 30), c(20, 1, 40)) # interior, then two corners
  nPix <- 3
  expected <- do.call(rbind, lapply(cells, function(f) {
    rc <- terra::rowColFromCell(r, f)
    off <- expand.grid(dr = -nPix:nPix, dc = -nPix:nPix) # column by column
    off <- off[(off$dr^2 + off$dc^2) > 0 & (off$dr^2 + off$dc^2) <= nPix^2, ]
    rr <- rc[1, 1] + off$dr
    cc <- rc[1, 2] + off$dc
    keep <- rr >= 1 & rr <= nrow(r) & cc >= 1 & cc <= ncol(r)
    data.frame(from = f, to = terra::cellFromRowCol(r, rr[keep], cc[keep]))
  }))
  out <- circleNeighbours(r, cells = cells, nPix = nPix)
  testthat::expect_equal(as.numeric(out$from), as.numeric(expected$from))
  testthat::expect_equal(as.numeric(out$to), as.numeric(expected$to))
})

testthat::test_that("several focal cells: each gets its own neighbours, and never itself", {
  r <- make_rtm()
  cells <- terra::cellFromRowCol(r, c(5, 15, 30), c(5, 20, 40))
  out <- circleNeighbours(r, cells = cells, nPix = 2)
  testthat::expect_setequal(unique(out$from), cells)
  testthat::expect_false(any(out$from == out$to))
  for (f in cells) {
    testthat::expect_equal(sort(out[from == f, to]), expectedNeighbours(r, f, 2))
  }
})
