##########building markerbar
Widget subclass MarkerBar

MarkerBar method init {args} {
	super init
	private $object options
	if {![info exists options(-target)]} {
		bgerror "No target given"
	} else {
		set target $options(-target)
	}
	set ::config::active_type $::config::default(active_type)
	rOptionMenu $object.marker -command "$object activate_marker" -list $::data::markers -textvariable ::data::active_marker
	balloon $object.marker markerbar,marker
	frame $object.xrange -highlightthickness 0
		label $object.xrange.l -text "XRange: "
		label $object.xrange.b -text "-"
		entry $object.xrange.min -width 4
		balloon $object.xrange.min markerbar,xmin
		$object.xrange.min delete 0 end
		$object.xrange.min insert 0 {}
		bind $object.xrange.min <Key-Return> [list $object rerange %W]
		bind $object.xrange.min <Key-Up> [list $object rerange %W +10]
		bind $object.xrange.min <Key-Down> [list $object rerange %W -10]
		entry $object.xrange.max -width 4
		balloon $object.xrange.max markerbar,xmax
		$object.xrange.max delete 0 end
		$object.xrange.max insert 0 {}
		bind $object.xrange.max <Key-Return> [list $object rerange %W]
		bind $object.xrange.max <Key-Up> [list $object rerange %W +10]
		bind $object.xrange.max <Key-Down> [list $object rerange %W -10]
		grid $object.xrange.l -row 0 -column 0
		grid $object.xrange.min -row 0 -column 1
		grid $object.xrange.b -row 0 -column 2
		grid $object.xrange.max -row 0 -column 3
	frame $object.yrange -highlightthickness 0
		label $object.yrange.l -text "YRange: "
		label $object.yrange.b -text "-"
		entry $object.yrange.min -width 6 -textvariable ::config::default(ymin)
		balloon $object.yrange.min markerbar,ymin
#		$object.yrange.min delete 0 end
#		$object.yrange.min insert 0 $config::default(ymin)
		bind $object.yrange.min <Key-Return> [list $object rerange %W]
		bind $object.yrange.min <Key-Up> [list $object rerange %W +100]
		bind $object.yrange.min <Key-Down> [list $object rerange %W -100]
		entry $object.yrange.max -width 6
		balloon $object.yrange.max markerbar,ymax
		$object.yrange.max delete 0 end
		$object.yrange.max insert 0 {}
		bind $object.yrange.max <Key-Return> [list $object rerange %W]
		bind $object.yrange.max <Key-Up> [list $object rerange %W +100]
		bind $object.yrange.max <Key-Down> [list $object rerange %W -100]
		grid $object.yrange.l -row 0 -column 0
		grid $object.yrange.min -row 0 -column 1
		grid $object.yrange.b -row 0 -column 2
		grid $object.yrange.max -row 0 -column 3
	frame $object.colors
	rOptionMenu $object.zoom -command "$::gridW configure -pattern" -list $::config::patternlist -textvariable ::config::temp(pattern)
	balloon $object.zoom markerbar,zoom
	button $object.superimp -text SI -command [list $::gridW superimpButton]
	balloon $object.superimp markerbar,superimp
	if {$args != ""} {eval $object configure $args}
	button $object.editGraph -text G -command [list $::gridW pushEdit $object.editGraph] -relief raised -image $::grid
	balloon $object.editGraph markerbar,editGraph
	grid $object.marker -column 0 -row 0
	grid $object.zoom -column 1 -row 0
	grid $object.superimp -column 2 -row 0
	grid $object.editGraph -column 3 -row 0
	grid $object.xrange -column 4 -row 0
	grid $object.yrange -column 5 -row 0
	grid $object.colors -column 6 -row 0
	bind $object <x> "focus $object.xrange.min"
	bind $object <y> "focus $object.yrange.min"
	if {$args != ""} {eval $object configure $args}
}

MarkerBar addoption -target {target Target {}} {
	Classy::todo $object refresh
}

MarkerBar addoption -listbox {listbox ListBox {}} {
	Classy::todo $object refresh
}

