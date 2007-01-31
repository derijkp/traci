##############################################
#
# chromatogram functions
#
##############################################

proc From2 {fromlist tolist from} {
	set to -1
	foreach minto [lreplace $tolist end end] maxto [lreplace $tolist 0 0] minfrom [lreplace $fromlist end end] maxfrom [lreplace $fromlist 0 0] {
		if {$from == $minfrom} {
			set to $minto
		} elseif {$from > $minfrom} {
			if {$from > $maxfrom} {
				continue
			} elseif {$from == $maxfrom} {
				set to $maxto
			}
			set to [expr $minto + (($from - $minfrom) * ($maxto-$minto) / 1.0 / ($maxfrom-$minfrom))]
		} else {
			#before scale
		}
	}
	if {[string equal $to -1]} {bgerror "Range should be between [lindex $fromlist 0] and [lindex $fromlist end]"}
	return $to
}

proc CreateX {startpos stoppos baslist poslist} {
	#set startpos 2067
	#set stoppos 2500
	set steplist [CalcStep $poslist $baslist]
	set list $startpos
	set steps [list]
	set stop 0
	foreach testpos [lreplace $poslist 0 0] step $steplist {
		if {$testpos < $stoppos && $testpos >$startpos} {
			lappend list $testpos
			lappend steps $step
		} elseif {$testpos >= $stoppos} {
			set stop 1
		}
		if {$stop} {
			lappend steps $step
			break
		}
	}
	lappend list $stoppos
	set stepnr 0
	set xlist ""
	if {![llength $steps]} {return 0}
	foreach step $steps {
		set begin [lindex $list $stepnr]
		incr stepnr
		set end [lindex $list $stepnr]
		set aantal [expr $end - $begin]
		set currentx [From2 $poslist $baslist $begin]
		if {$stepnr == 1} {
			lappend xlist $currentx
		}
		for {set a 1} {$a <= $aantal} {incr a} {
			set currentx [expr {$step + $currentx}]
#			set currentx [format %.2f $currentx]
			lappend xlist $currentx
		}
	}
	if {$end < $stoppos} {
		set begin $end
		set end $stoppos
		set aantal [expr $end - $begin]
		for {set a 1} {$a <= $aantal} {incr a} {
			set currentx [expr {$step + $currentx}]
#			set currentx [format %.2f $currentx]
			lappend xlist $currentx
		}
	}
	return $xlist
}

proc CalcStep {fromlist tolist} {
	# calculate the steps 'to' covering 1 'from'
	set list [list]
	foreach minto [lreplace $tolist end end] maxto [lreplace $tolist 0 0] minfrom [lreplace $fromlist end end] maxfrom [lreplace $fromlist 0 0] {
		lappend list [expr ((1) * ($maxto-$minto) / 1.0 / ($maxfrom-$minfrom))]
	}
	return $list
}

proc CreateY {startpos endpos signal} {
	# 2. get the list of points (ydata) from the analysed data
	set ylist [lrange $signal [expr {$startpos - 1}] [expr {$endpos - 1}]]
}

proc colorname2color {colorname} {
	if {[info exists config::dyecolor($colorname)]} {
		return $config::dyecolor($colorname)
	} else {
		return {}
	}
}

proc colornr2colorname {nr {reverse 0}} {
	array set colors {
		1 blue
		2 green
		3 yellow
		4 red
		5 orange
		* {blue green yellow red orange}
	}
	if {$reverse} {
		foreach tempnr [array names colors] {
			set testvalue $colors($tempnr)
			if {[string equal $nr $testvalue]} {
				return $tempnr
			}
		}
	} else {
		if {[info exists colors($nr)]} {
			return $colors($nr)
		} else {
			return {}
		}
	}
}

proc dye2color {color} {
	set dyes {6-FAM VIC NED PET LIZ}
        foreach dye $dyes colornr {1 2 3 4 5} {
                if {[regexp $color $dye]} {
                        return $colornr
                }
        }
        if {[string equal $color HEX]} {
                return [dye2color VIC]
        }
        bgerror "color $color not found"
}

##############################################
#
# assay functions
#
##############################################

proc x2locus {x} {
	set currentAssay $data::active_marker
	if {![info exist data::amplicons($currentAssay,all)]} {return}
	set amplicons {}
	foreach amplicon $data::amplicons($currentAssay,all) {
		set min $data::assay($currentAssay,$amplicon,min)
		set minmove $data::assay($currentAssay,$amplicon,minmove)
		set max $data::assay($currentAssay,$amplicon,max)
		set maxmove $data::assay($currentAssay,$amplicon,maxmove)
		set cmin [expr $min + $minmove]
		set cmax [expr $max + $maxmove]
		if {$x < $cmax && $x > $cmin} {
			lappend amplicons $amplicon
		}
	}
	return [lsort -unique $amplicons]
}

proc recalcQ {{ids {}}} {
puts recalcQ
	if {![string length $ids]} {
		set ids [$::listboxW.t getcolumns 0]
	}
	foreach index $ids {
		set Q [getQ $index]
		set qpos $data::column(q)
		lset ::data::active_datalist $index $qpos $Q
		altercell $index q $Q
	}
	set marker $::data::active_marker
	set ::data::datalist($marker) $data::active_datalist
}

proc AQupdate {{ids {}}} {
	if {![string length $ids]} {
		set ids [$::listboxW.t getcolumns 0]
	}
	set active_assay $data::active_marker
	if {[string equal unknown $active_assay]} {return}
	if {![info exist ::data::amplicons($active_assay,all)]} {return}
	set loci $::data::amplicons($active_assay,all)
	switch $config::default(showtype) {
		Dosage {
			set type dos 
		}
		Height {
			set type height
		}
		Area {
			set type area
		}
		default {
			error "Unknown showtype: '$config::default(showtype)'"
		}
	}
	foreach index $ids {
		foreach locus $loci {
			if {![info exist ::data::${type}($index,$locus)]} {continue}
			set value [set ::data::${type}($index,$locus)]
			if {[info exist data::column($locus)]} {
				set pos $data::column($locus)
				lset ::data::active_datalist $index $pos $value
#				altercell $index $locus $value
			}
		}
	}
}

proc recalcDos {{ids {}}} {
puts recalcDos
	if {![string length [info command $::listboxW.t]]} {return}
	if {![string length $ids]} {
		set ids [$::listboxW.t getcolumns 0]
	}
	set active_assay $data::active_marker
	if {[string equal unknown $active_assay]} {return}
	if {![info exist ::data::amplicons($active_assay,all)]} {return}
	set loci $::data::amplicons($active_assay,all)
	foreach index $ids {
		foreach locus $loci {
			foreach {y yerror} [id2mean $index $locus] break
			set ::data::dos($index,$locus) $y
		}
	}
	AQupdate $ids
}

proc reg_lgvs {} {
	global LGVs_dir
	set execs [glob [file join $LGVs_dir .. .. *.exe]]
	if {[llength $execs]} {
		# LGVs found
		set last [lindex [lsort -dictionary $execs] end]
		set LGVs_exe [file normalize $last]
	} else {
		error "$LGVs_exe exec not found"
	}
	set icos [glob [file join $LGVs_dir *.ico]]
	if {[llength $icos]} {
		set last [lindex [lsort -dictionary $icos] end]
		set LGVs_ico $last
	} else {
		set LGVs_ico ""
	}
	register_filetype .mqs LGVsFile "LGVs file" "application/lgvs" "\"$LGVs_exe\" \"%1\"" "$LGVs_ico 0"
}

proc register_filetype {extension class name mime code {icon {}}} {
	package require registry
	set error 1
	foreach hkey {HKEY_CLASSES_ROOT HKEY_CURRENT_USER\\Software\\Classes} {
		if {![catch {
			set extPath $hkey\\$extension
			set classPath $hkey\\$class
			set shellPath $classPath\\Shell
			registry set $extPath {} $class sz
			registry set $classPath {} $name sz
			registry set $shellPath\\open\\command {} $code sz
			# mimetype
			registry set $extPath "Content Type" $mime sz
			set mimeDbPath "$hkey\\MIME\\Database\\Content Type\\$mime"
			registry set $mimeDbPath Extension $extension sz
			if {[llength $icon]} {
				if {[llength $icon] != 2} {
					error "icon should be a list of {filename number}"
				}
				foreach {file number} $icon break
				registry set $classPath\\DefaultIcon {} [file nativename $file],$number sz
			}
		}]} {set error 0}
	}
	if {$error} {error $::errorInfo}
}

