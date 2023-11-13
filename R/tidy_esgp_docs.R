filter_esgp_url <- function(urls, url_type = c("OPENDAP", "HTTPServer")) {
  res = urls %>% .[grep(url_type[1], .)]
  if (length(res) == 0) {
    # res = NA
    res = urls %>% .[grep(url_type[2], .)]
  }
  res
}

#' tidy_esgp_docs
#' 
#' @param url_type if `url_type[1]` not found, use `url_type[2]` instead
#' 
#' @importFrom dplyr mutate rename arrange relocate
#' @importFrom data.table data.table as.data.table
#' @importFrom purrr map map_chr
#' 
#' @export 
tidy_esgp_docs <- function(docs, url_type = c("OPENDAP", "HTTPServer"), raw=FALSE) {
  urls_raw = sapply(docs$url, filter_esgp_url, url_type)
  tmp = urls_raw %>% strsplit("\\|")
  info <- data.table(
    url = map_chr(tmp, ~ .[1]) %>% gsub("\\.html$", "", .),
    url_type = map_chr(tmp, ~ .[3])
  )
  
  names <- c(
    "variable", 
    "size", 
    # "version", "_version_", "timestamp", "_timestamp", "mod_time", 
    "source_id",
    # "north_degrees", "south_degrees", "east_degrees", "west_degrees",
    "nominal_resolution"
  )

  urls = info$url
  d = docs[names] %>% map(replace_null) %>% as.data.table() %>% 
    mutate(size = as.numeric(size)/1e6) %>% 
    rename(size_mb = size) %>% 
    cbind(
      file = basename(urls), 
      version = basename(dirname(urls)), 
      host = get_host(urls),
      .) %>% 
    cbind(info) %>% 
    relocate(source_id, file, version) %>% 
    arrange(source_id, file, version)
  
  if (!raw) {
    info = CMIP5Files_info(d$file)
    info %<>% cbind(d[, .(variable, host, version, url_type, url, size_mb)])
    info
  } else {
    d
  }
}

# c(
#   "mip_era", "activity_drs", "institution_id", "source_id", "experiment_id", "member_id", "table_id", "variable_id",
#   "grid_label", "frequency", "realm", "product", "nominal_resolution", "source_type", "grid", "creation_date", "variant_label", "sub_experiment_id", "further_info_url", "activity_id", "data_specs_version", "title", "experiment_title", "model_cohort", "data_node", "index_node", "master_id", "instance_id", "id", "short_description", "replica", "latest", "type", "project", "version", "dataset_id_template_", "directory_format_template_",
#   "variable_long_name", "cf_standard_name", "variable_units", "variable",
#   "north_degrees", "south_degrees", "east_degrees", "west_degrees",
#   "dataset_id", "tracking_id", "size", "mod_time", "checksum", "checksum_type", "url", "citation_url", "pid", "_version_", "retracted", "_timestamp", "score", "timestamp"
# )
