#' Set the default src for future Argos functions
#'
#' Several of the utility functions in Argos query tables in a
#' database containing an OHDSI CDM.  All accept a \code{src} argument
#' allowing you to specify the data source to use when creating the necessary
#' \code{tbl} objects.  If you omit this argument, the \code{ohdsi_default_src()}
#' function is called to get the data source.
#'
#' You are free to define \code{ohdsi_default_src()} yourself, or you
#' may use this function as syntactic sugar.  It defines
#' \code{ohdsi_default_src}, in the caller's environment, to simply
#' return the supplied argument.
#' 
#' @param src A \code{\link[dplyr]{src}} object.
#' 
#' @return A function that returns the value of the \code{src} argument.
#'
#' @examples
#' \dontrun{
#' set_default_ohdsi_src(src_argos())
#' set_default_ohdsi_src(my.src)
#' set_default_ohdsi_src(src_postgres(...))
#' }

set_ohdsi_default_src <- function (src) {
    def.src <- function () src
    assign('ohdsi_default_src',
           def.src,
           envir = parent.frame())
    def.src
}
