#########building listbox
Classy::Toplevel subclass ListBox

ListBox method init {args} {
	global exp
	super init
	private $object options
	set top $object
	set target $options(-target)
	set marker $options(-marker)
	set header ""
	if {![info exist ::data::columns_sel]} {
		set columns_sel $::config::columns_sel
	} else {
		set columns_sel $::data::columns_sel
	}
	foreach col $columns_sel {
		if {[info exist config::colname($col)]} {
			set name $config::colname($col)
		} else {
			set name $col
		}
		append header " 0 \"$name\""
	}
	set hsb $top.hs
	set vsb $top.vs
	set tbl $top.t
	set fr $top.buttons
	option add *Tablelist.movableColumns    no
	tablelist::tablelist $tbl \
		-columns $header -stripeheight 0 \
		-labelcommand "$object sortByColumn" \
		-height 15 -width 100 -stretch all -selectmode extended \
		-xscrollcommand [list $hsb set] -yscrollcommand [list $vsb set]
	foreach obj [winfo children $tbl.hdr.t.f] {
		if {[regexp {.c$} $obj]} {continue}
		set text [$obj cget -text]
		if {[inlist $header $text]} {
			balloon $obj listbox,$text
		}
	}
	balloon [$tbl bodypath] listbox,main
	set l [llength $columns_sel]
	for {set i 0} {$i < $l} {incr i} {
		$object.t columnconfigure $i -sortmode dictionary
	}
	scrollbar $top.vs -orient vertical -command [list $tbl yview]
	scrollbar $top.hs -orient horizontal -command [list $tbl xview]
	frame $top.buttons
	button $fr.inactivate -text "Inactivate" -command "$object deactivate selected"
balloon $fr.inactivate listbox,inactivate
	button $fr.activate -text "Activate" -command "$object activate selected"
balloon $fr.activate listbox,activate_sel
#	button $fr.sel2ref -text "SetRef" -command "$object sel2ref"
#balloon $fr.sel2ref listbox,sel2ref
#	button $fr.setall -text "Activate all" -command "$object activate all"
#balloon $fr.setall listbox,activate_all
	button $fr.act2sel -text "Act2Sel" -command "$object show_activated"
balloon $fr.act2sel listbox,act2sel
	button $fr.analyze -text "AnaILS" -command "$object analyzeDialog"
balloon $fr.analyze listbox,anaILS
	button $fr.align -text "Align" -command "$object align"
balloon $fr.align listbox,align
	button $fr.export -text "Export" -command "$object export file"
balloon $fr.export listbox,export
	button $fr.close -text "Close" -command "$object exit"
	wm title $top "Listbox ($marker)"
	grid $tbl -row 1 -column 0 -sticky news
	grid $vsb -row 1 -column 1 -sticky ns
	grid $hsb -row 2 -column 0 -sticky ew
#	grid $fr.sel2ref -row 0 -column 1 
	grid $fr.activate -row 0 -column 2
	grid $fr.inactivate -row 0 -column 3
	grid $fr.act2sel -row 0 -column 4
	grid $fr.analyze -row 0 -column 5
	grid $fr.align -row 0 -column 6
	grid $fr.export -row 0 -column 7
	grid $fr.close -row 0 -column 12
	grid $fr -row 3 -column 0 -sticky we
	grid rowconfigure $top.t 1 -weight 1
	grid columnconfigure $top.t 1 -weight 1
	grid rowconfigure $top 1 -weight 1
	grid rowconfigure $top 0 -weight 0
	grid columnconfigure $top 0 -weight 1
	set bodyTag [$tbl bodytag]
	bind $bodyTag <1> [list $object updateAct %x %y %W]
	bind $bodyTag <3> [list $object centergrid %x %y %W]
	bind $top <MouseWheel> [list $object winscroll $tbl %D]
#	bind $bodyTag <Control-ButtonPress-4> [list $gridW graphbrowser page -1]
#	bind $bodyTag <Control-ButtonPress-5> [list $gridW graphbrowser page +1]
#	bind $bodyTag <ButtonPress-4> [list $gridW graphbrowser index -1]
#	bind $bodyTag <ButtonPress-5> [list $gridW graphbrowser index 1]
	bind $top <Key-Return> [list $object centergrid]
	bind $top <Shift-Key-Up> "[list $::markerbarW marker_select prev]"
	bind $top <Shift-Key-Down> "[list $::markerbarW marker_select next]"
	bind $top <Shift-Key-Left> "[list $::markerbarW marker_select first]"
	bind $top <Shift-Key-Right> "[list $::markerbarW marker_select last]"
	bind $top <Control-c> [list $object export clipboard]
	bind $top <Key-Left> [list $::genoviewerW.g0 scroller home]
	bind $top <Key-Right> [list $::genoviewerW.g0 scroller end]
	bind $top <Key-Up> [list $::genoviewerW.g0 scroller index -1]
	bind $top <Key-Down> [list $::genoviewerW.g0 scroller index 1]
	if {$args != ""} {eval $object configure $args}
	wm protocol $object WM_DELETE_WINDOW [list $object exit]\;return
	Classy::canceltodo $object place
}

