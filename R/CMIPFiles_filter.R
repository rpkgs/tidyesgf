#' @param duration length of year.
#' @param period starting and ending year, e.g. `c(1850, 2005)`. If
#' provided, duration will be overwritten.
#' If duration and period are `null` at the same time, no filter applied.
#' @param check_dupli Boolean. If true, duplicated date will be removed by [check_dfile()].
#' @param verbose
#' * echo nc file missing info, if `verbose >= 1`
#' * echo duplicated info, if `verbose >= 2`
#'
#' @rdname CMIP5Files_info
#' @importFrom stringr str_extract str_extract_all
#'
#' @return d_files A data.table with colnames of
#' `'Id', 'model', 'kind', 'start', 'end', 'year_start', 'year_start_adj',
#' 'year_end', 'file'`
#'
#' @note Only one scenario per time.
#' @seealso [check_dfile()], [rm_duplicate()]
#'
#' @examples
#' # filter CMIP5 files
#' CMIP5Files_filter(files_short, duration = 200)
#' 
#' @importFrom plyr . ddply
#' @export
CMIP5Files_filter <- function(
    files, duration = 200, period = NULL, check_dupli = TRUE,
    verbose = 1) {
  info <- CMIP5Files_info(files)
  ## 删除freq少于1%的freq
  freq <- table(info$freq) %>%
    {
      . / sum(.)
    }
  freq_good <- freq[freq >= 0.01] %>% names()
  info <- info[freq %in% freq_good, ]

  # If duration and period are null at the same time, no filter applied.
  if (is.null(duration) && is.null(period)) {
    d_files <- info
  } else {
    if (is.null(period)) {
      # 替换为dplyr
      d_files <- plyr::ddply(info, .(model, ensemble, freq), filter_duration, duration = duration) %>% data.table()
    } else {
      d_files <- info[year_end >= period[1] & year_start <= period[2]]
      d_files$start_adj %<>% pmax(make_date(period[1], 1, 1))
      d_files$end_adj %<>% pmin(make_date(period[2], 12, 31))
      d_files[, len := year(end_adj) - year(start_adj) + 1]
    }
  }

  rm_dupli <- function(d_file) {
    if (!is.data.table(d_file)) d_file %<>% as.data.table()

    model <- d_file$model %>% check_str_null()
    ensemble <- d_file$ensemble %>% check_str_null()

    d_file2 <- check_dfile(d_file, verbose)
    # note that some model begins from 12-01
    date_start <- d_file2$start_adj[1]

    if (month(date_start) == 12) {
      date_start %<>% add_1month()
      d_file2$start_adj[1] <- date_start
      warn(sprintf(
        "[m] date adjust from 12-01 to 01-01! [%s, %s]",
        model, ensemble
      ))
    }
    # check summary here
    info <- CMIP5Files_summary(d_file2)
    nmiss <- sum(info$len_adj) - sum(d_file2$len)
    if (nmiss > 0) {
      if (verbose >= 1) {
        str_miss <- d_file2[, missInfo.MonthDate(start, end)]
        cat("=========================================\n")
        warn(sprintf(
          "[missing] %2d years: %s in [%s, %s]",
          nmiss, str_miss, model, ensemble
        ))
        print(info)
        cat("-----------------------------------------\n")
        print(d_file2[1:pmin(10, nrow(d_file2)), 1:10])
      }
    }
    d_file2
  }

  if (check_dupli) {
    scenario <- d_files[1, str_extract(
      basename(file),
      sprintf("(?<=%s_).*(?=_%s)", model, ensemble)
    )]
    fmt <- ifelse(grepl("rcp|RCP", scenario), "=== %-6s ===", " %-10s ") %>%
      sprintf("===========================%s===========================\n", .)
    if (verbose > 0) cat(bold(sprintf(fmt, scenario)))
    ## check duplicated date
    d_files <- plyr::ddply(d_files, .(model, ensemble, freq), rm_dupli) %>% data.table()
  }
  return(d_files)
}


# Find the nearest duration's year data of 'piControl'
filter_duration <- function(d, duration = 200) {
  year_max <- max(d$year_end)
  year_min <- min(d$year_start)

  if ((year_max - year_min + 1) > duration) {
    if (d$model[1] == "BNU-ESM") {
      # 修改filter_duration的策略，从左侧优先选够200y
      # from left
      year_max0 <- year_min + duration - 1
      dnew <- subset(d, year_start <= year_max0)
      dnew$end_adj[nrow(dnew)] %<>% pmin(make_date(year_max0, 12, 31))
    } else {
      # from right
      year_min0 <- year_max - duration + 1 # great than the min year
      dnew <- subset(d, year_end >= year_min0)
      # adjust year_start
      dnew$start_adj[1] %<>% pmax(make_date(year_min0, 1, 1))
    }
    dnew %<>% mutate(len = year(end_adj) - year(start_adj) + 1)
    dnew
  } else {
    d
  }
}
