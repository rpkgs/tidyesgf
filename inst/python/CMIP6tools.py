import xarray as xr
import numpy as np
import os
from os import path
from functools import partial

## By Dongdong Kong; 2023-02-17
## References
# 1. http://gallery.pangeo.io/repos/pangeo-gallery/cmip6/search_and_load_with_esgf_opendap.html


## 截取中国范围内的数据
def clip_china(ds, range_china = np.array([70, 140, 15, 55]), delta = 3):
    # 向外稍微扩展，以确保插值时有足够的数据
    slon = range_china[:2] + np.array([-1, 1]) * delta # selected lon and lat
    slat = range_china[2:] + np.array([-1, 1]) * delta
    print(slon, slat)
    return ds.sel(lon=slice(*slon), lat=slice(*slat)) # include 


def get_bands(ds):
    vars = list(ds.keys())
    vars_coord = {'time_bnds', 'lat_bnds', 'lon_bnds', 'time', 'lat', 'lon'}
    return list(set(vars).difference(vars_coord))


def download_nc_dap(url, outfile=None, outdir="CMIP6", 
  overwrite=False, complevel=1):
    # url = "https://esgf-data2.llnl.gov/thredds/dodsC/user_pub_work/CMIP6/CMIP/E3SM-Project/E3SM-1-0/piControl/r1i1p1f1/day/tasmax/gr/v20210707/tasmax_day_E3SM-1-0_piControl_r1i1p1f1_gr_03510101-03601231.nc"
    # download_nc_dap(url)
    if outfile is None: 
        if not os.path.exists(outdir): os.makedirs(outdir)
        outfile = path.join(outdir, path.basename(url))
    
    if (not os.path.exists(outfile)) or overwrite:
        # try:
        # ds = xr.open_dataset(url, concat_dim="time", preprocess=partial(clip_china))
        print(path.basename(outfile))
        
        # 速度非常慢，怀疑没有生效
        ds = xr.open_dataset(url)
        d = clip_china(ds)
        
        varname = get_bands(ds)[-1]
        compress = {varname: {"zlib": True, "complevel": complevel}}
        
        # print(d)
        d.to_netcdf(outfile, encoding=compress) # 加载数据需要占用一定时间
        # except:
        #     print("[e] %s" % url)


## TODO add a main script
