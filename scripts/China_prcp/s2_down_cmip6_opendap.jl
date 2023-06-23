using Ipaper
using nctools
using nctools.CMIP
# using Tidytable2
using DataFrames

dir_root = path_mnt("/mnt/x/rpkgs/tidyesgf/OUTPUT/China_prcp")
# mkdir(dir_root)

using MPI
MPI.Init()
comm = MPI.COMM_WORLD
cluster = MPI.Comm_rank(comm)
ncluster = MPI.Comm_size(comm)

range = [70, 140, 15, 55]
delta = 5

# d = fread("./urls.txt"; header=false, sep=",")
urls = readlines("urls_pr.txt")
@time info = CMIPFiles_info(urls; include_year=true)
## ssp需要过滤掉一些年份
# info2 = @pipe info |> _[_.year_begin .<= 2100, :] |> 
#               # _[.!is_r1i1p1f1.(_.ensemble), :] |> 
#               _[_.scenario.!="ssp460", :] |> unique
info2 = info
# @pipe info |> _[_.model .=="ICON-ESM-LR", :]

function filter_finished(info2, dir_root)
  fs = basename.(dir(dir_root))
  _, I_x, I_y = match2(basename.(info2.file), fs)
  info2 = info2[Not(I_x),:]
end

# # add a match2 procedure
# @show info2

# df = @pipe info2 |> _[_.scenario.!="ssp585", :] |>
#            _[_.model.=="E3SM-1-0", :] |>
#            _[_.ensemble.=="r2i1p1f1_gr", :] |> 
#            _[_.year_begin .== 2075, :]
           
# historical的IITM-ESM只有一个r1i1p1f1_gn，是最后多了一天导致的，裁剪可以解决
# ssp585的E3SM-1-0的r2i1p1f1_gr的2075-2084年有问题，正好对应一份文件
info2 = info
host = get_host.(info2.file)
CMIP.cbind(info2; host)
lst = groupby(info2, [:host])

function down_groups(urls)
  for i = eachindex(urls)
    if (mod(i, ncluster) != cluster)
      continue
    end
    url = urls[i]

    try
      @time nc_subset(url, range; outdir=dir_root, verbose=false)
    catch ex
      @show ex
    end
  end
end


down_groups(info.file)
# for d = lst
#   println(nrow(d))  
#   down_groups(d.file)
# end

## 删除一些文件
# fs = dir("z:/GitHub/rpkgs/tidyesgf/OUTPUT/ChinaHW")
# d = CMIPFiles_info(fs; include_year=true)
# d2 = d[d.year_begin.>=2100, :]
# rm.(d2.file)
