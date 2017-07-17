# rkt-rrr-base
RKT Container: R-project (base), RServer, LittleR

## Rkt Usage

````bash
$ rkt run taqtiqa.com/rkt-rrr-base:3.4.1.1
````

## Rkt Build
````bash
$ sudo ./rkt-rrr-base.sh
````

## Rkt Container Contents
- Ubuntu Yakkety (`debootstrap`)
- R-project source build (`3.4.1`)
- RStudio server source build (`TBA`)
- littler (`TBA`)
- Nomad (`TBA`)
- Consul (`TBA`)

### R-packages:
The key for Ubuntu archives on CRAN is imported (“Michael Rutter marutter@gmail.com” with key ID E084DAB9)
R_LIBS_USER `/usr/lib/R/site-library`
R_LIBS_SITE `/usr/lib/R/site-library` /usr/local/lib/R/etc/Renviron

### Ubuntu Packages:
- The `r-base` package and dependencies
- Packages in the `r-recommended` bundle listed [here](https://cran.r-project.org/bin/linux/ubuntu/)
- The `littler` and `r-cran-rodbc` packages