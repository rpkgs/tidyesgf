using Ipaper
using nctools
using nctools.CMIP
# using Tidytable2
using DataFrames

dir_root = path_mnt("X:/rpkgs/tidyesgf/OUTPUT/China_prcp")
outdir = path_mnt("X:/rpkgs/tidyesgf/OUTPUT/China_prcp_combine")

using MPI
MPI.Init()
comm = MPI.COMM_WORLD
cluster = MPI.Comm_rank(comm)
ncluster = MPI.Comm_size(comm)

# function map_dt(fun::Function, lst)
#   map(i -> fun(lst[i]), eachindex(lst))
# end

# urls = readlines("urls.txt")
# info2.file = map(x -> "$indir/$x", basename.(info2.file))
fs = dir(dir_root)
info2 = CMIPFiles_info(fs; include_year=true)

lst = groupby(info2, [:variable, :model, :ensemble, :scenario])
# lens = map_dt(nrow, lst)

# df = @pipe info2 |> _[_.model.=="TaiESM1", :]
# lst = groupby(df, [:variable, :model, :ensemble, :scenario])
nc_combine(lst; outdir)
