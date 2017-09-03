# Argos

The Argos package provides a simple toolset intended to make a few common tasks easier when using databases that implement the OMOP/OHDSI CDM.   Argos lets you abstract out conenction information for [dplyr](https://github.com/hadley/dplyr) into configuration files, to promote reuse and to limit the amount of sensitive credentials that land in your analytic code. 

From the package vignette:

## Setting up connections

The [dplyr](https://cran.r-project.org/web/packages/dplyr/) package abstracts away database connection details, and a fair amount of dialect-specific SQL, behind its own `src` objects or its use of `DBI` connection objects.  However, code that uses [dplyr](https://cran.r-project.org/web/packages/dplyr/) must construct an appropriate `src` or connection, and use it to create any `tbl` instances that are used in a `join` operation.  This creates two problems for code that one might want to distribute.  First, the connection-building `src_whatever` or `dbConnect` statement typically contains credentials used to authenticate to the database server.  This creates a security risk, as sending around personal credentials isn't a good idea for a variety of reasons, and using the same "service credentials" for many users makes tracking usage more difficult.  It also makes it harder to reuse code, since it has to be edited to accommodate different users or different databases.

Argos provides some help in this area by providing the `src_argos` function.  As its documentation explains, `src_argos` isn't a new type of [dplyr](https://cran.r-project.org/web/packages/dplyr/) data source, but an adapter that lets you create a data source of a type known to [dplyr](https://cran.r-project.org/web/packages/dplyr/) or [DBI](https://cran.r-project.org/web/packages/DBI/) using configuration data passed to `src_argos`, or, more importantly, supplied in a configuration file.  This behavior is not OHDSI-specific, and can be used to set up any [dplyr](https://cran.r-project.org/web/packages/dplyr/)  or [DBI](https://cran.r-project.org/web/packages/DBI/)data source.

### Configuration file structure

Argos configuration files provide a simple way to represent in JSON the information needed to construct a data source.  The JSON must define a single object (or hash), which is translated into a list structure within R.  Two keys from the object are meaningful.  The `src_name` key must point to either

* the name of a [dplyr](https://cran.r-project.org/web/packages/dplyr/) function used to construct a data source, typically a database connection, such as `src_postgres` or `src_mysql`, or
* the name of a driver function compatible with the [DBI](https://cran.r-project.org/web/packages/DBI/) specification, such as `SQLite` or `PostgreSQL` (N.B. the initial `R` in the package name is not included).

The `src_args` key itself points to a list, where the keys are names of arguments to the constructor, and the corresponding elements are the argument values.  Here's a typical example:

```
{
    "src_name" : "src_postgres",
    "src_args" : {
	      "host"     : "my.database.server",
		    "port"     : 5432,
		    "dbname"   : "project_db",
		    "username" : "my_credential",
		    "password" : "DontLook",
		    "options"  : "-c search_path=schema0,schema1,schema2"
     }
}
```

If you're deriving the configuration information programattically, you can pass it directly to `src_argos` via the `config` argument, but it's perhaps more common that configuration remains the same for a given situation.  For these cases, Argos encourages separation of configuration from code.

## Finding configuration data

Argos tries to provide you with a lot of flexibility in the way you deploy your code and configuration, by letting you get the latter to `src_argos` in a variety of ways.  The first option that returns valid JSON is used, and later options aren't checked; `src_argos` does not try to merge data from more than one source.

#### Telling `src_argos` what to read

If you know where your configuration data lives, you can point `src_argos` directly to it, using the `paths` argument.  This is a vector of paths to check, so you can provide a series of places to look, and `src_argos` will use the first one it finds.  Each place can be a path to a local file, or a URL that returns JSON.  (As an implementation detail, since `src_json` uses [jsonlite::fromJSON](https://cran.r-project.org/web/packages/jsonlite/) under the hood, `paths` can also contain a JSON string rather than a pointer to outside configuration data.  We don't make any promises about this, as [jsonlite::fromJSON](https://cran.r-project.org/web/packages/jsonlite/) might change someday, but it can be a handy way to provide fallback configuration information after having `src_argos` check for an outside resource.)

#### Using environment variables

If you need to specify where to look at runtime, you can use the environment variable _BASENAME_`CONFIG` to point to a configuration file, where _BASENAME_ is one of the basenames `src_argos` would usually check (see below).  One note: `src_argos` will only pay attention to this environment variable if it points to an actual file, not a URL or JSON string.  This is construed as a feature, in that it may limit the damage someone can inflict by fiddling with the environment.  If you trust the environment, you can be more permissive by writing something like

```
my.paths <- c()
for (bn in my.basenames) {
    my.info <- Sys.getenv(paste0(toupper(bn), '_CONFIG'))
	if (my.info != '') my.paths <- c(my.paths, my.info)
}
src <- if (length(paths) > 0) src_argos(paths = my.paths) else src_argos(other.args)
```

#### Searching for configuration files

Argos tries to support a number of common deployment styles through its use of default search locations for configuration files.  For those who prefer per-user config files, it will look in your home directory.  If you prefer to deploy configuration data with your application, you can put the configuration file in the same directory as your main application program.  Finally, you can put the configuration file in the same directory as library code that calls `src_argos` either directly or through one intermediate call.

Similarly, `src_argos` will try to find files with the same basename as your application, or as the library file(s) making the call to `src_argos`.  Optionally, the file can have a "type" (i.e. suffix) of `.json` or `.conf`, or none at all.  Whatever the suffix, though, the contents must be JSON.   If these options don't suit your deployment strategy, you can provide explicit hints to `src_argos` using the `dirs`, `basenames`, and `suffices` arguments.

Finally, to accommodate convention on Unix-like systems, Argos first checks for a "hidden" file with a leading `.` before checking for the plain basename.

## Using a default connection

Each time [dplyr](https://cran.r-project.org/web/packages/dplyr/) sets up a new `tbl` it requires a data source.  Since the OHDSI-specific parts of Argos frequently reference the database, especially vocabulary tables, and since [dplyr](https://cran.r-project.org/web/packages/dplyr/)'s `src` constructors aren't idempotent, we need to keep track of the active data source.  You can pass the current data source to Argos functions using the named argument `src`.  If you don't, Argos will try to use the return value of `ohdsi_default_src()` as a data source.  You can define this function yourself, or you can use the `set_ohdsi_default_src` function to set it.

Whether your an adherent of DRY or a devotee of no-action-at-a-distance, we've got you covered.

Enjoy!

## Installation

You can install Argos from github with:

```R
# install.packages("devtools")
devtools::install_github("baileych/ohdsi-argos")
```

## Example

Establish a [dplyr](https://github.com/hadley/dplyr) connection to a database:

```R
library(Argos)

# Use defaults
my.src <- src_argos()

# Look for project config files
my.src <- src_argos( dirs = c('/my/project/dir', '/team/dir/conf', getwd()),
    basenames = c('test.db', 'dev.db') )
```
