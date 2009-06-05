Classy::Toplevel subclass SettingsW
SettingsW method init {args} {
	super init
	private $object options
	set prefix "  "
	# main tabset
	set Wtabset $object.ts
	tabset $Wtabset -relief flat -borderwidth 0 -highlightthickness 0
	$Wtabset configure -activeforeground black -highlightcolor black -tabforeground grey95 -selectforeground black -tabbackground blue -tiers 2 -rotate 90 -side left
	grid $Wtabset -columnspan 2 -sticky nwse
	grid columnconfigure $object 0 -weight 1
	grid rowconfigure $object 0 -weight 1
	tabChrom $object $Wtabset $prefix
	tabColors $object $Wtabset $prefix
	tabILS $object $Wtabset $prefix
	tabList $object $Wtabset $prefix
	tabGeneral $object $Wtabset $prefix
#	refresh_rOptionMenu
#	wm protocol $object WM_DELETE_WINDOW [list $object exit]\;return
#	wm title $object "Settings"
#	Classy::canceltodo $object place
#	update idletask
	set buttonframe [frame $object.buttons -pady 4]
	button $buttonframe.ok -text "Ok" -command [list $object apply close]
	balloon $buttonframe.ok settings,ok
	button $buttonframe.apply -text "Apply" -command [list $object apply]
	balloon $buttonframe.apply settings,apply
	button $buttonframe.undo -text "Undo" -command [list $object cancel]
	balloon $buttonframe.cancel settings,undo
	button $buttonframe.cancel -text "Cancel" -command [list $object cancel close]
	balloon $buttonframe.cancel settings,cancel
	grid $buttonframe.ok $buttonframe.apply $buttonframe.undo $buttonframe.cancel
	grid $buttonframe -sticky s
	wm protocol $object WM_DELETE_WINDOW [list $object exit]\;return
	wm title $object "Settings"
	Classy::canceltodo $object place
}


proc tabChrom {object Wtabset prefix} {
	# Chromatogram tabset
	set mainframe [frame $Wtabset.main]
	$Wtabset insert 1 main -text Chromatogram
#	$Wtabset tab configure main -fill both -padx 0.05i -pady 0.05i -window $mainframe
	$Wtabset tab configure main -fill both -pady 0.05i -window $mainframe
	grid columnconfigure $mainframe 0 -weight 1
	grid rowconfigure $mainframe 1 -weight 1
	set settingsframe [frame $mainframe.frame]
	grid $settingsframe -sticky nwse
	grid columnconfigure $settingsframe 0 -weight 1
	grid columnconfigure $settingsframe 1 -weight 1
		addHeader zooml $settingsframe "Zoom function"
		addSetting zoomrange $settingsframe "Extra range on either side of the marker area" entry
		addHeader labell $settingsframe "Label 'individual' inside chromatogram"
		addSetting showlabel $settingsframe "Label shown" button
		addSetting label_font $settingsframe "Label font" font
		addHeader lowl $settingsframe "Low height marker"
		addSetting showlow $settingsframe "Low height marker shown" button
		addSetting lowpeaks $settingsframe "Low height marker (height)" entry
		addHeader otherl $settingsframe "Other settings"
		addSetting showbinOnSi $settingsframe "Show bins on superimpose" button
		addSetting ymin $settingsframe "Minimal height treshold" entry
		addSetting signalwidth $settingsframe "Signal Width" entry
		addSetting overlayHold $settingsframe "Overlay reads while held" button
		addSetting showstandard $settingsframe "Show missing internal standard" button
	grid columnconfigure $settingsframe 0 -weight 1
	grid columnconfigure $settingsframe 1 -weight 1
	endline $settingsframe
}

proc tabColors {object Wtabset prefix} {
	# Colors tabset
	set mainframe [frame $Wtabset.colors]
	$Wtabset insert 1 colors -text Colors
	$Wtabset tab configure colors -fill both -pady 0.05i -window $mainframe
	grid columnconfigure $mainframe 0 -weight 1
	grid rowconfigure $mainframe 1 -weight 1
	set settingsframe [frame $mainframe.frame]
		addHeader ampl $settingsframe "Amplicons"
		addSetting score $settingsframe "Scored amplicon (bin)" color
		addHeader quality $settingsframe "Quality coloring"
		addSetting qgood $settingsframe "Good quality" color
		addSetting qmiddle $settingsframe "Medium quality" color
		addSetting qbad $settingsframe "Low quality" color
		addHeader actl $settingsframe "Active read coloring"
		addSetting activebg $settingsframe "Active read" color
		addSetting activeplotbg $settingsframe "Active read background" color
		addHeader low $settingsframe "Low Height"
		addSetting lowpeaks_bg $settingsframe "Low height marker (background)" color
		addSetting lowpeaks_border $settingsframe "Low height marker (border)" color
		addHeader othl $settingsframe "Other settings"
		addSetting overlayHold $settingsframe "Background reads (if superimposed)" color
	grid $settingsframe -sticky nwse -column 0 -row 0
	grid columnconfigure $settingsframe 0 -weight 1
	grid columnconfigure $settingsframe 1 -weight 1
	endline $settingsframe
}