proc testassay {assayData} {
	set errors {}
	set aantaltest 1
	set rangetest 1
	set colortest 1
	set assays {}
	set amplicons {}
	set header_test {assay amplicon min max type color minmove maxmove}
	set valid_colors {blue yellow red green}
	array unset ::data::assayData
	array unset ::data::assay
	array unset ::data::amplicons
	array unset ::data::verhC
	array unset ::data::controles
	set linenr 0
	set nomove 1
	foreach line [split $assayData \n] {
		set splitline [split $line \t]
		if {!$linenr} {
			set header $splitline
			set missing {}
			foreach type $header_test {
				if {[lsearch $header $type] < 0} {
					if {[lsearch {minmove maxmove} $type] < 0} {
						lappend missing $type
					} else {
						set minmove 0
					}
				}
			}
			if {[llength $missing]} {
				lappend errors "- This files does not contain the columns, missing columns :[join $missing ,]"
			}
			incr linenr
			continue
		}
		if {![llength $splitline]} {incr linenr;continue}
		set assay_pos [lsearch $header assay]
		set amplicon_pos [lsearch $header amplicon]
		set assayname [lindex $splitline $assay_pos]
		set amplicon [lindex $splitline $amplicon_pos]
		foreach col $header value $splitline {
			set assay($col) $value
			if {[lsearch $header_test $col] <0 && [string length $value]} {
				set ::data::verhC($assayname,$col,$amplicon) $value
				if {[string length $value] && $value > 0} {
					lappend ::data::controles($assayname,$amplicon) $col
					lappend used($assayname) $col
				}
			} else {
				set ::data::assay($assayname,$amplicon,$col) $value
			}
		}
		lappend assays $assay(assay)
		lappend amplicons $assay(amplicon)
		lappend ::data::amplicons($assay(assay),$assay(type)) $assay(amplicon)
		lappend ::data::amplicons($assay(assay),all) $assay(amplicon)
		if {$assay(min) >= $assay(max) || $assay(min) < 20} {
			if {$rangetest} {lappend errors "- One or more ranges are incorrect."}
			set rangetest 0
		}
		if {$colortest && [lsearch $valid_colors $assay(color)] < 0} {
			lappend errors "- One or more colors are incorrect ([join $valid_colors ,])."
			set colortest 0
		}
		if {![info exist ::data::assay($assayname,$amplicon,minmove)]} {
			set ::data::assay($assayname,$amplicon,minmove) 0
			set ::data::assay($assayname,$amplicon,maxmove) 0
#			set header {assay amplicon min max type color amp1 amp2 amp3}
			set pos [lsearch $header color]
			set bheader [lrange $header 0 $pos]
			set aheader [lrange $header [expr $pos +1] end]
			set newheader [concat $bheader {minmove maxmove} $aheader]
			set bline [lrange $splitline 0 $pos]
			set aline [lrange $splitline [expr $pos +1] end]
			set splitline [concat $bline {0 0} $aline]
 		} else {
			set newheader $header
		}
		
		lappend ::data::assayData($assay(assay)) [list_merge $newheader $splitline]
		set ::data::assay($assayname,$amplicon,pos) $linenr
		incr linenr
	}
#	set found_used 0
#	foreach tassay [array names used] {
#		set ::data::controles($tassay,used) [lsort -unique $used($tassay)]
#		set found_used 1
#	}
#	if {!$found_used} {
#		lappend errors "- No controle amplicons found in assay file."
#	}
	if {[llength $errors]} {
		array unset data::assayData
		error "Error(s):\n[join $errors \n]"
	} else {
		set assayList [lsort -unique $assays]
		set ::data::assayList $assayList
		set aantalAssays [llength $assayList]
		set aantalAmplicons [llength [lsort -unique $amplicons]]
		return "$aantalAssays assay(s), $aantalAmplicons amplicon(s)"
	}
}

proc applyAssays {} {
puts applyAssays
	set assayList $data::assayList
	set newdata {}
	if {![info exist ::data::datalist(unknown)]} {
		tk_messageBox -message "No data to work on..." -icon error -title "Import"
		return
	}
	set datalist $::data::datalist(unknown)
	array unset data::datalist
	set ::data::datalist(unknown) $datalist
	array unset ::data::height
	array unset ::data::area
	Classy::busy
	foreach assay $assayList {
		set newdata {}
		set min 500
		set max 0
		set amplicons $::data::assayData($assay)
		for {set i 0} {$i < [llength $datalist]} {incr i} {
			set line [lindex $datalist $i]
			set read [fetchVal $i gs_read]
			foreach amplicon $amplicons {
				array unset tam
				array set tam $amplicon
				set cmin [expr $tam(min) + $tam(minmove)]
				set cmax [expr $tam(max) + $tam(maxmove)]
				if {![info exist ::data::height($i,$tam(amplicon))]} {
					set height [$object getymax $read $cmin $cmax $tam(color)]
					set ::data::height($i,$tam(amplicon)) $height
				}
				if {![info exist ::data::opp($i,$tam(amplicon))]} {
					set opp [$object getopp $read $cmin $cmax $tam(color)]
					set ::data::opp($i,$tam(amplicon)) $opp
				}
				if {![info exist ::data::dos($i,$tam(amplicon))]} {
					set ::data::dos($i,$tam(amplicon)) 0
				}
				if {$cmin < $min} {set min $cmin}
				if {$cmax > $max} {set max $cmax}
			}
		}
		set ::data::${assay}(range_min) [expr $min -10]
		set ::data::${assay}(range_max) [expr $max +10]
		set ::data::${assay}(color) [colornr2colorname $tam(color) 1]
		set ::data::${assay}(type) LGV
	}
	set ::data::markers [concat $options(-assayList) unknown]
	$::markerbarW.marker configure -list $::data::markers
	Classy::busy remove
	return $::data::markers
}

proc getMeanH {assay index} {
	if {[info exist data::height($index,All)]} {
		return $data::height($index,All)
	} else {
		return {}
	}
	set list {}
	foreach name [array names data::height $index,*] {
		lappend list $::data::height($name)
	}
	if {[llength $list]} {
		set mean [format "%.0f" [::math::statistics::mean $list]]
	} else {
		set mean {}
	}
	return $mean
}

proc updateDos {{ids {}}} {
	set assay $data::active_marker
	if {![string length $assay] || [string equal unknown $assay]} {return}
	Classy::busy
	setverh $assay
	setControleVerh
	recalcDos $ids
	recalcQ $ids
	vectorUpdate
	Classy::busy remove
	if {![llength $ids]} {
		alterDatalist
		$::listboxW refresh
	}
}

proc alterDatalist {} {
#can be split up for one id only !!
	puts "alterDatalist"
	set assay $data::active_marker
	if {[string equal unknown $assay] || ![string length $assay]} {return}
	if {![info exist ::data::datalist(unknown)]} {return}
	set newdata {}
	set amplicons $::data::amplicons($assay,all)
	set datalist $data::datalist(unknown)
	Classy::busy
	for {set i 0} {$i < [llength $datalist]} {incr i} {
		set line [lindex $datalist $i]
		set read [fetchVal $i gs_read]
		set index_pos [lsearch $line index]
		set index [lindex $line [expr $index_pos + 1]]
		foreach amplicon $amplicons {
			if {![info exist ::data::score($assay,$amplicon,$index)]} {
				set value 0
			} else {
				set value [join $::data::score($assay,$amplicon,$index) /]
			}
			set line [concat $line "$amplicon" $value]
			set ::config::colname($amplicon) $amplicon
		}
		set ::config::colname(meanH) meanH
		set meanH [getMeanH $assay $index]
		set line [concat $line assay "$assay" meanH $meanH]
		lappend newdata $line
	}
	set ::data::datalist($assay) $newdata
	set ::data::active_datalist $newdata
	Classy::busy remove
}

proc setControleVerh {} {
puts setControleVerh
	set read_list $::data::controlereads
	set active_assay $::data::active_marker
	if {[string equal unknown $active_assay] || ![string length $active_assay]} {return}
	if {![info exist ::data::amplicons($active_assay,test)]} {return}
	set tests $::data::amplicons($active_assay,test)
	set controles $::data::amplicons($active_assay,control)
	set loci $::data::amplicons($active_assay,all)
	set ref_ids {}
	foreach geno [$::listboxW.t getcolumns 0] {
		if {[inlist $read_list [fetchVal $geno gs_read]]} {
			lappend ref_ids $geno
		}
	}
	if {![llength $ref_ids]} {
		return
	}
	array unset ::data::verhC
	foreach controleAmp $controles {
		foreach locus $loci {
			set verh $::data::verh($controleAmp,$locus)
			if {![llength $ref_ids]} {
				set currentVerh [::math::statistics::mean $verh]
			} else {
				set ids $::data::ids($controleAmp,$locus)
				set tempVerh {}
				foreach id $ids {
					if {![inlist $ref_ids $id]} {continue}
					set pos [lsearch $ids $id]
					lappend tempVerh [lindex $verh $pos]
				}
				set currentVerh [::math::statistics::mean $tempVerh]
			}
			set ::data::verhC($active_assay,$controleAmp,$locus) $currentVerh
		}
	}
}

proc getnorm {id locus} {
	if {![info exist ::data::assayData($::data::active_marker)]} {return}
	set active_assay $::data::active_marker
	set tests $::data::amplicons($active_assay,test)
	set controles $::data::amplicons($active_assay,control)
	set norm {}
	set controles_used {}
	set maxdos $::config::default(maxdos)
	foreach controleAmp $controles {
		set verh $::data::verh($controleAmp,$locus)
		set ids $::data::ids($controleAmp,$locus)
		set pos [lsearch $ids $id]
		set currentVerh [lindex $verh $pos]
		if {![info exist ::data::controles($active_assay,$locus)] || [lsearch $::data::controles($active_assay,$locus) $controleAmp] < 0} {continue}
		if {[info exist ::data::controles($active_assay,disabled)] && [inlist $::data::controles($active_assay,disabled) $controleAmp]} {continue}
		set controleVerh $::data::verhC($active_assay,$controleAmp,$locus)
		set tnorm [expr $currentVerh/$controleVerh]
		if {$tnorm > $maxdos} {set tnorm $maxdos}
		lappend norm $tnorm
		lappend controles_used $controleAmp
	}
	return [list $norm $controles_used]
}

proc getQ {id} {
	set references $::data::controlereads
	if {![llength $references]} {return {}}
	if {![info exist ::data::assayData($::data::active_marker)]} {return}
	set active_assay $::data::active_marker
	set controles $::data::amplicons($active_assay,control)
	set means {}
	foreach controlelocus $controles {
		foreach {points loci} [getnorm $id $controlelocus] break
		if {![llength $points]} {continue}
		lappend means [::math::statistics::mean $points]
	}
	set stdev [format "%.3f" [::math::statistics::stdev $means]]
	if {$stdev > 1} {set stdev 1.00}
	return $stdev
}

