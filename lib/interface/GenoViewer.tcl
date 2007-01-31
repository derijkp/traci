# building class GenoViewer
Widget subclass GenoViewer


####################
#globale variabelen
####################
# pac : bevat de huidige patroon gegevens
# alt : bevat de huidige alternatieve patroon gegevens
# rename_bin : info over de eventuele veranderingen van bins
# xrange : geeft de range weer die gecorrigeerd werd door de interne standaard


####################
# methoden
####################


GenoViewer method init {args} {
	super init
	graph $object.g -plotbackground white -height 80 -width 200 -relief flat
	balloon $object.g genoviewer,main
	$object.g crosshairs configure -hide yes
	text $object.comment -height 1 -relief flat -highlightthickness 0
	grid $object.comment -row 0 -column 0 -sticky nwe
	grid $object.g -sticky nwse -row 1 -column 0
	grid columnconfigure $object 0 -weight 1
	grid rowconfigure $object 0 -weight 0
	grid rowconfigure $object 1 -weight 1
	if {$args != ""} {eval $object configure $args}
	bind $object.g <Enter> "$object Tracker" 
	bind $object.g <Leave> "$object.g marker delete tracker"
	bind $object.g <Motion> "$object.g crosshairs configure -position @%x,%y;$object Tracker"
#	bind $object.g <Button1-Motion> "$object.g crosshairs configure -position @%x,%y;$object binchange_start move"
#	bind $object.g <Button3-Motion> "$object.g crosshairs configure -position @%x,%y;$object binchange_start resize"
#	bind $object.g <ButtonRelease> "$object binchange_stop"
	bind $object.g <ButtonPress-1> "[list focus $object.g]"
#	bind $object.g <Double-Button-1> "$object binclick"
#	bind $object.g <Double-Button-2> "$object binclick clear"
	bind $object.g <Control-ButtonPress-1> "$object binclick"
	bind $object.g <Control-ButtonPress-3> "$object binclick clear"
	bind $object.g <ButtonPress-3> "[list $object Activate %W]"
	bind $object.g <MouseWheel> [list $object scroller mouseindex %D]
	bind $object.g <Control-MouseWheel> [list $object scroller mousepage %D]
	bind $object.g <Control-ButtonPress-4> [list $object scroller page -1]
	bind $object.g <Control-ButtonPress-5> [list $object scroller page 1]
	bind $object.g <ButtonPress-4> [list $object scroller index -1]
	bind $object.g <ButtonPress-5> [list $object scroller index 1]
	bind $object.g <Key-Left> [list $object scroller home]
	bind $object.g <Key-Right> [list $object scroller end]
	bind $object.g <Key-Up> [list $object scroller index -1]
	bind $object.g <Key-Down> [list $object scroller index 1]
	bind $object.g <Control-Key-Up> [list $object scroller page -1]
	bind $object.g <Control-Key-Down> [list $object scroller page 1]
	bind $object.g <Shift-Key-Up> "[list $::markerbarW marker_select prev]"
	bind $object.g <Shift-Key-Down> "[list $::markerbarW marker_select next]"
	bind $object.g <Shift-Key-Left> "[list $::markerbarW marker_select first]"
	bind $object.g <Shift-Key-Right> "[list $::markerbarW marker_select last]"
	$object.g marker bind Hold <ButtonPress-1> "+ $object holdIt"
}

GenoViewer addoption -reads {reads Reads {}} {
	Classy::todo $object refresh
}

GenoViewer addoption -colors {colors Colors {}} {
	Classy::todo $object refresh
}

GenoViewer addoption -pattern {pattern Pattern {}} {
	Classy::todo $object refresh
}

GenoViewer addoption -comment {comment Comment {}} {
	Classy::todo $object refresh
}

GenoViewer addoption -xrange {xRange XRange {}} {
	Classy::todo $object refresh
}

GenoViewer addoption -yrange {yRange YRange {}} {
	Classy::todo $object refresh
}

GenoViewer addoption -defcolor {defColor DefColor {}} {
	Classy::todo $object refresh
}

GenoViewer addoption -si {superImpose SuperImpose 0} {
	Classy::todo $object refresh
}

GenoViewer addoption -index {index Index {}} {
	Classy::todo $object refresh
}

GenoViewer addoption -hold {hold Hold {}} {
	Classy::todo $object refresh
}

GenoViewer addoption -marker {marker Marker {}} {
	Classy::todo $object refresh
}

GenoViewer addoption -binlist {binlist BinList {}} {
}

GenoViewer method getymax {} {
	private $object options
	set reads $options(-reads)
	set hold $options(-hold)
	if {[llength $hold]} {
		set reads [fetchVal $hold gs_read]
	}
	set colors $options(-colors)
	set defcolor $options(-defcolor)
	set min [$object.g axis cget x -min]
	set max [$object.g axis cget x -max]
	set maxy 0
	foreach read $reads {
		set read_max [x$read index end]
		if {$max > $read_max} {set max [expr $read_max - 1]}
		if {![string length [info command x$read]]} {return 0}
		set min_index [lindex [x$read search $min [expr $min+1]] 0]
		set max_index [lindex [x$read search $max [expr $max+1]] 0]
		foreach nr {1 2 3 4 5} color {blue green yellow red orange} {
			if {[lsearch $defcolor $color] < 0 || [lsearch $colors $color] < 0} {continue}
			set tempmax [lmath_max [g${read}y$nr range $min_index $max_index]]
			if {$tempmax > $maxy} {set maxy $tempmax}
		}
	}
	return $maxy
}

