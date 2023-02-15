#' @import magrittr
#' @importFrom purrr map map_df
#' @importFrom jsonlite fromJSON read_json
#' @importFrom utils modifyList read.table
#' @importFrom stats end setNames start
#' @importFrom lubridate make_date
#' @importFrom data.table data.table as.data.table is.data.table fwrite fread
#' @importFrom dplyr top_n group_by
#' 
#' @keywords internal
"_PACKAGE"

## usethis namespace: start
## usethis namespace: end
NULL

.onLoad <- function(libname, pkgname) {
  if (getRversion() >= "2.15.1") {
    utils::globalVariables(
      c(".", ".SD", ".N")
    )
  }
}
