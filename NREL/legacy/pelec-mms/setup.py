try:
    from setuptools import setup
except ImportError:
    from distutils.core import setup


def readme():
    with open('README.rst') as f:
        return f.read()


setup(name='pelec-mms',
      version='0.1',
      description='PeleC verification scripts',
      long_description=readme(),
      keywords='PeleC, method of manufactured solutions',
      url='https://github.com/marchdf/pelec-mms',
      download_url='https://github.com/marchdf/pelec-mms',
      author='Marc T. Henry de Frahan',
      author_email='marc.henrydefrahan@nrel.gov',
      license='Apache License 2.0',
      packages=['pelec-mms'],
      install_requires=[
          'matplotlib',
          'numpy',
          'pandas'
      ],
      test_suite='tests',
      tests_require=['nose'],
      include_package_data=True,
      zip_safe=False)
