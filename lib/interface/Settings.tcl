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
#	tabExport $object $Wtabset $prefix
#	tabDos $object $Wtabset $prefix
	tabChrom $object $Wtabset $prefix
	tabColors $object $Wtabset $prefix
	tabList $object $Wtabset $prefix
	tabGeneral $object $Wtabset $prefix
#	refresh_rOptionMenu
	wm protocol $object WM_DELETE_WINDOW [list $object exit]\;return
	wm title $object "Settings"
	Classy::canceltodo $object place
#	update idletask
}

proc tabDos {object Wtabset prefix} {
	# dosplot tabset
	set dosframe [frame $Wtabset.dosplot]
	$Wtabset insert 0 dos -text DosPlot
#	$Wtabset tab configure dos -fill both -padx 0.05i -pady 0.05i -window $dosframe
	$Wtabset tab configure dos -fill both -pady 0.05i -window $dosframe
#	label $dosframe.heading -text "Settings"
#	grid $dosframe.heading
	set settingsframe [frame $dosframe.frame]
		addHeader plotl $settingsframe "DosPlot layout"
		addSetting dos_bg $settingsframe "Plot background" color
		addSetting dos_normal $settingsframe "Plot area around DQ 1 (0.8 < DQ < 1.2)" color
		addSetting ymax $settingsframe "Max height" entry
		label $settingsframe.llegend -text "${prefix}Legend" -anchor w
		button $settingsframe.blegend -command "typeSwitch legend" -textvariable ::config::default(legend)
		balloon $settingsframe.blegend settings,legend
		addSetting dos_grayzone $settingsframe "Plot area in between expected DQs (width of 0.1)" color
		addHeader otherl $settingsframe "Other settings"
		addSetting min_height $settingsframe "Minimal mean height" entry
		addSetting min_score $settingsframe "Quality cutoff" entry
		label $settingsframe.ltype -text "${prefix}Ratios based upon" -anchor w
		button $settingsframe.btype -command "$object changeType" -textvariable ::config::default(assaytype)
		balloon $settingsframe.btype settings,type
	set buttonframe [frame $dosframe.buttons]
		button $buttonframe.ok -text "Ok" -command [list $object apply $::dosW close]
		balloon $buttonframe.ok settings,ok
		button $buttonframe.apply -text "Apply" -command [list $object apply $::dosW]
		balloon $buttonframe.showdos settings,showdos
		button $buttonframe.cancel -text "Cancel" -command [list $object cancel]
		balloon $buttonframe.cancel settings,cancel
		grid $settingsframe.ltype $settingsframe.btype -sticky nwse
		grid $settingsframe.llegend $settingsframe.blegend -sticky nwse
	grid $settingsframe -sticky nwse
	grid columnconfigure $dosframe 0 -weight 1
	grid rowconfigure $dosframe 1 -weight 1
	grid columnconfigure $settingsframe 0 -weight 1
	grid columnconfigure $settingsframe 1 -weight 1
	grid $buttonframe.ok $buttonframe.apply $buttonframe.cancel
	grid $buttonframe -sticky s
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
		addHeader gridl $settingsframe "Grid layout"
#		label $settingsframe.gridl -text Grid -font "helvetica 10 bold" -anchor w
#		grid $settingsframe.gridl -sticky nwse -columnspan 2
		label $settingsframe.rowslabel -text "${prefix}Number of rows" -anchor w
		frame $settingsframe.rows -highlightthickness 0
			button $settingsframe.rows.up -command [list $::gridW gridincr rows 1] -width 1 -text {+}
			entry $settingsframe.rows.nr -width 2 -textvariable ::config::grid(rows)
			balloon $settingsframe.rows.nr grid,rows
			bind $settingsframe.rows.nr <Key-Return> [list $::gridW gridset rows]
			button $settingsframe.rows.down -command [list $::gridW gridincr rows -1] -width 1 -text {-}
			grid $settingsframe.rows.down -column 0 -row 0
			grid $settingsframe.rows.nr -column 1 -row 0 -sticky we
			grid $settingsframe.rows.up -column 2 -row 0
			grid columnconfigure $settingsframe.rows 1 -weight 1
		label $settingsframe.columnslabel -text "${prefix}Number of columns" -anchor w
		frame $settingsframe.columns -highlightthickness 0
			button $settingsframe.columns.up -command [list $::gridW gridincr columns 1] -width 1 -text {+}
			entry $settingsframe.columns.nr -width 2 -textvariable ::config::grid(columns)
			balloon $settingsframe.columns.nr grid,columns
			bind $settingsframe.columns.nr <Key-Return> [list $::gridW gridset columns]
			button $settingsframe.columns.down -command [list $::gridW gridincr columns -1] -width 1 -text {-}
			grid $settingsframe.columns.down -column 0 -row 0
			grid $settingsframe.columns.nr -column 1 -row 0 -sticky we
			grid $settingsframe.columns.up -column 2 -row 0
			grid columnconfigure $settingsframe.columns 1 -weight 1
		grid $settingsframe.rowslabel $settingsframe.rows -sticky nwse
		grid $settingsframe.columnslabel $settingsframe.columns -sticky nwse
		addHeader zooml $settingsframe "Zoom function"
#		label $settingsframe.zoom2l -text "${prefix}Amplicons to choose from" -anchor w
#		button $settingsframe.zoom2b -command "typeSwitch zoom2;$::gridW updatePatterns" -textvariable ::config::default(zoom2)
#		balloon $settingsframe.zoom2b settings,zoom2
#		grid $settingsframe.zoom2l $settingsframe.zoom2b -sticky nwse
		addSetting zoomrange $settingsframe "Extra range on either side of the marker area" entry
#		label $settingsframe.autozooml -text "${prefix}Auto zoom when editing bins" -anchor w
#		button $settingsframe.autozoomb -command "typeSwitch autozoom" -textvariable ::config::default(autozoom)
#		balloon $settingsframe.autozoomb settings,autozoom
#		grid $settingsframe.autozooml $settingsframe.autozoomb -sticky nwse
		addHeader labell $settingsframe "Label 'individual' inside chromatogram"
		label $settingsframe.showlabell -text "${prefix}Label shown" -anchor w
		button $settingsframe.showlabelb -command "typeSwitch showlabel" -textvariable ::config::default(showlabel)
		balloon $settingsframe.showlabelb settings,showlabel
		grid $settingsframe.showlabell $settingsframe.showlabelb -sticky nwse
		addSetting label_font $settingsframe "Label font" font
		addHeader lowl $settingsframe "Low height marker"
		label $settingsframe.showlowl -text "${prefix}Low height marker shown" -anchor w
		button $settingsframe.showlowb -command "typeSwitch showlow" -textvariable ::config::default(showlow)
		balloon $settingsframe.showlowb settings,showlow
		grid $settingsframe.showlowl $settingsframe.showlowb -sticky nwse
		addSetting lowpeaks $settingsframe "Low height marker (height)" entry
#		addHeader binl $settingsframe "Amplicon layout"
#		label $settingsframe.showbinl -text "${prefix}Amplicon bin shown" -anchor w
#		button $settingsframe.showbinb -command "typeSwitch showbin" -textvariable ::config::default(showbin)
#		balloon $settingsframe.showbinb settings,showbin
#		grid $settingsframe.showbinl $settingsframe.showbinb -sticky nwse
#		addSetting binname $settingsframe "Amplicon label (font)" font
#		addSetting binrotation $settingsframe "Amplicon label (rotate)" entry
#		label $settingsframe.showbinnamel -text "${prefix}Show only bin labels of this type" -anchor w
#		button $settingsframe.showbinnameb -command "typeSwitch showbinname" -textvariable ::config::default(showbinname)
#		balloon $settingsframe.showbinnameb settings,showbinname
#		grid $settingsframe.showbinnamel $settingsframe.showbinnameb -sticky nwse
#		addHeader refl $settingsframe "Normalized reference peaks"
#		label $settingsframe.showrefl -text "${prefix}Reference shown" -anchor w
#		button $settingsframe.showrefb -command "typeSwitch reference" -textvariable ::config::default(reference)
#		balloon $settingsframe.showrefb settings,showreference
#		grid $settingsframe.showrefl $settingsframe.showrefb -sticky nwse
#		addSetting reference_shift $settingsframe "Number of bases shifted compared to read" entry
#		addSetting reference_linewidth $settingsframe "Reference line width" entry
		addHeader otherl $settingsframe "Other settings"
		addSetting showbinOnSi $settingsframe "Show bins on superimpose" button
		addSetting ymin $settingsframe "Minimal height treshold" entry
		addSetting signalwidth $settingsframe "Signal Width" entry
#		label $settingsframe.showresl -text "${prefix}Amplicon height/area shown" -anchor w
#		button $settingsframe.showresb -command "typeSwitch showresult" -textvariable ::config::default(showresult)
#		balloon $settingsframe.showresb settings,showresult
#		grid $settingsframe.showresl $settingsframe.showresb -sticky nwse
		addSetting overlayHold $settingsframe "Overlay reads while held" button
		label $settingsframe.lshowstandard -text "${prefix}Show missing internal standard" -anchor w
		button $settingsframe.bshowstandard -command "typeSwitch showstandard" -textvariable ::config::default(showstandard)
		balloon $settingsframe.bshowstandard settings,showstandard
		grid $settingsframe.lshowstandard $settingsframe.bshowstandard -sticky nwse
	set buttonframe [frame $mainframe.buttons]
		button $buttonframe.ok -text "Ok" -command [list $object apply $::dosW close]
		balloon $buttonframe.ok settings,ok
		button $buttonframe.refresh -text Apply -command "$object apply $::gridW"
		balloon $buttonframe.refresh settings,refresh
		button $buttonframe.cancel -text "Cancel" -command [list $object cancel]
		balloon $buttonframe.cancel settings,cancel
		grid $buttonframe.ok $buttonframe.refresh $buttonframe.cancel
	grid $buttonframe -sticky s
}