proc getQ2_old {id} {
	set references $::data::controlereads
	if {![llength $references]} {return {}}
	if {![info exist ::data::assayData($::data::active_marker)]} {return}
	set active_assay $::data::active_marker
	set controles $::data::amplicons($active_assay,control)
	set worstl {}
	set bestq 1
	foreach notc $controles {
		set means {}
		foreach controlelocus $controles {
			if {[string equal $controlelocus $notc]} {continue}
			foreach {points loci} [getnorm $id $controlelocus] break
			if {![llength $points]} {continue}
			set newp {}
			foreach p $points l $loci {
				if {[string equal $l $notc]} {continue}
				lappend newp $p
			}
			lappend means [::math::statistics::mean $newp]
		}
		if {![llength $means]} {
			continue
		} else {
			set stdev [dformat "%.3f" [::math::statistics::stdev $means]]
			if {$stdev > 1} {set stdev 1.00}
		}
		if {$stdev < $bestq} {
			set bestq $stdev
			set worstl $notc
		}
	}
	return $bestq
}

proc getQ2_old2 {id} {
	set references $::data::controlereads
	if {![llength $references]} {return {}}
	if {![info exist ::data::assayData($::data::active_marker)]} {return}
	set active_assay $::data::active_marker
	set tests $::data::amplicons($active_assay,test)
	set tests $::data::amplicons($active_assay,all)
	set doslist {}
	foreach t $tests {
		lappend doslist $data::dos($id,$t)
	}
	set list $doslist
	set pos 0
	set penalty $config::default(q2penalty)
	set diff $config::default(q2range)
	foreach p1 $list {
		set inpos {}
		set inrange {}
		set beflist [lrange $list 0 $pos]
		set reverse {}
		foreach e $beflist {
			set reverse [linsert $reverse 0 $e]
		}
		set testpos [expr [llength $reverse] -1]
		foreach testvalue $reverse {
			set max [expr $p1 + $diff]
			set min [expr $p1 - $diff]
			if {$testvalue >= $min && $testvalue <= $max} {
				# in range
				set inrange [linsert $inrange 0 $testvalue]
				set inpos [linsert $inpos 0 $testpos]
			} else {
				# out range
				break
			}
			set beflist [lrange $beflist 0 [expr [llength $beflist] - 2]]
			incr testpos -1
		}
	#	lappend inrange $p1
		set aftlist [lrange $list [expr $pos + 1] end]
		set testpos 0
		set testpos [expr $pos +1]
		foreach testvalue $aftlist {
			set max [expr $p1 + $diff]
			set min [expr $p1 - $diff]
			if {$testvalue >= $min && $testvalue <= $max} {
				# in range
				lappend inrange $testvalue
				lappend inpos $testpos
			} else {
				# out range
				break
			}
			incr testpos
		}
		set mean [::math::statistics::mean $inrange]
		if {[llength $inrange] < 2} {
			set stdev 0
		} else {
			set stdev [dformat "%.3f" [::math::statistics::stdev $inrange]]
		}
		if {!$mean} {set mean 0.0001}
		set proc [expr $stdev / $mean]
		set temp($pos,values) $inrange
		set temp($pos,proc) $proc
		set temp($pos,pos) $inpos
		incr pos
	}
	for {set i 0} {$i < $pos} {incr i} {
		set bestlist $i
		set bestproc 1
		for {set i2 0} {$i2 < $pos} {incr i2} {
			set testlist $temp($i2,pos)
			if {[lsearch $testlist $i] >= 0} {
				# found
				set proc [llength $testlist]
				if {$proc > $bestproc} {
					set bestlist $i2
					set bestproc $proc
				}
			}
		}
		set best($i) $bestlist
	}
	array unset content
	for {set i 0} {$i < $pos} {incr i} {
		set belongsto [goIn $i best]
		lappend content($belongsto) $i
	}
	set score {}
	foreach group [array names content] {
		set members $content($group)
		set values {}
		foreach m $members {
			set value [lindex $list $m]
			lappend values $value
		}
		set mean [dformat "%.3f" [::math::statistics::stdev $values]]
		if {[toGroup $mean] == 3} {
			set tpenalty 0
		} else {
			set tpenalty [expr $penalty / [llength $values]]
		}
		if {[llength $values] < 2} {
			set stdev $tpenalty
		} else {
			set stdev [dformat "%.3f" [expr [::math::statistics::stdev $values] + $tpenalty]]
		}
		lappend score $stdev
	}
	set result  [dformat "%.3f" [eval expr [join $score +]]]
	return $result
}

proc getQ2_old3 {id} {
	set references $::data::controlereads
	if {![llength $references]} {return {}}
	if {![info exist ::data::assayData($::data::active_marker)]} {return}
	set active_assay $::data::active_marker
	set tests $::data::amplicons($active_assay,test)
	set tests $::data::amplicons($active_assay,all)
	set doslist {}
	foreach t $tests {
		lappend doslist $data::dos($id,$t)
	}
	set list $doslist
	set pos 0
#	set penalty $config::default(q2penalty)
#	set diff $config::default(q2range)
	set diff {}
	foreach p1 $list {
		set group [toGroup $p1]
		set test [expr $group /2]
		set diff [expr abs($test - $p1)]
		lappend scores $diff
	}
	set result  [dformat "%.3f" [eval expr ([join $scores +]) / [llength $scores]]]
	return $result
}

proc getQ2 {id} {
	set references $::data::controlereads
	if {![llength $references]} {return {}}
	if {![info exist ::data::assayData($::data::active_marker)]} {return}
	set active_assay $::data::active_marker
	set tests $::data::amplicons($active_assay,test)
	set tests $::data::amplicons($active_assay,all)
	set doslist {}
	foreach t $tests {
		lappend doslist $data::dos($id,$t)
	}
	set list $doslist
	set pos 0
#	set penalty $config::default(q2penalty)
#	set diff $config::default(q2range)
	set diff {}
	foreach p1 $list {
		set group [toGroup $p1]
		set test [expr $group /2]
		set diff [expr abs($test - $p1)]
		lappend scores $diff
	}
	set result  [dformat "%.3f" [eval expr ([join $scores +]) / [llength $scores]]]
	return $result
}

proc getSD {index locus} {
	if {![info exist ::data::assayData($::data::active_marker)]} {return}
	set active_assay $::data::active_marker
	set dosage_list {}
	set loci $::data::controles($active_assay,$locus)
	if {[llength $loci] < 2} {
		set loci $::data::amplicons($active_assay,control)
	}
	foreach locus $loci {
		lappend dosage_list $data::dos($index,$locus)
	}
	return [dformat "%.3f" [::math::statistics::stdev $dosage_list]]
}

proc getZ {index locus} {
	# punt
	set dos $data::dos($index,$locus)
	# standaard deviatie
	set sd [getSD $index $locus]
	# gemiddelde
	set gem [expr [toGroup $dos]/2.0]
	set diff [expr abs($gem - $dos)]
	if {!$diff} {
		set proc 100
	} else {
		set newdos [expr $diff + 1]
		set newgem 1
		set proc [dformat "%.1f" [expr [::math::statistics::cdf-normal $newgem $sd $newdos] * 100]]
	}
	return [list $gem $proc]
}

proc goIn {start arrayname} {
	upvar $arrayname local
	set value $local($start)
	if {$value != $start} {
		set result [goIn $value local]
	} else {
		return $value
	}
	return $result
}

proc groupIt {list} {

	array unset groups
	set prevgroup {}
	set groupnr 0
	foreach el $list {
		set group [toGroup $el]
		if {[string length $prevgroup]} {
			# groups found
			if {$group == $prevgroup} {
				# same as previous
				lappend groups($groupnr) $el
			} else {
				# diff group
				incr groupnr
				lappend groups($groupnr) $el
			}
		} else {
			# no group yet
			lappend groups($groupnr) $el
		}
		set prevgroup $group
	}

}

proc toGroup {value} {
	set notfound 1
	set test 0.25
	set group 0
	while {$notfound} {
		if {$value < $test} {
			break
		}
		set test [expr $test + 0.5]
		incr group
		if {$group > 20} {break}
	}
	return $group
}

proc locus2nr {locus} {
	global locus2id
	set length [llength [array names locus2id]]
	if {[info exist locus2id($locus)]} {
		return $locus2id($locus)
	} else {
		set locus2id($locus) $length
	}
	return $length
}

proc nr2locus {nr} {
	global locus2id
	foreach l [array names locus2id] {
		set test $locus2id($l)
		if {$test == $nr} {return $l}
	}
	return -1
}

proc usedIn {contr} {
	set active_assay $::data::active_marker
	set controles $::data::amplicons($active_assay,control)
	set all $::data::amplicons($active_assay,all)
	if {![inlist $controles $contr]} {return}
	set todo {}
	foreach amp $all {
		set loci $data::controles($active_assay,$amp)
		if {[inlist $loci $contr]} {
			lappend todo $amp
		}
	}
	return $todo
}

proc vectorUpdate {args} {
	set ids {}
	if {[llength $args]} {
		foreach {ids loci} $args break
	} else {
		set ids [$::listboxW.t getcolumn 0]
		if {![info exist ::data::amplicons($data::active_marker,all)]} {return}
		set loci $::data::amplicons($data::active_marker,all)
	}
	foreach id $ids {
		set yvector .y.id.$id.mean
		set yerrorvector .yerror.id.$id.mean
		if {![$yvector length]} {return}
		foreach locus $loci {
			set nr [locus2nr $locus]
			foreach {y yerror} [id2mean $id $locus] break
			if {![info exist y]} {
				continue
			}
			set testvalue [$yvector index $nr]
			if {$testvalue != $y} {
				$yvector index $nr $y
			}
			set testvalue [$yerrorvector index $nr]
			if {$testvalue != $yerror} {
				$yerrorvector index $nr $yerror
			}
		}
	}
}

proc id2mean {id locus} {
	foreach {points contr} [getnorm $id $locus] break
	if {![llength $points]} {
		return
	}
	set p [format "%.2f" [::math::statistics::mean $points]]
	set pstdev [::math::statistics::stdev $points]
	if {![string length $pstdev]} {set pstdev 0}
	return [list $p $pstdev]
}

