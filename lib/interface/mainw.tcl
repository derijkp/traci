Classy::Toplevel subclass mainw

proc resizeMin args {
	set width [expr 130*$::config::grid(columns)]
	if {$width < 620} {set width 540}
	set height [expr 130 + (90*$::config::grid(rows))]
	wm minsize $::mainW $width $height
}

proc UpdateDos {args} {
	return
	if {[string length [info command .dos]]} {
		Classy::todo .dos updateActive
	}
}

mainw method init args {
	global bar mainW gridW markerbarW genoviewerW listboxW settingsW
	set mainW $object
	super init
#	super init -resize [list 620 [expr 100 + (180*$::config::grid(rows))]]
#	Classy::DynaMenu attachmainmenu MainMenu $object
	# Configure initial arguments
	init
	set ::markerbarW $object.markerbar
	set ::gridW $object.grid
	set ::genoviewerW $gridW.graphs
	set ::listboxW .listbox
	set ::settingsW .settings
	set ::dosW .dos
	set ::startDemo 0
	set ::config::title TracI
	if {[info exist ::exp] && [string length $::exp]} {
		wm title $object "$config::title - v$::version - $::exp"
	} else {
		wm title $object "$config::title - v$::version"
	}
	set rows $config::grid(rows)
	set frame0 [frame $object.row0]
	set frame1 [frame $object.row1]

	button $frame0.selector -command selector -text Import
	balloon $frame0.selector main,selector
	button $frame0.listbox -command [list listboxButton $::listboxW] -text ListBox
	balloon $frame0.listbox main,listbox
#	button $frame0.dos -command [list dosButton $::dosW] -text DosPlot
#	balloon $frame0.dos main,dos
	button $frame0.settings -command [list settingsButton $::settingsW] -text Settings
	balloon $frame0.settings main,settings
#	button $frame0.export -text "Export" -command "export_dialog"
#	balloon $frame0.export main,export
	button $frame0.help -command [list helpButton] -text ?
	bind $frame0.help <Enter> [list balloontime enter]
	bind $frame0.help <Leave> [list balloontime leave]
	balloon $frame0.help main,help
	grid $frame0.selector $frame0.listbox $frame0.settings $frame0.help -row 0
	trace add variable ::config::default(help_state) write "update_helpButton $frame0.help"

if {[string equal Enabled $::config::default(starthelp)]} {
	set ::config::default(help_state) 1
} else {
	set ::config::default(help_state) 0
}

	MarkerBar $::markerbarW -target $::genoviewerW
	$markerbarW configure -highlightthickness 0
	grid $frame0.selector -column 0 -row 0
	grid $frame0 -column 0 -row 0
	grid $markerbarW -in $frame1 -row 1
	grid $frame1 -column 0 -row 1

	ListBox $::listboxW -target $gridW -marker unknown

	Grid $gridW -rows $config::grid(rows) -columns $config::grid(columns)
	grid $gridW -sticky nwse -column 0

	grid rowconfigure $object 0 -weight 0
	grid rowconfigure $object 1 -weight 0
	grid rowconfigure $object 2 -weight 1
	grid columnconfigure $object 0 -weight 1

	$object configure -destroycommand [list $object close] -resize [list 620 [expr 100 + (180*$::config::grid(rows))]]
	wm protocol $object WM_DELETE_WINDOW [list $object exit]\;return
	if {"$args" != ""} {eval $object configure $args}
	return $object
}

mainw method graphbrowser {type {aantal 0}} {
	if {[expr abs($aantal)] > 10} {set aantal [expr 0 - $aantal]}
	if {$aantal > 0} {
		set aantal 1
	} else {
		set aantal -1
	}
	$::gridW graphbrowser $type $aantal
}

mainw method exit {} {
	set message "Destroying the main window will close the application.\nAre you certain you wish to exit ?"
	set answer [tk_messageBox -parent . -title "Exit" -type yesno -message "$message" -icon question]
	switch $answer {
		yes {
#			saveState
			exit
		}
		default {
			return
		}
	}
}

proc saveState {{list {}}} {
	global cfgfile userfile
	set configFile $cfgfile
	set userFile $userfile
	foreach {vars arrays} [configVars $configFile] break
	if {[catch {open $userFile w} dst]} {
		tk_messageBox -message "You do not have the correct privileges to save your current settings." -icon error -type ok -title "Save settings"
		return
	} else {
		foreach array $arrays {
			if {![array exist $array]} {continue}
			if {[string length $list] && ![inlist $list $array]} {continue}
			puts $dst "array $array {"
			foreach {key value} [array get $array] {
				regsub -all "\n|\r" $value {} value
#				puts $dst \t"$key"\t"$value"
				puts $dst \t[list $key $value]
			}
			puts $dst "}"
		}
		close $dst
	}
}

proc configVars {file} {
	set arraysList {}
	set varList {}
	set src [open $file]
	while {![eof $src]} {
		set line [gets $src]
		regsub -all {\{|\}} $line {} line
		if {[regexp {^var} $line]} {
			foreach {var varname value} $line break
			lappend varList $varname
		} elseif {[regexp {^array } $line]} {
			foreach {null arrayname} $line break
			lappend arrayList $arrayname
		}
	}
	close $src
	return [list $varList $arrayList]
}

proc settingsButton {object} {
	global settingsplaced
	buildSettings $object
	if {![info exist settingsplaced]} {$object place}
	wm state $object normal
	raise $object
	set settingsplaced 1
	saveState
}

proc buildSettings {object} {
	if {![string length [info command $object]]} {
		SettingsW $object
	}
}

