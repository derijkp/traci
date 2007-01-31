#########building grid
Widget subclass Grid

Grid method init {args} {
	global tca_roles tca_role
	super init
	private $object options
	# graphs within .grid.graph
	frame $object.graphs -highlightthickness 0
	if {$args != ""} {eval $object configure $args}
	# text beneath graphs
	scrollbar $object.scroll -command [list $object graphscroll] -orient horizontal
	balloon $object.scroll grid,scroll
	grid $object.graphs -sticky nwse -column 0 -row 1
	grid $object.scroll -sticky ew -column 0 -row 2
	grid rowconfigure $object 0 -weight 0
	grid rowconfigure $object 1 -weight 1
	grid rowconfigure $object 2 -weight 0
	grid columnconfigure $object 0 -weight 1
	bind $object <MouseWheel> [list $object graphbrowser index %D]
	bind $object <Control-MouseWheel> [list $object graphbrowser page %D]
	bind $object <ButtonPress-4> [list $object graphbrowser index -1]
	bind $object <ButtonPress-5> [list $object graphbrowser index 1]
	Classy::todo $object refresh
}

Grid addoption -columns {columns Columns {1}} {
	Classy::todo $object refresh
}

Grid addoption -rows {rows Rows {1}} {
	Classy::todo $object refresh
}

Grid addoption -patterns [list patterns Patterns $config::patternlist] {
	catch {.mainw.markerbar.zoom configure -list $value}
}

Grid addoption -pattern {pattern Pattern all} {
	set ::config::temp(pattern) $value
	Classy::todo $object drawmaq
	Classy::todo $::listboxW configure -pattern $value
}

Grid addoption -superimp_state {superimp_state SuperImp_state {0}} {
	Classy::todo $object refresh
}

Grid addoption -listbox_state {listbox_state Listbox_State {0}} {
	$object update_listboxButton $value
}

Grid addoption -maq_state {maq_state Maq_State 0} {
	$object update_maqButton $value
}

Grid addoption -marker {marker Marker {}} {
#	Classy::todo $object refresh
}

Grid addoption -active {active Active 0} {
	Classy::todo $object refresh
	if {[string length [info command .dos]]} {Classy::todo .dos configure -active $value}
}

Grid addoption -first {first First 0} {
	Classy::todo $object refresh
	if {[string length [info command .dos]]} {Classy::todo .dos configure -first $value}
}

Grid addoption -xrange {xrange Xrange {}} {
	Classy::todo $object refresh
}

Grid addoption -yrange {yrange Yrange {}} {
	Classy::todo $object refresh
}

Grid addoption -colors {colors Colors {}} {
	Classy::todo $object refresh
}

Grid addoption -defcolor {defcolors Defcolors {}} {
	Classy::todo $object refresh
}

Grid method gridincr {type nr} {
	private $object options
	set newvalue [expr $options(-$type) + $nr]
	if {$newvalue < 1} {set newvalue 1}
	set ::config::grid($type) $newvalue
	$object configure -$type $newvalue
	resizeMin
}

Grid method gridset {type} {
	private $object options
	set nr $::config::grid($type)
	if {$nr < 1} {set nr 1}
	set ::config::grid($type) $nr
	$object configure -$type $nr
	resizeMin
}

Grid method superimpButton {} {
	private $object options
	set superimp $options(-superimp_state)
	if {$superimp} {
		$object configure -superimp_state 0
		$::markerbarW.superimp configure -relief raised
	} else {
		$object configure -superimp_state 1
		$::markerbarW.superimp configure -relief sunken
	}
}

Grid method refresh {} {
puts refresh_grid 
	private $object options
	set rows $options(-rows)
	set columns $options(-columns)
	set superimp $options(-superimp_state)
	if {$superimp} {
		set rows 1
		set columns 1
	}
	set marker $options(-marker)
	set nr 0
	for {set col 0} {$col<$columns} {incr col} {
		for {set row 0} {$row<$rows} {incr row} {
			if {![string length [info command $object.graphs.g$nr]]} {
				GenoViewer $object.graphs.g$nr
			}
			grid $object.graphs.g$nr -row $row -column $col -sticky nwse
			grid rowconfigure $object.graphs $row -weight 1
			grid columnconfigure $object.graphs $col -weight 1
			incr nr
		}
	}
	set usedcolumns ""
	set usedrows ""
	set graphs ""
	set used_graphs [winfo children $object.graphs]
	foreach graph $used_graphs {
		if {[regexp {[0-9]+$} $graph match] && $match > [expr ($columns * $rows)-1]} {
			set info [grid info $graph]
			set colpos [lsearch $info -column]
			set col [lindex $info [expr $colpos + 1]]
			lappend usedcolumns $col
			set rowpos [lsearch $info -row]
			set row [lindex $info [expr $rowpos + 1]]
			lappend usedrows $row
			lappend graphs $graph
		}
	}
	foreach g $graphs {
		grid forget $g
	}
	foreach row $usedrows {
		if {$row > [expr $rows -1]} {
			grid rowconfigure $object.graphs $row -weight 0
		}
	}
	foreach col $usedcolumns {
		if {$col > [expr $columns -1]} {
			grid columnconfigure $object.graphs $col -weight 0
		}
	}
	$object draw
	$object updatePatterns
#	$object drawmaq
}

