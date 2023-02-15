#' @rdname CMIP5Files_info
#' @export
#'
#' @examples
#' data(files_short)
#' ensemble <- get_ensemble(files_short)
get_ensemble <- function(files) {
  basename(files) %>% str_extract("(?<=_)r\\d.*(?=_\\d{6,8})") # %>% gsub("_gn$", "", .)
}

#' @rdname get_CMIP5
#' @export
get_varname <- function(file) {
  str_extract(basename(file), "^[:alnum:]*")
}

#' get CMIP5 scenario and model from file path
#' @name get_CMIP5
#' @keywords internal
#' NULL

#' @rdname get_CMIP5
#' @export
get_scenario <- function(file) {
  basename(file) %>% str_extract("[a-z,A-Z,\\-,0-9]*(?=_r\\d)")
}

# ! DEPRECATED
#' @rdname get_CMIP5
#' @export
get_scenario2 <- function(file) {
  basename(file) %>% str_extract("^[a-z,A-Z,\\-,0-9]*(?=_)")
}

#' @rdname get_CMIP5
#' @export
get_model <- function(file, prefix = "_", postfix = "_") {
  pattern <- sprintf("(?<=%s).*(?=%s)", prefix, postfix)
  str_extract(basename(file), pattern)
}

#' @rdname CMIP5Files_info
#' @export
#' @examples
#' model <- extract_model(files_short)
extract_model <- function(files) {
  basename(files) %>% str_extract("[[:alnum:]-]*(?=_his|_rcp|_ssp|_piControl)")
  # basename(files) %>% str_extract("(?<=day_|Day_|mon_|Mon).*(?=_his|_rcp|_piControl)")
}

#' @rdname get_CMIP5
#' @export
get_freq <- function(file) {
  str_extract(basename(file), "^[:alpha:]{3,6}")
}

#' @rdname get_CMIP5
#' @export
get_period <- function(scenario = "historical", period = NULL) {
  is_rcp <- str_detect(scenario, "RCP")
  is_his <- str_detect(scenario, "his")

  if (is.null(period)) {
    if (is_his) {
      period <- c(1850, 2012) # Historical
    }
  }

  duration <- 200
  if (scenario == "historical") {
    period <- c(1850, 2012) # Historical
  }
  if (is_rcp) {
    period <- c(2006, 2100) # RCP
  } else if (scenario == "piControl") {
    # duration <- NULL
    period <- NULL
  }
  listk(period, duration)
}

#' @name CMIP5Files_info
#' @title summary CMIP5 files information
#'
#' @description
#' - [get_ensemble]: Extract CMIP5 ensemle name from file names
#' - [extract_model]: Extract CMIP5 model name from file names
#'
#' - [CMIP5Files_info]: Extract CMIP5 information from file names
#' - [CMIP5Files_filter]: Filter corresponding duration or period files.
#' Dates has been adjust from 12-01 to 01-01 for `start_adj`. Duplicated dates
#' are also removed.
#' - [CMIP5Files_summary]: Get the start and end information of every model
NULL

#' @param files CMIP5 nc files, full name path.
#'
#' @rdname CMIP5Files_info
#' @examples
#' CMIP5Files_info(files_short)
#' 
#' @importFrom lubridate ymd date year month
#' @export
CMIP5Files_info <- function(files) {
  varname <- get_varname(files[1]) %>% paste0("_")

  files_short <- basename(files) %>% gsub(varname, "", .)
  model <- extract_model(files)
  ensemble <- get_ensemble(files_short)
  freq <- get_freq(files_short)
  scenario <- get_scenario(files)

  # get begin date and end date of all files
  info <- str_extract_all(files_short, "[0-9]{6,8}") %>%
    do.call(rbind, .) %>%
    as.data.table() %>%
    set_names(c("start", "end"))

  is_month <- nchar(info$start[1]) == 6
  if (is_month) {
    info %<>% map(~ paste0(., "01"))
  }

  info <- lapply(info, ymd) %>% as.data.table()

  info %<>% cbind(scenario, model, ensemble, freq, .)
  info[, `:=`(
    start_adj = start,
    end_adj = end,
    year_start = year(start),
    year_end = year(end)
  )]
  info[, `:=`(len = year_end - year_start + 1)]
  info$file <- files

  # filename already includes model, scenario and ensemble info.
  # info <- info[order(basename(file))] %>% 
  info %>% cbind(Id = seq_along(model), .)
}

#' @importFrom dplyr arrange across starts_with
sort_info <- function() {
  d %>% arrange(across(starts_with(c("scenario", "model"))))
}


#' @param d An object returned by `CMIP5Files_filter` or
#' `CMIP5Files_info` or a data.frame at least with the columns of `
#' 'model', 'year_start_adj', 'year_end', 'file'`.
#'
#' @rdname CMIP5Files_info
#' @examples
#' # Get the summary infomation of CMIP5Files_filter or CMIP5Files_info
#' CMIP5Files_filter(files_short) %>% CMIP5Files_summary()
#'
#' @export
CMIP5Files_summary <- function(d) {
  if (is.character(d)) d %<>% CMIP5Files_info()

  process <- function(di) {
    by <- c("model", "ensemble", "scenario") %>% intersect(colnames(di))
    res <- di[, .(
      start = min(start),
      end = max(end),
      start_adj = min(start_adj),
      end_adj = max(end_adj),
      year_start = min(year_start),
      year_end = max(year_end),
      n = .N
    ), by = by]
    res[, `:=`(
      len     = year_end - year_start + 1,
      len_adj = year(end_adj) - year(start_adj) + 1
    )]
    res[order(toupper(model)), ]
  }
  if (is.data.frame(d)) {
    # data.table
    process(d)
  } else {
    map(d, process)
  }
}