proc synchr_ListBox_Grid {{active_index {}}} {
	set active $data::active_genos
	set newactive {}
	set tbl $::listboxW.t
	foreach index [$tbl getcolumn 0] {
		if {[inlist $active $index]} {
			lappend newactive $index
		}
	}
	set ::data::active_genos $newactive
	if {[string length $active_index]} {
		set pos [lsearch $newactive $active_index]
		set active [$::gridW cget -active]
		$::gridW configure -first [expr $pos - $active]
	} else {
		$::gridW refresh
	}
}

ListBox method sortByColumn {args} {
	foreach {tbl col} $args break
	eval tablelist::sortByColumn $args
	synchr_ListBox_Grid
}

ListBox method exit {} {
	wm state $object withdrawn
	guide
}

ListBox addoption -marker {marker Marker {}} {
	Classy::todo $object refresh
	Classy::todo synchr_ListBox_Grid
}

ListBox addoption -target {target Target {}} {
	Classy::todo $object refresh
}

ListBox addoption -nodispl {nodispl Nodispl {}} {
	Classy::todo $object refresh
}

ListBox addoption -active {active Active {}} {
	Classy::todo $object showLine
}

ListBox addoption -pattern {pattern Pattern {}} {
	Classy::todo $object updateMeanH
	Classy::todo $object updatePattern
}

ListBox method updateLayout {marker} {
	if {![string length $marker] || ![info exist ::data::columns_sel]} {return}
	set header ""
	set tbl $object.t
	set marker $::data::active_marker
	foreach col $::data::columns_sel {
		if {[info exist config::colname($col)]} {
			set name $config::colname($col)
		} else {
			set name $col
		}
		append header " 0 \"$name\""
	}
	$tbl configure -columns $header
	foreach obj [winfo children $tbl.hdr.t.f] {
		if {[regexp {.c$} $obj]} {continue}
		set text [$obj cget -text]
		if {[inlist $header $text]} {
			balloon $obj listbox,$text
		} else {
			balloon $obj empty
		}
	}
}

ListBox method updateAct {x y Window} {
	set tbl $object.t
	set row -1
	foreach {tbl x y} [tablelist::convEventFields $Window $x $y] {
		set coord [$tbl containingcell $x $y]
		foreach {row col} [split $coord ,] break
	}
	if {$row < 0} {return}
	switch [$tbl columncget $col -title] {
		Act {
			#
			# Update the image contained in the cell
			#
			set list $data::active_genos
			set index [lindex [$tbl get $row] 0]
			set index [lindex [$tbl get $row] 0]
			if {[lsearch $list $index] < 0} {set text 1} else {set text 0}
			if {$text} {
				# is checked
				set img $::checkedImg
				set newlist [linsert $list $row $index]
			} else {
				# is unchecked
				set img $::uncheckedImg
				set pos [lsearch $list $index]
				set newlist [lreplace $list $pos $pos]
			}
			if {[string equal [lsort -unique $list] [lsort -unique $newlist]]} {return}
			set data::active_genos $newlist
			$tbl cellconfigure $row,$col -image $img
			$object update_checkbox
			synchr_ListBox_Grid
		}
	}
	return
}