Grid method draw {{type {}}} {
	private $object options
	set rows $options(-rows)
	set cols $options(-columns)
	set page [expr $rows * $cols]
	set superimp $options(-superimp_state)
	set pattern $options(-pattern)
	set active $options(-active)
	if {![string length $active] || $active >= [llength $data::active_genos]} {set active 0}
	set first $options(-first)
	if {![string length $first] || $first >= [llength $data::active_genos]} {set first 0}
	set first_geno [lindex $data::active_genos $first]
	set active_geno [lindex $data::active_genos [expr $first + $active]]
	set ::data::active_read [fetchVal $active_geno gs_read]
	set genos_pos $first
	if {$superimp} {
		set readlist $::data::active_read
		set genolist $active_geno
		foreach geno $data::active_genos {
			foreach {read exp} [fetchVal $geno {gs_read}] break
			if {![inlist $readlist $read]} {lappend readlist $read}
			if {![inlist $genolist $geno]} {lappend genolist $geno}
		}
		$object.graphs.g0 configure -reads $readlist -index $genolist -pattern $pattern -xrange $options(-xrange) -yrange $options(-yrange) -defcolor $options(-defcolor) -colors $options(-colors) -si 1
		set gridnr 1
		while {$gridnr < [expr $cols * $rows]} {
			$object.graphs.g$gridnr configure -reads {} -index {}
			incr gridnr
		}
	} else {
		set gridnr 0
		while {$gridnr < [expr $cols * $rows]} {
			set genotype [lindex $data::active_genos [expr $genos_pos + $gridnr]]
			foreach {read exp part} [fetchVal $genotype {gs_read experiment part}] break
			if {[string length $genotype]} {
				$object.graphs.g$gridnr configure -reads $read -index $genotype -pattern $pattern -xrange $options(-xrange) -yrange $options(-yrange) -defcolor $options(-defcolor) -colors $options(-colors) -si 0
			} else {
				$object.graphs.g$gridnr configure -reads {} -index {} -si 0
			}
			incr gridnr
		}
	}
	# scrollbar
	set length [llength $::data::active_genos]
	if {$length < 1} {
		$object.scroll set 0 1
	} else {
		$object.scroll set [expr $first / double($length)] [expr ($first + ($cols * $rows)) / double($length)]
	}
}

Grid method graphscroll {type number {units {}}} {
	private $object options
	set rows $options(-rows)
	set cols $options(-columns)
	set page [expr $rows * $cols]
	set length [llength $::data::active_genos]
	switch $type {
		moveto {
			set first [expr round($number * $length)]
			if {$first < 0} {
				set first 0
			} elseif {$first >= [expr $length - $page]} {
				set first [expr $length - $page]
			} 
			$object configure -first $first
			catch {$::listboxW showLine}
		}
		scroll {
			switch $units {
				units {
					$object graphbrowser index $number
				}
				pages {
					$object graphbrowser page $number
				}
			}
		}
	}
	Classy::todo $object refresh
}

Grid method graphbrowser {type {aantal {}}} {
	private $object options
	set rows $options(-rows)
	set cols $options(-columns)
	set nr [expr $cols * $rows]
	set first $options(-first)
	if {![string length $first]} {set first 0}
	set first_geno [lindex $data::active_genos $first]
	set active $options(-active)
	if {![string length $active]} {set active 0}
	set active_geno [lindex $data::active_genos [expr $first + $active]]
	set length [llength $data::active_genos]
	switch $type {
		end {
			set newfirst [expr $length -1]
		}
		home {
			set newfirst 0
		}
		page {
			set newfirst [expr $first + ( $aantal * $nr)]
		}
		index {
			set newfirst [expr $first + $aantal]
		}
	}
	if {$newfirst < 0 || [expr $length - $nr] < 0} {
		set newfirst 0
	} elseif {$newfirst >= [expr $length - 1]} {
		set newfirst [expr $length - 1]
	}
	$object configure -first $newfirst
	catch {$::listboxW showLine}
	Classy::todo $object refresh
}

