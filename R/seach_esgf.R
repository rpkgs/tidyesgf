build_url <- function(host, param, ...) {
  sprintf("%s=%s", names(param), unlist(param)) %>%
    paste0(collapse = "&") %>%
    paste0(host, "/?", .)
}


default_param_esgf <- list(
  project       = "CMIP6",
  distrib       = "false",
  type          = "File",
  table_id      = "day",
  variable_id   = "tasmax",
  experiment_id = "historical",
  # experiment_id = "hist-nat",
  # source_id   = "ACCESS-CM2",
  member_id     = "r1i1p1f1",
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

#' @rdname search_esgf
#' @export
build_esgf_url <- function(..., param = NULL, 
  host = "https://esgf-node.llnl.gov/esg-search/search") 
{
  keys <- build_esgf_param(..., param = param)
  build_url(host, keys)
}

#' @rdname search_esgf
#' @export 
retrieve_esgf_docs <- function(
  variable_id = "tasmax", 
  table_id = "day", 
  experiment_id = "historical", 
  member_id = "r1i1p1f1", 
  source_id = NULL, 
  ..., param = NULL) 
{
  keys = listk(variable_id, table_id, experiment_id, member_id, source_id) %>% 
    modifyList(param)
  param = build_esgf_param(param = keys)
  # print(param)

  offset   = 0
  numFound = 10000
  
  docs <- NULL
  i = 1

  while (offset < numFound) {
    param["offset"] <- offset
    url <- build_esgf_url(param = param)
    warn(url)

    res <- jsonlite::fromJSON(url)$response
    docs %<>% rbind(res$docs)

    numFound <- res$numFound
    ok(sprintf("[ok] %dth loop: found %4d files ...", i, numFound))
    
    offset <- offset + nrow(docs)
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
#' - table_id      : "day"
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
search_esgf <- function(param, url_type = c("HTTPServer", "OPENDAP"), ping = false) {
  t <- system.time({
    docs <- retrieve_esgf_docs(param = param)
  })
  print(t)

  ## 1.2. 文件挑选与清洗
  # url_type <- c("OPENDAP", "HTTPServer")
  info <- tidy_esgp_docs(docs, url_type)

  ## 1.3. 筛选：最新版本、最快节点
  d_host <- ping_host(info$host %>% unique())
  
  info2 <- merge(info, d_host)
  info2 %<>%
    group_by(file) %>%
    top_n(-1, version) %>% # lastest version
    group_by(file, version) %>%
    top_n(-1, speed_ms) %>% # fast node
    select(-host) %>%
    data.table()
  info2 %>% data.frame()
}
