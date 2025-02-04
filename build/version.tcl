#!/bin/sh
# the next line restarts using tclsh \
exec tclsh "$0" "$@"

# standard
# --------
package require pkgtools
pkgtools::version 1.1.0