proc tabGeneral {object Wtabset prefix} {
	# General tabset
	set mainframe [frame $Wtabset.general]
	$Wtabset insert 0 general -text General
	$Wtabset tab configure general -fill both -pady 0.05i -window $mainframe
	grid columnconfigure $mainframe 0 -weight 1
	grid rowconfigure $mainframe 1 -weight 1
	set settingsframe [frame $mainframe.frame]
		addHeader helpl $settingsframe "Help"
		addSetting guide $settingsframe "Enable/disable guide" button guide
		addSetting starthelp $settingsframe "Help enabled at startup" button
		addHeader globl $settingsframe "Globbing"
		addSetting glob_individual $settingsframe "individual" entry
		addSetting glob_well $settingsframe "well" entry
		addHeader reanalyse $settingsframe "Genescan analysis"
		addSetting restandard $settingsframe "Always overrule standard" button
		addHeader align $settingsframe "Aligning"
		addSetting alignwindow $settingsframe "window" entry
		addHeader check4update $settingsframe "Updates"
		addSetting check4update $settingsframe "Prompt if update available" button
		addSetting useicons $settingsframe "Use icons instead of buttons" button refreshIcons
		addSetting changeILS $settingsframe "Change the set ILS" button
	grid $settingsframe -sticky nwse
	grid columnconfigure $settingsframe 0 -weight 1
	grid columnconfigure $settingsframe 1 -weight 1
	endline $settingsframe
}

proc tabExport {object Wtabset prefix} {
	# Export tabset
	set mainframe [frame $Wtabset.export]
	$Wtabset insert 0 export -text Export
	$Wtabset tab configure export -fill both -pady 0.05i -window $mainframe
	grid columnconfigure $mainframe 0 -weight 1
	grid rowconfigure $mainframe 1 -weight 1
	set settingsframe [frame $mainframe.frame]
		addHeader inth $settingsframe "Include intensities"
		addSetting addarea $settingsframe "Area" checkbutton
		addSetting addheight $settingsframe "Height" checkbutton
		addHeader intrah $settingsframe "Include normalisation (intra)"
		addSetting intradetails $settingsframe "Details" checkbutton
		addSetting intrasummary $settingsframe "Summary" checkbutton
		addHeader interh $settingsframe "Include normalisation (inter)"
		addSetting interref $settingsframe "Reference samples" checkbutton
		addSetting intertest $settingsframe "Test samples" checkbutton
		addHeader dosh $settingsframe "Include dosage"
		addSetting dosref $settingsframe "Reference samples" checkbutton
		addSetting dostest $settingsframe "Test samples" checkbutton
	grid $settingsframe -sticky nwse
	grid columnconfigure $settingsframe 0 -weight 1
	grid columnconfigure $settingsframe 1 -weight 1
	endline $settingsframe
}

proc tabILS {object Wtabset prefix} {
	# ILS tabset
	set mainframe [Classy::ScrolledFrame $Wtabset.ils -height 100 -width 100 -relief flat]
	$Wtabset insert 0 ILS -text ILS
	$Wtabset tab configure ILS -fill both -pady 0.05i -window $mainframe
	set settingsframe $mainframe.view.frame
		addHeader reanalyse $settingsframe "Genescan analysis"
		addSetting showstandard $settingsframe "Show missing internal standard" button "$::gridW refresh"
		addSetting restandard $settingsframe "Always overrule standard" button
		addSetting ILScutoff $settingsframe "ILS cutoff value" entry
		addHeader overview $settingsframe "Internal Lane Standards"
		set nr 1
		foreach standard [array names ::config::stds sizes*] {
			set name [lindex $standard 1]
			addSetting standard$nr $settingsframe $name standard $name
			incr nr
		}
	grid $settingsframe -sticky nwse
	grid columnconfigure $settingsframe 0 -weight 1
	grid columnconfigure $settingsframe 1 -weight 1
	endline $settingsframe
}

