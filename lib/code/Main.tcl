proc addLogo {object} {
	set logofile [file join $Classy::appdir $config::default(winlogo)]
	if {[file exist $logofile]} {
		catch {wm iconbitmap $object -default $logofile}
	}
}

proc main args {
	global argv bar cfgfile userfile app_dir
	set keys {exp}
	foreach {key value} $argv {
		if {[inlist $keys $key]} {
			set ::$key $value
		}
	}
	set app_dir [file dirname [info script]]
#	set ::tca_cookie {}
	set ::tca_roles {}
	set ::tca_role {}
	if {![info exist ::exp]} {
		set ::exp {}
	}
	set ::local 0
	set ::version 1.0.5
	namespace eval config {}
	set cfgfile [file join $Classy::appdir conf Config.txt]
	if {[file exist $cfgfile]} {
		namespace eval config {}
	        readSettings $cfgfile
	} else {
	        error "Default config file not found"
	}
	set userfile [file join $::Classy::dira(appuser) UserConfig.txt]
	if {[file exist $userfile]} {
	        readSettings $userfile
	}
	set infofile [file join $Classy::appdir conf help.txt]
	if {[file exist $infofile]} {
	        source $infofile
	}
	package require BLT
	package require abi
	package require Tablelist
	package require http
	package require tls
	package require tca
	package require tcllib
	package require cksum
	package require aes
	package require math::statistics

        catch {namespace import blt::graph}
        catch {namespace import blt::vector}
        catch {namespace import blt::tabset}

	set dir [file join $tablelist::library demos]
	set ::checkedImg   [image create photo -file [file join $dir checked.gif]]
	set ::uncheckedImg [image create photo -file [file join $dir unchecked.gif]]
	set ::pointerImg [image create photo -file [file join $Classy::appdir conf pointer5.gif]]

	Classy::Balloon private time 1000000
	set mainW [mainw .mainw]
	buildbar $mainW
	bind  $mainW <Configure> "Classy::todo updatebar"
#	bind  $mainW <MouseWheel> [list $mainW graphbrowser index %D]
#	bind  $mainW <Control-MouseWheel> [list $mainW graphbrowser page %D]
#	bind  $mainW <Key-Up> [list $mainW graphbrowser index -1]
#	bind  $mainW <Key-Down> [list $mainW graphbrowser index 1]
#	bind  $mainW <Control-Key-Up> [list $mainW graphbrowser page -1]
#	bind  $mainW <Control-Key-Down> [list $mainW graphbrowser page 1]

#	drawbar $bar 0 "Please wait..."  black
	addLogo $mainW

#	update_listboxButton .mainw.row0.listbox
#	update_settingsButton .mainw.row0.settings
#	update_dosButton .mainw.row0.dos
	update_helpButton .mainw.row0.help
	reload_data
	checkUpdate
	guide
	raise $mainW
	focus $mainW
}

proc readSettings {file {array_only {}}} {
	set src [open $file]
	set inarray 0
	set invar 0
	while {![eof $src]} {
		set line [gets $src]
		regsub {^\}} $line {} line
		if {[regexp {^var ([^ ]+)} $line match varname]} {
			set inarray 0
			set invar 1
#			foreach {var varname value} $line break
#			set $varname $value
		} elseif {[regexp {^array ([^ ]+)} $line match arrayname]} {
			if {![string length $array_only] || [string equal $arrayname $array_only] } {
				set inarray 1
			}
#			foreach {null arrayname} $line break
		} else {
			if {![llength $line]} {
				set inarray 0
				set invar 0
			}
			if {[llength $line] == 1 && $invar} {
				set inarray 0
				foreach {value} $line break
				lappend $varname $value
			}
			if {$inarray} {
				set invar 0
#				foreach {name value} $line break
#				set ${arrayname}($name) $value
array set ${arrayname} $line
			}
		}
	}
	close $src
}

