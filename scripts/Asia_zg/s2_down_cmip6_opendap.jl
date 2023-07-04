using Ipaper
using nctools
using nctools.CMIP
using DataFrames
using Tidytable2

add_host(d) = CMIP.cbind(d; host=get_host.(d.file))


function filter_finished(info, dir_root)
  fs = basename.(dir(dir_root))
  _, I_x, I_y = match2(basename.(info.file), fs)
  info[Not(I_x), :]
end


dir_root = path_mnt("/mnt/x/rpkgs/tidyesgf/OUTPUT/China_zg")
# mkdir(dir_root)

# range = [70, 140, 15, 55]
range = [70, 160, 5, 60]
delta = 5

# d = fread("./urls.txt"; header=false, sep=",")
# urls = readlines("urls_zg.txt")
# the first not work
urls = readlines("urls_zg_ghg.txt")[-1]
@time info = CMIPFiles_info(urls; include_year=true)
## ssp需要过滤掉一些年份
# info2 = @pipe info |> _[_.year_begin .<= 2100, :] |> 
#               # _[.!is_r1i1p1f1.(_.ensemble), :] |> 
#               _[_.scenario.!="ssp460", :] |> unique
# @pipe info |> _[_.model .=="ICON-ESM-LR", :]

info2 = filter_finished(info, dir_root) |> add_host
info2.model = @pipe basename.(info2.file) |> 
  str_extract(_, "(?<=day_|dayZ_).*(?=_his|_ssp)")
@show nrow(info2)

writelines(info2.file, "a.txt")

# @pipe info2 |> _[_.model.=="MRI-ESM2-0", :]
# d = @pipe info2 |> _[_.model.=="", :]
# fwrite(info2, "a.txt")

# outdir = "X:/rpkgs/tidyesgf/OUTPUT/_zg"
# outdir2 = "X:/rpkgs/tidyesgf/OUTPUT/China_prw/filtered"

# split_model(d) = groupby(d, [:variable, :model, :ensemble, :scenario])
# lst = split_model(info2)
# lst = groupby(info2, [:host])

function down_groups(urls)
  for i = eachindex(urls)
    if !isCurrentWorker(i); continue; end
    url = urls[i]

    try
      @time nc_subset(url, range; outdir=dir_root, verbose=false, big=false)
    catch ex
      @show ex
    end
  end
end

down_groups(info2.file)
# down_groups(lst[5].file)

# down_groups(info2.file)
# for d = lst
#   println(nrow(d))
  
#   try
#     down_groups(d.file)
#   catch ex
#     @show ex
#   end
# end

## 删除一些文件
# fs = dir("z:/GitHub/rpkgs/tidyesgf/OUTPUT/ChinaHW")
# d = CMIPFiles_info(fs; include_year=true)
# d2 = d[d.year_begin.>=2100, :]
# rm.(d2.file)
