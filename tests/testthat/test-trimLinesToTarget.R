test_that("trimLinesToTarget keeps the lines unchanged when the target is not exceeded", {
  skip_on_cran()
  lns <- terra::vect(lapply(1:5, function(i) rbind(c(0, i * 10), c(100, i * 10))), type = "lines", crs = "EPSG:3005")
  len <- function(v) sum(terra::perim(v))
  out <- trimLinesToTarget(lns, target = 1000, measure = len)
  expect_equal(NROW(out$lines), 5L)
  expect_equal(out$area, 500)
})

test_that("trimLinesToTarget lands on the target: whole lines plus the next one, shortened", {
  skip_on_cran()
  # 40 lines of 100 m each: a target of 1,230 m means 12 whole lines (1,200 m) plus 30 m of a 13th line
  lns <- terra::vect(lapply(1:40, function(i) rbind(c(0, i * 10), c(100, i * 10))), type = "lines", crs = "EPSG:3005")
  len <- function(v) sum(terra::perim(v))
  set.seed(1)
  out <- trimLinesToTarget(lns, target = 1230, measure = len)
  expect_equal(NROW(out$lines), 13L)
  expect_lte(abs(out$area - 1230), 0.005 * 1230)
  expect_equal(len(out$lines), out$area)
  # a different seed keeps different lines, but ends on the target as well
  set.seed(2)
  out2 <- trimLinesToTarget(lns, target = 1230, measure = len)
  expect_lte(abs(out2$area - 1230), 0.005 * 1230)
  # a target that is a whole number of lines needs no shortened line
  out3 <- trimLinesToTarget(lns, target = 1200, measure = len)
  expect_equal(NROW(out3$lines), 12L)
  expect_equal(out3$area, 1200)
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
