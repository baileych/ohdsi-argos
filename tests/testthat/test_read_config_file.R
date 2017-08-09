# Test whether the contents of a config file can be read and parsed correctly
library(jsonlite)

config.path <- (function () find_config_files(dirs = c('config_etc')))()
config.content <- fromJSON(config.path)

test_that('Config file contents (JSON) can be parsed', {
    expect_equal(Argos::read_config_file(config.path), config.content)
    expect_named(config.content, c('src_name', 'src_args'),
                 ignore.order = TRUE)
})