ListBox method create_runinfo {} {
	set exp $::exp
	set marker $data::active_marker
	set p $object
	set fr $p.runinfo
	destroy $fr
	if {![winfo exist $fr]} {
		set fr [frame $fr]
	}
	set ns $p.notscored
	if {![info exist ::config::active_type]} {return}
	if {![winfo exist $ns]} {
		frame $ns
		label $ns.label -text {} -font {helvetica 12 bold} -fg red
	}
	set text "Trace Inspector"
#	if {![string length [info command $ns.showAmp]]} {
#		rOptionMenu $ns.showAmp -command "$object ShowColumns" -list {All Controle Test} -textvariable ::config::default(showamp)
#		grid $ns.showAmp -column 0 -sticky e -row 0
#		balloon $ns.showAmp listbox,showamps
#		rOptionMenu $ns.showType -command "$object ShowType" -list {Height Area Dosage} -textvariable ::config::default(showtype)
#		grid $ns.showType -column 2 -sticky e -row 0
#		balloon $ns.showType listbox,showtype
#	}
	$ns.label configure -text $text
	if {![string length $exp]} {
		grid forget $fr
		grid forget $ns
	} else {
		grid forget $fr
		grid $ns.label -column 1 -row 0
		grid $ns -column 0 -row 0 -sticky we -columnspan 2
		grid columnconfigure $ns 1 -weight 1
#		grid columnconfigure $ns 0 -weight 0
	}
}

ListBox method ShowType {args} {
#	if {![string length [info command .settings]]} {return}
	alterDatalist
	$object refresh
}

ListBox method updateMeanH {} {
	set assay $data::active_marker
	if {![info exist data::columns_sel] || [string equal unknown $assay]} {return}
	set pattern $::config::temp(pattern)
	set tbl $object.t
	set colnr [lsearch $data::columns_sel meanH]
	if {$colnr <0} {return}
	set columnpos $data::column(meanH)
	for {set r 0} {$r < [$tbl size]} {incr r} {
		set index [$tbl getcells $r,0]
		if {![info exist data::height($index,$pattern)]} {continue}
		set meanH $data::height($index,$pattern)
		set fillcolor [height2color $meanH]
		$tbl cellconfigure $r,$colnr -text $meanH -bg $fillcolor -fg black
		lset ::data::active_datalist $index $columnpos $meanH
	}
}

ListBox method updatePattern {} {
	set assay $data::active_marker
	if {![info exist data::columns_sel] || [string equal unknown $assay]} {return}
	set pattern $::config::temp(pattern)
	set columns $data::columns_sel
	set tbl $object.t
	set colnr 0
	set amplicons $data::amplicons($assay,all)
	set hide $config::default(hide_nonactive)
	foreach column $columns {
		if {![inlist $amplicons $column]} {incr colnr;continue}
		if {[string equal $column $pattern] || [string equal $pattern All]} {
			if {[string equal $hide Enabled]} {
				$tbl columnconfigure $colnr -background {} -hide 0
			} else {
				$tbl columnconfigure $colnr -background grey80 -hide 0
			}
		} else {
			if {[string equal $hide Enabled]} {
				$tbl columnconfigure $colnr -background {} -hide 1
			} else {
				$tbl columnconfigure $colnr -background {} -hide 0
			}
		}
		incr colnr
	}
}

ListBox method ShowColumns {args} {
	set active_assay $data::active_marker
	if {[string equal $active_assay unknown]} {
		return
	} 
	if {![info exist ::data::amplicons($active_assay,test)]} {
		return
	} 
	set type $::config::default(showamp)
	set tests $::data::amplicons($active_assay,test)
	set controles $::data::amplicons($active_assay,control)
	set all $::data::amplicons($active_assay,all)
	set columns $data::columns_sel
	set tbl $object.t
	set currentstate [grid info $tbl]
	grid forget $tbl
	switch $type {
		Test {
			set loci $tests
		}
		All {
			set loci $all
		}
		Controle {
			set loci $controles
		}
	}
	set colnr 0
	foreach column $columns {
		if {![inlist $all $column]} {incr colnr;continue}
		if {[inlist $loci $column]} {
			$tbl columnconfigure $colnr -hide 0
		} else {
			$tbl columnconfigure $colnr -hide 1
		}
		incr colnr
	}
	eval grid $tbl $currentstate
}

