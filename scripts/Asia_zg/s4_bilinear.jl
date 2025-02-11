using Ipaper
using nctools
using nctools.CMIP
using DataFrames


function nc_interp(f, fout;
  scale=Float32(86400), band=nothing,
  range=[70, 140, 15, 55], cellsize=0.5)

  band === nothing && (band = nc_bands(f)[1])

  delta = cellsize / 2
  rlon = range[1:2]
  rlat = range[3:4]
  xx = rlon[1]+delta:cellsize:rlon[2] #|> collect
  yy = rlat[1]+delta:cellsize:rlat[2] #|> collect

  nc_open(f) do nc
    # var = nc[band]
    # units = nc["pr"].attrib["units"]  
    # println(units)
    x = nc["lon"][:]
    y = nc["lat"][:]
    println("Reading ...")
    data = nc_read(f) .* scale # to mm/d

    println("Interpolation ...")
    @time vals = bilinear(x, y, data; range, cellsize)

    dims = [
      NcDim("lon", xx, Dict("longname" => "Longitude", "units" => "degrees east"))
      NcDim("lat", yy, Dict("longname" => "Latitude", "units" => "degrees north"))
      nc_dim(nc, "time")
    ]

    println("Writing ...")
    @time nc_write(fout, band, vals, dims, Dict("units" => "mm/day");
      global_attrib=Dict(nc.attrib))
  end
end

dir_root = path_mnt("X:/rpkgs/tidyesgf/OUTPUT/China_zg_combine")
outdir = "X:/rpkgs/tidyesgf/OUTPUT/China_G050_zg"



fs = dir(dir_root, "nc\$")
info = CMIPFiles_info(fs)
# map(f -> nc_open(f) do nc
#   dims = ncvar_dim(f)
#   dims[""]
#   println(names(dims))
# end, fs);
# f = fs[1]

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
  println("i = $i")
  nc_interp(f, fout; band="pr")
end
