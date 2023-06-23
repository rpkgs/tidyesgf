# R20, Rx5day, R95pTOT, CDD, prcptot
using RollingFunctions
using StatsBase
# using Ipaper

function rollmax5!(x5, x::AbstractVector{T}) where {T<:Real}
  win = 5
  n = length(x)
  # x5 = zeros(T, n-win+1)
  @inbounds for i = 1:n-win+1
    x5[i] = max(x[i], x[i+1], x[i+2], x[i+3], x[i+4])
  end
  x5
end

function GroupFlag(inds::Vector{Int64})
  cumsum([false; diff(inds) .!= 1]) .+ 1
end




function CDD(prcp::AbstractVector{T}) where {T<:Real}
  inds = findall(prcp .< T(1.0))
  grp = GroupFlag(inds)
  _, len = rle(grp)
  maximum(len)
end

function CWD(prcp::AbstractVector{T}) where {T<:Real}
  inds = findall(prcp .>= T(1.0))
  grp = GroupFlag(inds)
  _, len = rle(grp)
  maximum(len)
end

# function index_P(x, inds_ref::BitVector)
#   q95 = quantile(x[inds_ref], 0.95)
#   index_P(x, q95)
# end

function index_P!(x5::AbstractVector{T}, x::AbstractVector{T}, q95::T) where {T<:Real}
  rollmax5!(x5, x)
  rx5day = maximum(x5)

  r20mm = sum(x .>= 20.0) # days
  r95ptot = sum(x[x.>q95])
  prcptot = sum(x[x.>=1.0])
  cdd = CDD(x)
  [cdd, r20mm, rx5day, r95ptot, prcptot]
end

function index_P(x::AbstractVector{T}, q95::T) where {T<:Real}
  x5 = rollmax(x, 5)
  rx5day = maximum(x5)

  r20mm = sum(x .>= 20.0) # days
  r95ptot = sum(x[x.>q95])
  prcptot = sum(x[x.>=1.0])
  cdd = CDD(x)
  [cdd, r20mm, rx5day, r95ptot, prcptot]
end



function cal_climIndex(f; outdir=".", overwrite=false)
  prefix = str_extract(basename(f), ".*(?=_\\d{4})")
  fout = "$outdir/$(prefix)_climIndex.nc"
  
  if isfile(fout) && !overwrite
    println("File exists: $fout")
    return
  end

  dates = nc_date(f)
  data = nc_read(f)

  years = year.(dates)
  grps = unique(years)
  grps = grps[grps.<=2014]

  ## 生成reference period
  period_ref = [1961, 1990]
  inds_ref = period_ref[1] .<= years .<= period_ref[2]
  data_ref = selectdim(data, 3, inds_ref)
  q95 = mapslices(x -> nanquantile(x; probs=[0.95]), data_ref, dims=3)[:, :, 1] |> x -> Float32.(x)
  # q95 = Float32.(q95)

  ## 计算
  nlon, nlat = 140, 80
  varnames = ["cdd", "r20mm", "rx5day", "r95ptot", "prcptot"]
  nvar = length(varnames)
  res = zeros(Float32, nlon, nlat, length(grps), nvar)

  @time @inbounds for k in eachindex(grps)
    year = grps[k]
    mod(k, 10) == 0 && println("year = $year")
    ind = findall(years .== year)
    @views x = data[:, :, ind]
    x5 = zeros(Float32, size(x, 3) - 4)

    for i = 1:nlon, j = 1:nlat
      res[i, j, k, :] = index_P!(x5, x[i, j, :], q95[i, j])
    end
  end

  dims = [
    ncvar_dim(f)[1:2]...
    # NcDim("lon", xx, Dict("longname" => "Longitude", "units" => "degrees east"))
    # NcDim("lat", yy, Dict("longname" => "Latitude", "units" => "degrees north"))
    NcDim("year", grps)
    NcDim("index", varnames)
    # nc_dim(nc, "time")
  ]

  println("Writing ...")
  band = nc_bands(f)[1]
  @time nc_write(fout, band, res, dims)
end

# using BenchmarkTools
# x = rand(Float64, 365)
# x5 = zeros(Float64, 361)
# @benchmark index_P(x, 0.95)
# @benchmark index_P!(x5, x, 0.95)
# @profview index_P(x, 0.95)
