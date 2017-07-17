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
             --disable-nls \
             --without-recommended-packages \
## Build and install
make
make install
## Add a default CRAN mirror
echo "options(repos = c(CRAN = 'https://cran.rstudio.com/'), download.file.method = 'libcurl')" >> /usr/local/lib/R/etc/Rprofile.site
## Add a library directory (for user-installed packages)
mkdir -p /usr/local/lib/R/site-library
chown root:staff /usr/local/lib/R/site-library
chmod g+wx /usr/local/lib/R/site-library
## Fix library path
echo "R_LIBS_USER='/usr/local/lib/R/site-library'" >> /usr/local/lib/R/etc/Renviron
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