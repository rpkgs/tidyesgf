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

build_esgf_param <- function(..., param = NULL) {
  keys <- c(param, list(...))
  # print(str(keys))
  keys <- modifyList(default_param_esgf, keys) %>% unlist()
  keys
}

#' build_esgf_url
#' 
#' @param param list parameters
#' @param ... named parameters
build_esgf_url <- function(..., param = NULL, host = "https://esgf-node.llnl.gov/esg-search/search") {
  keys <- build_esgf_param(..., param = param)
  build_url(host, keys)
}

retrieve_esgf_docs <- function(..., param = NULL) {
  param = build_esgf_param(..., param = NULL)
  offset   = 0
  numFound = 10000
  
  docs <- NULL
  i = 1
  
  while (offset < numFound) {
    param["offset"] <- offset
    url <- build_esgf_url(param = param)
    # print(offset)
    # ok("")
    res <- jsonlite::fromJSON(url)$response
    docs %<>% rbind(res$docs)

    numFound <- res$numFound
    ok(sprintf("[ok] %dth loop: found %4d files ...", i, numFound))
    
    offset <- offset + nrow(docs)
    i = i + 1
  }
  docs
}

search_esgf <- function() {  
  # do.call(paste0, param)
  # paste0()
  # GET()  
}

extract_query_file <- function(docs) {
  
}
