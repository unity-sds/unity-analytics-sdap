from setuptools import setup

setup(
    name='img_to_nc',
    version='0.1.0',
    py_modules=['img_to_nc'],
    entry_points={
        'console_scripts': [
            'img_to_nc = img_to_nc:img_to_nc',
        ],
    },
)
