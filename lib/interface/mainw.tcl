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
	initIcons
	set ::markerbarW $object.markerbar
	set ::gridW $object.grid
	set ::genoviewerW $gridW.graphframe.graphs
	set ::listboxW .listbox
	set ::settingsW .settings
	set ::dosW .dos
	set ::startDemo 0
	set ::config::title TracI
#reg_traci
	set ::keepPos 1
	if {[info exist ::exp] && [string length $::exp]} {
		wm title $object "$config::title - v$::version - $::exp"
	} else {
		wm title $object "$config::title - v$::version"
	}
	set rows $config::grid(rows)
	set frame0 [frame $object.row0]
	set frame1 [frame $object.row1]

	button $frame0.selector -command selector -text Import -image $::Open
	balloon $frame0.selector main,selector
	button $frame0.save -command exportProject -text Save -image $::Save
	balloon $frame0.save main,save
	button $frame0.listbox -command [list listboxButton $::listboxW] -text ListBox -image $::ListBox
	balloon $frame0.listbox main,listbox
	button $frame0.settings -command [list settingsButton $::settingsW] -text Settings -image $::Configure
	balloon $frame0.settings main,settings
#	button $frame0.export -text "Export" -command "export_dialog"
#	balloon $frame0.export main,export
	button $frame0.help -command [list helpButton] -text ? -image $::Help
	bind $frame0.help <Enter> [list balloontime enter]
	bind $frame0.help <Leave> [list balloontime leave]
	balloon $frame0.help main,help


	set buttons {selector save listbox dos export settings help}
	set buttons {selector save listbox settings help}
	set colnr 0
	foreach button $buttons {
		grid $frame0.$button -row 0 -column $colnr
		grid columnconfigure $frame0 $colnr -pad 0
		incr colnr
	}
#	grid $frame0.selector $frame0.listbox $frame0.settings $frame0.help -row 0
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
	if {![string equal $::config::default(useicons) Enabled]} {
		grid $markerbarW -in $frame1 -row 1
	} else {
	set colnr 0
	foreach button $buttons {
		grid columnconfigure $frame0 $colnr -pad 2
		incr colnr
	}
		grid $markerbarW -in $frame0 -row 0 -column 6
		grid $frame0.help -column 10 -row 0
		grid columnconfigure $frame0 10 -pad 3
	}
	grid $frame1 -column 0 -row 1

	ListBox $::listboxW -target $gridW -marker unknown

	Grid $gridW -rows $config::grid(rows) -columns $config::grid(columns)
	grid $gridW -sticky nwse -column 0

	grid rowconfigure $object 0 -weight 0
	grid rowconfigure $object 1 -weight 0
	grid rowconfigure $object 2 -weight 1
	grid columnconfigure $object 0 -weight 1

	set width [expr 680+(($::config::grid(columns)-1)*60)]
	set height [expr 250+(($::config::grid(rows)-1)*100)]

	$object configure -destroycommand [list $object close] -resize [list $width $height]
	wm protocol $object WM_DELETE_WINDOW [list $object exit]\;return
	if {"$args" != ""} {eval $object configure $args}
	Classy::canceltodo $object place
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
			saveState
			exit
		}
		default {
			return
		}
	}
}