proc tabColors {object Wtabset prefix} {
	# Colors tabset
	set mainframe [frame $Wtabset.colors]
	$Wtabset insert 1 colors -text Colors
#	$Wtabset tab configure colors -fill both -padx 0.05i -pady 0.05i -window $mainframe
	$Wtabset tab configure colors -fill both -pady 0.05i -window $mainframe
#	label $mainframe.heading -text "Color settings"
#	grid $mainframe.heading -sticky n
	grid columnconfigure $mainframe 0 -weight 1
	grid rowconfigure $mainframe 1 -weight 1
	set settingsframe [frame $mainframe.frame]
		addHeader ampl $settingsframe "Amplicons"
		addSetting score $settingsframe "Scored amplicon (bin)" color
#		addSetting badcontrol $settingsframe "Controle amplicon (bin)" color
#		addSetting goodcontrol $settingsframe "Controle amplicon (height)" color
#		addSetting badtest $settingsframe "Test amplicon (bin)" color
#		addSetting goodtest $settingsframe "Test amplicon (height)" color
#		addHeader quall $settingsframe "Quality"
#		addSetting qgood $settingsframe "Good Quality (0 <= Q <= 0.1)" color
#		addSetting qmiddle $settingsframe "Average Quality (0.1 < Q <= 0.15)" color
#		addSetting qbad $settingsframe "Bad Quality (0.15 < Q <= 1)" color
#		addHeader dell $settingsframe "Dosage quantity"
#		addSetting full_deletion $settingsframe "Homozygous deletion (0 < DQ < 0.25)" color
#		addSetting half_deletion $settingsframe "Heterozygous deletion (0.25 < DQ < 0.75)" color
#		addSetting unk_deletion $settingsframe "Slight decrease (0.75 < DQ < 0.80)" color
#		addSetting unk_duplication $settingsframe "Slight increase (1.2 < DQ < 1.3)" color
#		addSetting half_duplication $settingsframe "Heterozygous duplication (1.3 < DQ < 1.75)" color
#		addSetting full_duplication $settingsframe "Homozygous duplication (DQ > 1.75)" color
		addHeader quality $settingsframe "Quality coloring"
		addSetting qgood $settingsframe "Good quality" color
		addSetting qmiddle $settingsframe "Medium quality" color
		addSetting qbad $settingsframe "Low quality" color
		addHeader actl $settingsframe "Active read coloring"
		addSetting activebg $settingsframe "Active read" color
		addSetting activeplotbg $settingsframe "Active read background" color
		addHeader low $settingsframe "Low Height"
#		addSetting blue-area $settingsframe "Peak area background" color
		addSetting lowpeaks_bg $settingsframe "Low height marker (background)" color
		addSetting lowpeaks_border $settingsframe "Low height marker (border)" color
#		addSetting reference_line $settingsframe "Normalized reference line color" color
		addHeader othl $settingsframe "Other settings"
		addSetting overlayHold $settingsframe "Background reads (if superimposed)" color
	grid $settingsframe -sticky nwse
	grid columnconfigure $settingsframe 0 -weight 1
	grid columnconfigure $settingsframe 1 -weight 1
	set buttonframe [frame $mainframe.buttons]
		button $buttonframe.ok -text "Ok" -command [list $object apply "$::listboxW $::gridW" close]
		balloon $buttonframe.ok settings,ok
		button $buttonframe.refresh -text Apply -command "$object apply $::listboxW"
		balloon $buttonframe.refresh settings,refresh
		button $buttonframe.default -text "Default" -command [list $object default]
		balloon $buttonframe.default settings,default
		button $buttonframe.cancel -text "Cancel" -command [list $object cancel]
		balloon $buttonframe.cancel settings,cancel
		grid $buttonframe.ok $buttonframe.refresh $buttonframe.default $buttonframe.cancel
	grid $buttonframe -sticky s
}