proc initVectors {} {
	set max 0
	set active_assay $::data::active_marker
	if {![string length $active_assay] || [string equal $active_assay unknown]} {return}
	set all [$::listboxW.t getcolumn 0]
	if {![info exist ::data::amplicons($active_assay,all)]} {return}
	set loci $::data::amplicons($active_assay,all)
	foreach id $all {
		foreach vector [list .x.id.$id.mean .y.id.$id.mean .yerror.id.$id.mean] {
			if {![string length [info command $vector]]} {
				vector create ::$vector
			} else {
				$vector set {}
			}
		}
		foreach locus $loci {
			set x [expr [locus2nr $locus] + 1]
			foreach {y yerror} [id2mean $id $locus] break
			if {![string length $y]} {continue}
			.x.id.$id.mean append $x
			.y.id.$id.mean append $y
			.yerror.id.$id.mean append $yerror
			set ::data::dos($id,$locus) $y
		}
	}
}

proc value2type {value} {
	if {![string length $value]} {return}
	set newvalue [expr round($value * 100)]
	set nr [expr (($newvalue + 25) / 50)-2]
	set linecolor black
	if {$value < 0.25} {
		set fillcolor $config::color(full_deletion)
	} elseif {$value < 0.75} {
		set fillcolor $config::color(half_deletion)
	} elseif {$value <= 0.8} {
		set fillcolor $config::color(unk_deletion)
	} elseif {$value < 1.2} {
		set fillcolor {}
		set linecolor {}
	} elseif {$value <= 1.3} {
		set fillcolor $config::color(unk_duplication)
	} elseif {$value < 1.75} {
		set fillcolor $config::color(half_duplication)
	} else {
		set fillcolor $config::color(full_duplication)
	}
	return [list $nr $fillcolor $linecolor]
}

proc typebar {nr {height 0.05}} {
	set coords {}
	lappend coords [expr $nr - 0.5]
	lappend coords -1
	lappend coords [expr $nr + 0.5]
	lappend coords -1
	lappend coords [expr $nr + 0.5]
	lappend coords 0
	lappend coords [expr $nr - 0.5]
	lappend coords 0
	return $coords
}

proc badtypebar {nr {height 0.05}} {
	set coords {}
	set step 0.1
	for {set point -0.4} {$point < 0.5} {set point [expr $point + $step]} {
		lappend coords [expr $nr + $point]
		lappend coords -1
		lappend coords [expr $nr + $point]
		lappend coords 0
		lappend coords [expr $nr + $point]
		lappend coords -1
	}
	return $coords
}

##############################################
#
# general functions
#
##############################################

proc drawbar {path x text {fill white} {color red} {update 0}} {
	set ::xbar $x
        set width [winfo width $path]
	set test [string length [$path itemcget rect_item -fill]]
	$path delete rect_item
	$path delete text_item
        $path create rectangle 0c 3 [expr $x*$width/100] 0.8c -fill $color -tags rect_item -outline "black"
        $path create text [expr 50*$width/100] .2c -text $text -anchor n -tags text_item -fill $fill -font {helvetica 10 bold}
	if {$update == 2} {
	        update idletask
	} elseif {$update} {
		update
	}
}

proc updatebar {} {
	global bar xbar
        set width [winfo width $bar]
	set test [string length [$bar itemcget rect_item -fill]]
	if {$test} {
		$bar coords rect_item 0c 3 [expr $xbar*$width/100] 0.8c
		$bar coords text_item [expr 50*$width/100] .2c
	}
}

proc buildbar {window} {
        global bar
        set barframe [frame $window.bar]
        set bar [canvas $barframe.canvas -height 0.6c -relief sunken -borderwidth 2]
	balloon $bar main,bar
        pack $barframe.canvas -fill x
        grid $barframe -sticky we
	update idletask
}

proc createcomment {index} {
	if {![string length $index]} {
		return [list {} {}]
	} elseif {[llength $index] > 1} {
		set index [lindex $index 0]
	}
	set color {}
	set comment {}
	set meanH {}
	set assay $data::active_marker
	set pattern [.mainw.markerbar.zoom cget -text]
	if {![string equal $pattern All]} {
		if {[info exist data::height($index,$pattern)]} {
			set meanH $data::height($index,$pattern)
		}
		lappend comment $meanH
		lappend comment [fetchVal $index individual]
		lappend comment $pattern
		if {[info exist data::score($assay,$pattern,$index)]} {
			lappend comment $data::score($assay,$pattern,$index)
		}
	} else {
		set meanH [getMeanH $assay $index]
		lappend comment $meanH
		lappend comment [fetchVal $index individual]
		lappend comment $pattern
	}
	set color [height2color $meanH]
	return [list $color $comment]
}

proc splitlist {list} {
	set means [list]
	set bins [list]
	foreach {mean bin} $list {
		lappend means $mean
		lappend bins $bin
	}
	return [list $means $bins]
}

proc dformat {format double} {
        if {[string length $double]} {
                return [format $format $double]
        } else {
                return ""
        }
}

proc list2table {list cols} {
	set result [list]
	foreach line $list {
		set vals [list]
		array set t $line
		foreach col $cols {
			if {[info exists t($col)]} {
				lappend vals $t($col)
			} else {
				lappend vals {}
			}
		}
		lappend result $vals
		array unset t
	}
	return $result
}

proc mktitle {string} {
	set capital [string toupper [string index $string 0]]
	set rest [string range $string 1 end]
	return $capital$rest
}

proc createList {marker} {
	if {![string length $marker] || ![info exist ::data::active_datalist]} {return}
	set list {}
	if {![string equal unknown $marker]} {
		set columns_sel [createColumns $marker]
	} else {
		set columns_sel $config::columns_sel
	}
	set ::data::columns_sel $columns_sel
	catch {list2table $data::active_datalist $columns_sel} datatable
	set markerpos [lsearch $columns_sel str_marker] 
	set assaypos [lsearch $columns_sel assay] 
	foreach line $datatable {
		if {[string equal $marker [lindex $line $markerpos]] || [string equal $marker [lindex $line $assaypos]]} {
			lappend list $line
		}
	}
	return $list
}

proc value2color {value} {
	if {$value < 0} {return}
	if {$value <= 0.1} {
		# blue
		set color $::config::color(qgood)
	} elseif {$value <= 0.15} {
		# orange
		set color $::config::color(qmiddle)
	} elseif {$value <= 1} {
		# red
		set color $::config::color(qbad)
	} else {
	        set color ""
	}
	return $color
}

proc height2color {value} {
	if {$value < 0} {return}
	set min_height $config::default(lowpeaks)
	if {$value >= [expr $min_height * 2]} {
		# blue
		set color $::config::color(qgood)
	} elseif {$value >= [expr $min_height * 3 / 4]} {
		# orange
		set color $::config::color(qmiddle)
	} elseif {$value > 0} {
		# red
		set color $::config::color(qbad)
	} else {
	        set color ""
	}
	return $color
}

proc fetchVal {index columns} {
	if {![info exist data::active_datalist] || ![string length $index]} {return}
	set line [lindex $data::active_datalist $index]
	set vals [list]
	foreach col $columns {
		if {[info exists data::column($col)]} {
			lappend vals [lindex $line $data::column($col)]
		} else {
			lappend vals {}
		}
	}
	return $vals
}

proc globSetting {} {
	set w .globbing
	if {[winfo exist $w]} {wm state $w normal;raise $w;return}
	toplevel $w
	set buttonframe [frame $w.buttonframe]
	wm title $w "Glob settings"
	label $w.help -text "These patterns are used\nto gather information from file names"
	grid $w.help -columnspan 2
	set nr 0
	array set ::temparray [array get ::config::glob]
	foreach {name value} [array get ::config::glob] {
		label $w.text$nr -text $name
		entry $w.entry$nr -textvariable ::temparray($name) -width 20
		balloon $w.entry$nr glob,$name
		grid $w.text$nr $w.entry$nr
		incr nr
	}
	button $buttonframe.ok -text OK -command "makeChanges ::temparray ::config::glob;destroy $w"
	grid $buttonframe.ok -column 0 -row 0
	button $buttonframe.cancel -text Cancel -command "destroy $w"
	grid $buttonframe.cancel -column 1 -row 0
	grid $buttonframe -sticky nwse -columnspan 2
}

proc getArea {read min max color} {
	set maxy 0
	if {![string length [info command x$read]]} {return 0}
	set min_index [lindex [x$read search $min [expr $min+1]] 0]
	set max_index [lindex [x$read search $max [expr $max+1]] 0]
	foreach nr {1 2 3 4 5} tcolor {blue green yellow red orange} {
		if {[lsearch $color $tcolor] >= 0} {break}
	}
	set points [g${read}y$nr range $min_index $max_index]
	set area 0
	foreach p1 [lrange $points 0 [expr [llength $points] -2]] p2 [lrange $points 1 end] {
		if {$p1 <0} {set p1 0}
		if {$p2 <0} {set p2 0}
		set min [lmath_min [list $p1 $p2]]
		set max [lmath_max [list $p1 $p2]]
		set diff [expr $max - $min]
		set tarea [expr $min + ($diff/2)]
		set area [expr $area + $tarea]
	}
	return $area
}

proc getHeight {read min max color} {
	set maxy 0
	if {![string length [info command x$read]]} {return 0}
	set min_index [lindex [x$read search $min [expr $min+1]] 0]
	set max_index [lindex [x$read search $max [expr $max+1]] 0]
	foreach nr {1 2 3 4 5} tcolor {blue green yellow red orange} {
		if {[lsearch $color $tcolor] < 0} {continue}
		set tempmax [lmath_max [g${read}y$nr range $min_index $max_index]]
		if {$tempmax > $maxy} {set maxy $tempmax}
	}
	return $maxy
}

