using MPI
MPI.Init()
comm = MPI.COMM_WORLD
cluster = MPI.Comm_rank(comm)
ncluster = MPI.Comm_size(comm)
# if (mod(i, ncluster) != cluster); continue; end

using Ipaper
using nctools
include("index_P.jl")


outdir = path_mnt("X:/rpkgs/tidyesgf/OUTPUT/China_climIndex")
dir_root = "X:/rpkgs/tidyesgf/OUTPUT/China_G050_prcp"
fs = dir(dir_root)

for i = eachindex(fs)
  f = fs[i]
  if (mod(i, ncluster) != cluster); continue; end
  cal_climIndex(f; outdir)
end

# f = "/China_G050_pr_day_CESM2_historical_r1i1p1f1_gn_18500101-20150101.nc"

# Z:/DATA/China/CN0.5.1_ChinaDaily_025x025/CN05.1_Pre_1961_2021_daily_025x025.nc
f = "X:/rpkgs/tidyesgf/OUTPUT/CN05.1_Pre_1961_2021_daily_G050.nc"
cal_climIndex(f; outdir=dirname(outdir))