proc tabGeneral {object Wtabset prefix} {
	# General tabset
	set mainframe [frame $Wtabset.general]
	$Wtabset insert 0 general -text General
#	$Wtabset tab configure general -fill both -padx 0.05i -pady 0.05i -window $mainframe
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
#		addSetting glob_reference $settingsframe "references" entry
		addHeader reanalyse $settingsframe "Genescan analysis"
#		addSetting reanalyse $settingsframe "Always overrule analysis" button
		addSetting restandard $settingsframe "Always overrule standard" button
		addHeader align $settingsframe "Aligning"
		addSetting alignwindow $settingsframe "window" entry
		addHeader check4update $settingsframe "Updates"
		addSetting check4update $settingsframe "Prompt if update available" button
#		addHeader q2 $settingsframe "Q2 settings"
#		addSetting q2penalty $settingsframe "Indel penalty" entry
#		addSetting q2range $settingsframe "Window" entry
		addSetting changeILS $settingsframe "Change the set ILS" button
	grid $settingsframe -sticky nwse
	grid columnconfigure $settingsframe 0 -weight 1
	grid columnconfigure $settingsframe 1 -weight 1
	set buttonframe [frame $mainframe.buttons]
		button $buttonframe.ok -text "Ok" -command [list $object apply $::dosW close]
		balloon $buttonframe.ok settings,ok
		button $buttonframe.apply -text "Apply" -command [list $object apply $::listboxW]
		balloon $buttonframe.apply settings,apply
		button $buttonframe.cancel -text "Cancel" -command [list $object cancel]
		balloon $buttonframe.cancel settings,cancel
		grid $buttonframe.ok $buttonframe.apply $buttonframe.cancel
	grid $buttonframe -sticky s
}

