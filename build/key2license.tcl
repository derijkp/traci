#!/home/boris/darcs/tca/Linux-i686/tclsh8.4 

###########
# source libs
###########

set dir [file dirname [info script]]
source [file join $dir .. lib/code/functions.tcl]
source [file join $dir .. lib/code/Main.tcl]

set main [info body main]
regexp {set ::version ([^\n]+)} $main match version

package require tcllib
package require aes

###########
# parse vars
###########

set now [clock seconds]
foreach {keyfile months} $argv break
if {[info exist months] && [string length $months]} {
	if {[string equal molgen $months]} {
		set months [expr 12*20]
		set version 10.10
	} elseif {[string equal x $months]} {
		set months [expr 12*20]
	}
	set expir [expr $now + (60*60*24*31*$months)]
} else {
	error "No expiration date given !"
}

set ar(key) "It smells like teen spirit !"
set ar(created)	[clock format $now -format "%Y-%m-%d"]
set ar(term) [clock format $expir -format "%Y-%m-%d"]
set ar(version) $version

###########
# read Key.bin
###########

set src [open $keyfile]
fconfigure $src -encoding binary -translation binary
set encdata [read $src]
close $src

set MACkey [decryptSimple $encdata]

###########
# write License.bin
###########

set licensefile License.bin

updateLicense $licensefile ar $MACkey

set src [open $licensefile]
fconfigure $src -encoding binary -translation binary
set encdata [read $src]
close $src

###########
# test License.bin
###########

set test [decryptSimple $encdata $MACkey]
if {[regexp "It smells like teen spirit !" $test]} {
	puts $MACkey
	puts $test
	puts "Encryption done"
} else {
	puts "Encryption failed"
}