Grid method updatePatterns {} {
	set currentAssay $::data::active_marker
	if {![info exist ::config::active_type] || ![info exist ::data::amplicons($currentAssay,control)]} {
		set cpattern [$object cget -pattern]
		if {![string equal $cpattern All]} {
			$object configure -patterns All -pattern All
		} else {
			$object configure -patterns All
		}
		return
	}
	set cpatterns [$object cget -patterns]
	set cpattern [$object cget -pattern]
	set controles $::data::amplicons($currentAssay,control)
#	set tests $::data::amplicons($currentAssay,test)
	set loci $::data::amplicons($currentAssay,all)
	if {![info exist ::data::amplicons($currentAssay,test)] || ![llength $::data::amplicons($currentAssay,test)]} {
		set tests $loci
	}
#	set used $::data::controles($currentAssay,used)
	switch $::config::default(zoom2) {
		Test {
			set list [concat All $tests]
		}
		Control {
			set list [concat All $controles]
		}
		default {
			set list [concat All $loci]
		}
	}
	set args ""
	if {![string equal $list $cpatterns]} {
		append args " [list -patterns $list]"
	}
	if {![inlist $list $cpattern]} {
#		append args " [list -pattern [lindex $list 0]]"
	}
	if {[string length $args]} {
		eval $object configure $args
	}
}

Grid method zoom_new {min max} {
	set changed 0
	set testmin [$::markerbarW.xrange.min get]
	if {$testmin != $min} {
		$::markerbarW.xrange.min delete 0 end
		$::markerbarW.xrange.min insert 0 $min
		set changed 1
	}
	set testmax [$::markerbarW.xrange.max get]
	if {$testmax != $max} {
		$::markerbarW.xrange.max delete 0 end
		$::markerbarW.xrange.max insert 0 $max
		set changed 1
	}
	if {$changed} {
		$::markerbarW rerange $::markerbarW.xrange.min
	}
}

Grid method zoom {min max {colors {}}} {
	set changed 0
	set testmin [$::markerbarW.xrange.min get]
	if {$testmin != $min} {
		$::markerbarW.xrange.min delete 0 end
		$::markerbarW.xrange.min insert 0 $min
		set changed 1
	}
	set testmax [$::markerbarW.xrange.max get]
	if {$testmax != $max} {
		$::markerbarW.xrange.max delete 0 end
		$::markerbarW.xrange.max insert 0 $max
		set changed 1
	}
	set colors_found {}
	foreach tcolor {blue orange red yellow green} {
		if {[lsearch $colors $tcolor] >=0 || ![string length $colors]} {
			$::markerbarW.colors.$tcolor configure -relief sunken
			lappend colors_found $tcolor
		} else {
			$::markerbarW.colors.$tcolor configure -relief raised
		}
	}
#	if {$changed} {
#		$::markerbarW rerange $::markerbarW.xrange.min
		$object configure -xrange [list $min $max] -defcolor $colors_found -colors $colors_found
#	}
}

Grid method drawmaq_new {} {
	private $object options
	set pattern $options(-pattern)
	set currentAssay $data::active_marker
	if {![info exist data::assayData($currentAssay)]} {return}
	set assaydata $data::assayData($currentAssay)
	set range $::config::default(zoomrange)
	set minmin 240
	set maxmax 260
	set found 0
	foreach line $assaydata {
		array unset tamp
		array set tamp $line
		set min [expr $tamp(min) + $tamp(minmove)]
		set max [expr $tamp(max) + $tamp(maxmove)]
		if {$minmin > $min} {set minmin $min}
		if {$maxmax < $max} {set maxmax $max}
		if {[string equal $tamp(amplicon) $pattern]} {
			set found 1
			break
		}
	}
	if {$found} {
		if {$min < $minmin} {
			set min [expr $minmin - $range]
		} else {
			set min [expr $min - $range]
		}
		if {$max > $maxmax} {
			set max [expr $maxmax + $range]
		} else {
			set max [expr $max + $range]
		}
		$object zoom $min $max
	} else {
		$object zoom [expr $minmin - $range] [expr $maxmax + $range]
	}
}

Grid method drawmaq {} {
puts drawmaq
#return
	private $object options
	set pattern $options(-pattern)
	set currentAssay $data::active_marker
	if {![info exist data::assayData($currentAssay)]} {
		if {[info exist data::active_genos] && [llength $data::active_genos]} {
			$object zoom 0 500
		}
		return
	}
	set assaydata $data::assayData($currentAssay)
	set range $::config::default(zoomrange)
	set minmin 240
	set maxmax 260
	set found 0
	foreach line $assaydata {
		array unset tamp
		array set tamp $line
		set min [expr $tamp(min) + $tamp(minmove)]
		set max [expr $tamp(max) + $tamp(maxmove)]
		if {$minmin > $min} {set minmin $min}
		if {$maxmax < $max} {set maxmax $max}
		set color $tamp(color)
		if {[string equal $tamp(amplicon) $pattern]} {
			set found 1
			break
		}
	}
	if {$found} {
		if {$min < $minmin} {
			set min [expr $minmin - $range]
		} else {
			set min [expr $min - $range]
		}
		if {$max > $maxmax} {
			set max [expr $maxmax + $range]
		} else {
			set max [expr $max + $range]
		}
		$object zoom $min $max $color
	} else {
		$object zoom [expr $minmin - $range] [expr $maxmax + $range]
	}
}