GenoViewer method getymax_old {reads} {
	private $object options
#	set reads $options(-reads)
	set colors $options(-colors)
	set defcolor $options(-defcolor)
	set found 0
	foreach c $colors {
		if {[inlist $defcolor $c]} {
			set found 1
		}
	}
	if {!$found} {
		set defcolor $colors
	}
	set min [$object.g axis cget x -min]
	set max [$object.g axis cget x -max]
	set maxy 0
	foreach read $reads {
		set read_max [x$read index end]
		if {$max > $read_max} {set max [expr $read_max - 1]}
		if {![string length [info command x$read]]} {return 0}
		set min_index [lindex [x$read search $min [expr $min+1]] 0]
		set max_index [lindex [x$read search $max [expr $max+1]] 0]
		foreach nr {1 2 3 4 5} color {blue green yellow red orange} {
			if {([lsearch $defcolor $color] < 0) && ![string equal all $colors]} {continue}
			set tempmax [lmath_max [g${read}y$nr range $min_index $max_index]]
			if {$tempmax > $maxy} {set maxy $tempmax}
		}
	}
	return $maxy
}

GenoViewer method Tracker {} {
	private $object options
	set index [lindex $options(-index) 0]
	set marker $options(-marker)
	set coords [$object.g crosshairs cget -pos]
	set anchor [$object anchor $coords]
	foreach {x y} [$object point2base] break
	if {![info exist x] ||![info exist y]} {return}
	if {![$object.g marker exists sizer]} {
		$object.g marker create text -name tracker -anchor $anchor -fill {} -xoffset 2 -fg black
	}
	set text {}
	set textx [format "%0.1f" $x]
	set texty [expr round($y)]
	set text "$textx"
	$object.g marker configure tracker -coords [list $x $y] -text "$text"
}

GenoViewer method anchor {coords} {
	set wp 10
	set hp 40
	set geo [winfo geometry $object]
	regexp {([0-9]+),([0-9]+)} $coords match x y
	regexp {([0-9]+)x([0-9]+)} $geo match w h
	if {![info exist y]} {return}
	if {$y > [expr $h*0.5]} {
		set anchor s
	} else {
		set anchor n
	}
	if {$x < [expr $w*0.5]} {
		append anchor w
	} else {
		append anchor e
	}
	return $anchor
}

GenoViewer method binclick {{clear {}}} {
#set object .mainw.grid.graphs.g0
	private $object options
	set index $options(-index)
	set marker $data::active_marker
	foreach {x y} [$object point2base] break
	if {[string length $clear]} {
		set x 0
	}
	$object checkBin $x
	$object refresh
}

GenoViewer method drawbin {index} {
	private $object options
	if {[llength $index] > 1 && [string equal Disabled $config::default(showbinOnSi)]} {
		return
	}
	set index [lindex $index 0]
#	set index $options(-index)
	set marker $data::active_marker
	set pattern $options(-pattern)
	set range 0.75
	set bincolor $config::color(score)
	if {![info exist data::score($marker,$pattern,$index)]} {
		set score [list 0 0]
	} else {
		set prev -1
		foreach s $data::score($marker,$pattern,$index) type {min max} {
			if {$prev == $s} {continue}
			set min [expr $s - $range]
			set max [expr $s + $range]
			$object.g marker create polygon -name $marker-$type
			$object.g marker configure $marker-$type -fill $bincolor -linewidth 1 -coords "$min -1000 $min 50000 $max 50000 $max -1000" -under 1 -outline black
		}
	}
}

GenoViewer method checkBin {pos} {
	private $object options
	set index $options(-index)
	if {[llength $index] > 1 && [string equal Disabled $config::default(showbinOnSi)]} {
		return
	}
	set index [lindex $index 0]
	set marker $data::active_marker
	set pattern $options(-pattern)
	if {[string equal unknown $marker] || [string equal All $pattern]} {return}
	set range 0.75
	if {![info exist data::score($marker,$pattern,$index)] || !$pos} {
		set score [list $pos $pos]
	} else {
		set tempscore $data::score($marker,$pattern,$index)
		foreach {min max} $tempscore break
		set testminmin [expr $min - $range]
		set testminmax [expr $min + $range]
		set testmaxmin [expr $max - $range]
		set testmaxmax [expr $max + $range]
		if {[string equal $min $max]} {
			# homo
			if {$pos < $testminmax && $pos > $testminmin} {
				# within range of bin => clear score
				set score [list 0 0]
			} else {
				# new bin
				if {!$min} {
					# first bin
					set score [list $pos $pos]
				} elseif {$pos < $min} {
					# before bin
					set score [list $min $pos]
				} else {
					# after bin
					set score [list $pos $min]
				}
			}
		} else {
			# hetero
			set diffmin [expr abs($min - $pos)]
			set diffmax [expr abs($max - $pos)]
			if {$pos < $testminmax && $pos > $testminmin} {
				# within range of min bin => delete
				set score [list $max $max]
			} elseif {$pos > $testmaxmin && $pos < $testmaxmax} {
				# within range of max bin => delete
				set score [list $min $min]
			} elseif {$diffmin <= $diffmax} {
				# near min => replace this
				set score [list $pos $max]
			} else {
				# near max => replace this
				set score [list $min $pos]
			}
		}
	}
	set newscore {}
	set newbins {}
	foreach s [lsort -real $score] {
		if {!$s} {
			lappend newscore 0
		} else {
			lappend newscore [dformat "%.1f" $s]
		}
	}
	altercell $index $pattern [join $newscore /]
	set pos $data::column($pattern)
	lset ::data::active_datalist $index $pos [join $newscore /]
	set ::data::datalist($marker) $data::active_datalist
	set ::data::score($marker,$pattern,$index) $newscore
}

proc altercell {index column value} {
	set tbl $::listboxW.t
	set row [search_row $index]
	set col [lsearch $::data::columns_sel $column]
	$tbl cellconfigure $row,$col -text $value
}

GenoViewer method scroller {type {aantal 0}} {
	private $object options
	set grid [winfo parent [winfo parent $object]]
	if {[string equal mouseindex $type]} {
		set type index
		if {$aantal > 0} {
			set aantal -1
		} else {
			set aantal 1
		}
	} elseif {[string equal mousepage $type]} {
		set type page
		if {$aantal > 0} {
			set aantal -1
		} else {
			set aantal 1
		}
	}
	$grid graphbrowser $type $aantal
}

GenoViewer method Activate {gridwindow} {
	global binmove
	if {[info exist binmove] && [string length $binmove]} {return}
	if {![regexp {.g([0-9]+).g$} $gridwindow match active]} {return}
	private $object options
	set grid $::gridW
	$grid configure -active $active
	if {[winfo exist $::listboxW]} {
		raise $::listboxW
		$::listboxW configure -active $active
	}
}

GenoViewer method showOpp {} {
	private $object options
	set index [lindex $options(-index) 0]
	set assay $options(-marker)
	if {![string length $assay] || [string equal $assay unknown] || ![info exist data::assayData($assay)]} {return}
	if {![inlist {Auto Area} $::config::default(showresult)]} {return}
	if {![string equal $::config::default(assaytype) area]} {return}
	set read [fetchVal $index gs_read]
	set assayData $data::assayData($assay)
	set nr 0
	foreach line $assayData {
		array unset t
		array set t $line
		set amplicon $t(amplicon)
		set min [expr $t(min) + $t(minmove)]
		set max [expr $t(max) + $t(maxmove)]
		set color $t(color)
		set areacolor $::config::color($color-area)
		if {![string length [info command x$read]]} {return 0}
		set min_index [lindex [x$read search $min [expr $min+1]] 0]
		set max_index [lindex [x$read search $max [expr $max+1]] 0]
		foreach nr {1 2 3 4 5} tcolor {blue green yellow red orange} {
			if {[lsearch $color $tcolor] >= 0} {break}
		}
		set ypoints [g${read}y$nr range $min_index $max_index]
		set ypoints_new {}
		foreach p $ypoints {
			if {$p <0 } {set p 0}
			lappend ypoints_new $p
		}
		set xpoints [x${read} range $min_index $max_index]
		set coords [list_merge $xpoints $ypoints_new]
		set coords [linsert $coords 0 [lindex $xpoints 0] 0]
		set coords [linsert $coords end [lindex $xpoints end] 0]
		$object.g marker create polygon -name opp-$assay-$t(amplicon)
#		$object.g marker configure opp-$assay-$t(amplicon) -fill $color -linewidth 1 -coords $coords -under 0 -outline $color
		$object.g marker configure opp-$assay-$t(amplicon) -fill $areacolor -linewidth 1 -coords $coords -under 0 -outline [colorname2color $color]
	}
}

GenoViewer method binchange_stop {} {
	global binmove binmover
	if {![info exist binmove] || ![string length $binmove]} {return}
	foreach {amplicon lmax rmax} [split $binmove ,] break
	set marker $data::active_marker
	if {![info exist data::assay($marker,$amplicon,min)] || ![info exist binmover] || ![string length $binmover]} {return}
	set binmover {}
	set startmin $data::assay($marker,$amplicon,min)
	set startmax $data::assay($marker,$amplicon,max)
	foreach {newmin null null null newmax} [$object.g marker cget bins-$marker-$amplicon-upper -coords] break
	set newminmove [expr $newmin - $startmin]
	set newmaxmove [expr $newmax - $startmax]
	set ::data::assay($marker,$amplicon,minmove) [reformat $newminmove]
	set ::data::assay($marker,$amplicon,maxmove) [reformat $newmaxmove]
	$::gridW refresh
}

GenoViewer method binchange_start {type} {
	global binmove binmover
	if {![info exist binmove] || ![string length $binmove]} {return}
	foreach {amplicon lmax rmax} [split $binmove ,] break
	set marker $data::active_marker
	if {![info exist data::assay($marker,$amplicon,min)]} {return}
	foreach {x y} [$object point2base] break
	set startmin $data::assay($marker,$amplicon,min)
	set startmax $data::assay($marker,$amplicon,max)
	set startminmove $data::assay($marker,$amplicon,minmove)
	set startmaxmove $data::assay($marker,$amplicon,maxmove)
	if {![info exist binmover] || ![string length $binmover]} {
		set binmover $x
	}
	set diff [expr $x - $binmover]
	switch $type {
		move {
			set newmin [expr $startmin + $startminmove + $diff]
			set newmax [expr $startmax + $startmaxmove + $diff]
		}
		resize {
			set newmin [expr $startmin + $startminmove - $diff]
			set newmax [expr $startmax + $startmaxmove + $diff]
		}
	}
	# limited range of original position
	set middle [expr ($startmax + $startmin)/2]
	set newmiddle [expr ($newmax + $newmin) /2]
	if {[expr abs($newmiddle - $middle)] > 10} {return}
	# not smaller than 1 base
	if {[expr $newmax - $newmin] < 1} {return}
	# not bigger than 6 base
	if {[expr $newmax - $newmin] > 6} {return}
	# pointer outside bin
	if {$x < $newmin || $x > $newmax} {return}
	# limitation of other bins
	if {$newmin <= $lmax} {return}
	if {$newmax >= $rmax} {return}
	$object.g marker configure bins-$marker-$amplicon-upper -coords "$newmin -10000 $newmin 50000 $newmax 50000 $newmax -10000"
	set middle [expr ($newmin+$newmax)/2.0]
	$object.g marker configure bins-$marker-text-$amplicon -coords "$middle +Inf"
}


proc assayLimits {amplicon} {
	set marker $::data::active_marker
	if {![info exist data::amplicons($marker,all)] || [lsearch $data::amplicons($marker,all) $amplicon] < 0} {return}
	set min $data::assay($marker,$amplicon,min)
	set minmove $data::assay($marker,$amplicon,minmove)
	set max $data::assay($marker,$amplicon,max)
	set maxmove $data::assay($marker,$amplicon,maxmove)
	set cmin [expr $min + $minmove]
	set cmax [expr $max + $maxmove]
	set nearestmin 0
	set nearestmax 500
	foreach tamp $data::amplicons($marker,all) {
		if {[string equal $amplicon $tamp]} {continue}
		set min $data::assay($marker,$tamp,min)
		set minmove $data::assay($marker,$tamp,minmove)
		set max $data::assay($marker,$tamp,max)
		set maxmove $data::assay($marker,$tamp,maxmove)
		set tmin [expr $min + $minmove]
		set tmax [expr $max + $maxmove]
		if {$tmax > $nearestmin && $tmax <= $cmin} {
			set nearestmin $tmax
		}
		if {$tmin < $nearestmax && $tmin >= $cmax} {
			set nearestmax $tmin
		}
	}
	return [list $nearestmin $nearestmax]
}

GenoViewer method clearmarkers {pattern} {
	eval $object.g marker delete [$object.g marker names $pattern]
}

GenoViewer method togglemarkers {marker} {
	foreach tag [$object.g marker names *] {
		if {[regexp "^$marker-\[0-9]+\$" $tag match]} {
			$object.g marker configure $tag -hide 0
		} else {
			$object.g marker configure $tag -hide 1
		}
	}
}

GenoViewer method holdIt {} {
	private $object options
	set holdit $options(-hold)
	set index $options(-index)
	if {[string length $holdit]} {
		set holdit {}
	} else {
		set holdit $index
	}
	$object configure -hold $holdit
}

GenoViewer method point2base {args} {
	set point [$object.g crosshairs cget -pos]
	regexp {([0-9]+),([0-9]+)} $point match X Y
	if {[info exists Y]} {
		if {![catch {$object.g invtransform $X $Y} tempresult]} {
			if {[string length $tempresult]} {
				foreach {base int} $tempresult break
				return [list $base $int]
			}
		}
	}
}

GenoViewer method base2point {base height} {
	if {[string length $base]} {
		if {![catch {$object.g transform $base $height} tempresult]} {
			if {[string length $tempresult]} {
				foreach {base int} $tempresult break
				return [list $base $int]
			}
		}
	}
}

GenoViewer method standardrange {} {
	global xrange
	private $object options
	set reads $options(-reads)
	set color $::config::color(lowpeaks_bg)
	set border $::config::color(lowpeaks_border)
	if {[llength $reads] != 1} {return}
	if {![info exist xrange($reads)]} {return}
	foreach {st_begin st_end} $xrange($reads) break
	$object.g marker create polygon -name standardbegin
	$object.g marker configure standardbegin -fill $color -linewidth 1 -coords "-100 -10000 -100 50000 $st_begin 50000 $st_begin -10000" -under 1 -outline $border
	$object.g marker create polygon -name standardend
	$object.g marker configure standardend -fill $color -linewidth 1 -coords "$st_end -10000 $st_end 50000 10000 50000 10000 -10000" -under 1 -outline gray80
}

GenoViewer method ShowPeaks {reads} {
#	set object .mainw.grid.graphs.g0
	private $object options
#	set reads $options(-reads)
	set colors $options(-colors)
	set defcolor $options(-defcolor)
	foreach {xmin xmax ymin ymax} "{} {} $config::default(ymin) {}" break
	foreach {xmin xmax} $options(-xrange) break
	foreach {ymin ymax} $options(-yrange) break
	set maxy 0
	if {[info exist ::data::active_read]} {
		set active_read $::data::active_read
	} else {
		set active_read {}
	}
	eval $object.g element delete [$object.g element names peaks-*]
	set first 1
	foreach read $reads {
		foreach nr {1 2 3 4 5} color {blue green yellow red orange} {
			set linewidth $config::default(signalwidth)
			if {[catch {g${read}y$nr length}]} {
				$object showtext "Data not available (too old?)" red "helvetica 16"
				continue
			}
			if {[lsearch $colors $color]<0 && ![string equal all $colors]} {continue}
			if {$first} {
				$object.g element create peaks-$read-$nr -x x$read -y g${read}y$nr -color [colorname2color $color] -linewidth $linewidth -smooth linear -symbol ""
			} else {
				set color $::config::color(overlayHold)
				$object.g element create peaks-$read-$nr -x x$read -y g${read}y$nr -color $color -linewidth $linewidth -smooth linear -symbol ""
			}
			$object.g legend configure -hide 1
			if {[lsearch $defcolor $color] < 0 && ![string equal all $defcolor]} {continue}
			if {[string length $xmax]} {
				set max_index [lindex [x$read search [expr $xmax-1] $xmax] 0]
				if {![string length $max_index]} {set max_index end}
			} else {
				set max_index end
			}
			if {[string length $xmin]} {
				set min_index [lindex [x$read search $xmin [expr $xmin+1]] 0]
			} else {
				set min_index 0
			}
			if {[g${read}y$nr length] < $max_index} {set max_index end}
			set tempmaxy [lmath_max [g${read}y$nr range $min_index $max_index]]
			if {$maxy < $tempmaxy} {set maxy $tempmaxy}
		}
		set first 0
	}
	if {$ymin > $maxy} {set maxy $ymin}
	if {![string length $ymax] && $maxy} {set ymax $maxy}
	return $ymax
}

GenoViewer method ShowHold {} {
	private $object options
	set hold $options(-hold)
	set index $options(-index)
	if {[llength $index] > 1} {return}
	if {[llength $hold]} {
		set color red
		set label [fetchVal $hold individual]
		set text "Hold $label"
	} else {
		set color grey70
		set text "Hold"
	}
	$object.g marker create text -name Hold -text $text -coords {+Inf +Inf} -font {Helvetica 10 bold} -foreground $color -xoffset 0 -yoffset 0 -anchor e -background white
#	$object.g marker configure Hold -text $text -foreground $color
}

GenoViewer method ShowRPeaks {} {
#	set object .mainw.grid.graphs.g0
	if {[string equal $config::default(reference) Disabled]} {return}
	if {[string equal $data::active_marker unknown]} {return}
if {![string length [info command ::SX1]]} {
	createRef
}
	private $object options
	set currentread $options(-reads)
	if {![llength $currentread]} {return}
	if {![string length [info command ::SY1]]} {return}
	set colors $options(-colors)
	set defcolor $options(-defcolor)
	set maxy 0
	eval $object.g element delete [$object.g element names refpeaks*]
	foreach nr {1 2 3 4 5} color {blue green yellow red orange} {
		if {[lsearch $colors $color]<0} {continue}
		set maxAmp [getMaxAmpl ::SX$nr ::SY$nr]
		set height [getAssayHeight ::x$currentread ::g${currentread}y$nr $maxAmp]
		catch {vector destroy ::SY$nr.$currentread}
		vector create ::SY$nr.$currentread
		vector create ::SX$nr.$currentread
		::SY$nr.$currentread expr ::SY$nr*$height
		set shift [string trim $::config::default(reference_shift) +]
		::SX$nr.$currentread expr ::SX$nr+($shift)
		$object.g element create refpeaks-$nr -x ::SX$nr.$currentread -y ::SY$nr.$currentread -color $::config::color(reference_line) -linewidth $::config::default(reference_linewidth)
		$object.g element configure refpeaks-$nr -smooth linear -symbol ""
	}
}

proc createRef {} {
	set refreads $::data::controlereads
	if {![llength $refreads]} {return}
	if {[string equal unknown $data::active_marker]} {return}
	set maxy 0
	# normalize each read
	foreach nr {1 2 3 4 5} color {blue green yellow red orange} {
		set maxlength 100000
		set maxread {}
		# determine length of each vector (take smallest)
		foreach read $refreads {
			set testlength [::g${read}y$nr length]
			if {$testlength < $maxlength} {
				set maxlength $testlength
				set maxread $read
			}
			set testlength [::x$read length]
			if {$testlength < $maxlength} {
				set maxlength $testlength
				set maxread $read
			}
		}
		foreach read $refreads {
			vector create ::norm$read.${nr}
			::norm$read.${nr} expr norm(::g${read}y$nr)
			::norm$read.${nr} set [::norm$read.${nr} range 0 [expr $maxlength - 1]]
			::x$read set [::x$read range 0 [expr $maxlength -1]]
			set maxAmp [getMaxAmpl ::x$read ::norm$read.${nr}]
			set tassayheight [getAssayHeight ::x$read ::norm$read.${nr} $maxAmp]
			::norm$read.${nr} expr ::norm$read.${nr}/$tassayheight
		}
		# populate Xvector
		::x$maxread populate ::SX$nr 1
		# create splined Yvectors
		set sys {}
		foreach read $refreads {
			vector create ::snorm$read.${nr}
			blt::spline natural ::x$read ::norm$read.${nr} ::SX$nr ::snorm$read.${nr}
#			blt::spline quadratic ::x$read ::norm$read.${nr} ::SX$nr ::snorm$read.${nr}
			vector destroy ::norm$read.${nr}
			lappend sys ::snorm$read.${nr}
		}
		set aantal [llength $refreads]
		vector create ::SY$nr
		eval ::SY$nr expr ([join $sys +])/$aantal
		foreach s $sys {
			vector destroy $s
		}
#		roundVector ::SY$nr 1e-10
	}
}

proc roundVector {vector level} {
	vector create tempvector
	tempvector expr $vector>$level
	$vector expr $vector*tempvector
}

GenoViewer method update_comment {index} {
	private $object options
	$object.comment delete 0.0 end
	foreach {bgcolor comment} [createcomment $index] break
	$object.comment insert 0.0 [join $comment \t]
	if {![string length $bgcolor]} {
		set bgcolor #9db9c8
	}
	$object.comment configure -bg $bgcolor
}

GenoViewer method empty {} {
	eval $object.g element delete [$object.g element show]
 	eval $object.g marker delete [$object.g marker names]
	$object update_comment {}
	$object update_geometry 0
}

GenoViewer method update_geometry {maxh} {
	private $object options
	set index $options(-index)
	set marker $data::active_marker
	foreach {xmin xmax ymint ymax} "{} {} 0 $config::default(ymin)" break
	foreach {xmin xmax} $options(-xrange) break
	if {![string length $xmax]} {set xmax 500}
	foreach {ymin ymaxt} $options(-yrange) break
	set type 2
	set stepsize [expr (( abs($xmax - $xmin - 25) / 50 )+1) * $type]
	set geometry [wm geometry $::mainW]
	regexp {^([0-9]+)x([0-9]+)[+]([-]*[0-9]+)[+]([-]*[0-9]+)} $geometry match width height x y
	set w [expr round((700.0 + 700/2)/$width)]
	set gp $::gridW
	set columns [$gp cget -columns]
	set first [$gp cget -first]
	set active [$gp cget -active]
	set active_index [lindex $::data::active_genos [expr $first + $active]]
	if {[string equal $active_index $index] && [string length $active_index]} {
		set bgcolor $::config::color(activebg)
		if {![string length $bgcolor]} {set bgcolor [. cget -background]}
		$object.g axis configure x -background $bgcolor
		$object.g axis configure y -background $bgcolor
		$object.g configure -background $bgcolor -plotbackground $config::color(activeplotbg)
	} else {
		set color [. cget -background]
		$object.g axis configure x -background $color
		$object.g axis configure y -background $color
		$object.g configure -background $color -plotbackground white
	}
	set stepsize [expr round($stepsize * $columns * $w)]
	$object.g axis configure x -min $xmin -max $xmax -stepsize $stepsize
	if {[info exist ymaxt] && [string length $ymaxt]} {
		set ymax $ymaxt
	} elseif {$maxh > $ymax} {
		set ymax $maxh
	}
	set ymax [expr $ymax + ($ymax * 0.25)]
	$object.g axis configure y -min 0 -max $ymax
}

GenoViewer method showLow {} {
	private $object options
	if {![llength $options(-reads)] || [string equal $config::default(showlow) Disabled]} {return}
	set color $::config::color(lowpeaks_bg)
	set border $::config::color(lowpeaks_border)
	set height $::config::default(lowpeaks)
	$object.g marker create polygon -name lowpeaks
	$object.g marker configure lowpeaks -fill $color -linewidth 1 -coords "-100 -10000 -100 $height 10000 $height 10000 -10000" -under 1 -outline $border
}

GenoViewer method refresh {} {
	set ::GenoViewer_refresh 0
	puts GenoViewer_refresh
	$object empty
	private $object options
	set index $options(-index)
	set hold $options(-hold)
	set reads $options(-reads)
#	set object .mainw.grid.graphs.g0
	$object clearmarkers *
	if {[info exist ::data::active_read]} {
		set active_read $::data::active_read
	} else {
		set active_read {}
	}
	set marker $data::active_marker
	if {[string length $::exp]} {
		set exp $::exp
	} else {
		set exp [fetchVal $index experiment]
	}
	$object showLow
	if {[string length $hold] && [llength $reads] == 1} {
		set hold_read [fetchVal $hold gs_read]
		if {[string equal $config::default(overlayHold) Disabled]} {
			set reads $hold_read
			set index $hold
		} elseif {![inlist $reads $hold_read]} {
			lappend reads $hold_read
		}
	}
	set maxy [$object getymax]
	$object update_comment $index
	$object ShowPeaks $reads
	$object update_geometry $maxy
	$object showLabel $index
	$object showStandard
	$object drawbin $index
	$object ShowHold
	if {$options(-si)} {
		$object showRanges
	}
	if {$::startDemo || ![checkLicense 1]} {
		$object showtext "Demonstration " gray80 "courier 18 bold"
	}
	set ::GenoViewer_refresh 1
}

GenoViewer method showRanges {} {
#	--------------------------
#	show the range of the marker(s) of the selected color - only active in superimpose state
#	--------------------------
#	set object .mainw.grid.graphs.g0
	private $object options
	set colors $options(-colors)
	set assay $data::active_marker
	if {[string equal $assay unknown]} {return}
	set mins {}
	array unset sizes
	set markers $data::amplicons($assay,all)
	foreach m $markers {
		if {[string equal unknown $m]} {continue}
		if {![info exist data::assay($assay,$m,min)]} {continue}
		set min $data::assay($assay,$m,min)
		lappend sizes($min) $m 
	}
	set firstgraph [winfo parent $object].g0
	set object $firstgraph
	eval $object.g marker delete [$object.g marker names marker*]
	set max -100
	set yoffset 0
	set rows {}
	array unset rowmax
	foreach minsize [lsort -real [array names sizes]] {
		foreach m $sizes($minsize) {
			set name marker$m
			set max $data::assay($assay,$m,max)
			set colorname $data::assay($assay,$m,color)
			if {[lsearch $colors $colorname] <0} {continue}
			set color [colorname2color $colorname]
			if {![string length $rows]} {
				# de eerste is altijd ok
				# tot aan zijn max
				set row 0
				lappend rows $row
				set rowmax($row) $max
			} else {
				# test de verschillende rijen
				set foundrow {}
				foreach testrow $rows {
					if {$minsize > $rowmax($testrow)} {
						set foundrow $testrow
					}
				}
				if {![string length $foundrow]} {
					# geen plaats gevonden in bestaande rijen
					set foundrow [expr $testrow +1]
				}
				set rowmax($foundrow) $max
				lappend rows $foundrow
				set yoffset [expr $foundrow * 16]
			}
			$object.g marker create line -name $name
			$object.g marker configure $name -linewidth 2 -coords "$minsize Inf $max Inf" -under 0 -outline $color -yoffset [expr $yoffset +8]
			$object.g marker create text -name ${name}t
			$object.g marker configure ${name}t -coords "[expr ($minsize + $max)/2] Inf" -under 0 -bg {} -fg black -yoffset $yoffset -text $m -anchor center
		}
	}
}

GenoViewer method showStandard {} {
	private $object options
	if {[llength $options(-reads)] != 1 || [string equal $config::default(showstandard) Disabled]} {return}
	set missing [testStandard $options(-reads)]
	set addbefore 1
	set addafter 1
	set best $data::standards(best)
	set color $::config::color(lowpeaks_bg)
	set border $::config::color(lowpeaks_border)
	if {[llength $missing]} {
		set done {}
		foreach m $missing {
			if {[lsearch $done $m] >= 0} {continue}
			# search boundery left
			set pos [lsearch $best $m]
			set templist [lrange $best 0 [expr $pos - 1]]
			if {[llength $templist]} {
				set startsize [lindex $templist end]
			} else {
				set startsize -100
				set addbefore 0
			}
			# search boundery right
			set templist [lrange $best [expr $pos + 1] end]
			set found 0
			while {[llength $templist]} {
				set stopsize [lindex $templist 0]
				if {[lsearch $missing $stopsize] >= 0} {
					lappend done $stopsize
					set templist [lrange $templist 1 end]
				} else {
					set  found 1
					break
				}
			}
			if {!$found} {
				set stopsize 1000
				set addafter 0
			}
			$object.g marker create polygon -name nostandard-$m
			$object.g marker configure nostandard-$m -fill $color -linewidth 1 -coords "$startsize -10000 $startsize 10000 $stopsize 10000 $stopsize -10000" -under 1 -outline $border
		}
	}
	if {$addbefore} {
		set startsize -100
		set stopsize [lindex $best 0]
		$object.g marker create polygon -name nostandard-bef
		$object.g marker configure nostandard-bef -fill $color -linewidth 1 -coords "$startsize -10000 $startsize 10000 $stopsize 10000 $stopsize -10000" -under 1 -outline $border
	}
	if {$addafter} {
		set startsize [lindex $best end]
		set stopsize 1000
		$object.g marker create polygon -name nostandard-aft
		$object.g marker configure nostandard-aft -fill $color -linewidth 1 -coords "$startsize -10000 $startsize 10000 $stopsize 10000 $stopsize -10000" -under 1 -outline $border
	}
}

GenoViewer method showLabel {index} {
	if {[string equal $config::default(showlabel) Disabled]} {return}
	$object.g marker create text -name readlabel
	if {[llength $index] > 1} {set index [lindex $index 0]}
	set label [fetchVal $index individual]
	set middle [expr [$object.g axis cget y -max] / 2]
	$object.g marker configure readlabel -coords "-Inf $middle" -text $label -bg {} -fg black -rotate 90 -anchor w -font $config::font(label_font)
}

GenoViewer method showtext {text color font} {
	set xmax [$object.g xaxis cget -max]
	if {![string length $xmax]} {set xmax 0}
	set xmin [$object.g xaxis cget -min]
	if {![string length $xmin]} {set xmin 0}
	set ymax [$object.g yaxis cget -max]
	if {![string length $ymax]} {set ymax 0}
	set xhalf [expr ($xmax + $xmin) /2]
	set yhalf [expr $ymax /2]
	$object.g marker create text -font $font -shadow black -fg $color -background {} -name textbox -coords "$xhalf $yhalf" -text $text -under 1
}

GenoViewer method showBins_maq {} {
#	set object .mainw.grid.graphs.g0
	global binmove
	if {![info exist binmove]} {set binmove {}}
	foreach {move_amplicon lmax rmax} [split $binmove ,] break
	$object clearmarkers bins-*
	private $object options
	if {![llength $options(-reads)] || [string equal Disabled $config::default(showbin)]} {return}
	set index $options(-index)
	set marker $data::active_marker
	if {![string length $marker] || [string equal $marker unknown]} {return}
	set individual [fetchVal $index individual]
	if {[string length $::exp]} {
		set exp $::exp
	} else {
		set exp [fetchVal $index experiment]
	}
	set nr 0
	foreach amplicon $data::amplicons($marker,all) {
		set type $data::assay($marker,$amplicon,type)
		set min $data::assay($marker,$amplicon,min)
		set minmove $data::assay($marker,$amplicon,minmove)
		set max $data::assay($marker,$amplicon,max)
		set maxmove $data::assay($marker,$amplicon,maxmove)
		if {[info exist ::data::height($index,$amplicon)]} {
			set height $::data::height($index,$amplicon)
		} else {
			set height 0
		}
		if {[string equal control $type]} {
			if {([info exist ::data::controles($marker,disabled)] && [inlist $::data::controles($marker,disabled) $amplicon]) || ![info exist ::data::controles($marker,used)] || ![inlist $::data::controles($marker,used) $amplicon]} {
				set bincolor $config::color(badcontrol)
			} else {
				set bincolor $config::color(goodcontrol)
			}
			set text {}
			set upperbincolor $config::color(badcontrol)
		} else {
			set bincolor $config::color(goodtest)
			set upperbincolor $config::color(badtest)
		}
		incr nr
		set text $amplicon
		switch $::config::default(showbinname) {
			None {
				set text {}
			}
			Test {
				if {[string equal control $type]} {
					set text {}
				}
			}
			Control {
				if {[string equal test $type]} {
					set text {}
				}
			}
		}
		if {[info exist move_amplicon] && [string equal $amplicon $move_amplicon]} {
			set outline red
		} else {
			set outline grey80
		}
		set cmin [expr $min + $minmove]
		set cmax [expr $max + $maxmove]
		if {[string equal Height $::config::default(showresult)] || ([string equal Auto $::config::default(showresult)] && [string equal $::config::default(assaytype) height])} {
			$object.g marker create line -name height-$marker-$amplicon -linewidth 1 -coords "$cmin $height $cmax $height" -under 0 -outline grey50
			$object.g marker create polygon -name bins-$marker-$amplicon-upper -fill $upperbincolor -linewidth 1 -coords "$cmin $height $cmin 50000 $cmax 50000 $cmax $height" -under 1 -outline $outline
			$object.g marker create polygon -name bins-$marker-$amplicon-lower -fill $bincolor -linewidth 1 -coords "$cmin -10000 $cmin $height $cmax $height $cmax -10000" -under 1 -outline $outline
		} else {
			$object.g marker create polygon -name bins-$marker-$amplicon-upper -fill $upperbincolor -linewidth 1 -coords "$cmin -10000 $cmin 50000 $cmax 50000 $cmax -10000" -under 1 -outline $outline
		}
		set middle [expr ($cmin + $cmax)/2.0]
		$object.g marker create text -name bins-$marker-text-$amplicon -font $::config::font(binname) -text $text -coords "$middle +Inf" -fill {} -outline black -under 0 -rotate $::config::default(binrotation) -yoffset -10 -anchor n
	}
}


#proc OrderAssay {assayData} {
#	foreach line $assayData {
#		array unset t
#		array set t $line
#		set amplicon $t(amplicon)
#		set pos $t(min)
#		set order($pos) $line
#	}
#	set newdata {}
#	foreach pos [lsort -real [array names order]] {
#		lappend newdata $order($pos)
#	}
#	return $newdata
#}

GenoViewer method getxmax {index min max} {
#	set object .mainw.grid.graphs.g0
	private $object options
#	set reads $options(-reads)

	set assay $data::active_marker
	set marker $options(-pattern)
	set defcolor $data::assay($assay,$marker,color)
	set index $options(-index)
	set read [fetchVal $index gs_read]
	set score $data::score($assay,$marker,$index)
	foreach size $score {
		set min [expr $size - 0.75]
		set max [expr $size + 0.75]
		set maxy 0
		set read_max [x$read index end]
		if {$max > $read_max} {set max [expr $read_max - 1]}
		if {![string length [info command x$read]]} {return 0}
		set min_index [lindex [x$read search $min [expr $min+1]] 0]
		set max_index [lindex [x$read search $max [expr $max+1]] 0]
		foreach nr {1 2 3 4 5} color {blue green yellow red orange} {
			if {[lsearch $defcolor $color] < 0} {continue}
			set rangey [g${read}y$nr range $min_index $max_index]
			set rangex [::x${read} range $min_index $max_index]
	
			vector create tempy
			eval ::tempy append $rangey
			vector create tempx
			eval ::tempx append $rangex
	
			tempx populate tempsx 10
	
			blt::spline natural tempx tempy tempsx tempsy
	
			set maxy [vector expr max(::tempy)]
			::tempy search $maxy
	
			set maxsy [vector expr max(::tempsy)]
			::tempsy search $maxsy
			tempy max
	
			set maxy 0
			set maxx 0
			foreach xvalue [tempsx range 0 end] yvalue [tempsy range 0 end] {
				if {$maxy < $yvalue} {
					set maxx $xvalue
					set maxy $yvalue
				}
			}
	
			set tempmax [lmath_max [g${read}y$nr range $min_index $max_index]]
			if {$tempmax > $maxy} {set maxy $tempmax}
		}
	}

set list {10.4 10.7 10.8 12.2 12.5 12.4 16.6 19.2 19.1 19.5}



}

