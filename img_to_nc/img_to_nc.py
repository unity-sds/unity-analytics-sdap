import click
from opener import open_raster_img

@click.command()
@click.option('--reproject/--no-reproject', default=True)
@click.option('-m', '--method')
@click.option('-r', '--resolution', type=(float, float))
@click.argument('src')
@click.argument('dst')
def img_to_nc(src, dst, reproject, method, resolution):
    img = open_raster_img(src, reproj=reproject, method=method,
                          resolution=resolution).squeeze()
    img.to_netcdf(dst)
    print(f'{dst} saved.')
    
