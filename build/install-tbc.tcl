#!/home/boris/bin/tca/tclsh8.4
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
set libfiles {TracI.ico TracI.tcl conf}
set tbclibfiles {lib}
set shareddatafiles {}
set headers {}
set libbinaries {}
set binaries {}
set version 1.0.5

# standard
# --------
package require pkgtools
pkgtools::install $argv

set move2 " \
	TracI.exe TracI$version.exe \
"

foreach dir $argv {
	set workdir [file dirname $dir]
	foreach {src dst} $move2 {
		set srcfile [file join $srcdir $src]
		set dstfile [file join $workdir $dst]
		file copy -force $srcfile $dstfile
puts "file copy -force $srcfile $dstfile"
	}
} 

