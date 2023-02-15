#' make sure no overlaping in date
#' 
#' @inheritParams rm_duplicate
#' @param d_file object returned by [CMIP5Files_summary()]
#' 
#' @keywords internal
#' @export
check_dfile <- function(d_file, verbose = 0){
    tryCatch({
        rm_duplicate(d_file)
    }, warning = function(w){
        message(sprintf("[w] %s | %s\n", d_file$model[1], w$message))
        suppressWarnings(rm_duplicate(d_file, verbose))
    })   
}

# ' @importFrom missInfo zip_dates
missInfo.MonthDate <- function(dates_begin, dates_end){
    dates <- foreach(begin = dates_begin, end = dates_end) %do% {
        date_begin <- make_date(year(begin), month(begin), 1)
        date_end   <- make_date(year(end), month(end), 1)
        seq.Date(date_begin, date_end, by = "month")    
    } %>% do.call(c, .)
    dates <- unique(dates) %>% sort()
    zip_dates(dates, "month")$str_miss
}


#' Remove duplicated date in `CMIP5Files_summary`
#' 
#' 
#' Currently only `HadGEM2` have overlaping time-period in ncfiles. This 
#' function works well for this situation.
#' 
#' @inheritParams CMIP5Files_summary
#' @param verbose echo duplicated info if `verbose >= 2`
#' 
#' @keywords internal
#' @importFrom lubridate interval %within%
#' @export
rm_duplicate <- function(d, verbose = 0){
    model <- d$model %>% check_str_null()
    ensemble <- d$ensemble %>% check_str_null()

    n0 <- n <- nrow(d)
    d0 <- d
    if (n == 1) return(d)
    # browser()
    I <- c(FALSE, d$start[2:n] < d$end[1:(n-1)]) %>% which()
    
    if (!is_empty(I)){
        ## 1. rm containing interval
        while (TRUE) {
            interval <- interval(d$start, d$end)
            n <- length(interval)
            I1 <- interval %>% {.[-n] %within% .[-1]} %>% c(FALSE, .) %>% which()   # -1
            I2 <- interval %>% {.[-1] %within% .[-n]} %>% c(FALSE, .) %>% which() 
            
            I <- union(I1 - 1, I2)
            if (!is_empty(I)) {
                # if have containing interval, rm it
                d <- d[-I, ]    
            } else {
                # if not break while
                break()
            }
        }
        
        ## 2. fix intersect
        # duplicate date will lead nc_merge error!
        n <- nrow(d)
        if (n >= 2) {
            I <- c(FALSE, d$start[2:n] < d$end[1:(n-1)]) %>% which()
            
            if (!is_empty(I)){
                warn(sprintf("[w] still intersected date! [%s, %s]\n", model, ensemble))
                d$start_adj[2:n] <- pmax(d$start_adj[-1], add_1month(d$end_adj[-n])) 
                d_pre <- d

                I_del <- with(d, start_adj >= end_adj) %>% which
                if (length(I_del) > 0) d <- d[-I_del, ,drop = FALSE]
                
                warn("======================================")
                # print(cbind(d0[, 1:9], file = basename(d0$file)))
                I_show <- unique(c(I - 1, I)) %>% sort()
                print(d_pre[I_show, 1:10])
                if (length(I_del) > 0) {
                    cat("------------------ [delete] -----------------\n")
                    print(d_pre[-I_del, 1:10])
                }
                cat("--------------------------------------\n")
            }
        }
    }

    if (n0 != n){
        if (verbose >= 2) {
            warn("======================================")
            # print(cbind(d0[, 1:9], file = basename(d0$file)))
            print(d0[, 1:10])
            cat("--------------------------------------\n")
            print(d[, 1:10])    
        }
    }
    d
}

add_1month <- function(date){
    year  <- year(date)
    month <- month(date) + 1

    I <- which(month > 12)
    if (!is_empty(I)){
        month[I] <- 1
        year[I] <- year[I] + 1
    }
    make_date(year, month, 1)
}
