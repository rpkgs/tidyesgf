using Ipaper
using NetCDFTools
using NetCDFTools.CMIP
# using Tidytable2
using DataFrames

dir_root = "/mnt/z/GitHub/rpkgs/tidyesgf/OUTPUT/ChinaHW"

using MPI
MPI.Init()
comm = MPI.COMM_WORLD
cluster = MPI.Comm_rank(comm)
ncluster = MPI.Comm_size(comm)

range = [70, 140, 15, 55]
delta = 5

# d = fread("./urls.txt"; header=false, sep=",")
urls = readlines("urls.txt")
@time info = CMIPFiles_info(urls; include_year=true)
## ssp需要过滤掉一些年份
info2 = @pipe info |> _[_.year_begin .<= 2100, :] |> 
              # _[.!is_r1i1p1f1.(_.ensemble), :] |> 
              _[_.scenario.!="ssp460", :] |> unique

# fs = basename.(dir(dir_root))
# _, I_x, I_y = match2(basename.(info2.file), fs)
# info2 = info2[Not(I_x),:]
# # add a match2 procedure
@show info2

df = @pipe info2 |> _[_.scenario.!="ssp585", :] |>
           _[_.model.=="E3SM-1-0", :] |>
           _[_.ensemble.=="r2i1p1f1_gr", :] |> 
           _[_.year_begin .== 2075, :]
           
# historical的IITM-ESM只有一个r1i1p1f1_gn，是最后多了一天导致的，裁剪可以解决
# ssp585的E3SM-1-0的r2i1p1f1_gr的2075-2084年有问题，正好对应一份文件

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
