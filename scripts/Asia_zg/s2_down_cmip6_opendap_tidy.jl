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

# range = [70, 140, 15, 55]
range = [70, 160, 5, 60]
delta = 5
urls = readlines("urls_zg_ghg.txt")[-1]
@time info = CMIPFiles_info(urls; include_year=true)

info2 = filter_finished(info, dir_root) |> add_host
info2.model = @pipe basename.(info2.file) |> 
  str_extract(_, "(?<=day_|dayZ_).*(?=_his|_ssp)")
@show nrow(info2)

writelines(info2.file, "a.txt")


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