proc applyAssay {assay} {
	set datalist $::data::datalist(unknown)
#	array unset data::datalist
#	set ::data::datalist(unknown) $datalist
	array unset ::data::height
	array unset ::data::area
	array unset ::data::dos
	Classy::busy
	set newdata {}
	set min 500
	set max 0
	if {![info exist ::data::assayData($assay)]} {return}
	set amplicons $::data::assayData($assay)
	for {set i 0} {$i < [llength $datalist]} {incr i} {
		set line [lindex $datalist $i]
		set read [fetchVal $i gs_read]
		set heights 0
		foreach amplicon $amplicons {
			array unset tam
			array set tam $amplicon
			set cmin [expr $tam(min) + $tam(minmove)]
			set cmax [expr $tam(max) + $tam(maxmove)]
			if {![info exist ::data::height($i,$tam(amplicon))]} {
				set height [getHeight $read $cmin $cmax $tam(color)]
				set ::data::height($i,$tam(amplicon)) $height
				lappend heights $height
			}
			if {![info exist ::data::area($i,$tam(amplicon))]} {
				set area [getArea $read $cmin $cmax $tam(color)]
				set ::data::area($i,$tam(amplicon)) $area
			}
			if {![info exist ::data::dos($i,$tam(amplicon))]} {
				set ::data::dos($i,$tam(amplicon)) 0
			}
			if {$cmin < $min} {set min $cmin}
			if {$cmax > $max} {set max $cmax}
		}
		set ::data::height($i,All) [::math::statistics::mean $heights]
	}
	set ::data::${assay}(range_min) [expr $min -10]
	set ::data::${assay}(range_max) [expr $max +10]
	set ::data::${assay}(color) [colornr2colorname $tam(color) 1]
	set ::data::${assay}(type) LGV
	Classy::busy remove
}

proc getAssayHeight {xvector yvector {amp {}}} {
	set assay $data::active_marker
	if {![info exist ::data::assayData($assay)]} {return}
	if {![string length [info command $xvector]] || ![string length [info command $yvector]]} {return}
	set amplicons $::data::assayData($assay)
	set maxy 0
	foreach amplicon $amplicons {
		array unset tam
		array set tam $amplicon
		if {[string length $amp] && ![string equal $amp $tam(amplicon)]} {continue}
		set cmin [expr $tam(min) + $tam(minmove)]
		set cmax [expr $tam(max) + $tam(maxmove)]
		set min_index [lindex [$xvector search $cmin [expr $cmin+1]] 0]
		set max_index [lindex [$xvector search $cmax [expr $cmax+1]] 0]
		set tempmax [lmath_max [$yvector range $min_index $max_index]]
		if {$tempmax > $maxy} {set maxy $tempmax}
	}
	return $maxy
}

proc getMaxAmpl {xvector yvector} {
	set assay $data::active_marker
	if {![info exist ::data::assayData($assay)]} {return}
	if {![string length [info command $xvector]] || ![string length [info command $yvector]]} {return}
	set amplicons $::data::assayData($assay)
	set maxy 0
	set amp {}
	foreach amplicon $amplicons {
		array unset tam
		array set tam $amplicon
		set cmin [expr $tam(min) + $tam(minmove)]
		set cmax [expr $tam(max) + $tam(maxmove)]
		set usedcontroles $data::controles($assay,used)
		if {![inlist $usedcontroles $tam(amplicon)]} {continue}
		set min_index [lindex [$xvector search $cmin [expr $cmin+1]] 0]
		set max_index [lindex [$xvector search $cmax [expr $cmax+1]] 0]
		set tempmax [lmath_max [$yvector range $min_index $max_index]]
		if {$tempmax > $maxy} {
			set maxy $tempmax
			set amp $tam(amplicon)
		}
	}
	return $amp
}

proc makeChanges {from to} {
	array set $to [array get $from]
	array unset $from
}

proc refresh_rOptionMenu {} {
	foreach c [rOptionMenu info children] {
		set value [$c cget -textvariable]
		if {![string length $value]} {continue}
		set textvar [$c cget -textvariable]
		set $textvar [set $textvar]
	}
}

proc search_row {index} {
	set tbl $::listboxW.t
	set rownr 0
	foreach r [$tbl getcolumns 0] {
		if {[string equal $index $r]} {
			return $rownr
		} 
		incr rownr
	}
	return -1
}

proc altercell {index column value} {
	set tbl $::listboxW.t
	set index [lindex $index 0]
	set row [search_row $index]
	if {$row < 0} {return}
	set col [lsearch $::data::columns_sel $column]
	$tbl cellconfigure $row,$col -text $value
	set line [lindex $data::active_datalist $index]
	set color [value2color $value]
	if {[string length $color]} {
		$tbl cellconfigure $row,$col -bg $color
	}
}

proc check_heights {} {
	set currentAssay $::data::active_marker
	set ::data::lowReads {}
	set tbl $::listboxW.t
	set controles $::data::amplicons($currentAssay,control)
	set tests $::data::amplicons($currentAssay,test)
	set loci $::data::amplicons($currentAssay,all)
#	set assaytype $config::default(assaytype)
	set assaytype height
	foreach geno [$tbl getcolumns 0] {
		set lheights {}
		foreach locus $loci {
			lappend lheights [set ::data::${assaytype}($geno,$locus)]
		}
		set meanlh [::math::statistics::mean $lheights]
		set ::data::height($geno) $meanlh
		if {$meanlh < $::config::default(min_height)} {
			lappend ::data::lowReads $geno
		}
	}
}

proc reformat {value} {
	if {[string length $value]} {
		set newvalue [format "%.02f" $value]
	} else {
		set newvalue ""
	}
	return $newvalue
}

proc create_assay_results {} {
	set currentAssay $::data::active_marker
	if {[string equal unknown $currentAssay]} {return}
	set controles $::data::amplicons($currentAssay,control)
	set tests $::data::amplicons($currentAssay,test)
	set loci $::data::amplicons($currentAssay,all)
	set used $::data::controles($currentAssay,used)
	# Peak intensities
	foreach assaytype {area height} {
		if {$config::checkbutton(add$assaytype)} {
#			set assaytype $config::default(assaytype)
			lappend outline [join [concat read/$assaytype $loci] \t]
			foreach geno $data::active_genos {
				set out [fetchVal $geno individual]
				foreach allel $loci {
					set value [set ::data::${assaytype}($geno,$allel)]
					lappend out $value
				}
				lappend outline [join $out \t]
			}
		}
		lappend outline {}
	}
	# normalisation (intra)
	if {$config::checkbutton(intradetails) || $config::checkbutton(intrasummary)} {
		foreach allel $loci {
			if {[lsearch $controles $allel] < 0} {continue}
#			lappend outline "Testing versus $allel"
			set testloci [usedin $currentAssay $allel]
			lappend outline "versus-$allel\tIndividual\tRead\t[join $testloci \t]"
			if {$config::checkbutton(intradetails)} {
				foreach geno $data::active_genos {
					foreach {individual read} [fetchVal $geno {individual gs_read}] break
					set out [list "" $individual $read]
					set value [set ::data::${assaytype}($geno,$allel)]
					if {!$value} {set value 1}
					foreach suballel $testloci {
						set subvalue [set ::data::${assaytype}($geno,$suballel)]
						if {!$subvalue} {set subvalue 1}
						lappend out [reformat [expr $subvalue/$value]]
					}
					lappend outline "[join $out \t]"
				}
			}
			if {$config::checkbutton(intrasummary)} {
				foreach type {mean stdev proc} {
					set out [list "" "" $type]
					foreach suballel $testloci {
						set all_values $::data::verh($allel,$suballel)
						set all_ids $::data::ids($allel,$suballel)
						set values {}
						foreach geno $data::active_genos {
							set pos [lsearch $all_ids $geno]
							lappend values [lindex $all_values $pos]
						}
						if {[string equal $type proc]} {
							set mean [::math::statistics::mean $values]
							set stdev [::math::statistics::stdev $values]
							lappend out [reformat [expr $stdev/$mean*100]]
						} else {
							set tvalue [::math::statistics::$type $values]
							lappend out [reformat $tvalue]
						}
					}
					lappend outline "[join $out \t]"
				}
			}
			lappend outline {}
		}
		lappend outline {}
	}
	# controles dosage
	set reads $::data::controlereads
	set refs {}
	set tbl $::listboxW.t
	foreach r [$tbl getcolumns 0] {
		set testread [fetchVal $r gs_read]
		if {[inlist $reads $testread]} {
			lappend refs $r
		}
	}
	if {$config::checkbutton(interref)} {
#		lappend outline "\"Overview of references\"\t\"per amplicon\""
		foreach allel $controles {
			set used $data::controles($currentAssay,$allel)
#			lappend outline "Testing for $allel"
			lappend outline "Reference-Quality-$allel\tIndividual\tRead\t[join $used \t]\tMean\tStDev"
			foreach geno $refs {
				foreach {individual read} [fetchVal $geno {individual gs_read}] break
				set out [list "" $individual $read]
				array unset means
				set verh_list {}
				foreach suballel $used {
					set all_values $::data::verh($suballel,$allel)
					set all_ids $::data::ids($suballel,$allel)
					set pos [lsearch $all_ids $geno]
					set value [lindex $all_values $pos]
					set ref $::data::verhC($currentAssay,$suballel,$allel)
					set verh [reformat [expr $value/$ref]]
					lappend verh_list $verh
					lappend out $verh
				}
				lappend out [reformat [::math::statistics::mean $verh_list]]
				lappend out [reformat [::math::statistics::stdev $verh_list]]
				lappend outline [join $out \t]
			}
		}
		lappend outline {}
	}
	if {$config::checkbutton(intertest)} {
#		lappend outline "\"Overview of samples\"\t\"per amplicon\""
		foreach allel $loci {
			set used $data::controles($currentAssay,$allel)
#			lappend outline "Testing for $allel"
			lappend outline "Quality-$allel\tIndividual\tRead\t[join $used \t]\tMean\tStDev"
			foreach geno $data::active_genos {
				foreach {individual read} [fetchVal $geno {individual gs_read}] break
				set out [list "" $individual $read]
				array unset means
				set verh_list {}
				foreach suballel $used {
					set all_values $::data::verh($suballel,$allel)
					set all_ids $::data::ids($suballel,$allel)
					set pos [lsearch $all_ids $geno]
					set value [lindex $all_values $pos]
					set ref $::data::verhC($currentAssay,$suballel,$allel)
					set verh [reformat [expr $value/$ref]]
					lappend verh_list $verh
					lappend out $verh
				}
				lappend out [reformat [::math::statistics::mean $verh_list]]
				lappend out [reformat [::math::statistics::stdev $verh_list]]
				lappend outline [join $out \t]
			}
			lappend outline {}
		}
		lappend outline {}
	}
	if {$config::checkbutton(dosref)} {
#		lappend outline "{Dosage quotients of 'Controle' amplicons}"
		lappend outline "Dosage-refs\tIndividual\tRead\t[join $controles \t]\tQ"
		foreach geno $data::active_genos {
			foreach {individual read} [fetchVal $geno {individual gs_read}] break
			set out [list "" $individual $read]
			set ps {}
			foreach allel $controles {
				foreach {points contr} [getnorm $geno $allel] break
				if {[llength $points]} {
					set p [format "%.2f" [::math::statistics::mean $points]]
					lappend ps $p
				} else {
					set p -
				}
				lappend out $p
			}
			lappend out [format "%.3f" [::math::statistics::stdev $ps]]
			lappend outline [join $out \t]
		}
		lappend outline {}
	}
	if {$config::checkbutton(dostest)} {
#		lappend outline "{Dosage quotient of 'Test' amplicons}"
		lappend outline "Dosage-test\tIndividual\tRead\t[join $tests \t]"
		foreach geno $data::active_genos {
			foreach {individual read} [fetchVal $geno {individual gs_read}] break
			set out [list "" $individual $read]
			foreach allel $tests {
				foreach {points contr} [getnorm $geno $allel] break
				if {[llength $points]} {
					set p [format "%.2f" [::math::statistics::mean $points]]
				} else {
					set p -
				}
				lappend out $p
			}
			lappend outline [join $out \t]
		}
		lappend outline {}
	}
	return $outline
}

