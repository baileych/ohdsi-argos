#' Connect to database using config file
#'
#' \code{src_argos} sets up a \pkg{dplyr} data source using information from
#' a JSON configuration file, and returns \code{\link[dplyr]{src}} for that
#' data source.
#'
#' The configuration file must provide all of the information
#' necessary to set up the \code{\link[dplyr]{src}}.  Given the
#' variety of ways a \code{\link[dplyr]{src}} can be specified, the
#' JSON must be a two-element hash.  The \verb{src_name} key points to
#' a string containing name of \pkg{dplyr} function that sets up the
#' data source (e.g. \code{\link[dplyr]{src_postgres}}).  The
#' \verb{src_args} key points to a nested hash, whose keys are the
#' arguments to that function, and whose values are the argument
#' values.
#'
#' If \code{paths} is present, only the specified paths are checked.
#' Otherwise, \code{\link{find_config_files}} is called to locate
#' candidate configuration files, using \code{dirs} and
#' \code{basenames}, if present.  The first file that exists, is
#' readable, and evaluates as legal JSON is used as the source of
#' configuration data.
#' 
#' @param paths A vector of full path names for the configuration file.  If present,
#'   only \code{paths} is checked.
#' @param dirs A vector of directory names to use in searching for configuration
#'   files, if \code{paths} is absent.  It defaults to \verb{$HOME}, the location
#'   of the file containing the calling function, and the location of this file.
#' @param basenames A vector of file names to use in searching for configuration
#'   file, if \code{paths} is absent.  It defaults to the name of this file.
#' @param config A list containg the configuration data, to be used instead of
#'   reading a configuration file, should you wish to skip that step.
#' 
#' @return A \code{\link[dplyr]{src}} object.  The specific class of the object
#'   is determined by the \code{src_name} in the configuration data.
#'
#' @examples
#' \dontrun{
#' src_argos()  # Search all the defaults
#' src_argos('/path/to/known/config.json') # No defaults
#' src_argos( dirs = c(Sys.getenv('PROJ_CONF_DIR'), 'var/lib', getwd()),
#'            basenames = c('myproj', Sys.getenv('PROJ_NAME')))
#' }

src_argos <- function(paths = NA, dirs = NA, basenames = NA, config = NA) {

    if (is.na(config)) {
        if (is.na(paths)) {
            args <- mget(c('dirs','basenames'))
            args <- args[ !is.na(args) ]
            paths <- do.call(find_config_files, args)
        }
        config <- .read.config(paths)
    }

    do.call(config$src_name, config$src_args)
}


#' Locate candidate configuration files
#'
#' Given vectors of directories, basenames, and suffices,
#' \code{find_config_files} combines them to find existing files.
#'
#' This function is intended to support a variety of installation patterns, so
#' it attempts to be flexible in looking for configuration files.  First,
#' environment variables of the form \emph{basename}\verb{_CONFIG}, where
#' \emph{<basename>} is the uppercase form of each candidate basename, are
#' examined to see whether any translate to a file path.
#'
#' Following this, the path name parts supplied as arguments are used to
#' build potential file names.  If \code{dirs} is not specified, the
#' following directories are checked by default: \enumerate{
#'    \item the user's \verb{$HOME} directory
#'    \item the directory in which the executing script is located
#'    \item the directory in which the calling function's calling function's
#'       source file is located (typically an application-level library)
#'    \item the directory in which the calling function's source file is located
#'       (typically a utility function, such as \code{src_argos})
#' }.  In each location, the file names given in \code{basenames} are checked; if
#' not specified, several default file names are tried: \enumerate{
#'    \item the name of the calling function's source file
#'    \item the name of the executing script
#'    \item the directory in which the calling function's calling function's
#'       source file is located (typically an application-level library)
#' }.  The suffices (file "type"s) of \verb{.json}, \verb{.conf}, and nothing,
#' are tried with each candidate path; you may override this default by
#' specifying \code{suffices}.  Finally, in order to accommodate the Unix
#' tradition of "hidden" configuration files, each basename is prefixed with
#' \verb{.} before tryng the basename alone.
#'
#' @param dirs A vector of directory names to use in searching for configuration
#'   files.
#' @param basenames A vector of file names to use in searching for configuration
#'   files.
#' @param suffices A vector of suffices (file "type"s) to use in searching for
#'   the configuration file.
#' 
#' @return A function that constructs \code{\link[dplyr]{tbl}} objects
#'
#' @examples
#' find_config_files() # All defaults
#' find_config_files(dirs = c(file.path(Sys.getenv('HOME'),'etc'),
#'                           '/usr/local/etc', '/etc'),
#'                  basenames = c('my_app'),
#'                  suffices = c('.conf', '.rc'))
find_config_files <- function(dirs = .dir.defaults(),
                              basenames = .basename.defaults(),
                              suffices = .suffix.defaults()) {

    files <- c()

    for (b in basenames) {
        cand <- Sys.getenv(paste0(toupper(b),'_CONFIG'))
        if (cand %in% files) next
        if (file.exists(cand)) files <- c(files,cand)
    }
    
    for (d in dirs[ !is.na(dirs) ]) {
        for (b in basenames) {
            for (name in c(paste0('.',b), b)) {
                for (type in suffices) {
                    cand <- file.path(d,
                                      paste0(name,type))
                    if (nchar(cand) < 1 || cand %in% files) next
                    if (file.exists(cand)) files <- c(files,cand)
                }
            }
        }
    }
    files
}


### "Private" functions

# Internal function to generate vector of dirs to search
.dir.defaults <- function() {
    p <- c(Sys.getenv('HOME'),
           unlist(lapply(c(1, sys.parent(3), sys.parent(2)),
                         function (x)
                             tryCatch(utils::getSrcDirectory(sys.function(x)),
                                      error = function(e) NULL)
                         )))
#    p[nchar(p) > 0]
}

# Internal function to generate vector of basenames to search
.basename.defaults <- function() {
    p <- unlist(lapply(c(sys.parent(2), 1, sys.parent(3)),
                       function (x)
                           sub('\\.[^.]*$', '',
                               tryCatch(utils::getSrcFilename(sys.function(x)),
                                        error = function(e) NULL),
                               perl = TRUE)
                       ))
    p[nchar(p) > 0]
}

# Internal function to generate vector of suffices to search
.suffix.defaults <- function() c('.json', '.conf', '')

# Internal function to read JSON config file; returns contents of
# first file successfully read
.read.config <- function(paths = NA) {
    for (p in paths) {
        config <-
            tryCatch(jsonlite::fromJSON(p),
                     error = function(e) NA)
        if (!is.na(config[1])) return(config)
    }
}
