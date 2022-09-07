import xarray as xr
import rioxarray as rio
import numpy as np
import pyproj

def open_raster_img(img_path, reproj=True, method='nearest', resolution=None):
    """Opens a raster image as an xarray DataArray object.
    
    This is a convenience function for opening a georeferenced raster image. The
    image must be in a gdal/rasterio supported format.
    
    Parameters
    ----------
    img_path : str
        path to raster image
    reproj : bool, optional
        Reproject directly to rectilinear latlon grid
    method : {nearest, bilinear}
        Interpolation method for reprojection.
    resolution : Tuple of float, optional
        Grid lonlat spacing in degrees.
        
    Returns
    -------
    img : xarray.DataArray
        Image as xarray object.
    """
    img = rio.open_rasterio(img_path)
    crs = img.rio.crs
    img.name = 'img'
    #
    proj = pyproj.Proj(crs)
    if reproj:
        resampling = 1 if method == 'bilinear' else 0
        img = img.rio.reproject(proj.to_latlong().to_proj4(),
                                resampling=resampling,
                                resolution=resolution)
    coords = ['x', 'y']
    for coord in coords:
        if (img[coord].diff(coord) < 0).any():
            img = img.sel(**{coord: img[coord][::-1]})
    if not reproj:
        x, y = np.meshgrid(img.x, img.y)
        lon, lat = proj(x, y, inverse=True)
        img.assign_coords(lat=(('y', 'x'), lat), lon=(('y', 'x'), lon))
    else:
        img = img.rename(x='lon', y='lat')
    return img.squeeze()