ListBox method activate {type} {
	private $object options
	set tbl $object.t
	switch $type {
		all {
			$tbl selection set 0 end
			$object activate selected
		}
		selected {
			set list $data::active_genos
			set newlist {}
			set selected [$tbl curselection]
			for {set r 0} {$r < [$tbl size]} {incr r} {
				if {[lsearch $selected $r] >=0} {
					lappend newlist [lindex [$tbl get $r] 0]
				}
			}
			if {[string equal $list $newlist]} {return}
			set data::active_genos $newlist
			$tbl selection clear 0 end
			$object update_checkbox
		}
	}
}

ListBox method deactivate {type} {
	private $object options
	set tbl $object.t
	switch $type {
		all {
			$tbl selection clear 0 end
			set data::active_genos ""
			$object update_checkbox
		}
		selected {
			set list $data::active_genos
			set newlist {}
			set selected [$tbl curselection]
			for {set r 0} {$r < [$tbl size]} {incr r} {
				set index [lindex [$tbl get $r] 0]
				if {[inlist $list $index] && ![inlist $selected $r]} {
					lappend newlist $index
				}
			}
			if {[string equal $list $newlist]} {return}
			set data::active_genos $newlist
			$tbl selection clear 0 end
			$object update_checkbox
		}
	}
}

ListBox method export {type} {
	set object $::listboxW
	set text {}
	set tbl $object.t
	switch $type {
		clipboard {
			clipboard clear
			append text [join $data::columns_sel \t]\n
			set selected [$tbl curselection]
			for {set r 0} {$r < [$tbl size]} {incr r} {
				if {[lsearch $selected $r] >=0} {
					set data [$tbl get $r]
					append text [join $data \t]\n
				}
			}
			clipboard append $text
		}
		file {
			lappend text [join $data::columns_sel \t]
			set content [$tbl get 0 end]
			foreach line $content {
				lappend text [join $line \t]
			}
			set initialdir $config::default(datadir)
			set initialfile $data::active_marker.xls
			set types {{Spreadsheet {.xls}}}
			set outFile [tk_getSaveFile -initialdir $initialdir -filetypes $types -parent $tbl -initialfile $initialfile]
			if {[string length $outFile]} {
				set dst [open $outFile w]
				puts $dst [join $text \n]
				close $dst
			}
		}
		default {
			error "This kind of export is not supported."
		}
	}
}

ListBox method copy2clipboard {} {
	clipboard clear
	set text {}
	set tbl $object.t
#	set data::active_genos ""
	set selected [$tbl curselection]
	for {set r 0} {$r < [$tbl size]} {incr r} {
		if {[lsearch $selected $r] >=0} {
			set data [$tbl get $r]
			clipboard append [join $data \t]\n
		}
	}
}

ListBox method update_checkbox {} {
	global uncheckedImg checkedImg
	private $object options
	set target $options(-target)
	set tbl $object.t
	set list [$tbl getcolumns 0]
	set selected $data::active_genos
	set pos [lsearch $::data::columns_sel Act]
	set line 0
	set newlist {}
	foreach ele $list {
		if {[lsearch $selected $ele] >=0} {
			set image $checkedImg
			lappend newlist $ele
		} else {
			set image $uncheckedImg
		}
		if {$pos>=0} {
			$tbl cellconfigure $line,$pos -image $image
		}
		incr line
	}
	if {![string equal [lsort -unique $newlist] [lsort -unique $selected]]} {
		set data::active_genos $newlist
	}
	if {[string length $target]} {
		$target draw
	}
}

ListBox method show_activated {} {
	private $object options
	set tbl $object.t
	set rownr 0
	set selection [list]
	$tbl selection clear 0 end
	foreach r [$tbl getcolumns 0] {
		if {[lsearch $data::active_genos $r] >= 0} {
			lappend selection $rownr
		} 
		incr rownr
	}
	if {![llength $data::active_genos]} {
		$tbl selection set 0 end
	} else {
		$tbl selection set $selection
	}
}

