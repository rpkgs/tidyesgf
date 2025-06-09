pacman::p_load(
  Ipaper, data.table, dplyr, lubridate,
  httr, xml2, jsonlite
)

info = query_esgf()
info_latest = select_latest(info)

res <- llply(info_latest$url, get_fileLink, .progress = "text")
urls <- unlist(res) %>% gsub("fileServeresg", "fileServer/esg", .) %>% unique()

d <- CMIP5Files_info((urls))
d2 <- d[end <= "2100-12-31"]
writeLines(d2$file, "urls.txt")

fs <- dir2("ET", "*.nc")
I <- match2(basename(fs), basename(d2$file))
# file.remove(fs[-I$I_x])
d_left <- d2[-I$I_y]

## 存在相同的文件名
writeLines(d2$file, "urls.txt")
writeLines(d_left$file, "urls_left.txt")