proc usedin {assay amplicon} {
	set usedin {}
	set loci $::data::amplicons($assay,all)
	foreach locus $loci {
		set used $data::controles($assay,$locus)
		if {[inlist $used $amplicon]} {
			lappend usedin $locus
		}
	}
	return $usedin
}

proc checkControles {{skip {}}} {
	set treshold $::config::treshold(controles)
	set currentAssay $::data::active_marker
	set assayInfo $::data::assayData($currentAssay)
	set controles {}
	foreach line $assayInfo {
		array unset t
		array set t $line
		if {[string equal control $t(type)]} {
			lappend controles $t(amplicon)
		}
	}
	array unset ::data::stdev
	array unset ::data::bad
	foreach controle $controles {
		foreach ar [array names data::verh $controle,*] {
			foreach {c s} [split $ar ,] break
			if {[lsearch $skip $c] >= 0 || [lsearch $controles $s] < 0} {continue}
			set mean [::math::statistics::mean $data::verh($ar)]
			set stdev [::math::statistics::stdev $data::verh($ar)]
			set value [expr $stdev/$mean*100]
			set ::data::stdev($ar) $value
			if {$value > $treshold} {
				if {[lsearch $controles $s] >=0} {
					if {[lsearch $skip $s] < 0} {
						#bad controle
						lappend ::data::bad($controle) $s
					}
				}
			}
		}
	}
	set skiplist {}
	set max 0
	set badest {}
	foreach c [array names data::bad] {
		set number [llength $data::bad($c)]
		if {$number > $max} {set max $number;set skiplist [concat $skip $c]}
	}
	if {[llength $skiplist]} {
		return [checkControles $skiplist]
	} else {
		set good {}
		foreach c $controles {
			if {![inlist $skip $c]} {
				lappend good $c
			}
		}
		return [list $skip $good]
	}
}

proc dec2rgb {r {g 0} {b UNSET} {clip 0}} {
    if {![string compare $b "UNSET"]} {
	set clip $g
	if {[regexp {^-?(0-9)+$} $r]} {
	    foreach {r g b} $r {break}
	} else {
	    foreach {r g b} [winfo rgb . $r] {break}
	}
    } 
    set max 255
    set len 2
    if {($r > 255) || ($g > 255) || ($b > 255)} {
	if {$clip} {
	    set r [expr {$r>>8}]; set g [expr {$g>>8}]; set b [expr {$b>>8}]
	} else {
	    set max 65535
	    set len 4
	}
    }
    return [format "#%.${len}X%.${len}X%.${len}X" \
	    [expr {($r>$max)?$max:(($r<0)?0:$r)}] \
	    [expr {($g>$max)?$max:(($g<0)?0:$g)}] \
	    [expr {($b>$max)?$max:(($b<0)?0:$b)}]]
}

proc do {args} {
	catch {eval [lindex $args 0]}
}

proc rOptionMenu_update {object var args} {
	set changedvar [lindex $args 0]
	$object configure -$var [set $changedvar]
}

##############################################
#
# Help/Info button in main
#
##############################################

proc helpButton {} {
	set state $::config::default(help_state)
	if {$state} {
		set ::config::default(help_state) 0
	} else {
		set ::config::default(help_state) 1
	}
	update_helpButton
}

proc update_helpButton {args} {
	set button [lindex $args 0]
	set state $::config::default(help_state)
	set ::config::default(help_state) $state
	if {$state} {
		Classy::Balloon private time 0
		catch {$button configure -relief sunken}
	} else {
		Classy::Balloon private time 1000000
		catch {$button configure -relief raised}
	}
	return
}

proc balloon {obj var} {
	if {[info exist ::info($var)]} {
		set text $::info($var)
		if {[string length [info command $obj]]} {
			Classy::Balloon add $obj $text
		}
	}
}

proc balloontime {type} {
	set state $::config::default(help_state)
	if {!$state} {
		switch $type {
			enter {
				Classy::Balloon private time 0
			}
			leave {
				Classy::Balloon private time 10000000
			}
		}
	}
}

proc guide {} {
	global bar afterids guide
	set ids {}
	if {![info exist guide]} {set guide {}}
	if {[info exist afterids]} {
		foreach id $afterids {after cancel $id}
	}
	if {[string equal Disabled $::config::default(guide)]} {
#	        drawbar $bar 0 "" black
		return
	}
	if {![info exist ::exp_temp] || ![string length $::exp_temp]} {
		if {![winfo exist .selector]} {
			# 1. open an experiment
			set object .mainw.row0.selector
		        drawbar $bar 0 "Push the 'Import' button in order to select your data folder and assay files." red
			set ids [flash $object]
		} elseif {![checkLicense 1] && !$::startDemo} {
			# no valid license found
			set object .selector.buttonframe.createkey
		        drawbar $bar 0 "Push the 'Create Key' button for the first step in obtaining a license." red
			set ids [flash $object]
		} else {
			set object .selector.dataframe.button
		        drawbar $bar 0 "Push the 'Browse' button in order to select your data folder." red
			set ids [flash $object]
		}
	} elseif {![info exist ::assay_temp] || ![string length $::assay_temp]} {
		if {![winfo exist .selector]} {
			# 1. open an experiment
			set object .mainw.row0.selector
		        drawbar $bar 0 "Push the 'Import' button in order to select your data folder and assay files." red
			set ids [flash $object]
		} elseif {![checkLicense 1] && !$::startDemo} {
			# no valid license found
			set object .selector.buttonframe.createkey
		        drawbar $bar 0 "Push the 'Create Key' button for the first step in obtaining a license." red
			set ids [flash $object]
		} else {
			set object .selector.assayframe.button
		        drawbar $bar 0 "Push the 'Browse' button in order to select your assay file." red
			set ids [flash $object]
		}
	} elseif {![string length $::exp] || [string equal unknown $::data::active_marker]} {
		if {![winfo exist .selector]} {
			# 1. open an experiment
			set object .mainw.row0.selector
		        drawbar $bar 0 "Push the 'Import' button in order to select your data folder and assay files." red
			set ids [flash $object]
		} elseif {![checkLicense 1] && !$::startDemo} {
			# no valid license found
			set object .selector.buttonframe.createkey
		        drawbar $bar 0 "Push the 'Create Key' button for the first step in obtaining a license." red
			set ids [flash $object]
		} else {
			set object .selector.buttonframe.ok
		        drawbar $bar 0 "Push the 'Ok' button in order to start the analysis." red
			set ids [flash $object]
		}
#	} elseif {![llength $data::controlereads] && ![topNormal .listbox]} {
#		# 3. open listbox
#		set object .mainw.row0.listbox
#	        drawbar $bar 0 "Push the 'ListBox' button first in order to set the reference reads." red
#		set ids [flash $object]
#	} elseif {![llength $data::controlereads]} {
#		# 4. choose reference reads
#		set object .listbox.buttons.sel2ref
#	        drawbar $bar 0 "Select the reference reads and push the 'SetRef' button in order to set the reference reads." red
#		set ids [flash $object]
#		set guide dos
#	} elseif {[string equal $guide dos] || ![string length [info command .dos]]} {
##	topNormal .dos
#		set object .mainw.row0.dos
#	        drawbar $bar 0 "Push the 'DosPlot' button in order to view the dosage plots." red
#		set ids [flash $object]
#		set guide export
#	} elseif {[string equal $guide export]} {
#		set object .mainw.row0.export
#	        drawbar $bar 0 "Push the 'Export' button in order to export your results." red
#		set ids [flash $object]
	} else {
	        drawbar $bar 0 "" black
		set ids {}
	}
	set afterids $ids
}

proc topNormal {top} {
	catch {wm state $top} type
	if {[string equal normal $type]} {
		return 1
	} else {
		return 0
	}
}

