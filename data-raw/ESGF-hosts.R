library(data.table)

ESGF_hosts = get_data_node()

fwrite(ESGF_hosts, "data-raw/ESGF_hosts.csv")
usethis::use_data(ESGF_hosts, overwrite = TRUE)
