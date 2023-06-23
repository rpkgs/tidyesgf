include("main_pkgs.jl")
using MPI
MPI.Init()
comm = MPI.COMM_WORLD
cluster = MPI.Comm_rank(comm)
ncluster = MPI.Comm_size(comm)
# if (mod(i, ncluster) != cluster); continue; end

dir_root = path_mnt("X:/rpkgs/tidyesgf/OUTPUT/China_prcp_combine")
outdir = "X:/rpkgs/tidyesgf/OUTPUT/China_G050_prcp"

fs = dir(dir_root, "nc\$")
info = CMIPFiles_info(fs)

# - `units`: `kg m-2 s-1`
n = nrow(info)
for i = 1:n
  f = fs[i]
  fout = "$outdir/China_G050_$(basename(f))"
  
  if isfile(fout); 
    continue
  end
  
  if (mod(i, ncluster) != cluster)
    continue
  end
  # f = info.file[i]  
  println("i = $i")
  nc_interp(f, fout; band="pr")
end


## 观测数据
f = "Z:/DATA/China/CN0.5.1_ChinaDaily_025x025/CN05.1_Pre_1961_2021_daily_025x025.nc"
nc = nc_open(f)

# x = nc["lon"][:]
# y = nc["lat"][:]
# println("Reading ...")
# data = nc_read(f) .* scale # to mm/d

fout = "CN05.1_Pre_1961_2021_daily_G050.nc"
nc_interp(f, fout; scale=Float32(1), band="pre")
