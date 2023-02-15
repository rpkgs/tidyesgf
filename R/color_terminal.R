#' Colored terminal output
#' @name color_terminal
#'
#' @param ... Strings to style.
#' @importFrom crayon green red bold underline
#'
#' @keywords internal
NULL

#' @export
crayon::bold

#' @export
crayon::red

#' @export
crayon::green

#' @export
crayon::underline

#' @rdname color_terminal
ok <- function(...) cat(green(...), sep = "\n")

#' @rdname color_terminal
#' @export
warn <- function(...) cat(red(...), sep = "\n")
# warn  <- function(...) cat(red $ underline (...))

width_str <- function(str, width = NULL) {
  if (!is.null(width) && width > 0) {
    pattern <- sprintf("%%%ds", width)
    sprintf(pattern, str)
  } else {
    sprintf("%s", str)
  }
}

#' @rdname color_terminal
#' @export
num_bad <- function(str, width = NULL, ...) {
  str <- width_str(str, width)
  bold$ underline$ red(str)
}

#' @rdname color_terminal
#' @export
num_good <- function(str, width = NULL, ...) {
  str <- width_str(str, width)
  bold$ underline$ green(str)
}
