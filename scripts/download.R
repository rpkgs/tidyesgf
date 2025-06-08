pacman::p_load(
  Ipaper, data.table, dplyr, lubridate,
  httr, xml2, jsonlite
)

facets <- URLencode("activity_id,+data_node,+source_id,+institution_id,+source_type,+experiment_id,+sub_experiment_id,+nominal_resolution,+variant_label,+grid_label,+table_id,+frequency,+realm,+variable_id,+cf_standard_name", reserved = TRUE)

param <- list(
  project = "CMIP6",
  offset = 0,
  limit = 200,
  type = "Dataset",
  format = "application%2Fsolr%2Bjson",
  facets = facets,
  latest = "true",
  variable_id = "evspsbl",
  experiment_id = "ssp245",
  frequency = "mon",
  variant_label = "r1i1p1f1"
)
.param <- paste(names(param), unlist(param), sep = "=", collapse = "&")

url <- glue("https://esgf-metagrid.cloud.dkrz.de/metagrid-backend/proxy/search?{.param}")


p <- GET(url) %>% content()
text <- xml_text(p) %>% fromJSON()

fix_null <- function(xs) {
  xs[which.empty(xs)] <- ""
  unlist(xs)
}

select_url <- function(xs) {
  x <- xs[grepl("THREDDS", xs)]
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

get_fileLink(url)
docs <- text$response$docs
urls <- docs$url %>%
  map(select_url) %>%
  fix_null()
# info = data.table(data_node = docs$data_node, url = fix_null(urls))

info <- select(
  docs, institution_id, source_id, experiment_id, member_id, table_id,
  latest, replica, version, `_timestamp`
) %>%
  map(unlist) %>%
  as.data.table() %>%
  cbind(url = fix_null(urls)) %>%
  arrange(source_id, version)
info2 <- info[url != "", ] %>%
  {
    .[, .SD[order(`_timestamp`, decreasing = TRUE)[1], ], .(source_id)]
  }

res <- llply(info2$url, get_fileLink, .progress = "text")

urls <- unlist(res) %>%
  gsub("fileServeresg", "fileServer/esg", .) %>%
  unique()

d <- CMIP5Files_info((urls))
d2 <- d[end <= "2100-12-31"]

fs <- dir2("ET", "*.nc")
I <- match2(basename(fs), basename(d2$file))
# file.remove(fs[-I$I_x])
d_left <- d2[-I$I_y]

## 存在相同的文件名
# d[, .N, basename(file)][N > 1]

writeLines(d2$file, "urls.txt")
writeLines(d_left$file, "urls_left.txt")


url <- info2$url[1]
# url = info2$url[1]
# p <- GET(url) %>% content()
# xml_find_all(p, "dataset")
# node = xml_children(p)[5]
# writeLines(urls, "urls.txts")
# ns <- c(thredds = "http://www.unidata.ucar.edu/namespaces/thredds/InvCatalog/v1.0")
# ns = xml_ns(p)
# xml_find_all(p, "dataset", ns)

# https://esgf-metagrid.cloud.dkrz.de/
# https://esgf3.dkrz.de/thredds/fileServer/cmip6/ScenarioMIP/IPSL/IPSL-CM6A-LR/ssp126/r1i1p1f1/Amon/evspsbl/gr/v20190903/evspsbl_Amon_IPSL-CM6A-LR_ssp126_r1i1p1f1_gr_201501-210012.nc