proc tabList {object Wtabset prefix} {
	# ListBox tabset
	set mainframe [frame $Wtabset.listbox]
	$Wtabset insert 0 listbox -text Listbox
	$Wtabset tab configure listbox -fill both -pady 0.05i -window $mainframe
	grid columnconfigure $mainframe 0 -weight 1
	grid rowconfigure $mainframe 1 -weight 1
	set settingsframe [frame $mainframe.frame]
		addHeader inth $settingsframe "Columns shown"
		addSetting hide_nonactive $settingsframe "Hide inactive markers" button
	grid $settingsframe -sticky nwse
	grid columnconfigure $settingsframe 0 -weight 1
	grid columnconfigure $settingsframe 1 -weight 1
	endline $settingsframe
}

proc endline {frame} {
	set rows [lindex [grid size $frame] end]
	incr rows
	grid rowconfigure $frame $rows -weight 1
}

#SettingsW method apply {windows {close {}}} {
#	saveState
#	foreach w $windows {
#		if {![string length [info command $w]]} {continue}
#		$w refresh
#	}
#	if {[string equal $close close]} {
#		$object exit
#	}
#}
SettingsW method apply {{close {}}} {
	set skip {positions}
	foreach var [info vars ::tempconfig::*] {
		set varname [lindex [split $var :] end]
		if {[inlist $skip $varname]} {continue}
		if {[array exists $var]} {
			array set ::config::$varname [array get $var]
		} else {
			set ::config::$varname [set $var]
		}
	}
	doStalledCommands
	saveState
	if {[string equal $close close]} {
		$object exit
	}
}

#SettingsW method cancel {} {
#	global userfile
#        readSettings config $userfile
#	$object refresh_colors
#	$object exit
#}
SettingsW method cancel {{close {}}} {
	# make tempconfig = config
	foreach var [info vars ::config::*] {
		set varname [lindex [split $var :] end]
		if {[array exists $var]} {
			array set ::tempconfig::$varname [array get $var]
		} else {
			set ::tempconfig::$varname [set $var]
		}
	}
	doStalledCommands
	dropStalledCommands
	if {[string length $close]} {
		$object exit
	}
}

#SettingsW method refresh_colors {} {
#	set root .settings.ts.colors.frame
#	foreach button [winfo children $root] {
#		if {[regexp "$root\.cb(.*)" $button match name]} {
#			set color $config::color($name)
#			$button configure -background $color -highlightbackground $color -activebackground $color
#		}
#	}
#}

SettingsW method refresh_colors {{buttons {}}} {
	if {![string length $buttons]} {
		set root .settings.ts.colors.view.frame
		set buttons [winfo children $root]
	}
	foreach button $buttons {
		if {[regexp {.cb([^.]+)$} $button match name]} {
			set color $::tempconfig::color($name)
			$button configure -background $color -highlightbackground $color -activebackground $color
		}
	}
}

SettingsW method default {} {
	global cfgfile
	readSettings config $cfgfile config::color
	$object refresh_colors
#	$::gridW refresh
#	$::listboxW refresh
}

SettingsW method exit {} {
	set ::settingsplaced 0
	wm state $object withdrawn
}

SettingsW method changeType {} {
	typeSwitch assaytype
	updateDos
}

proc addHeader {name parent text} {
	label $parent.$name -text $text -font "Arial 10 bold" -anchor w
	grid $parent.$name -sticky nwse -columnspan 2
}

