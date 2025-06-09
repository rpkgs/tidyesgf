$url = "http://esg-dn1.nsc.liu.se/thredds/fileServer/esg_dataroot10/cmip6data/20250305_smhi_req00232/CMIP6/ScenarioMIP/EC-Earth-Consortium/EC-Earth3-HR/ssp245/r1i1p1f1/Amon/evspsbl/gr/v20250226/evspsbl_Amon_EC-Earth3-HR_ssp245_r1i1p1f1_gr_209101-209112.nc"

aria2c -c $url --http-proxy="http://127.0.0.1:1081"
