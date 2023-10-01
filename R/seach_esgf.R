build_url <- function(host, param, ...) {
  sprintf("%s=%s", names(param), unlist(param)) %>%
    paste0(collapse = "&") %>%
    paste0(host, "/?", .) |> 
    URLencode()
}


default_param_esgf <- list(
  project       = "CMIP6",
  distrib       = "false",
  type          = "File",
  frequency      = "day",
  variable_id   = "tasmax",
  experiment_id = "historical",
  # experiment_id = "hist-nat",
  # source_id   = "ACCESS-CM2",
  # member_id     = "r1i1p1f1",
  limit         = 1e4,
  format        = "application%2Fsolr%2Bjson",
  # replica       = FALSE,
  latest        = TRUE,
  offset        = 0
)

#' @rdname search_esgf
#' @export
build_esgf_param <- function(..., param = NULL) {
  # param should be list
  if (is.character(param)) {
    param %<>% as.list()
  }
  keys <- c(param, listk(...))
  # print(str(keys))

  keys <- modifyList(default_param_esgf, keys) %>% 
    rm_empty()
  keys
}

host_llnl = "https://esgf-node.llnl.gov/esg-search/search"
host_dkrz = "https://esgf-data.dkrz.de/esg-search/search"

#' @rdname search_esgf
#' @export
build_esgf_url <- function(..., param = NULL, host = host_dkrz) 
{
  keys <- build_esgf_param(..., param = param)
  build_url(host, keys)
}

#' @rdname search_esgf
#' @importFrom httr GET content
#' @export 
retrieve_esgf_docs <- function(
  variable_id = "tasmax", 
  frequency = "day", 
  experiment_id = "historical", 
  member_id = "r1i1p1f1", 
  source_id = NULL, 
  ..., param = NULL) 
{
  keys = listk(variable_id, frequency, experiment_id, member_id, source_id) %>% 
    modifyList(param)
  param = build_esgf_param(param = keys)
  # print(param)

  offset   = 0
  numFound = Inf
  
  docs <- NULL
  i = 1

  while (offset < numFound) {
    param["offset"] <- offset
    url <- build_esgf_url(param = param)
    warn(url)

    p = GET(url) %>% content()
    res <- jsonlite::fromJSON(p)$response
    docs %<>% dplyr::bind_rows(res$docs)

    if (is.infinite(numFound)) numFound <- res$numFound

    ok(sprintf("[ok] %dth loop: found %4d files ...", i, numFound))
    
    offset <- nrow(docs)
    # print2(offset, res$numFound)
    i = i + 1
  }
  docs
}


#' search_esgf
#'
#' @details
#' #### Parameters
#'
#' - project       : "CMIP6"
#' - type          : "File"
#' - frequency      : "day"
#' - variable_id   : "tasmax"
#' - experiment_id : "historical"
#' - source_id     : "ACCESS-CM2"
#' - member_id     : "r1i1p1f1"
#' - latest        : TRUE
#'
#' @param param list parameters
#' @param ... named parameters
#'
#' @export 
search_esgf <- function(param, url_type = c("OPENDAP", "HTTPServer"), ping = false, raw=FALSE) {
  docs <- retrieve_esgf_docs(param = param)
  ## 1.2. 文件挑选与清洗
  # url_type <- c("OPENDAP", "HTTPServer")
  # url_type <- c("HTTPServer", "OPENDAP") %>% rev()
  info <- tidy_esgp_docs(docs, url_type)
  info %<>% group_by(file) %>%
    top_n(-1, version) %>%
    data.table()
  if (raw) return(info)
  
  ## 1.3. 筛选：最新版本、最快节点
  d_host <- ping_host(info$host %>% unique())
  
  info2 <- merge(info, d_host)
  info2 %<>% # lastest version
    group_by(file, version) %>%
    top_n(-1, speed_ms) %>% # fast node
    select(-host) %>%
    data.table()
  info2
}
