#' wget
#'
#' @param url character
#' @param outfile character
#'
#' @examples
#' url <- "http://esgf-data.dkrz.de/esg-search/wget/?mip_era=CMIP6&experiment_id=ssp370&frequency=day&variable=tas&realm=atmos&member_id=r1i1p1f1&limit=10000"
#' wget(url, "test.txt")
#' @export
wget <- function(url, outfile = NULL) {
  if (is.null(outfile)) outfile <- basename(url)
  wget <- system.file("exec/wget.exe", package = "CMIP6tools")
  cmd <- sprintf("%s \"%s\" -O %s", wget, url, outfile)
  status <- system(cmd)
  # if (status != 0) {
  #     stop("download error")
  # }
}

options_cmip6 <- list2env(list(aria2c = "aria2c"))

#' @export
set_aria2c <- function(aria2c) {
  options_cmip6$aria2c <- aria2c
  invisible()
}

#' @export
get_aria2c <- function() {
  options_cmip6$aria2c
}

#' aria2c
#'
#' @param j --max-concurrent-downloads=N Set maximum number of parallel downloads for
#' every static (HTTP/FTP) URL, torrent and metalink.
#' See also --split and --optimize-concurrent-downloads options.
#' Possible Values: 1-*, Default: 5, Tags: #basic
#' @param s --split=N Download a file using N connections. If more than N URIs
#' are given, first N URIs are used and remaining URLs are used for backup.
#' If less than N URIs are given, those URLs are used more than once so that
#' N connections total are made simultaneously. The number of connections to the
#' same host is restricted by the --max-connection-per-server option. See also the
#' --min-split-size option.
#' Possible Values: 1-*, Default: 5, Tags: #basic, #http, #ftp
#' @param x --max-connection-per-server=NUM The maximum number of connections to one
#' server for each download.
#' Possible Values: 1-16, Default: 1, Tags: #basic, #http, #ftp
#' @param verbose whether to print the downloading command line?
#' @param options other parameters to `aria2c`
#'
#' @import glue
#' @export
aria2c <- function(
    infile, outdir = "OUTPUT", j = 1, x = 4, s = 5,
    verbose = TRUE, run = TRUE,
    options = "") {
  aria2c_path <- get_aria2c()

  is_http <- substr(infile, 1, 4) == "http"
  if (is_http) {
    cmd <- glue::glue("{aria2c_path} -c -x{x} -j{j} -s{s} -d {outdir} {infile} {options}")
  } else {
    aria2c_rem(infile, outdir)
    infile <- gsub(".txt$", "_rem.txt", infile)
    cmd <- glue::glue("{aria2c_path} -c -x{x} -j{j} -s{s} -i {infile} -d {outdir} {options}")
  }
  if (verbose) print(cmd)
  if (run) shell(cmd)
}

#' @export
aria2c_rem <- function(infile, outdir, verbose = TRUE) {
  files_finished <- aria2c_finished(outdir)
  infile_rem <- gsub(".txt$", "_rem.txt", infile)

  if (length(files_finished) > 0) {
    # skip comment lines
    urls <- read.table(infile)[, 1]
    ind <- match(basename(files_finished), basename(urls)) %>% rm_empty() # finished
    # infile <- gsub(".txt$", "_rem.txt", infile)
    if (verbose) {
      print_FUN <- ifelse(length(urls[-ind]) == 0, ok, warn)
      print_FUN(sprintf(
        "[ok] %-16s: %4s finished, %4s left",
        basename(infile), length(ind), length(urls[-ind])
      ))
      # message(sprintf("[ok] remaining urls was written to: %s", infile))
    }
    writeLines(urls[-ind], infile_rem)
  } else {
    if (verbose) message(sprintf("[ok] no file downloaded yet!"))
    file.copy(infile, infile_rem)
  }
}

#' @rdname aria2c
#' @export
aria2c_finished <- function(indir, subfix = "*.nc$|*.nc4$", subfix_temp = "*.aria2$") {
  # there is no nc4 files
  files_downloaded <- dir(indir, subfix, full.names = TRUE) #|.nc4$

  files_temp <- dir(indir, subfix_temp, full.names = T) # temp file
  files_temp <- gsub(".aria2$", "", files_temp)

  # rm aria2c temp files
  files_finished <- setdiff(files_downloaded, files_temp)
  files_finished
}

file.exists <- function(file) {
  status <- file.size(file)
  !(is.na(status) | status < 100)
}