proc tabExport {object Wtabset prefix} {
	# Export tabset
	set mainframe [frame $Wtabset.export]
	$Wtabset insert 0 export -text Export
#	$Wtabset tab configure export -fill both -padx 0.05i -pady 0.05i -window $mainframe
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
	set buttonframe [frame $mainframe.buttons]
		button $buttonframe.ok -text "Ok" -command [list $object apply $::dosW close]
		balloon $buttonframe.ok settings,ok
		button $buttonframe.apply -text "Apply" -command [list $object apply $::listboxW]
		balloon $buttonframe.apply settings,apply
		button $buttonframe.cancel -text "Cancel" -command [list $object cancel]
		balloon $buttonframe.cancel settings,cancel
		grid $buttonframe.ok $buttonframe.apply $buttonframe.cancel
	grid $buttonframe -sticky s
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
	set buttonframe [frame $mainframe.buttons]
		button $buttonframe.ok -text "Ok" -command [list $object apply $::listboxW close]
		balloon $buttonframe.ok settings,ok
		button $buttonframe.apply -text "Apply" -command [list $object apply $::listboxW]
		balloon $buttonframe.apply settings,apply
		button $buttonframe.cancel -text "Cancel" -command [list $object cancel]
		balloon $buttonframe.cancel settings,cancel
		grid $buttonframe.ok $buttonframe.apply $buttonframe.cancel
	grid $buttonframe -sticky s
}

