# tests/testthat/test-cores.R
library(testthat)

test_that("the tests run with at most 2 cores", {
  skip_on_cran()
  ## tests/run-tests.R sets the limit; other harnesses (e.g. upstream's tests.yml) do not
  skip_if(Sys.getenv("OMP_THREAD_LIMIT") == "", "not run by tests/run-tests.R")
  expect_identical(Sys.getenv("OMP_THREAD_LIMIT"), "2")
  expect_lte(data.table::getDTthreads(), 2L)
})