proc flash {object} {
	set oribg [$object cget -bg]
	if {[string equal red $oribg]} {return}
	set oriactbg [$object cget -activebackground]
	set ids {}
	set after 0
	for {set i 0} {$i < 10} {} {
		set after [expr $after + 500]
		lappend ids [after $after "catch {$object configure -bg red -activebackground red;update}"]
		set after [expr $after + 250]
		lappend ids [after $after "catch {$object configure -bg $oribg -activebackground $oriactbg;update}"]
		incr i
	}
	after $after "catch {$object configure -bg $oribg -activebackground $oriactbg;update}"
	return $ids
}

##############################################
#
# varia
#
##############################################

proc buildListbox {object} {
	if {![string length [info command $object]]} {
		ListBox $object -target $::gridW -marker $data::active_marker
	}
}

proc listboxButton {object} {
	global listboxplaced
	buildListbox $object
	if {![info exist listboxplaced]} {$object place}
	wm state $object normal
	raise $object
	set listboxplaced 1
	wm minsize $object 340 143
	guide
}

proc createColumns {assay} {
	if {[string equal $assay unknown]} {return}
	set columns_sel {index Act ILS  meanH well gs_read individual assay}
	if {![info exist data::assayData($assay)]} {return}
	foreach line $::data::assayData($assay) {
		array unset t
		array set t $line
		lappend columns_sel $t(amplicon)
	}
	lappend columns_sel chromatogram
	return $columns_sel
}

proc init {} {
	catch {namespace delete data}
	namespace eval data {}
	set data::active_genos {}
	set data::active_marker unknown
	catch {eval vector destroy [vector names]}
	catch {unset data::active_datalist}
	array unset data::datalist
	set data::markers {}
	array set data::pool {}
	trace add variable ::data::active_genos write "DosRefresh"
	set ::data::lastmessage {}
	set ::config::role 0
	set ::data::controlereads {}
	array unset ::data::standards
}

proc DosRefresh {args} {
	if {[string length [info command $::dosW]]} {
		$::dosW refresh
	}
}

proc checking {token} {
	global bar
	upvar #0 $token state
        set data [http::data $token]
        http::cleanup $token
	if {[regexp {html} $data]} {
	        drawbar $bar 0 "Connection to the server failed." black
	} else {
		set latest [lindex [lsort [list $::version $data]] end]
		if {![string equal $latest $::version] && [string length $latest] < 10} {
			# new version
			set message "Update available (v$latest) !"
			if {![info exist config::default(check4update)] || [string equal $config::default(check4update) Enabled]} {
				tk_messageBox -icon info -type ok -message $message -title "Update check" -parent $::mainW
			}
		        drawbar $bar 0 $message red
		} else {
		        drawbar $bar 0 "" black
		}
	}
}

proc checkUpdate {} {
	global bar
	blt::busy hold $::mainW
        drawbar $bar 0 "Checking for updates..." red
	update
	set url "http://$config::default(ip)/$config::default(url)"
	if {[catch {::http::geturl $url -command checking} token]} {
	        drawbar $bar 0 "Connection to the server failed." black
	}
	blt::busy release $::mainW
}

proc setStandard {} {
	set longest 0
	foreach tread [array names data::standards] {
		set list $data::standards($tread)
		set length [llength $list]
		if {$length > [llength $longest]} {
			set longest $list
		}
	}
	set ::data::standards(best) $longest
}

proc testStandard {read} {
	if {![info exist data::standards(best)]} {
		setStandard
	}
	set missing {}
	foreach l $data::standards(best) {
		if {[lsearch $data::standards($read) $l] < 0} {
			lappend missing $l
		}
	}
	return $missing
}

proc reload_data {{markerset {}}} {
        global tca_cookie exp bar dumpfile grid reads
#	init
	foreach var {data::newpooldata data::pooldata} {
		if {[info exist $var]} {unset $var}
	}
	if {![info exist reads]} {set reads {}}
	if {[string length $exp] && ![string equal custom $exp]} {
		drawbar $bar 0 "Sending request..."  black
		set keyvaluelist [list exp $exp]
		append keyvaluelist " nofiles [list [assemble_nofiles]]"
		if {[string length $markerset]} {
			append keyvaluelist " markerset $data::active_marker"
		}
		set query [eval ::http::formatQuery $keyvaluelist]
		::Classy::busy

		senddata loaddb3 $keyvaluelist KillBar
	} elseif {[string length $reads]} {
		drawbar $bar 0 "Sending request..."  black
		set keyvaluelist [list reads $reads]
#		append keyvaluelist " nofiles [list [assemble_nofiles]]"
		if {[string length $markerset]} {
			append keyvaluelist " markerset [list $markerset]"
			append keyvaluelist " autofill 0"
		} else {
			append keyvaluelist " autofill 1"
		}
		set query [eval ::http::formatQuery $keyvaluelist]
		::Classy::busy
		senddata loaddb3 $keyvaluelist KillBar
	} else {
#		drawbar $bar 0 "Please select your data folder and assay file."  red
	}
}

proc typeSwitch {var} {
	if {[info exist ::config::default($var-list)]} {
		set typelist $::config::default($var-list)
	} else {
		set typelist {Enabled Disabled}
	}
#	if {![info exist ::config::default($var-list)]} {return}
#	set typelist $::config::default($var-list)
	set current $::config::default($var)
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
	set ::config::default($var) $value
}

##########################
#
# Import procs
#
##########################

proc dosButton {object} {
	global dosplaced
	buildDosplot $object
	if {![info exist dosplaced]} {$object place}
	wm state $object normal
	raise $object
	set dosplaced 1
	guide
}

proc buildDosplot {object} {
	if {![string length [info command $object]]} {
		Dosviewer $object
	}
	$object showdos
}

proc export_dialog {} {
	set ::guide {}
	set tw .export
	set text {}
	if {[winfo exist $tw]} {
		destroy $tw
	}
	set ::export assay_html
	Classy::Dialog $tw -title "Export"
	wm minsize $tw 246 135
	set w [$tw component options]
	set message "Export assay results to file(s) from:"
	label $w.header -text $message
	radiobutton $w.radioct -text "Current assay (txt)" -variable export -value assay
	radiobutton $w.radioch -text "Current assay (html)" -variable export -value assay_html
	radiobutton $w.radiom -text "Current chromatogram" -variable export -value chromatogram
	radiobutton $w.radiod -text "Current dosage plot" -variable export -value dosplot
	radiobutton $w.radioas -text "Assay description file" -variable export -value assay_description
#	radiobutton $w.radioa -text "All assays" -variable export -value all
	$tw.actions.close configure -text Cancel
	$tw add updatedb "Export" "export;destroy $tw"
	grid $w.header -pady 5 -row 1
	grid $w.radioct -pady 1 -row 2 -sticky w -columnspan 2
	grid $w.radioch -pady 1 -row 3 -sticky w -columnspan 2
	grid $w.radiom -pady 1 -row 4 -sticky w -columnspan 2
	grid $w.radiod -pady 1 -row 5 -sticky w -columnspan 2
	grid $w.radioas -pady 1 -row 6 -sticky w -columnspan 2
#	grid $w.radioa -pady 1 -row 6 -sticky w -columnspan 2
	Classy::todo $tw place
	guide
}

proc getMAC {} {
	set homedir $::env(HOME)
	set keys {}
	if {[regexp {^([A-z]+):} $homedir match]} {
		# windows
		if {[catch {exec ipconfig /all} data]} {
			error "Error while creating or checking Key/License (error 1)"
		}
		set keys [getMACwin $data]
	} else {
		# linux
		if {[catch {exec /sbin/ifconfig -a} data]} {
			error "Error while creating or checking Key/License (error 2)."
		}
		set keys [getMAClin $data]
	}
	return $keys
}

proc checkLicense {{silent 0}} {
	if {[regexp TracI $::config::title]} {
		return 1
	} else {
		return 0
	}
}

proc checkLicense_disabled {{silent 0}} {
	set error 0
	if {![info exist ::config::default(licenseFile)] || ![file exist $::config::default(licenseFile)]} {
		if {$silent} {return 0}
		set message "No valid License found !\nDo you have a valid license file ?"
		set answer [tk_messageBox -icon question -type yesno -message $message -title "License check"]
		if {[string equal $answer no]} {
			set message "A license is based upon a key created specifically for your computer. The first step in obtaining a valid license or to start the DEMO version is by creating this key by pushing the 'Create Key' button."
			if {!$::startDemo} {
				tk_messageBox -icon info -type ok -message $message -title "Demo"
			}
			guide
			return 0
		}
	} elseif {$silent && [info exist ::LicenseOK]} {
		return $::LicenseOK
	}
	if {[catch {validKey} valid]} {
		set error 1
		set message $valid
	} elseif {![string length $valid]} {
		set error 1
		set message "Unknown error while creating/validating license/key."
	}
	if {$error} {
		if {$silent} {return 0}
		tk_messageBox -icon error -type ok -message $message -title "License check"
		set message "A license is based upon a key created specifically for your computer. The first step in obtaining a valid license or to start the DEMO version is by creating this key by pushing the 'Create Key' button."
		if {!$::startDemo} {
			tk_messageBox -icon info -type ok -message $message -title Demo
		}
		guide
		set config::default(licenseFile) ""
		set ::LicenseOK 0
		return 0
	} else {
		set ::LicenseOK 1
		set ::startDemo 0
		return 1
	}
}

proc validKey {} {
	if {[catch {getMAC} keys]} {
		# failed to find proper MAC key
		error $keys
	}
	set ok {}
	foreach key $keys {
		set tok [readLicense $key]
		if {$tok} {set ok $key}
	}
	return $ok
}

proc getMACwin {data} {
	set macs {}
	set cname $::env(COMPUTERNAME)
	set length [string length $cname]
	set first [string range $cname 0 1]
	set last [string range $cname [expr $length-2] [expr $length-1]]
	set name [string range "${first}${last}1234" 0 3]
	foreach line [split $data \n] {
		if {[regexp {([A-z0-9]+-[A-z0-9]+-[A-z0-9]+-[A-z0-9]+-[A-z0-9]+-[A-z0-9]+)} $line match mac]} {
			regsub -all -- {-} $mac {} mac
			lappend macs "$name$mac"
			continue
		}
	}
	if {![llength $macs]} {error "Error while creating or checking Key/License (error 3)"}
	return $macs
}

