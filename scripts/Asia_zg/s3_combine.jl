using Ipaper
using nctools
using nctools.CMIP
using Tidytable2
using Tidytable2: @subset
using DataFrames

dir_root = path_mnt("/mnt/x/rpkgs/tidyesgf/OUTPUT/China_zg")
outdir = path_mnt("/mnt/x/rpkgs/tidyesgf/OUTPUT/China_zg_combine")


fs = dir(dir_root)
info = CMIPFiles_info(fs; include_year=true)
info.freq = get_freq.(info.file)

# filter_model(info2, ["ACCESS-CM2", "NorESM2-MM"])
# table(info2.model)

split_model(d) = groupby(d, [:freq, :variable, :model, :ensemble, :scenario])

lst = split_model(info)
# lens = map_dt(nrow, lst)

# df = @pipe info2 |> _[_.model.=="TaiESM1", :]
# lst = groupby(df, [:variable, :model, :ensemble, :scenario])
for d = lst
  try
    nc_combine(d; outdir)
  catch ex
    @show ex
  end
end


dat = filter_model(info, ["FGOALS-g3", "EC-Earth3"][2])
d = split_model(dat)[1]

nc_combine(d; outdir=".")
# @subset(info, scenasrio == "historical" .&& model == "EC-Earth3", verbose=true)
