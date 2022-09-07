## Installation
Create a new environment with the required packages (replace `mamba` with `conda` if you don't have it)
```
conda activate base
mamba create -n img_to_nc rioxarray netCDF4 pyproj
```
Then install the utility with
```
conda activate img_to_nc
python setup.py install
```

Usage:
```
$ img_to_nc --help
Usage: img_to_nc [OPTIONS] SRC DST

Options:
  --reproject / --no-reproject
  -m, --method TEXT
  -r, --resolution <FLOAT FLOAT>...
  --help                          Show this message and exit.
```

Example:
```
$ img_to_nc ~/Downloads/H0018_0000_BL3.IMG test.nc
test.nc saved.
```

Output:
```
$ ncdump -h test.nc
netcdf test {
dimensions:
	lon = 759 ;
	lat = 16636 ;
variables:
	double lon(lon) ;
		lon:_FillValue = NaN ;
		lon:axis = "X" ;
		lon:long_name = "longitude" ;
		lon:standard_name = "longitude" ;
		lon:units = "degrees_east" ;
	double lat(lat) ;
		lat:_FillValue = NaN ;
		lat:axis = "Y" ;
		lat:long_name = "latitude" ;
		lat:standard_name = "latitude" ;
		lat:units = "degrees_north" ;
	int64 band ;
	int64 spatial_ref ;
		spatial_ref:crs_wkt = "GEOGCS[\"unknown\",DATUM[\"unknown\",SPHEROID[\"unknown\",3396000,0]],PRIMEM[\"Reference meridian\",0],UNIT[\"degree\",0.0174532925199433,AUTHORITY[\"EPSG\",\"9122\"]],AXIS[\"Longitude\",EAST],AXIS[\"Latitude\",NORTH]]" ;
		spatial_ref:semi_major_axis = 3396000. ;
		spatial_ref:semi_minor_axis = 3396000. ;
		spatial_ref:inverse_flattening = 0. ;
		spatial_ref:reference_ellipsoid_name = "unknown" ;
		spatial_ref:longitude_of_prime_meridian = 0. ;
		spatial_ref:prime_meridian_name = "Reference meridian" ;
		spatial_ref:geographic_crs_name = "unknown" ;
		spatial_ref:grid_mapping_name = "latitude_longitude" ;
		spatial_ref:spatial_ref = "GEOGCS[\"unknown\",DATUM[\"unknown\",SPHEROID[\"unknown\",3396000,0]],PRIMEM[\"Reference meridian\",0],UNIT[\"degree\",0.0174532925199433,AUTHORITY[\"EPSG\",\"9122\"]],AXIS[\"Longitude\",EAST],AXIS[\"Latitude\",NORTH]]" ;
		spatial_ref:GeoTransform = "-37.48965632760937 0.0016872633341273463 0.0 12.48948029458924 0.0 -0.0016872633341273463" ;
	ubyte img(lat, lon) ;
		img:_FillValue = 0UB ;
		img:STATISTICS_MAXIMUM = 202LL ;
		img:STATISTICS_MEAN = 105.349 ;
		img:STATISTICS_MINIMUM = 82LL ;
		img:STATISTICS_STDDEV = 3.65355 ;
		img:scale_factor = 1. ;
		img:add_offset = 0. ;
		img:coordinates = "band" ;
		img:grid_mapping = "spatial_ref" ;
}
```
