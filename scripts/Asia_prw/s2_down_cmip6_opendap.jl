using Ipaper
using nctools
using nctools.CMIP
using DataFrames
# using Tidytable2


function filter_finished(info, dir_root)
  fs = basename.(dir(dir_root))
  _, I_x, I_y = match2(basename.(info.file), fs)
  info[Not(I_x), :]
end


dir_root = path_mnt("/mnt/x/rpkgs/tidyesgf/OUTPUT/China_prw")
# mkdir(dir_root)

# range = [70, 140, 15, 55]
range = [70, 160, 5, 60]
delta = 5

# d = fread("./urls.txt"; header=false, sep=",")
urls = readlines("urls_prw.txt")
@time info = CMIPFiles_info(urls; include_year=true)
## ssp需要过滤掉一些年份
# info2 = @pipe info |> _[_.year_begin .<= 2100, :] |> 
#               # _[.!is_r1i1p1f1.(_.ensemble), :] |> 
#               _[_.scenario.!="ssp460", :] |> unique
# @pipe info |> _[_.model .=="ICON-ESM-LR", :]

info2 = filter_finished(info, dir_root)
CMIP.cbind(info2; host=get_host.(info2.file))

@show nrow(info2)

# outdir = "X:/rpkgs/tidyesgf/OUTPUT/China_prw"
# outdir2 = "X:/rpkgs/tidyesgf/OUTPUT/China_prw/filtered"

# for f = fs
#   file = "$outdir/$f"
#   f_new = "$outdir2/$f"
#   @show file
  
#   mv(file, f_new)
# end



lst = groupby(info2, [:host])

function down_groups(urls)
  for i = eachindex(urls)
    # if !isCurrentWorker(i); continue; end
    url = urls[i]

    # try
      @time nc_subset(url, range; outdir=dir_root, verbose=false)
    # catch ex
    #   @show ex
    # end
  end
end

down_groups(urls)

# down_groups(info2.file)
for d = lst
  println(nrow(d))
  
  try
    down_groups(d.file)
  catch ex
    @show ex
  end
end

## 删除一些文件
# fs = dir("z:/GitHub/rpkgs/tidyesgf/OUTPUT/ChinaHW")
# d = CMIPFiles_info(fs; include_year=true)
# d2 = d[d.year_begin.>=2100, :]
# rm.(d2.file)