proc addSetting {name parent text type args} {
	set prefix "  "
	set font "helvetica -10"
	set configArray tempconfig
	switch $type {
		entry {
			set var ::${configArray}::default($name)
			label $parent.el$name -text ${prefix}$text -anchor nw -font $font
			entry $parent.ee$name -textvariable $var -font $font -vcmd "stallCommand $name $args;return 1" -validate key
			button $parent.ed$name -text X -command "toDefault [list $var];stallCommand $name $args" -font $font
			grid $parent.el$name $parent.ee$name $parent.ed$name -sticky nwe
			balloon $parent.ee$name settings,$name
			balloon $parent.ed$name settings,todefault
		}
		standard {
			set var ::${configArray}::stds(sizes\ $args)
			label $parent.el$name -text ${prefix}$text -anchor nw -font $font
			entry $parent.ee$name -textvariable $var -font $font -vcmd "stallCommand $name;return 1" -validate key
			button $parent.ed$name -text X -command "toDefault [list standard-$args];stallCommand $name" -font $font
			grid $parent.el$name $parent.ee$name $parent.ed$name -sticky nwe
			balloon $parent.ee$name settings,$name
			balloon $parent.ed$name settings,todefault
		}
		color {
			set var ::${configArray}::color($name)
			label $parent.cl$name -text ${prefix}$text -anchor nw -font $font
			set current [set $var]
			button $parent.cb$name -bg $current -activebackground $current -highlightbackground $current -command "ChooseColor $parent.cb$name $configArray $name" -font $font
			button $parent.cd$name -text X -command "toDefault [list $var];$::settingsW refresh_colors $parent.cb$name;stallCommand $name \"$::settingsW refresh_colors\"" -font $font
			grid $parent.cl$name $parent.cb$name $parent.cd$name -sticky nwe
			balloon $parent.cb$name settings,$name
			balloon $parent.cd$name settings,todefault
		}
		font {
			set var ::${configArray}::font($name)
			label $parent.fl$name -text ${prefix}$text -anchor nw -font $font
			set current [set $var]
			button $parent.fb$name -textvariable $var -command "ChooseFont $var;stallCommand $name $args" -font $font -height 1
			button $parent.fd$name -text X -command "toDefault [list $var];stallCommand $name $args" -font $font
			grid $parent.fl$name $parent.fb$name $parent.fd$name -sticky nwe
			balloon $parent.fb$name settings,$name
			balloon $parent.fd$name settings,todefault
		}
		checkbutton {
			set var ::${configArray}::checkbutton($name)
			label $parent.chl$name -text ${prefix}$text -anchor nw -font $font
			checkbutton $parent.chb$name -variable $var -command [list stallCommand $name $args]
			grid $parent.chl$name $parent.chb$name -sticky nwe
			balloon $parent.chl$name settings,$name
		}
		button {
			set var ::${configArray}::default($name)
			label $parent.bl$name -text "${prefix}$text" -anchor nw -font $font
			button $parent.bb$name -command "typeSwitch $configArray $name;stallCommand $name $args" -textvariable $var -font $font
			button $parent.bd$name -text X -command "toDefault [list $var];stallCommand $name $args" -font $font
			grid $parent.bl$name $parent.bb$name $parent.bd$name -sticky nwe
			balloon $parent.bb$name settings,$name
			balloon $parent.bd$name settings,todefault
		}
	}
}

proc ChooseFont {var} {
	set current [set $var]
	set os [getOS]
	if {[string equal lin $os]} {
		catch {Classy::getfont -font $current} font
	} else {
		foreach {name size style} $current break
		catch {Classy::GetFont $name $size $style} font
	}
	if {[string length $font] && ![regexp {No font} $font]} {
		set $var $font
	}
	return
}

proc ChooseColor {object var} {
	set current [$object cget -bg]
	set tcolor [Classy::getcolor -initialcolor $current]
	set $var $tcolor
	$object configure -bg $tcolor -activebackground $tcolor
	return
}

##############################

proc stallCommand {name {command {}}} {
	if {[string length $command]} {
		eval set ::config::todo($name) [list $command]
	}
}

proc doStalledCommands {} {
	if {![array exist ::config::todo]} {return}
	set todo {}
	foreach index [array names ::config::todo] {
		set command $::config::todo($index)
		if {![inlist $todo $command]} {
			lappend todo $command
			catch {eval $command}
		}
	}
	array unset config::todo	
}

proc dropStalledCommands {} {
	catch {unset ::config::todo}
}

proc cancelStalledCommand {var} {
	catch {unset ::config::todo($var)}
}

proc toDefault {name} {
	global cfgfile
	# default values from ORIGINAL config file
	if {[regexp {^standard-(.*)$} $name match size]} {
		readSettings oriconfig $cfgfile
		if {[info exist oriconfig::stds(sizes\ ${size})]} {
			set tempconfig::stds(sizes\ ${size}) [set oriconfig::stds(sizes\ ${size})]
		}
		namespace delete oriconfig
	} else {
		set check [split $name :]
		if {[llength $check]} {set name [lindex $check end]}
		readSettings oriconfig $cfgfile
		set tempconfig::$name [set oriconfig::${name}]
		namespace delete oriconfig
	}
}

proc typeSwitch {arrays var} {
	foreach array $arrays {
		if {[info exist ::${array}::default($var-list)]} {
			set typelist [set ::${array}::default($var-list)]
		} else {
			set typelist {Enabled Disabled}
		}
		if {![info exist ::${array}::default($var)]} {return}
		set current [set ::${array}::default($var)]
		lappend typelist [lindex $typelist 0]
		set found 0
		foreach value $typelist {
			if {[string equal $value $current]} {
				set found 1
				continue
			}
			if {$found} {
				break
			}
		}
		# catch settings variable in case namespace tempconfig does not exists (yet)
		catch {set ::${array}::default($var) $value}
	}
}
