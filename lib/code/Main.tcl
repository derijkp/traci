proc addLogo {object} {
	set logofile [file join $Classy::appdir $config::default(winlogo)]
	if {[file exist $logofile]} {
		catch {wm iconbitmap $object -default $logofile}
	}
}

proc refreshIcons {} {
	initIcons
	set frame0 .mainw.row0
	set frame1 .mainw.row1
	$frame0.selector configure -image $::Open
	$frame0.save configure -image $::Save
	$frame0.listbox configure -image $::ListBox
	$frame0.settings configure -image $::Configure
#	$frame0.export configure -image $::Print
	$frame0.help configure -image $::Help
	set buttons {selector save listbox settings help}
	grid forget $frame0
	grid forget $frame1
	if {[string equal $::config::default(useicons) Disabled]} {
		grid $frame0 -in $::mainW -row 0
		grid $frame1 -in $::mainW -row 1
		grid $::markerbarW -in $frame1 -row 1
		update
		grid $::markerbarW -in $frame1 -row 1
	} else {
		grid $::markerbarW -in $::mainW -row 1 -column 0
		grid $frame0 -in $::mainW -row 0 -column 0
		set colnr 0
		foreach button $buttons {
			grid columnconfigure $frame0 $colnr -pad 2
			incr colnr
		}
		grid $::markerbarW -in $frame0 -row 0 -column 6
		grid $frame0.help -column 10 -row 0
		grid columnconfigure $frame0 10 -pad 3
	}
}

proc initIcons {} {
	set iconsdir [file join $Classy::appdir conf icons]
	set size {}
	set ::pointerImg [image create photo -file [file join $iconsdir pointer5.gif]]
#	set ::grid [image create photo -file [file join $iconsdir Grid2.gif]]
	set ::grid [image create photo -file [file join $iconsdir changeGrid.gif]]
	set ::arrowdd2 [image create photo -file [file join $iconsdir Arrowdd2.gif]]
	set ::arrowll2 [image create photo -file [file join $iconsdir Arrowll2.gif]]
	set ::arrowld2 [image create photo -file [file join $iconsdir Arrowld2.gif]]
	set ::arrowlu2 [image create photo -file [file join $iconsdir Arrowlu2.gif]]
	set ::arrowrd2 [image create photo -file [file join $iconsdir Arrowrd2.gif]]
	set ::arrowrr2 [image create photo -file [file join $iconsdir Arrowrr2.gif]]
	set ::arrowru2 [image create photo -file [file join $iconsdir Arrowru2.gif]]
	set ::arrowuu2 [image create photo -file [file join $iconsdir Arrowuu2.gif]]
	if {![string equal $::config::default(useicons) Enabled]} {
		set ::Open {}
		set ::Save {}
		set ::Configure {}
		set ::ListBox {}
		set ::DosPlot {}
		set ::Print {}
		set ::Help {}
	} else {
		set ::Open [image create photo -file [file join $iconsdir fileopen$size.gif]]
#		set ::Print [image create photo -file [file join $iconsdir fileprint$size.gif]]
		set ::Print [image create photo -file [file join $iconsdir export.gif]]
		set ::Save [image create photo -file [file join $iconsdir filesave$size.gif]]
		set ::Configure [image create photo -file [file join $iconsdir configure$size.gif]]
		set ::ListBox [image create photo -file [file join $iconsdir ListBox$size.gif]]
		set ::DosPlot [image create photo -file [file join $iconsdir DosPlot$size.gif]]
		set ::Help [image create photo -file [file join $iconsdir help.gif]]
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
	set ::version 1.1.0b
	namespace eval config {}
	set cfgfile [file join $Classy::appdir conf Config.txt]
	if {[file exist $cfgfile]} {
		namespace eval config {}
	        readSettings config $cfgfile
	} else {
	        error "Default config file not found"
	}
	set userfile [file join $::Classy::dira(appuser) UserConfig.txt]
	if {[file exist $userfile]} {
	        readSettings config $userfile
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
	setPos $mainW
	bind  $mainW <Configure> "Classy::todo updatebar;keepPos .mainw %W %h %w %x %y"
#	bind  $mainW <Configure> "Classy::todo updatebar"
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
	if {[regexp {.tri$|tri\}} [lindex $argv 0]]} {
		openProject [lindex $argv 0]
	}
}

proc readSettings {namespace file {skip 0}} {
	namespace eval $namespace {}
	set src [open $file]
	set inarray 0
	set invar 0
	set skips {}
	if {$skip} {
		set skips {temp columns_sel}
	}
	while {![eof $src]} {
		set line [gets $src]
		regsub {^\}} $line {} line
		if {[regexp {^var ([^ ]+)} $line match varname]} {
			set varname [lindex [split $varname :] end]
			if {![inlist $skips $varname]} {
				set inarray 0
				set invar 1
			}
		} elseif {[regexp {^array ([^ ]+)} $line match arrayname]} {
			set arrayname [lindex [split $arrayname :] end]
			if {![inlist $skips $arrayname]} {
				set inarray 1
			}
		} else {
			if {![llength $line]} {
				set inarray 0
				set invar 0
			}
			if {[llength $line] == 1 && $invar} {
				set inarray 0
				foreach {value} $line break
				lappend ${namespace}::$varname $value
			}
			if {$inarray} {
				set invar 0
				if {[catch {array set ${namespace}::${arrayname} $line} error]} {
					puts $line--$error
				}
			}
		}
	}
	close $src
}