ListBox method centergrid {args} {
	private $object options
	set target $options(-target)
	set tbl $object.t
	if {[string length $args]} {
		foreach {x y Window} $args break
		set x [expr {$x + [winfo x $Window]}]
		set y [expr {$y + [winfo y $Window]}]
		set coord [$tbl containingcell $x $y]
		foreach {row col} [split $coord ,] break
		$tbl selection clear 0 end
		$tbl selection set $row $row
	} else {
		set row [lindex [$tbl curselection] 0]
	}
	set index_list [$tbl getcolumn 0]
	set index [lindex $index_list $row]
	set first [lsearch $::data::active_genos $index]
	if {$first >= 0} {
		$target configure -first $first -active 0
	}
}

ListBox method showLine {} {
	private $object options
	set target $options(-target)
	set active $options(-active)
	if {![string length $active]} {set active 0}
	set first [$target cget -first]
	set active_pos [expr $first + $active]
	set index [lindex $::data::active_genos $active_pos]
	set tbl $object.t
	set rownr 0
	set selection [list]
	$tbl selection clear 0 end
	foreach r [$tbl getcolumns 0] {
		if {[string equal $index $r]} {
			lappend selection $rownr
		} 
		incr rownr
	}
	if {[llength $selection]} {
		$tbl selection set $selection
		$tbl see $selection
	}
}

ListBox method empty {} {
	set tbl $object.t
	$tbl delete 0 end
}

ListBox method sort {{column {}}} {
	set tbl $object.t
	set first_pos [$::gridW cget -first]
	set active_pos [$::gridW cget -active]
	set genos_before $data::active_genos
	set active_index [lindex $genos_before [expr $active_pos + $first_pos]]
	if {[string length $column]} {
		set pos [lsearch $::data::columns_sel $column]
		if {$pos >= 0} {
			$tbl sortbycolumn $pos -$config::default(sortorder)
		}	
	} else {
		set q_pos [$tbl sortcolumn]
		if {$q_pos >= 0} {
			$tbl sortbycolumn $q_pos -[$tbl sortorder]
		} else {
			$object sort sample
		}
	}
	synchr_ListBox_Grid $active_index
}

ListBox method refresh {} {
puts listbox_refresh
	private $object options
	set target $options(-target)
	set marker $options(-marker)
	set exp $::exp
	set assaytype $::config::active_type
	wm title $object "ListBox ($marker)"
	set tbl $object.t
	$object empty
	set datalist [createList $marker]
	$object updateLayout $marker
	$object ShowColumns
#	if {[string length $target]} {
#		$target configure -listbox $tbl
#	}
	set tempindex 0
	if {![info exist data::column(part)]} {return}
	set partcol $data::column(part)
	array unset ::data::part
	Classy::busy
	set l [llength $::data::columns_sel]
	for {set i 0} {$i < $l} {incr i} {
		$object.t columnconfigure $i -sortmode dictionary
	}
	foreach line $datalist {
		set index [lindex $line 0]
		set part [lindex [lindex $data::active_datalist $index] $partcol]
		lappend ::data::part($marker,$part) $index
		$tbl insert end $line
	}
	$object create_runinfo
	$tbl columnconfigure 0 -hide 1
	$object sort
	$object update_checkbox
	$object showLine
	$object updateMeanH
	$object updatePattern
#	$object colorAmplicons
#	$object showRefs
	Classy::busy remove
}

ListBox method colorQ {{ids {}}} {
	set header $data::columns_sel
	set colnr [lsearch $header q]
	set table $::listboxW.t
	if {![string length $ids]} {
		set ids [$table getcolumns 0]
	}
	foreach id $ids {
		set value [fetchVal $id q]
		set fillcolor [value2color $value]
		set row [search_row $id]
		$table cellconfigure $row,$colnr -bg $fillcolor -fg black
	}
}