proc getMAClin {data} {
	set macs {}
	set hname [lindex [split $::env(HOSTNAME) .] 0]
	set length [string length $hname]
	set first [string range $hname 0 1]
	set last [string range $hname [expr $length-2] [expr $length-1]]
	set name [string range "${first}${last}1234" 0 3]
	foreach line [split $data \n] {
		if {[regexp {([A-z0-9]+:[A-z0-9]+:[A-z0-9]+:[A-z0-9]+:[A-z0-9]+:[A-z0-9]+)} $line match mac]} {
			regsub -all -- {:} $mac {} mac
			lappend macs "$name$mac"
			continue
		}
	}
	if {![llength $macs]} {error "Error while creating or checking Key/License (error 4)"}
	return $macs
}

proc readLicense {key} {
#	set licensefile [file join $::tca_base License.bin]
	if {[info exist ::config::default(licenseFile)] && [file exist $::config::default(licenseFile)]} {
		set licensefile $::config::default(licenseFile)
	} else {
		set licensefile [tk_getOpenFile -initialdir $::tca_base -title "License check" -filetypes {"LicenseFile .bin"}]
	}
	if {![file exist $licensefile]} {
		error "License file does not exist !"
	}
	set testdata "It smells like teen spirit !"
	set src [open $licensefile]
	fconfigure $src -encoding binary -translation binary
	set text [read $src]
	close $src
	if {[catch {decryptSimple $text $key} data]} {
		error "Error while trying to read License file."
	} else {
		if {[regexp $testdata $data]} {
			array unset ar
			foreach line [split $data \n] {
				foreach var {k v} {set $var {}}
				foreach {k v} [split $line \t] break
				set k [string trim $k { }]
				set v [string trim $v { }]
				if {[string length $k] && [string length $v]} {
					set ar($k) $v
				}
			}
			checkClock
			timeLicense ar
			checkVersion ar
			set safefile [moveLicense $licensefile]
			set ::config::default(licenseFile) $safefile
			saveState
			updateLicense $licensefile ar $key
			return 1
		} else {
			return 0
		}
	}
}

proc checkVersion {arrayName} {
	upvar $arrayName arL
	set version [getVersion $::version]
	if {![info exist arL(version)]} {
		set arL(version) 1.0
	}
	set list [lsort -dictionary [concat $version $arL(version)]]
	if {![string equal [lindex $list end] $arL(version)]} {
		error "Your current License ($arL(version)) does not cover this version !"
	} else {
		return 1
	}
}

proc getVersion {version} {
	set v [lrange [split $version .] 0 1]
	return [join  $v .]
}

proc updateLicense {licensefile arrayName key} {
#	set licensefile $::config::default(licenseFile)
	set nowt [clock seconds]
	upvar $arrayName arL
	foreach type {key created term version} {
		switch $type {
			key {
				set value "It smells like teen spirit !"
			}
			created {
				set value 2006-03-01
			}
			term {
				set value 2006-06-01
			}
			version {
				set value 1.0.0
			}
		}
		if {![info exist arL($type)]} {
			set arL($type) $value
		}
	}
	set arL(changed) [clock format $nowt -format "%Y-%m-%d"]
	set newdata {}
	foreach var [array names arL] {
		append newdata "$var\t$arL($var)\n"
	}
	set enctext [encryptSimple $newdata $key]
	set dst [open $licensefile w]
	fconfigure $dst -encoding binary -translation binary
	puts -nonewline $dst $enctext
	close $dst
}

proc checkClock {} {
	set nowt [clock seconds]
	global userfile
	if {[info exist userfile] && [file exist $userfile]} {
		file stat $userfile filear
		foreach type {ctime mtime atime} {
			if {$nowt < $filear($type)} {
				error "System time incorrect !"
			}
		}
	}
	if {[info exist ::env(TMP)]} {
		set tmpdir [file join $::env(TMP)]
		set files [glob -nocomplain $tmpdir/*]
		if {[llength $files]} {
			foreach file $files {
				if {![catch {file mtime $file} $mtime]} {
					lappend t $mtime
				}
			}
			set last [lindex [lsort $t] end]
			if {$nowt < $last} {
				error "System time incorrect !"
			}
		}
	}
	return
}

proc timeLicense {arrayName} {
	set nowt [clock seconds]
	upvar $arrayName arL
	if {[info exist arL(created)]} {
		set createdt [clock scan $arL(created)]
		if {$nowt < $createdt} {
			error "System time incorrect !"
		}
	}
	if {[info exist arL(changed)]} {
		set changedt [clock scan $arL(changed)]
		if {$nowt < $changedt} {
			error "System time incorrect !"
		}
	}
	if {[info exist arL(term)]} {
		set termt [clock scan $arL(term)]
		warnUser $nowt $termt
		if {$nowt > $termt} {
			error "License file expired on $arL(term)!"
		}
	}
}

proc warnUser {now end} {
	global bar
	set limit [expr 60*60*24*30]
	set diff [expr $end - $now]
	if {$diff < 0} {
		drawbar $bar 0 "Your License is expired !" red
	} elseif {$diff < $limit} {
		set left [expr $diff / (24 * 60 * 60)]
		drawbar $bar 0 "Your License file will expire in $left days !" red
	}
}

proc moveLicense {orifile} {
	set safedir $::Classy::dira(appuser)
	set oridir [file dirname $orifile]
	set safefile $orifile
	if {![string equal $safedir $oridir]} {
#		set message "The License file is not in a safe directory. Shall I move it to a safer one ? ($::Classy::dira(appuser))"
#		set answer [tk_messageBox -icon question -type yesno -message $message]
#		if {[string equal $answer yes]} {
			set safefile [file join $safedir [file tail $orifile]]
			file rename -force $orifile $safefile
#		}
	}
	return $safefile
}

proc createLicense {key} {
	set licensefile [file join $::Classy::appdir License.bin]
	set plaintext "It smells like teen spirit !"
	set enctext [encryptSimple $plaintext $key]
	set dst [open $licensefile w]
	fconfigure $dst -encoding binary -translation binary
	puts -nonewline $dst $enctext
	close $dst
}

proc KeyBin {key} {
#	set keyFile [file join $::Classy::appdir Key.bin]
	set types {{binfile {.bin}}}
	if {[info exist ::tca_base]} {
		set initialdir $::tca_base
	} else {
		set initialdir {}
	}
	set keyFile [tk_getSaveFile -initialdir $initialdir -filetypes $types -parent .selector -initialfile Key.bin]
	if {[string length $keyFile]} {
		set dst [open $keyFile w]
		fconfigure $dst -encoding binary -translation binary
		puts -nonewline $dst [encryptSimple $key]
		close $dst
		return $keyFile
	} else {
		error "Incorrect file name."
	}
}

proc Kget {} {
	upvar Key lKey
	set nil_block1 {\0\f\0\2\d\2\w\0}
	set nil_block2 {nvoyqfdvndf98vfd}
	set lKey(p1) [aes::aes -hex -mode cbc -dir encrypt -key $nil_block1 $nil_block1]
	set lKey(p2) [aes::aes -hex -mode cbc -dir encrypt -key $nil_block2 $nil_block2]
	set lKey(Key) [aes::Init cbc $lKey(p1) $lKey(p2)]
}

proc encryptSimple {plaintext {key {}}} {
	Kget
	if {[string length $key]} {
		set Key(p1) [aes::aes -hex -mode cbc -dir encrypt -key $key $key]
	}
	aes::Reset $Key(p1) $Key(p2)
	set Key(Key) [aes::Init cbc $Key(p1) $Key(p2)]
	set enctext {}
	for {set p 0} {$p < [string length $plaintext]} {incr p 16} {
		set start $p
		set end [expr $p + 15]
		set text [string range $plaintext $start $end]
		while {[string length $text] < 16} {
			append text "\n"
		}
		append enctext [aes::Encrypt $Key(Key) $text]
	}
	return $enctext
}

proc decryptSimple {text {key {}}} {
	Kget
	if {[string length $key]} {
		set Key(p1) [aes::aes -hex -mode cbc -dir encrypt -key $key $key]
	}
	set Key(Key) [aes::Init cbc $Key(p1) $Key(p2)]
	set data [aes::Decrypt $Key(Key) $text]
	return $data
}

proc createKey {} {
	set error 0
	if {[catch {getMAC} keys]} {
		# failed to find proper MAC key
		set message "Failed to find proper computer ID"
		set error 1
	}
	if {[catch {KeyBin [lindex $keys 0]} file]} {
		# failed to create KeyBin file
		set message "Failed to create KeyBin file"
		set error 1
	} else {
		set message "You just created a Key.bin file and saved it somewhere on your computer.\n\nSo, what's next ?\n1. mail this Key.bin file to us (boris.harding@ua.ac.be)\n2. pay for 1 or more licenses\n3. receive your unique License key\n\nKeep in mind that this License key will only work on the computer you created this Key upon."
	}
	if {$error} {
		tk_messageBox -icon error -type ok -message $message
	} else {
		tk_messageBox -icon info -type ok -message $message
	}
	set message "In the meanwhile, you can test the program and have a look and feel by using the demo files that came together with this package."
	if {![checkLicense 1]} {
		set ::startDemo 1
		set config::default(licenseFile) "DeMo"
		saveState
		tk_messageBox -icon info -type ok -message $message -title Demo
		wm title $::mainW "$config::title Demo v$::version - $::exp"
	}
	guide
}


if {0} {

# In case there is no valid License.bin file in the working LGV dir (validKey)
# An encrypted MACkey file will be created by the LGV software (KeyBin)
# This should be sent to the GSF
# GSF side: use the Key.bin file to create a valid License.bin file (createLicense)
# This file should be put in the working LGV dir


}


