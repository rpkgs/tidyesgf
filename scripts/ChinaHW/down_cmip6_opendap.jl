using Ipaper
using nctools
using nctools.CMIP
# using Tidytable2
using DataFrames

using MPI
MPI.Init()
comm = MPI.COMM_WORLD
cluster = MPI.Comm_rank(comm)
ncluster = MPI.Comm_size(comm)

get_host(x::AbstractString) = str_extract(x, "(?<=://)[^\\/]*")
is_ssp(x::AbstractString) = x[1:3] == "ssp"
is_r1i1p1f1(x::AbstractString) = x[1:8] == "r1i1p1f1"

function down_each(d)
  prefix = str_extract(f, ".*(?=_\\d{4})")
  date_begin = d[1, :date_begin]
  date_end = d[end, :date_end]
  fout = "$(prefix)_$date_begin-$date_end.nc"

  urls = d.file
  nc_subset(urls, range, fout)
end

range = [70, 140, 15, 55]
delta = 5

# d = fread("./urls.txt"; header=false, sep=",")
urls = readlines("urls.txt")
@time info = CMIPFiles_info(urls; include_year=true)
## ssp需要过滤掉一些年份
info2 = @pipe info |> _[_.year_begin .<= 2100, :] |> 
              _[.!is_r1i1p1f1.(_.ensemble), :] |> 
              _[_.scenario.!="ssp460", :]

# add a match2 procedure

host = get_host.(info2.file)
CMIP.cbind(info2; host)

lst = groupby(info2, [:host])
# hosts = @pipe info.file[1] |> str_extract(_, "(?<=//).*(?=/)")

# lst = groupby(info2, [:variable, :model, :ensemble, :scenario])
# d = lst[1]
# for i = eachindex(lst)
#   if (mod(i, ncluster) != cluster)
#     continue
#   end
#   d = lst[i]
#   @time nc_subset(d, range; outdir="./OUTPUT/ChinaHW")
# end
# nc_subset(f, range);

function down_groups(urls)
  for i = eachindex(urls)
    if (mod(i, ncluster) != cluster)
      continue
    end
    url = urls[i]
    
    try
      @time nc_subset(url, range; outdir="./OUTPUT/ChinaHW")
    catch ex
      @show ex
    end
  end
end


for d = lst
  # println(d)
  println(nrow(d))
  urls = d.file

  try
    down_groups(urls)
  catch e
    @show e
  end
end




## 删除一些文件
# fs = dir("z:/GitHub/rpkgs/tidyesgf/OUTPUT/ChinaHW")
# d = CMIPFiles_info(fs; include_year=true)
# d2 = d[d.year_begin.>=2100, :]
# rm.(d2.file)
