#!/bin/sh
# the next line restarts using tclsh \
exec tclsh "$0" "$@"

set script [file normalize [info script]]
if {"$tcl_platform(platform)"=="unix"} {
	while 1 {
		if {[catch {set script [file normalize [file readlink $script]]}]} break
	}
}

# settings
# --------

set srcdir [file dir [file dir $script]]
set libfiles {lib pedviewer.tcl conf help settings.tcl}
set tbclibfiles {}
set shareddatafiles {}
set headers {}
set libbinaries {}
set binaries {}
set version 0.7.0

# standard
# --------
package require pkgtools
pkgtools::install $argv