proc saveState_old {{list {}}} {
#	saveLicense
	set parent [checkParent $::mainW]
	global cfgfile userfile
	set configFile $cfgfile
	set userFile $userfile-backup
	set skiparrays {temp}
	foreach {vars arrays} [configVars $configFile] break
	if {[catch {open $userFile w} dst]} {
		tk_messageBox -message "You do not have the correct privileges to save your current settings." -icon error -type ok -title "Save settings" -parent $parent
		return
	} else {
		foreach arrayname $arrays {
			set array config::$arrayname
			if {![array exist $array] || [inlist $skiparrays $arrayname]} {continue}
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
	file rename -force $userFile $userfile
}

proc saveLicense {} {
	if {![info exist ::config::default(licenseFile)] || ![file exist $::config::default(licenseFile)]} {
		set safedir $::Classy::dira(appuser)
		foreach file [glob -nocomplain $safedir/License*.bin] {
			set ::config::default(licenseFile) $file
			if {[checkLicense 1]} {
				break
			} else {
				set ::config::default(licenseFile) ""
			}
		}
	}
}

proc saveState {{list {}}} {
	saveLicense
	set parent [checkParent $::mainW]
	global cfgfile userfile
	set configFile $cfgfile
	set userFile $userfile-backup
	set skiparrays {temp colname columns_sel}
	foreach {vars arrays} [configVars $configFile] break
	if {[catch {open $userFile w} dst]} {
		tk_messageBox -message "You do not have the correct privileges to save your current settings." -icon error -type ok -title "Save settings" -parent $parent
		return
	} else {
		foreach arrayname $arrays {
			set array config::$arrayname
			if {![array exist $array] || [inlist $skiparrays $arrayname]} {continue}
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
	file rename -force $userFile $userfile
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
	global settingsplaced userfile
	# if not open already, dump tmpconfig and create array
	if {![info exist settingsplaced] || !$settingsplaced} {
		readSettings tempconfig $userfile 1
	}
	buildSettings $object
	if {![info exist settingsplaced] || !$settingsplaced} {
		setPos $object
	}
	raise $object
	set settingsplaced 1
}

proc buildSettings {object} {
	if {![string length [info command $object]]} {
		SettingsW $object
		bind $object <Configure> "keepPos $object %W %h %w %x %y"
	}
}

proc check4Project {dir} {
	set parent [checkParent .selector]
	set files [glob -nocomplain $dir/*.tri]
	if {![llength $files]} {
		return 0
	}
	set message "Project file(s) found...should I load one of those ?"
	set answer [tk_messageBox -type yesno -title "Open project" -icon info -message $message -parent $parent]
	if {[string equal yes $answer]} {
		set list [glob -nocomplain $dir/*.tri]
		set title Project
		set command openProject
		choose1 $list $title $command "Load Project"
		return 1
	} else {
		return 0
	}
}


proc selectProject {window} {
	set parent [checkParent .selector]
	if {[string length $::config::default(datadir)]} {
		set initialdir $::config::default(datadir)
	} else {
		set initialdir {}
	}
	set projectfile [tk_getOpenFile -initialdir $initialdir -title "Project import" -filetypes {"MAQsfile {.mqs}"} -parent $parent]
	if {[file exist $projectfile]} {
		destroy $window
		openProject $projectfile
		set ::config::default(datadir) [file dirname $projectfile]
		catch {set ::tempconfig::default(datadir) [file dirname $projectfile]}
	}
}

proc choose1 {list title command message} {
	set top .listw
	if {[llength $list] == 1} {
		catch {destroy .selector}
		eval $command [list [lindex $list 0]]
		return
	}
	Classy::Dialog $top -title $title
	Classy::canceltodo $top place
	wm minsize $top 246 135
	set w [$top component options]
	label $w.header -text $message
	set hsb $w.hs
	set vsb $w.vs
	set tbl $w.t
	$top.actions.close configure -text Cancel -command "set ::hold 0"
	$top add open "Open" "picked1 \"$tbl\" \"$command\""
#	set fr $w.buttons
	option add *Tablelist.movableColumns    no
	set header "0 List 1 Filename"
	scrollbar $vsb -orient vertical -command [list $tbl yview]
	scrollbar $hsb -orient horizontal -command [list $tbl xview]
	tablelist::tablelist $tbl \
		-columns $header -stripeheight 0 \
		-height 10 -width 20 -stretch all -selectmode single \
		-xscrollcommand [list $hsb set] -yscrollcommand [list $vsb set]
	foreach file $list {
		set filename [file tail $file]
		$tbl insert end [list $filename $file]
	}
	$tbl columnconfigure 1 -hide 1
	grid columnconfigure $w 0 -weight 1
	grid rowconfigure $w 1 -weight 1
	grid $w.header -row 0 -columnspan 1
	grid $tbl -row 1 -column 0 -sticky news
	grid $vsb -row 1 -column 1 -sticky ns
	grid $hsb -row 2 -column 0 -sticky ew
#	frame $top.buttons
	grid $w.header -pady 5 -row 1
	centerWindow $top $::mainW
	set ::hold 1
	vwait ::hold
}

proc picked1 {tbl command} {
	set row [$tbl curselection]
	set projectfile [$tbl getcells $row,1]
	set toplevel [winfo toplevel $tbl]
	$toplevel close
	if {[string length $projectfile]} {
		catch {destroy .selector}
		eval $command [list $projectfile]
	}
	set ::hold 0
}

proc readProjectFile {file} {
	upvar project project
	array unset project
	set src [open $file]
	set testaantal {}
	while {![eof $src]} {
		set line [gets $src]
		set splitline [split $line \t]
		lappend testaantal [llength $splitline]
		foreach {name value} $splitline break
		set project($name) $value
	}
	close $src
	regsub -all {2|0|" "} $testaantal {} testaantal
	if {[llength [array names project]] < 4 || [llength $testaantal]} {
		error "Unknown project file format."
	}
}

proc index2file {indexlist} {
	set filelist {}
	foreach index $indexlist {
		set file [fetchVal $index chromatogram]
		if {[string length $file]} {
			lappend filelist [file tail $file]
		}
	}
	return $filelist
}

proc file2index {files} {
	for {set index 0} {$index < [$::listboxW.t size]} {incr index} {
		set file [file tail [fetchVal $index chromatogram]]
		set file2index($file) $index
	}
	set indexlist {}
	foreach file $files {
		if {[info exist file2index($file)]} {
			lappend indexlist $file2index($file)
		}
	}
	return $indexlist
}

proc parseLegacyProjects {} {
	# check for 'older' index numbers and translate them into file names
	upvar project project
	if {![info exist project(controlfiles)]} {
		if {[info exist project(controls)]} {
			set controlfiles [index2file $project(controls)]
		} else {
			set controlfiles {}
		}
		set project(controlfiles) $controlfiles
	}
	if {![info exist project(genotypefiles)]} {
		if {[info exist project(genotypes)]} {
			set genotypefiles [index2file $project(genotypes)]
		} else {
			set genotypefiles {}
		}
		set project(genotypefiles) $genotypefiles
	}
}

proc exportProject {} {
	set dir $config::default(datadir)
	set expname [file tail $::exp]
	set assayname $data::active_marker
	set projectfile [file join $dir $expname-$assayname.mqs]
	set projectfilename [file tail $projectfile]
	set parent [checkParent .mainw]
	set types {{MAQsProject {.mqs}}}
	if {![string length $::exp] || ![string length $::assay_temp]} {
		return
	}
	set savefile [tk_getSaveFile -initialdir $dir -filetypes $types -parent $parent -initialfile $projectfilename]
	if {[string length $savefile]} {
		set dst [open $savefile w]
		foreach {var value} [list \
			exp $::exp \
			assayfile $::assay_temp \
			genotypefiles [index2file $data::active_genos] \
			assay $data::active_marker \
		] {
			puts $dst $var\t$value
		}
		close $dst
		set ::config::default(datadir) [file dirname $savefile]
		catch {set ::tempconfig::default(datadir) [file dirname $savefile]}
	}
}

proc openProject {file} {
	set parent [checkParent .mainw]
	catch {eval vector destroy [vector names ::S*]}
	if {[catch {readProjectFile $file}]} {
		set message "Something went wrong while opening your project file."
		tk_messageBox -type ok -title "Open project" -icon error -message $message -parent $parent
		return
	}
	set fsafound [llength [glob -nocomplain $project(exp)/*.fsa]]
	if {[string is int $project(exp)] && [string length $project(exp)]} {
		# Gentli data
		set ::exp $project(exp)
	} elseif {![file isdirectory $project(exp)] || !$fsafound} {
		# in case the files were moved
		set found [look4 *.fsa [file dirname $file]]
		if {![string length $found]} {
			set error "No fsa files found to analyze !"
			set answer [tk_messageBox -type ok -title "Open project" -icon info -message $error -parent $parent]
			return
		} elseif {[llength $found] > 1} {
			choose1 $found Datadir "set ::exp" "Choose data directory"
#			vwait ::exp
		} else {
			set ::exp [lindex $found 0]
		}
	} else {
		set ::exp $project(exp)
	}
	if {[file isfile $project(assayfile)]} {
		set assayfile $project(assayfile)
	} else {
		set assayfile {}
		set assayfilename [file tail $project(assayfile)]
		set found [look4 $assayfilename [file dirname $file]]
		if {![string length $found]} {
			set error "Assay description file not found !"
		} elseif {[llength $found] > 1} {
			choose1 $found Assay "set ::assayfile" "Choose your assay description file"
#			vwait ::assayfile
			set assayfile [file join [lindex $found 0] $::::assayfile]
		} else {
			set assayfile [file join [lindex $found 0] $assayfilename]
		}
	}
	set currentassay $project(assay)
	set ::exp_temp $::exp
	# reading data files
	if {[regexp {/} $::exp]} {
		set ::config::role 0
		ImportDir $::exp
	} elseif {[string length $::exp]} {
		change_exp $::exp
		vwait ::data::datalist(unknown)
	}
	# reading assay file
	if {[file exist $assayfile]} {
		Classy::busy
		set ::config::default(assaydir) [file dirname $assayfile]
		set error [catch {readAssay $assayfile} data]
		if {$error} {
			set message "Something went wrong while decrypting the assay file: '[file tail $assayfile]'"
			set error 1
		} else {
			if {[catch {testassay $data} message]} {
				set importfile {}
				set error 1
			}
		}
		set ::assay $assayfile
		set ::assay_temp $assayfile
		set assays $::data::assayList
		lappend assays unknown
		globRef 1
		Classy::busy remove
	} else  {
		set assays unknown
		set message "Assay description file not found !"
		set error 1
	}
	if {$error} {
		tk_messageBox -type ok -title "Open project" -icon error -message $message -parent $parent
		return
	}
	parseLegacyProjects
	set ::data::active_genos [file2index $project(genotypefiles)]
	$::markerbarW.marker configure -list $assays
	set assaypos [lsearch $assays $currentassay]
	if {$assaypos < 0} {
		set assaypos 0
	}
	$::markerbarW activate_marker [lindex $assays $assaypos]
	$::gridW configure -pattern All
	titleUpdate
	saveState
}

proc look4 {file start} {
	set currentdir $start
	set testlength [llength [glob -nocomplain [file join $currentdir $file]]]
	if {$testlength} {
		return [list $start]
	}
	set dirs [glob -nocomplain -types d $currentdir/*]
	foreach dir $dirs {
		set result [look4 $file $dir]
		if {[string length $result]} {
			if {![info exist found]} {
				set found $result
			} else {
				set found [concat $found $result]
			}
		}
#		set testlength [string length $found]
#		if {$testlength} {break}
	}
	append found ""
	return $found
}