SettingsW method apply {windows {close {}}} {
	saveState
	foreach w $windows {
		if {![string length [info command $w]]} {continue}
		$w refresh
	}
	if {[string equal $close close]} {
		$object exit
	}
}

SettingsW method cancel {} {
	global userfile
        readSettings $userfile
	$object refresh_colors
	$object exit
}

SettingsW method refresh_colors {} {
	set root .settings.ts.colors.frame
	foreach button [winfo children $root] {
		if {[regexp "$root\.cb(.*)" $button match name]} {
			set color $config::color($name)
			$button configure -background $color -highlightbackground $color -activebackground $color
		}
	}
}

SettingsW method default {} {
	global cfgfile
	readSettings $cfgfile config::color
	$object refresh_colors
#	$::gridW refresh
#	$::listboxW refresh
}

SettingsW method showdos {} {
	if {[string length [info command $::dosW]]} {
		$::dosW refresh
	}
}

SettingsW method exit {} {
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
	switch $type {
		entry {
			set var ::config::default($name)
			label $parent.el$name -text ${prefix}$text -anchor w
			entry $parent.ee$name -textvariable $var
			grid $parent.el$name $parent.ee$name -sticky nwse
			balloon $parent.ee$name settings,$name
		}
		color {
			set var ::config::color($name)
			label $parent.cl$name -text ${prefix}$text -anchor w
			set current [set $var]
			button $parent.cb$name -bg $current -activebackground $current -command "ChooseColor $parent.cb$name $var"
#			button $parent.cb$name -textvariable $var -bg $current -activebackground $current -command "ChooseColor $parent.cb$name $var"
			grid $parent.cl$name $parent.cb$name -sticky nwse
			balloon $parent.cb$name settings,$name
		}
		font {
			set var ::config::font($name)
			label $parent.fl$name -text ${prefix}$text -anchor w
			set current [set $var]
			button $parent.fb$name -textvariable $var -command "ChooseFont $var"
			grid $parent.fl$name $parent.fb$name -sticky nwse
			balloon $parent.fb$name settings,$name
		}
		checkbutton {
			set var ::config::checkbutton($name)
			label $parent.chl$name -text ${prefix}$text -anchor w
			checkbutton $parent.chb$name -variable $var
			grid $parent.chl$name $parent.chb$name -sticky nwse
			balloon $parent.chl$name settings,$name
		}
		button {
			set var ::config::default($name)
			label $parent.bl$name -text "${prefix}$text" -anchor w
			button $parent.bb$name -command "typeSwitch $name;$args" -textvariable $var
			grid $parent.bl$name $parent.bb$name -sticky nwse
			balloon $parent.bb$name settings,$name
		}
	}
}

proc ChooseFont {var} {
	set current [set $var]
	catch {Classy::getfont -font $current} font
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

proc recolor {} {
	$::dosW configure -colors {}
}