MarkerBar method rerange {button {nr 0}} {
	private $object options
	set target $options(-target)
	if {![string length $target]} {
		return
	}
	set grids [winfo children $target]
	set parent [winfo parent $button]
	set option [lindex [split $parent .] end]
	set premin [$parent.min get]
	set premax [$parent.max get]
	if {$nr} {
		set temp [expr [$button get] + ($nr)]
		if {$temp <=0} {return}
		$button delete 0 end
		$button insert 0 $temp
	}
	set min [$parent.min get]
	set max [$parent.max get]
	if {![string length $min] || ![string length $max] || $min < $max} {
		eval $::gridW configure -$option \"$min $max\"
#		foreach grid $grids {
#			if {![string length [grid info $grid]]} {continue}
#			eval $grid configure -$option \"$min $max\"
#		}
	} else {
		$parent.min delete 0 end
		$parent.min insert 0 $premin
		$parent.max delete 0 end
		$parent.max insert 0 $premax
	}
}

MarkerBar method change_option {option value} {
	private $object options
	set target $options(-target)
	if {![string length $target]} {
		return
	}
	set grids [winfo children $target]
	foreach grid $grids {
		if {![string length [grid info $grid]]} {continue}
		eval $grid configure -$option \"$value\"
	}
}

MarkerBar method refresh {} {
puts markerbar_refresh
	private $object options
	set target $options(-target)
	set col 0
	foreach color {blue yellow red green orange} {
		if {![string length [info command $object.colors.$color]]} {
			ColorButton $object.colors.$color
			$object.colors.$color configure -target $target -color $color -incolor grey
		}
		grid $object.colors.$color -row 0 -column $col
		incr col
	}
	$object.marker configure -list $::data::markers
}

MarkerBar method activate_marker {marker} {
	if {![info exist ::data::datalist(unknown)]} {
		tk_messageBox -message "No data to work on..." -icon error -title "Import"
		return
	}
	set ::config::temp(pattern) All
	if {[info exist ::locus2id]} {unset ::locus2id}
	set ::data::active_marker $marker
	applyAssay $marker
	alterDatalist
	set grid $::gridW
	if {![string length $marker]} {return}
	global bar
	set ::data::active_datalist $data::datalist($marker)
	set testline [lindex $::data::active_datalist 0]
	set pos 1
	array unset ::data::column
	foreach {col val} $testline {
		set ::data::column($col) $pos
		incr pos 2
	}
	set ::data::active_datalist [lsort -real -index $::data::column(index) $::data::active_datalist]
	if {![llength $data::active_genos] || [string equal $config::default(activateAll) Enabled]} {updateActive_genos}
	private $object options
	set newlist {}
	set parts {}
	Classy::busy
	array unset ::data::part
	set partcol $::data::column(part)
	set indexcol $::data::column(index)
	foreach line $::data::active_datalist {
		set index [lindex $line $indexcol]
		set part [lindex $line $partcol]
		lappend parts $part
		lappend ::data::part($::data::active_marker,$part) $index
		lappend newlist $index
	}
	set ::data::active_genos $newlist
	$object.marker configure -text "$marker"
	set notes ""
	if {[info exist ::data::${marker}(notes)]} {
		set notes [lindex [set ::data::${marker}(notes)] 0]
	}
	if {[string length $notes]} {
	        drawbar $bar 0 "Note: $notes" red
	} else {
	        drawbar $bar 0 "" black
	}
	catch {$::listboxW configure -marker $marker}
	$::gridW configure -pattern All
	Classy::busy remove
}

proc updateActive_genos {} {
	set newlist {}
	set parts {}
	array unset ::data::part
	set partcol $::data::column(part)
	set indexcol $::data::column(index)
	foreach line $::data::active_datalist {
		set index [lindex $line $indexcol]
		set part [lindex $line $partcol]
		lappend parts $part
		lappend ::data::part($::data::active_marker,$part) $index
		lappend newlist $index
	}
	set ::data::active_genos $newlist
}

MarkerBar method marker_select {type} {
	set marker $::data::active_marker
	set markerlist $::data::markers
	set mpos [lsearch $markerlist $marker]
	switch $type {
		next {
			incr mpos
		}
		prev {
			incr mpos -1
		}
		first {
			set mpos 0
		}
		last {
			set mpos [expr [llength $markerlist] - 2]
		}
	}
	set newmarker [lindex $markerlist $mpos]
	if {![string length $newmarker] || [inlist "$marker unknown" $newmarker]} {return}
	$object activate_marker $newmarker
}

