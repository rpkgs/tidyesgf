using Ipaper
using nctools
using nctools.CMIP
# using Tidytable2
using DataFrames

dir_root = "/mnt/z/GitHub/rpkgs/tidyesgf/OUTPUT/ChinaHW"

using MPI
MPI.Init()
comm = MPI.COMM_WORLD
cluster = MPI.Comm_rank(comm)
ncluster = MPI.Comm_size(comm)

function map_dt(fun::Function, lst)
  map(i -> fun(lst[i]), eachindex(lst))
end

urls = readlines("urls.txt")
@time info = CMIPFiles_info(urls; include_year=true)
## ssp需要过滤掉一些年份
info2 = @pipe info |> _[_.year_begin.<=2100, :] |>
              # _[.!is_r1i1p1f1.(_.ensemble), :] |> 
              _[_.scenario.!="ssp460", :] |> unique

indir = "OUTPUT/ChinaHW"
info2.file = map(x -> "$indir/$x", basename.(info2.file))

lst = groupby(info2, [:variable, :model, :ensemble, :scenario])
lens = map_dt(nrow, lst)

# df = @pipe info2 |> _[_.model.=="TaiESM1", :]
# lst = groupby(df, [:variable, :model, :ensemble, :scenario])

function nc_get_value(fs, band=nothing)
  band === nothing && (band = nc_bands(fs[1])[1])

  res = map(f -> begin
      nc_open(f) do ds
        ds[band].var[:]
      end
    end, fs)

  dims = length(size(res[1]))
  cat(res..., dims=dims)
end

function nc_combine(fs, fout)
  f = fs[1]
  nc = nc_open(f)
  band = nc_bands(f)[1]
  v = nc[band]

  printstyled("Reading data...\n")
  @time vals = nc_get_value(fs, band)
  time = nc_get_value(fs, "time")
  
  dims = ncvar_dim(nc)
  dim_time = NcDim("time", time, dims["time"].atts)
  dims[3] = dim_time

  printstyled("Writing data...\n")
  @time nc_write(fout, band, vals, dims, Dict(v.attrib);
    compress=0, goal_attrib=Dict(nc.attrib))
end

function nc_combine(d::AbstractDataFrame; outdir = ".", overwrite=false)

  prefix = str_extract(basename(d.file[1]), ".*(?=_\\d{4})")
  date_begin = d.date_begin[1]
  date_end = d.date_end[end]
  fout = "$outdir/$(prefix)_$date_begin-$date_end.nc"

  if isfile(fout) && !overwrite
    println("[ok] file downloaded already!")
    return
  end
  
  @show fout
  fs = d.file
  nc_combine(fs, fout)  
end

function nc_combine(lst::GroupedDataFrame; outdir = ".", overwrite=false)
  for i = 1:length(lst)
    d = lst[i]
    if mod(i, ncluster) != cluster
      continue
    end
    nc_combine(d; outdir, overwrite)
  end
end

nc_combine(lst; outdir="OUTPUT/combine")