ListBox method colorH {{ids {}}} {
	set header $data::columns_sel
	set colnr [lsearch $header meanH]
	set table $::listboxW.t
	if {![string length $ids]} {
		set ids [$table getcolumns 0]
	}
	set assay $data::active_marker
	foreach id $ids {
		set value [getMeanH $assay $id]
		set fillcolor [height2color $value]
		set row [search_row $id]
		$table cellconfigure $row,$colnr -bg $fillcolor -fg black
	}
}

ListBox method colorAmplicons {{ids {}}} {
	set active_assay $data::active_marker
	if {![info exist ::data::amplicons($active_assay,test)]} {return}
	set tests $::data::amplicons($active_assay,test)
	set all $::data::amplicons($active_assay,all)
	if {![info exist data::datalist($active_assay)]} {return}
	set datalist $data::datalist($active_assay)
	set table $::listboxW.t
	set header $data::columns_sel
	if {![string length $ids]} {
		set ids [$table getcolumns 0]
	}
	foreach index $ids {
		set row [search_row $index]
		set q [fetchVal $index q]
		set nr 0
		foreach locus $all {
			set colnr [lsearch $header $locus]
			if {$colnr < 0} {continue}
			set value $data::dos($index,$locus)
			foreach {copynr fillcolor linecolor} [value2type $value] break
			if {![string length $q] || [string equal $q {{}}]} {
				$table cellconfigure $row,$colnr -fg black -bg {}
			} elseif {([info exist data::lowreads] && [inlist $data::lowReads $index]) || $q > $config::default(min_score)} {
				$table cellconfigure $row,$colnr -fg gray50 -bg {}
			} else {
				$table cellconfigure $row,$colnr -bg $fillcolor -fg black
			}
			incr nr
		}
	}
}

ListBox method winscroll {widget amount} {
	set lines [expr $amount/(-60)]
	eval $widget yview scroll $lines units
}

ListBox method sel2ref {} {
	set reads {}
	set tbl $object.t
	set selected [$tbl curselection]
	set active_genos {}
	for {set r 0} {$r < [$tbl size]} {incr r} {
		if {[lsearch $selected $r] >=0} {
			lappend active_genos [lindex [$tbl get $r] 0]
		}
	}
	$tbl selection clear 0 end
	foreach geno $active_genos {
		lappend reads [fetchVal $geno gs_read]
	}
	set ::data::controlereads $reads
	createRef
	updateDos
	guide
}

ListBox method ref2sel {} {
	set reads $::data::controlereads
	set active_refs {}
	set tbl $object.t
	set rownr 0
	set ref_rows {}
	$tbl selection clear 0 end
	foreach r [$tbl getcolumns 0] {
		set testread [fetchVal $r gs_read]
		if {[inlist $reads $testread]} {
			lappend ref_rows $rownr
		}
		incr rownr
	}
	$tbl selection set $ref_rows
}

ListBox method showRefs {} {
	set tbl $object.t
	set refs $::data::controlereads
	set row 0
	set header $data::columns_sel
	set default [$tbl cget -font]
	foreach index [$tbl getcolumns 0] {
		set testread [fetchVal $index gs_read]
		if {[inlist $refs $testread]} {
			$tbl rowconfigure $row -font "$default bold"
		} else {
			$tbl rowconfigure $row -font $default
		}
		incr row
	}
}

