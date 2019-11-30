# Test that src_argos() can handle post-connect params

has_sqlite <- function () {
  if (! require(RSQLite, quietly = TRUE))
    skip("RSQLite needed to test src instantiation")
}

get.con.yes <- function(tag) {
  src_argos(basenames = paste0('test_src_dbi_', tag),
            dirs = c('config_etc'),
            allow_post_connect_sql = TRUE, allow_post_connect_fun = TRUE)
}
get.con.no <- function(tag) {
  src_argos(basenames = paste0('test_src_dbi_', tag),
            dirs = c('config_etc'))
}

test.data <- data.frame(id = c(1L, 2L, 3L), str = c('a', 'b', 'c'),
                        stringsAsFactors = FALSE)

test_that('Post-connect SQL executes if permitted', {
  has_sqlite()
  expect_is((mysrc <- get.con.yes('sql')), 'SQLiteConnection')
  expect_is((test.table <- tbl(mysrc,'test_table')), 'tbl')
  expect_equal(collect(test.table), test.data)
})

test_that('Post-connect SQL does not execute unless permitted', {
  has_sqlite()
  expect_is((mysrc <- get.con.no('sql')), 'SQLiteConnection')
  expect_error(tbl(mysrc,'test_table'), 'no such table')
})

test_that('Post-connect function executes if permitted', {
  has_sqlite()
  expect_is((mysrc <- get.con.yes('fun')), 'SQLiteConnection')
  expect_is((test.table <- tbl(mysrc,'test_table')), 'tbl')
  expect_equal(collect(test.table), test.data)
})

test_that('Post-connect function does not execute unless permitted', {
  has_sqlite()
  expect_is((mysrc <- get.con.no('fun')), 'SQLiteConnection')
  expect_error(tbl(mysrc,'test_table'), 'no such table')
})
