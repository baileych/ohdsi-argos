# Test setting of ohdsi_default_src


test.src <- c('dummy', 'src')

test_that('Setting of ohdsi_default_src', {
    expect_equal( (set_ohdsi_default_src(test.src))(), test.src)
    expect_equal(ohdsi_default_src(), test.src)
})