ListBox method analyzeDialog {} {
	global analyze
	if {![array exist analyze]} {
		if {[string equal Enabled $config::default(reanalyse)]} {
			set analyze(analysed) 1
		} else {
			set analyze(analysed) 0
		}
		if {[string equal Enabled $config::default(restandard)]} {
			set analyze(standard) 1
		} else {
			set analyze(standard) 0
		}
		set analyze(force) 1
	}
	set tw .analyze
	set text {}
	if {[winfo exist $tw]} {
		destroy $tw
	}
	Classy::Dialog $tw -title "ILS Analysis"
#	wm minsize $tw 246 135
	set w [$tw component options]
	set message "The application will now analyse the .fsa files.\nThis could take a few minutes depending on the settings."
	label $w.header -text $message -font {arial 12 bold}
	label $w.selection -text "The files you want to analyze :" -font {arial 10 bold}
	radiobutton $w.radiocac -text "Active reads" -variable config::default(file2analyze) -value active
	radiobutton $w.radiocse -text "Selected reads" -variable config::default(file2analyze) -value selected
	radiobutton $w.radiocal -text "All reads" -variable config::default(file2analyze) -value all
	label $w.settings -text "Settings :" -font {arial 10 bold}
	label $w.endline -text "" -font {arial 10 bold}
#	checkbutton $w.checka -text "Overrule analysed data" -variable analyze(analysed)
	checkbutton $w.checks -text "Overrule standard (can take some time)" -variable analyze(standard)
#	checkbutton $w.checke -text "Overwrite previous .extra files" -variable analyze(force)
	$tw.actions.close configure -text Cancel
	$tw add analyze "Analyze" "destroy $tw;$object analyze"
	grid $w.header -pady 10 -row 0 -sticky n
	grid $w.selection -pady 0 -padx 12 -row 1 -sticky w
	grid $w.radiocac -pady 1 -padx 24 -row 2 -sticky w -columnspan 2
	grid $w.radiocse -pady 1 -padx 24 -row 3 -sticky w -columnspan 2
	grid $w.radiocal -pady 1 -padx 24 -row 4 -sticky w -columnspan 2
	grid $w.settings -pady 3 -padx 12 -row 5 -sticky w
#	grid $w.checka -pady 1 -padx 24 -row 6 -sticky w -columnspan 2
	grid $w.checks -pady 1 -padx 24 -row 7 -sticky w -columnspan 2
#	grid $w.checke -pady 1 -padx 24 -row 8 -sticky w -columnspan 2
	grid $w.endline -pady 5 -padx 12 -row 9 -sticky w
	Classy::todo $tw place
}

ListBox method analyze {} {
	global bar analyze
	private $object options
	set tbl $object.t
	switch $config::default(file2analyze) {
		all {
			set selection [$tbl getcolumns 0]
		}
		selected {
			set selection [$tbl curselection]
		}
		active {
			set selection $data::active_genos
		}
	}
	set files {}
	foreach index $selection {
		lappend files "[file join $::exp_temp [fetchVal $index chromatogram].fsa]"
	}
	Classy::busy
	CreateStandard $files force
	Classy::busy remove
	array unset analyze
	drawbar $bar 0 "Analysis complete" black red 1
	openDir ::exp_temp ::assay_temp
}

ListBox method align {} {
	set pos 0
	set penalty 0
	set diff $config::default(alignwindow)
#	set diff 0.3
	set patterns [.mainw.markerbar.zoom cget -list]
	set assay $::data::active_marker
	foreach pattern $patterns {
		if {[string equal All $pattern]} {continue}
		set columnpos $data::column($pattern)
		set list {}
		foreach key [array names data::score $assay,$pattern,*] {
			set score $data::score($key)
			set list [concat $list $score]
		}
		array unset temp
		array unset belongs
		set pos 0
		set list [lsort $list]
		set names {}
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
#			lappend inrange $p1
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
			set testname [expr round($mean)]
			if {[inlist $names $testname]} {
				set testname [expr $testname + 1]
			}
			lappend $names $testname
			if {[llength $inrange] < 2} {
				set stdev 0
			} else {
				set stdev [dformat "%.3f" [::math::statistics::stdev $inrange]]
			}
			if {!$mean} {set mean 0.0001}
			set proc [expr $stdev / $mean]
			set temp($pos,name) $testname
			set temp($pos,values) $inrange
			set temp($pos,proc) $proc
			set temp($pos,mean) $mean
			set temp($pos,pos) $inpos
			foreach value $inrange {
				lappend belongs($value) $pos
			}
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
		foreach key [array names data::score $assay,$pattern,*] {
			set index [lindex [split $key ,] end]
			set score $data::score($key)
			set newscore {}
			set bins {}
			foreach allel $score {
				set group [lindex $belongs($allel) 0]
				set check $best($group)
				lappend newscore [format "%.1f" $temp($check,mean)]
				set binname $temp($check,name)
				lappend bins $binname
			}
			set data::score($key) $newscore
			lset ::data::active_datalist $index $columnpos [join $bins /]
		}
	}
	set data::datalist($assay) $data::active_datalist
	$object refresh
}


