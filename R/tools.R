# pair <- function(x, encode = TRUE) {
#   checkmate::assert_vector(x, TRUE, null.ok = TRUE)

#   # get name
#   var <- deparse(substitute(x))

#   # skip if empty
#   if (is.null(x) || length(x) == 0) {
#     return()
#   }
#   # get key name
#   key <- dict[names(dict) == var]
#   if (!length(key)) key <- var

#   if (is.logical(x)) x <- tolower(x)

#   if (encode) x <- query_param_encode(as.character(x))

#   paste0(key, "=", paste0(x, collapse = query_param_encode(",")))
# }

# `%and%` <- function(lhs, rhs) {
#   if (is.null(rhs)) {
#     lhs
#   } else if (lhs == url_base) {
#     paste(lhs, rhs, sep = "", collapse = "")
#   } else {
#     paste(lhs, rhs, sep = "&", collapse = "&")
#   }
# }

get_host <- function(url) {
  stringr::str_extract(url, "(?<=://)[^\\/]*")
}

ping2 <- function(x) {
  cat(sprintf("ping: %-25s ", x))
  time = pingr::ping(x) %>% mean(na.rm = TRUE)
  
  cat_fun = ifelse(is.na(time) || time > 200, warn, ok) 
  cat_fun(sprintf("%.1f", time))
  time
}

#' @importFrom dplyr arrange
ping_host <- function(hosts, verbose = TRUE) {
  speed_ms = sapply(hosts, ping2)
  data.table(host = hosts, speed_ms) %>% arrange(speed_ms)
}


replace_null <- function(lst, replacement = NA) {
  ind <- Ipaper::which.isnull(lst)
  lst[ind] <- ""
  unlist(lst)
}

listk <- function (...){
  cols <- as.list(substitute(list(...)))[-1]
  vars <- names(cols)
  Id_noname <- if (is.null(vars))
      seq_along(cols)
  else which(vars == "")
  if (length(Id_noname) > 0)
      vars[Id_noname] <- sapply(cols[Id_noname], deparse)
  x <- setNames(list(...), vars)
  return(x)
}

rm_empty <- function(x) {
  if (is.list(x)) {
    x[!sapply(x, is_empty)]
  } else {
    x[!is.na(x)]
  }
}

is_empty <- function(x) {
  is.null(x) || 
    (is.data.frame(x) && nrow(x) == 0) || 
    length(x) ==0
}

#' @export
#' @keywords internal
write_url <- function(x, outfile = "url.txt") {
  fwrite(data.table(x), outfile, col.names = FALSE)
}
