
# R package template

<!-- badges: start -->
[![R-CMD-check](https://github.com/rpkgs/tidyesgf/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/rpkgs/tidyesgf/actions/workflows/R-CMD-check.yaml)
[![codecov](https://codecov.io/gh/rpkgs/tidyesgf/branch/master/graph/badge.svg)](https://app.codecov.io/gh/rpkgs/tidyesgf)
<!-- [![CRAN](http://www.r-pkg.org/badges/version/tidyesgf)](https://cran.r-project.org/package=tidyesgf) -->
<!-- [![total](http://cranlogs.r-pkg.org/badges/grand-total/tidyesgf)](https://www.rpackages.io/package/tidyesgf) -->
<!-- [![monthly](http://cranlogs.r-pkg.org/badges/tidyesgf)](https://www.rpackages.io/package/tidyesgf) -->
<!-- badges: end -->

- [x] `ESGF`: `CMIP6`文件检索；

- [x] `opendap`: 裁剪指定区域并下载；如果只是下载中国区域，相比于全球，数据量会小20倍，因此下载速度也更可观。

## Installation

You can install the development version of `tidyesgf` like so:

``` r
remotes::install_github("rpkgs/tidyesgf")
```

## Example

This is a basic example which shows you how to solve a common problem:

``` r
library(tidyesgf)
## basic example code
```
