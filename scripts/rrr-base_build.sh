#!/usr/bin/env bash

if [ -z "$BASH_VERSION" ]; then
  echo "Please do ./$0"
  exit 1
fi

set -ex

cd "$(dirname "$0")"

## Set R compiler flags
R_PAPERSIZE=letter
R_BATCHSAVE="--no-save --no-restore"
R_BROWSER=xdg-open
PAGER=/usr/bin/pager
PERL=/usr/bin/perl
R_UNZIPCMD=/usr/bin/unzip
R_ZIPCMD=/usr/bin/zip
R_PRINTCMD=/usr/bin/lpr
LIBnn=lib
AWK=/usr/bin/awk
CFLAGS="-g -O2 -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g"
CXXFLAGS="-g -O2 -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g"

#
# Configure R options
#
./configure --enable-R-shlib \
             --enable-memory-profiling \
             --with-readline \
             --with-blas="-lopenblas" \
             --enable-BLAS-shlib \
             --disable-nls \
             --without-recommended-packages \
## Build and install
make
make install
## Add a default CRAN mirror
echo "options(repos = c(CRAN = 'https://cran.rstudio.com/'), download.file.method = 'libcurl')" >> /usr/local/lib/R/etc/Rprofile.site
## Add a library directory (for user-installed packages)
mkdir -p /usr/local/lib/R/site-library
chown root:rserver /usr/local/lib/R/site-library
chmod g+wx /usr/local/lib/R/site-library
## Fix library path
echo "R_LIBS_USER='/usr/local/lib/R/site-library'" >> /usr/local/lib/R/etc/Renviron
echo "R_LIBS_SITE=\${R_LIBS_SITE-'/usr/local/lib/R/site-library:/usr/local/lib/R/library:/usr/lib/R/library'}" >> /usr/local/lib/R/etc/Renviron
echo "R_LIBS=\${R_LIBS-'/usr/local/lib/R/site-library:/usr/local/lib/R/library:/usr/lib/R/library'}" >> /usr/local/lib/R/etc/Renviron
## install packages from date-locked MRAN snapshot of CRAN
[ -z "$BUILD_DATE" ] && BUILD_DATE=$(TZ="America/Los_Angeles" date -I) || true
MRAN=https://mran.microsoft.com/snapshot/${BUILD_DATE}
echo MRAN=$MRAN >> /etc/environment
export MRAN=$MRAN
echo "options(repos = c(CRAN='$MRAN'), download.file.method = 'libcurl')" >> /usr/local/lib/R/etc/Rprofile.site
#
# Use littler installation scripts
#
Rscript -e "install.packages(c('littler', 'docopt'), repo = '$MRAN')"
ln -s /usr/local/lib/R/site-library/littler/examples/install2.r /usr/local/bin/install2.r
ln -s /usr/local/lib/R/site-library/littler/examples/installGithub.r /usr/local/bin/installGithub.r
ln -s /usr/local/lib/R/site-library/littler/bin/r /usr/local/bin/r
## TEMPORARY WORKAROUND to get more robust error handling for install2.r prior to littler update
mkdir -p /usr/local/bin/
curl -O /usr/local/bin/install2.r https://github.com/eddelbuettel/littler/raw/master/inst/examples/install2.r
chmod +x /usr/local/bin/install2.r

#
# Build RStudio server
#
# compile and install RStudio Server from source code:
# References:
# https://mark911.wordpress.com/2016/02/06/how-to-compile-and-install-wget-and-rstudio-server-from-source-code-via-github-in-ubuntu-14-04-lts-64-bit/
#
cd /
git clone --depth=1 https://github.com/rstudio/rstudio.git  # Get only latest
cd rstudio/
mkdir build
cd build/
cd ~/rstudio/dependencies/common
bash install-common
bash install-common
cd
bash ~/rstudio/dependencies/linux/install-dependencies-debian --exclude-qt-sdk
bash ~/rstudio/dependencies/linux/install-dependencies-debian --exclude-qt-sdk
cd /tmp
wget http://dl.google.com/closure-compiler/compiler-latest.zip
unzip compiler-latest.zip
rm COPYING README.md compiler-latest.zip
sudo mv compiler.jar ~/rstudio/src/gwt/tools/compiler/compiler.jar
cd ~/rstudio
sudo rm -rf build
sudo cmake -DRSTUDIO_TARGET=Server -DCMAKE_BUILD_TYPE=Release
time sudo make
# sudo make install process should take around 45 minutes to finish
time sudo checkinstall
# sudo checkinstall process should take around 20 minutes to finish
apt-cache show rstudio
# Terminal output should look like this:
# Package: rstudio
# Status: install ok installed
# Priority: extra
# Section: checkinstall
# Installed-Size: 293492
# Maintainer: root
# Architecture: amd64
# Version: 20160206-1
# Provides: rstudio
# Description: Package created with checkinstall 1.6.2
# Description-md5: 556b8d22567101c7733f37ce6557412e
sudo ln -s /usr/local/lib/rstudio-server/bin/rserver /usr/bin
nohup rserver &
# then use a web browser to navigate to http://127.0.0.1:8787/ to access the RStudio Server interface

Advertisements
Share this: