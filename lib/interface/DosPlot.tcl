Classy::Toplevel subclass Dosviewer

Dosviewer method init {args} {
	super init
	private $object options
	set graph [graph $object.g -plotbackground $::config::color(dos_bg) -width 700 -height 200]
	balloon $graph dos,main
	$object.g axis configure y -title "Dosage Quotient (DQ)"
	grid $graph -sticky nwse
	set comment [text $object.comment -height 1 -relief sunken -highlightthickness 0]
	grid $comment -sticky nwse
	set buttonbar [frame $object.buttonbar]
		button $buttonbar.show -command "typeSwitch show;$object refresh" -textvariable ::config::default(show)
		balloon $buttonbar.show dos,show
		button $buttonbar.recolor -text "Re-Color" -command recolor
		balloon $buttonbar.recolor dos,recolor
		button $buttonbar.close -text close -command "$object exit"
		grid $buttonbar.show $buttonbar.recolor $buttonbar.close
	grid $buttonbar -sticky nwse
	grid columnconfigure $object 0 -weight 1
	grid rowconfigure $object 0 -weight 1
	wm title $object "Dosage plot"
	$object createUpperElements
	bind $object <ButtonPress-3> [list $object Activate]
	bind $object <Key-Up> [list $object graphbrowser index -1]
	bind $object <Key-Down> [list $object graphbrowser index 1]
	bind $object <ButtonPress-4> [list $object graphbrowser index -1]
	bind $object <ButtonPress-5> [list $object graphbrowser index 1]
	bind $object <MouseWheel> [list $object graphbrowser index %D]
	bind $object <Control-MouseWheel> [list $object graphbrowser page %D]
	wm protocol $object WM_DELETE_WINDOW [list $object exit]\;return
	Classy::canceltodo $object place
}

Dosviewer method printit {} {
	$object.g postscript output file.ps -maxpect no -decorations yes
}

Dosviewer method exit {} {
	wm state $object withdrawn
}

Dosviewer method Activate {} {
	set upper [$object cget -upper]
	set first [lsearch $::data::active_genos $upper]
	if {$first >= 0} {
		$::gridW configure -first $first -active 0
		$::listboxW configure -active 0
	}
#	$object checkVar $upper
}

Dosviewer method graphbrowser {type {aantal {}}} {
	if {[expr abs($aantal)] > 10} {set aantal [expr 0 - $aantal]}
	if {$aantal > 0} {
		set aantal 1
	} else {
		set aantal -1
	}
	$::gridW graphbrowser $type $aantal
}

Dosviewer method conf {localvar linkvar} {
	set value [set $linkvar]
	$object configure $localvar $value
}

Dosviewer addoption -colors {colors Colors {}} {
	Classy::todo $object updateActive
}

Dosviewer addoption -upper {upper Upper {}} {
}

Dosviewer addoption -showamplicons {showamplicons ShowAmplicons 1} {
	Classy::todo $object ShowAmplicons
}

Dosviewer addoption -reference {reference Reference {}} {
	$object refresh
}

Dosviewer addoption -errorflag {errorflag Errorflag 1} {
	$object refresh
}

Dosviewer addoption -active {active Active 0} {
	set first [$object cget -first]
	Classy::todo $object updateActive [expr $value + $first]
}

Dosviewer addoption -first {first First 0} {
	set active [$object cget -active]
	Classy::todo $object updateActive [expr $value + $active]
}

Dosviewer method exit {} {
	set ::dosplaced 0
	wm state $object withdrawn
}

Dosviewer method refresh {} {
	$object showdos
	$object.g configure -plotbackground $::config::color(dos_bg)
}

Dosviewer method clearElements {} {
	eval $object.g element delete [$object.g element names]
}

Dosviewer method createUpperElements {} {
	# create upper elements
	if {![string length [info command x.upper]]} {
		vector create x.upper
		vector create y.upper
		vector create yerror.upper
		vector create x.offscale_upper
		vector create y.offscale_upper
		vector create yerror.offscale_upper
	}
	x.upper set {}
	y.upper set {}
	yerror.upper set {}
	x.offscale_upper set {}
	y.offscale_upper set {}
	yerror.offscale_upper set {}
	yerror.offscale_upper set {}
	if {![$object.g element exists upper]} {
		$object.g element create upper -x x.upper -symbol circle -y y.upper -linewidth 0 -yerror yerror.upper -pixels 10 -errorbarwidth 1 -label {}
	} else {
		$object.g element configure upper -x x.upper -y y.upper -yerror yerror.upper
	}
	if {![$object.g element exists offscale-upper]} {
		$object.g element create offscale-upper -x x.offscale_upper -symbol triangle -y y.offscale_upper -linewidth 0 -yerror yerror.offscale_upper -pixels 12 -errorbarwidth 1 -label {}
	} else {
		$object.g element configure offscale-upper -x x.offscale_upper -y y.offscale_upper -yerror yerror.offscale_upper
	}
}

Dosviewer method height2color {index} {
	set height [fetchVal $index meanH]
	set max 5000
	set min 100
	if {$height < $min} {
		set height [expr $max/10]
	} elseif {$height > $max} {
		set height $max
	}
	set tempvalue $height
	set most $max
	set value [expr 100-round($tempvalue*100.0/$most)]
	return grey$value
}

Dosviewer method IdElements {{active {}}} {
	private $object options
	array set colors $options(-colors)
#	set all [$::listboxW.t getcolumn 0]
	eval $object.g element delete [$object.g element names id.*]
	foreach {tosee null} [$object ids2see] break
	if {![string length $active]} {
		set active $null
	}
	if {[llength $tosee] == 1} {set onlyone 1} else {set onlyone 0}
	foreach geno $tosee {
		if {[inlist $tosee $geno]} {
			set hide 0
		} else {
			set hide 1
		}
		if {$onlyone} {
			set color [$object height2color $geno]
		} else {
			if {![info exist colors($geno)]} {
				set color [dec2rgb [expr round(rand()*255)] [expr round(rand()*255)] [expr round(rand()*255)]]
				lappend options(-colors) $geno $color
				set colors($geno) $color
			} else {
				set color $colors($geno)
			}
		}
		switch $config::default(legend) {
			read {
				set label [fetchVal $geno gs_read]
			}
			individual {
				set label [fetchVal $geno individual]
			}
		}
		set xvector .x.id.$geno.mean
		set yvector .y.id.$geno.mean
		set yerrorvector .yerror.id.$geno.mean
		if {![$object.g element exists id.$geno]} {
			$object.g element create id.$geno -x $xvector -symbol circle -y $yvector -color $color -label $label -yerror $yerrorvector -pixels 10 -errorbarwidth 1 -outlinewidth 0 -linewidth 0 -hide $hide
			$object.g element bind id.$geno <Enter> [list $object index2upper id.$geno]
			$object.g legend bind id.$geno <Enter> [list $object index2upper id.$geno]
			$object.g legend bind id.$geno <Leave> [list $object OffLegend id.$geno]
			$object.g element configure id.$geno -hide $hide
		} else {
			$object.g element configure id.$geno -hide $hide -x $xvector -y $yvector -yerror $yerrorvector -label $label -color $color
		}
	}
	$object index2upper id.$active
	$object CheckReads
	if {$onlyone} {
#		$object checkVar $active
	}
}

Dosviewer method showdos {} {
	set active_assay $::data::active_marker
	set color white
	if {![string length $active_assay] || [string equal $active_assay unknown]} {
		$object Message "No Assay loaded..."
		return
	} else {
		$object.g marker delete textbox
	}
	private $object options
	if {[llength $data::active_genos] > 50} {
		$object.g legend configure -font {helvetica 6}
	} elseif {[llength $data::active_genos] > 20} {
		$object.g legend configure -font {helvetica 8}
	} else {
		$object.g legend configure -font {helvetica 10}
	}
	if {[llength $data::controlereads]} {
		set extra "([llength $data::controlereads] references)"
	} else {
		set extra {(Without references)}
	}
	$object.g configure -title "Assay: $active_assay $extra" -font {*-Helvetica-Bold-R-Normal-*-14-140-*}
	$object.g grid on
	$object.g grid configure -minor 0
	set tests $::data::amplicons($active_assay,test)
	set controles $::data::amplicons($active_assay,control)
	check_heights
	$object IdElements
	$object axisUpdate
#	$object CheckReads
	$object ShowAmplicons
	$object GreyZone
	if {$::startDemo} {
		$object showtext "Demonstration " gray80 "courier 18 bold"
	} else {
		$object showtext "" gray80 "courier 18 bold"
	}
#	update
}

Dosviewer method showtext {text color font} {
	set xmax [$object.g xaxis cget -max]
	set xmin [$object.g xaxis cget -min]
	set ymax [$object.g yaxis cget -max]
	set xhalf [expr ($xmax + $xmin) /2]
	set yhalf [expr $ymax /2]
	set yhalf 1
	$object.g marker create text -font $font -shadow black -fg $color -background {} -name textbox -coords "$xhalf $yhalf" -text $text -under 0
}

Dosviewer method Message {text} {
	set xmax [$object.g xaxis cget -max]
	set ymax [$object.g yaxis cget -max]
	if {![string length $xmax]} {set xmax 1.0}
	if {![string length $ymax]} {set ymax 1.0}
	set xhalf [expr $xmax /2]
	set yhalf [expr $ymax /2]
	$object.g marker create text -font "helvetica 16" -fg red -background {} -name textbox -coords "$xhalf $yhalf" -text $text
}

Dosviewer method axisUpdate {} {
	set active_assay $::data::active_marker
	set nrs {}
	set nr [llength $::data::amplicons($active_assay,all)]
	for {set i 0} {$i <= $nr} {incr i} {
		lappend nrs $i
	}
	if {[string length $::config::default(ymax)]} {
		set max $::config::default(ymax)
	} else {
		set max [$object getmax]
	}
	set yticks_maj {0.5 1.5}
	for {set i 1} {$i <= $max} {incr i} {
		lappend yticks_maj $i
		lappend yticks_maj $i
	}
	set yticks_min 0.5
	$object.g grid configure -mapy {}
	$object.g axis configure y -min 0 -majorticks $yticks_maj -max $max
	$object.g axis configure x -min 0.5 -max [expr $nr +0.5] -hide 0 -command [list $object nr2name] -majorticks $nrs -rotate 90
	return $max
}

Dosviewer method getmax {} {
	foreach {all active} [$object ids2see] break
	set max $config::default(mindos)
	foreach id $all {
		set q [fetchVal $id q]
		if {[llength $all] > 1 && ([inlist $data::lowReads $id] || $q > $config::default(min_score))} {continue}
		set test [vector expr max(.y.id.$id.mean)]
		if {$test > $max} {set max $test}
	}
	return $max
}

Dosviewer method ids2see {} {
	set active [$::gridW cget -active]
	set first [$::gridW cget -first]
	set active_genos $data::active_genos
	switch $config::default(show) {
		One-by-one {
			set ids_tosee $active_genos
		}
		default {
			set ids_tosee [lindex $active_genos [expr $active + $first]]
		}
	}
	return [list $ids_tosee [lindex $active_genos [expr $active + $first]]]
}

#Dosviewer method refresh {} {
#	set tosee [$object ids2see]
#}

Dosviewer method ShowAmplicons {} {
	private $object options
	set active_assay $data::active_marker
#	set tests $::data::amplicons($active_assay,test)
	set controles $::data::amplicons($active_assay,control)
	set loci $::data::amplicons($active_assay,all)
	set nr 1
	eval $object.g marker delete [.dos.g marker names *-*] 
	foreach {all ids} [$object ids2see] break
	if {[llength $ids] != 1} {
		set shown -1
	} else {
		set shown $ids
	}
#	set nrshown [regsub -all {id\.} [$object.g element show] {} null]
#	if {$nrshown == 1} {
#		if {![regexp {id\.([0-9]+)} [$object.g element show] match shown]} {
#			set shown -1
#		}
#	} else {
#		set shown -1
#	}
	foreach locus $loci {
		set badcontrol 0
		if {![$object.g marker exists $locus-$nr] && $options(-showamplicons)} {
			if {[lsearch $controles $locus] >= 0} {
				if {$shown >= 0} {
					set dosage $::data::dos($shown,$locus)
					foreach {copynr test linecolor} [value2type $dosage] break
					if {[string length $test]} {
						set badcontrol 1
					}
				}
				if {([info exist ::data::controles($active_assay,disabled)] && [inlist $::data::controles($active_assay,disabled) $locus]) || ![info exist ::data::controles($active_assay,used)] || ![inlist $::data::controles($active_assay,used) $locus]} {
					set fillcolor $config::color(badcontrol)
				} else {
					set fillcolor $config::color(goodcontrol)
				}
			} else {
				if {$shown >= 0} {
					set dosage $::data::dos($shown,$locus)
					foreach {copynr fillcolor linecolor} [value2type $dosage] break
				} elseif {[lsearch $::data::lowAmplicons $locus] >= 0} {
					set fillcolor $config::color(badtest)
				} else {
					set fillcolor $config::color(goodtest)
				}
			}
			$object.g marker create polygon -name $locus-$nr -coords [typebar $nr] -fill $fillcolor -linewidth 1 -outline black
if {$badcontrol} {
	$object.g marker create polygon -name BAD$locus-$nr -coords [badtypebar $nr] -linewidth 1 -outline black
}
			$object.g marker bind $locus-$nr <Enter> [list $object ShowControles $locus-$nr on]
			$object.g marker bind $locus-$nr <Leave> [list $object ShowControles $locus-$nr off]
		}
		incr nr
	}
}

Dosviewer method ShowControles {tag state} {
	set assay $data::active_marker
	if {![regexp {^(.*)-[0-9]+$} $tag match name]} {return}
	if {![info exist data::controles($assay,$name)]} {return}
	set controles $data::controles($assay,$name)
	switch $state {
		off {
			$object.g marker configure $tag -linewidth 1 -outline black
			foreach controle $controles {
				set marker [$object.g marker names $controle-*]
				if {![string length $marker]} {return}
				if {([info exist ::data::controles($assay,disabled)] && [inlist $::data::controles($assay,disabled) $controle]) || ![info exist ::data::controles($assay,used)] || ![inlist $::data::controles($assay,used) $controle]} {
					set color $config::color(badcontrol)
				} else {
					set color $config::color(goodcontrol)
				}
				$object.g marker configure $marker -fill $color
			}
		}
		on {
			$object.g marker configure $tag -linewidth 2 -outline red
			foreach controle $controles {
				set marker [$object.g marker names $controle-*]
				if {![string length $marker]} {return}
				$object.g marker configure $marker -fill black
			}
		}
	}
}

Dosviewer method GreyZone {} {
	if {[string length $::config::default(ymax)]} {
		set max $::config::default(ymax)
	} else {
		set max [$object getmax]
	}
	eval $object.g marker delete [.dos.g marker names greyzone-*] 
	set zones {}
	set step 0.5
	for {set i 0.25} {$i < $max} {set i [expr $i+ $step]} {
		lappend zones $i
#		if {$zone > 1.75} {set step 0.5}
	}
	set color $config::color(dos_grayzone)
	foreach zone $zones {
		set starty [expr $zone -0.05]
		set endy [expr $zone +0.05]
		set coords "-2 $starty -2 $endy 500 $endy 500 $starty"
		$object.g marker create polygon -name greyzone-$zone -coords $coords -fill $color -under 1
	}
	$object.g marker create polygon -name greyzone-normal -coords {-2 0.8 -2 1.2 500 1.2 500 0.8} -fill $::config::color(dos_normal) -under 1
}

Dosviewer method CheckReads {} {
	set bg [$object.g cget -bg]
	$object.g legend configure -activeforeground red -activebackground $bg
	if {![info exist data::lowReads]} {return}
	foreach {tosee active} [$object ids2see] break
	foreach id $tosee {
		set q [fetchVal $id q]
		if {[inlist $data::lowReads $id] || $q > $config::default(min_score)} {
			$object.g legend activate id.$id
			$object.g element configure id.$id -x {} -y {} -yerror {}
		} else {
			set xvector .x.id.$id.mean
			set yvector .y.id.$id.mean
			set yerrorvector .yerror.id.$id.mean
			$object.g legend deactivate id.$id
			$object.g element configure id.$id -x $xvector -y $yvector -yerror $yerrorvector
		}
	}
}

Dosviewer method updateActive {{pos {}}} {
	if {![string length $pos]} {
		set first [$object cget -first]
		set active [$object cget -active]
		set pos [expr $first + $active]
	}
	set index [lindex $data::active_genos $pos]
	$object refresh
#	$object IdElements $index
#	$object axisUpdate
}

Dosviewer method updateStatusBar {active} {
	$object.comment delete 0.0 end
	foreach {bgcolor comment} [createcomment $active] break
	$object.comment insert 0.0 "\t[join $comment \t]"
	if {![string length $bgcolor]} {
		set bgcolor #9db9c8
	}
	$object.comment configure -bg $bgcolor
}

Dosviewer method ElementValues {tag} {
	set shown [$object.g element cget $tag -showvalues]
	switch $shown {
		y {
			$object.g element configure $tag -showvalues n
		}
		default {
			$object.g element configure $tag -showvalues y -valuecolor black -valueformat "%g" -valueshadow white -valuefont {Arial 10 bold} -valueanchor s
		}
	}
}

Dosviewer method OffLegend {tag} {
	foreach {null index} [split $tag .] break
	if {![string length $index] || [string equal ShowAll $::config::default(show)]} {return}
	$object configure -upper {}
	$object.g element configure $tag -labelrelief flat
	$object.g element configure upper -outlinewidth 0 -pixels 10
#	$object.g element configure offscale-upper -outlinewidth 0 -pixels 14
	eval $object.g marker delete [$object.g marker names var-*]
}

Dosviewer method nr2name {widget nr} {
	if {[string equal unknown $::data::active_marker]} {return}
	set assayInfo $::data::assayData($::data::active_marker)
	set loci {{}}
	foreach line $assayInfo {
		array unset t
		array set t $line
		lappend loci $t(amplicon)
	}
	set locus [lindex $loci $nr]
	return $locus
}

Dosviewer method index2upper {tag} {
	eval $object.g marker delete [$object.g marker names var-*]
	foreach {null index} [split $tag .] break
	if {![string length $index]} {return}
	foreach {all active} [$object ids2see] break
	$object configure -upper $index
	$object updateStatusBar $index
	$object.g element bind upper <Button-1> [list $object ElementValues upper]
	$object.g element bind upper <Enter> [list $object index2upper $tag]
	$object.g element bind upper <Leave> [list $object OffLegend $tag]
	set x {}
	set y {}
	set yerror {}
	set color black
	set found 0
	foreach element [$object.g element names] {
		if {$element == $tag} {
			set found 1
			$object.g element configure $element -labelrelief sunken
			set x [$object.g element cget $element -x]
			set y [$object.g element cget $element -y]
			set yerror [$object.g element cget $element -yerror]
			set color [$object.g element cget $tag -color]
		} else {
			$object.g element configure $element -labelrelief flat
		}
	}
#	$object checkVar $index
	if {![string length $x] && [string equal $active $index]} {return}
	$object.g element configure upper -x $x -y $y -yerror $yerror -color $color -outline grey20 -outlinewidth 2 -pixels 11
#	$object.g element bind offscale-upper <Button-1> [list $object ElementValues offscale-upper]
#	$object.g element bind offscale-upper <Enter> [list $object index2upper $tag]
#	$object.g element bind offscale-upper <Leave> [list $object OffLegend $tag]
#	if {![inlist [.dos.g element names] offscale-$tag]} {return}
#	set x [.dos.g element cget offscale-$tag -x]
#	set y [.dos.g element cget offscale-$tag -y]
#	set yerror [.dos.g element cget offscale-$tag -yerror]
#	$object.g element configure offscale-upper -x $x -y $y -yerror $yerror -color $color -symbol triangle -outline grey20 -outlinewidth 2 -pixels 15
}









if {0} {

.dos.g legend get 1


.dos.g element configure 88 -symbol triangle



set showlist [.dos.g element show]
set element 82
set pos [lsearch $showlist $element]
set showlist [lreplace $showlist $pos $pos]
set showlist [linsert $showlist end $element]

.dos.g element bind 88 <Enter> {puts hello}

.dos.g element cget id.52 -hide


,  circle,  diamond,  plus,  cross,  splus,
                     scross, triangle

bind .dos <Button-1> {puts h}

set object .dos



 .dos.g element show "70 69"

 .dos.g element show "69 70"

proc reformat {value} {
	return [format "%.2f" $value]
}
}


