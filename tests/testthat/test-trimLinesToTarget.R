test_that("trimLinesToTarget keeps the lines unchanged when the target is not exceeded", {
  skip_on_cran()
  lns <- terra::vect(lapply(1:5, function(i) rbind(c(0, i * 10), c(100, i * 10))), type = "lines", crs = "EPSG:3005")
  len <- function(v) sum(terra::perim(v))
  out <- trimLinesToTarget(lns, target = 1000, measure = len)
  expect_equal(NROW(out$lines), 5L)
  expect_equal(out$area, 500)
})

test_that("trimLinesToTarget trims to within one line of the target", {
  skip_on_cran()
  # 40 lines of 100 m each: a target of 1,230 m means 12 lines (1,200 m, closer than 13 lines = 1,300 m)
  lns <- terra::vect(lapply(1:40, function(i) rbind(c(0, i * 10), c(100, i * 10))), type = "lines", crs = "EPSG:3005")
  len <- function(v) sum(terra::perim(v))
  set.seed(1)
  out <- trimLinesToTarget(lns, target = 1230, measure = len)
  expect_equal(NROW(out$lines), 12L)
  expect_equal(out$area, 1200)
  expect_equal(len(out$lines), out$area)
  # a different seed keeps different lines, but the same number
  set.seed(2)
  out2 <- trimLinesToTarget(lns, target = 1230, measure = len)
  expect_equal(NROW(out2$lines), 12L)
})

test_that("trimLinesToTarget keeps at least one line", {
  skip_on_cran()
  lns <- terra::vect(lapply(1:4, function(i) rbind(c(0, i * 10), c(100, i * 10))), type = "lines", crs = "EPSG:3005")
  len <- function(v) sum(terra::perim(v))
  out <- trimLinesToTarget(lns, target = 10, measure = len)
  expect_equal(NROW(out$lines), 1L)
})

test_that("trimLinesToTarget stops the compounding: repeated duplication adds the target each step", {
  skip_on_cran()
  # Emulates the seismic cluster method: each time step duplicates ALL existing lines (one big
  # cluster), then only the target is kept. Without trimming the line count doubles every step.
  len <- function(v) sum(terra::perim(v))
  lns <- terra::vect(lapply(1:20, function(i) rbind(c(0, i * 10), c(100, i * 10))), type = "lines", crs = "EPSG:3005")
  target <- 1500                                  # 15 lines of 100 m per step
  set.seed(1)
  for (step in 1:6) {
    dup <- terra::shift(lns, dy = 1000 * step)
    added <- trimLinesToTarget(dup, target, len)$lines
    expect_lte(abs(len(added) - target), 100)
    lns <- rbind(lns, added)
  }
  expect_equal(NROW(lns), 20L + 6L * 15L)
})
