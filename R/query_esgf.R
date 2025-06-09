fix_null <- function(xs) {
  xs[which.empty(xs)] <- ""
  unlist(xs)
}

select_url <- function(xs) {
  x <- xs[grepl("THREDDS", xs)]
  if (is.null(x)) x = ""
  gsub("|application/xml+thredds|THREDDS", "", x, fixed = TRUE)
}

get_host <- function(url) {
  l <- httr::parse_url(url)
  sprintf("%s://%s", l$scheme, l$hostname)
}

get_fileLink <- function(url) {
  p <- read_html(url)
  # host = xml_find_all(p, "//property[@name='citation_url']") %>%
  #   xml_attr("value") %>% get_host()
  host <- get_host(url)
  path <- xml_find_all(p, "//access") %>%
    {
      xml_attr(., "urlpath")
    } %>%
    unique()
  # host = "http://vesg.ipsl.upmc.fr"
  link <- sprintf("%s/thredds/fileServer/%s", host, path)
  link
}

#' @export
query_esgf <- function(variable_id = "evspsbl", experiment_id = "ssp245", 
  frequency = "mon", variant_label = "r1i1p1f1", limit = 200) {
  
  facets <- URLencode("activity_id,+data_node,+source_id,+institution_id,+source_type,+experiment_id,+sub_experiment_id,+nominal_resolution,+variant_label,+grid_label,+table_id,+frequency,+realm,+variable_id,+cf_standard_name", reserved = TRUE)

  param <- listk(
    project = "CMIP6",
    offset = 0,
    limit,
    type = "Dataset",
    format = "application%2Fsolr%2Bjson",
    facets = facets,
    latest = "true",
    variable_id,
    experiment_id,
    frequency,
    variant_label
  ) %>% rm_empty()
  .param <- paste(names(param), unlist(param), sep = "=", collapse = "&")

  url <- glue("https://esgf-metagrid.cloud.dkrz.de/metagrid-backend/proxy/search?{.param}")

  p <- GET(url) %>% content()
  text <- xml_text(p) %>% fromJSON()

  docs <- text$response$docs
  urls <- map(docs$url, select_url) %>% fix_null()

  info <- select(
    docs, institution_id, source_id, experiment_id, member_id, table_id,
    latest, replica, version, `_timestamp`
  ) %>% 
    map(unlist) %>%
    as.data.table() %>%
    cbind(url = fix_null(urls)) %>%
    arrange(source_id, version) %>%
    unique()
  info
}

select_latest <- function(info) {
  info[url != "", ] %>%
    {
      .[, .SD[order(`_timestamp`, decreasing = TRUE)[1], ], .(source_id)]
    }
}
