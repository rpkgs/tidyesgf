#' Get data nodes which store CMIP6 output
#'
#' @param speed_test If `TRUE`, use [pingr::ping()] to perform connection speed
#'        test on each data node. A `ping` column is appended in returned
#'        data.table which stores each data node response in milliseconds. This
#'        feature needs pingr package already installed. Default: `FALSE`.
#' @param timeout Timeout for a ping response in seconds. Default: `3`.
#'
#' @return A [data.table::data.table()] of 2 or 3 (when `speed_test` is `TRUE`)
#' columns:
#'
#' | Column      | Type      | Description                                                                     |
#' | -----       | -----     | -----                                                                           |
#' | `data_node` | character | Web address of data node                                                        |
#' | `status`    | character | Status of data node. `"UP"` means OK and `"DOWN"` means currently not available |
#' | `ping`      | double    | Data node response in milliseconds during speed test                            |
#'
#' @examples
#' \donttest{
#' get_data_node()
#' }
#'
#' @export
get_data_node <- function(speed_test = TRUE, timeout = 3) {
  # read html page
  f <- tempfile()
  utils::download.file("https://esgf-node.llnl.gov/status/", f, "libcurl", quiet = TRUE)
  l <- readLines(f)

  # locate table
  l_s <- grep("<!--load block main-->", l, fixed = TRUE)
  # nocov start
  if (!length(l_s)) stop("Internal Error: Failed to read data node table")
  # nocov end
  l <- l[l_s:length(l)]
  l_s <- grep("<table>", l, fixed = TRUE)[1L]
  l_e <- grep("</table>", l, fixed = TRUE)[1L]
  # nocov start
  if (!length(l_s) || !length(l_e)) stop("Internal Error: Failed to read data node table")
  # nocov end
  l <- l[l_s:l_e]

  # extract nodes
  loc <- regexec("\\t<td>(.+)</td>", l)
  nodes <- vapply(seq_along(l), function(i) {
    if (all(loc[[i]][1] == -1L)) {
      return(NA_character_)
    }
    substr(l[i], loc[[i]][2], loc[[i]][2] + attr(loc[[i]], "match.length")[2] - 1L)
  }, NA_character_)
  nodes <- nodes[!is.na(nodes)]

  # extract status
  loc <- regexec('\\t\\t<font color="#\\S{6}"><b>(UP|DOWN)</b>', l)
  status <- vapply(seq_along(l), function(i) {
    if (all(loc[[i]][1] == -1L)) {
      return(NA_character_)
    }
    substr(l[i], loc[[i]][2], loc[[i]][2] + attr(loc[[i]], "match.length")[2] - 1L)
  }, NA_character_)
  status <- status[!is.na(status)]

  # nocov start
  if (length(nodes) != length(status)) stop("Internal Error: Failed to read data node table")
  # nocov end
  res <- data.table::data.table(data_node = nodes, status = status)
  data.table::setorderv(res, "status", -1)
  
  if (!speed_test) return(res)
  
  # nocov start
  if (!length(nodes_up <- res[status == "UP", data_node])) {
    message("No working data nodes available now. Skip speed test")
    return(res)
  }
  
  res$speed_ms <- sapply(res$data_node, ping2)
  res %>% arrange(speed_ms)
  # speed <- vapply(nodes_up, ping2, numeric(1))
  # res[status == "UP", ping := speed][order(ping)]
}
