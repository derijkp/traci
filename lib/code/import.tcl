proc selector {} {
	set w .selector
	setDemoDir
	if {[winfo exist $w]} {wm state $w normal;raise $w;return}
	toplevel $w -takefocus 1
	wm title $w "Importing data and assay files"
#	label $w.title -text Import -font "Helvetica 12 bold"
	set dataframe [frame $w.dataframe]
		label $dataframe.title -text "Data Directory" -font "Helvetica 12 bold"
		entry $dataframe.entry -width 20 -textvariable exp_temp 
		button $dataframe.button -text Browse... -command "browse exp_temp $dataframe.title"
		label $dataframe.help -text "Browse to select the directory holding your data/chromatgram (.fsa) files." -font "Helvetica 10"
		grid $dataframe.title -columnspan 2 -row 0
		grid $dataframe.entry -row 1 -column 0 -sticky nwse
		grid $dataframe.button -row 1 -column 1
		grid $dataframe.help -row 2 -columnspan 2
		grid columnconfigure $dataframe 0 -weight 1
	set assayframe [frame $w.assayframe]
		label $assayframe.title -text "Assay Description File" -font "Helvetica 12 bold"
		entry $assayframe.entry -width 20 -textvariable assay_temp 
		button $assayframe.button -text Browse... -command "import assay_temp $assayframe.title"
		label $assayframe.help -text "Browse to select the file containing the appropriate assay/binning data." -font "Helvetica 10"
		grid $assayframe.title -columnspan 2 -row 0
		grid $assayframe.entry -row 1 -column 0 -sticky nwse
		grid $assayframe.button -row 1 -column 1
		grid $assayframe.help -row 2 -columnspan 2
	grid columnconfigure $assayframe 0 -weight 1
	set buttonframe [frame $w.buttonframe]
		button $buttonframe.ok -text Ok -command "openDir exp_temp assay_temp $w"
		button $buttonframe.project -text Project -command "selectProject $w;guide"
		balloon $buttonframe.project import,project
#		button $buttonframe.convert -text Convert -command "convert assay_temp"
#		balloon $buttonframe.convert import,convert
		if {[string length [info command $buttonframe.role]]} {catch {$buttonframe.role destroy}}
		rOptionMenu $buttonframe.role -command tca_changerole -list $::tca_roles -textvariable ::tca_role
		trace add variable ::config::role write roleButton
#		button $buttonframe.createkey -text "Create Key" -command "createKey"
#		balloon $buttonframe.createkey import,createkey
		button $buttonframe.cancel -text Close -command "destroy $w;guide"
		grid $buttonframe.role $buttonframe.ok $buttonframe.project $buttonframe.cancel
#	grid $w.title -sticky nwse -columnspan 2
	grid $dataframe -column 0 -sticky nwse
	grid $assayframe -column 0 -sticky nwse
	grid $buttonframe -sticky nwse -columnspan 2
	bind $w <Return> [list $buttonframe.ok invoke]
	$dataframe.entry select range 0 end
	set ::config::role $::config::role
	focus $dataframe.entry
	guide
	wm withdraw $w
	update
	centerWindow $w .mainw
	wm deiconify $w
}

proc roleButton {args} {
	if {![string length [info command .selector.buttonframe.role]]} {return}
	set state $::config::role
	if {![info exist ::roleGrid]} {
		set ::roleGrid [grid info .selector.buttonframe.role]
	}
	if {$state} {
		eval grid .selector.buttonframe.role $::roleGrid
	} else {
		grid forget .selector.buttonframe.role
	}
}

proc titleUpdate {{extraText {}}} {
	if {[info exist ::exp] && [string length $::exp]} {
		set titleExp "- $::exp"
	} else {
		set titleExp ""
	}
	if {[info exist ::assay] && [string length $::assay]} {
		set titleAssay "([file rootname [file tail $::assay]])"
	} else {
		set titleAssay ""
	}
	wm title $::mainW "$config::title - $extraText v$::version $titleExp $titleAssay"
}

proc change_exp {dir} {
	global mainW
	set ::exp $dir
	init
	reload_data
	wm title $mainW "$config::title v$::version - $::exp"
}

proc ReadExtraFile {file} {
	set Efile [file rootname $file].extra
	set src [open $Efile]
	set data [string trimright [read $src] \n]
	close $src
	set data [split $data \t\n]
	return $data
}

proc openDir_old {udirvar ufile {window {}}} {
	global bar
	upvar $udirvar dir
	upvar $ufile file
	if {[info exist ::config::default(licenseFile)] && [string equal DeMo $::config::default(licenseFile)]} {
		set ::startDemo 1
		wm title $::mainW "$config::title Demo v$::version - $::exp"
	}
	set license [checkLicense]
	if {$::startDemo} {
		set demofiles [readChecksum $dir]
		foreach dfile [glob -nocomplain $dir/*fsa] {
			set sum [crc::cksum -filename $dfile]
			if {![inlist $demofiles $sum]} {
				# invalid demo file !
				set error "I'm very sorry but you need to buy a license in order to view and analyse these files."
				tk_messageBox -icon error -type ok -message $error -title "No License"
				return
			}
		}
	} elseif {!$license} {
		return
	}
	if {[string length $dir]} {
		if {[regexp {/} $dir]} {
			set ::config::role 0
			openLocaldir $dir
		} else {
			change_exp $dir
			vwait ::data::datalist(unknown)
		}
	}
	if {[string length $file]} {
		if {[string length $window]} {destroy $window}
		drawbar $bar 0 {Applying assay...} black red 1
		Kget
		set error []
		if {[catch {readAssay $file} data]} {
			tk_messageBox -icon error -type ok -message $data
			return
		} else {
			testassay $data
	                set assays $::data::assayList
	                lappend assays unknown
	                $::markerbarW.marker configure -list $assays
	                $::markerbarW activate_marker [lindex $assays 0]
		}
	} else {
                $::markerbarW activate_marker unknown
	}
	saveState
#	guide
}

proc openDir {udirvar ufile {window {}}} {
	global bar
	upvar $udirvar dir
	upvar $ufile file
	if {[info exist ::config::default(licenseFile)] && [string equal DeMo $::config::default(licenseFile)]} {
		set ::startDemo 1
		titleUpdate Demo
#		wm title $::mainW "$config::title Demo v$::version - $::exp"
	}
#	set license [checkLicense]
#	if {$::startDemo} {
#		set demofiles [readChecksum $dir]
#		foreach dfile [glob -nocomplain $dir/*fsa] {
#			set sum [crc::cksum -filename $dfile]
#			if {![inlist $demofiles $sum]} {
#				# invalid demo file !
#				set error "I'm very sorry but you need to buy a license in order to view and analyse these files."
#				tk_messageBox -icon error -type ok -message $error -title "No License"
#				return
#			}
#		}
#	} elseif {!$license} {
#		return
#	}
	if {[string length $dir]} {
		if {[regexp {/} $dir]} {
			set ::config::role 0
			openLocaldir $dir
		} else {
			change_exp $dir
			vwait ::data::datalist(unknown)
		}
	}
	if {[string length $file]} {
		if {[string length $window]} {destroy $window}
		drawbar $bar 0 {Applying assay...} black red 1
		Kget
		set error []
		if {[catch {readAssay $file} data]} {
			tk_messageBox -icon error -type ok -message $data
			return
		} else {
			testassay $data
	                set assays $::data::assayList
	                lappend assays unknown
	                $::markerbarW.marker configure -list $assays
	                $::markerbarW activate_marker [lindex $assays 0]
		}
	} else {
                $::markerbarW activate_marker unknown
	}
	saveState
#	guide
}

proc openLocaldir {dir} {
	puts $dir
	init
	set ::exp $dir
	wm title $::mainW "$config::title v$::version - [file tail $dir]"
	if {[catch {ImportDir $dir} error]} {
		tk_messageBox -icon error -type ok -message $error
	}
}

proc testDir {dir ext} {
	set files [glob -nocomplain $dir/*$ext]
	return [llength $files]
}

proc browse {udirvar object} {
	upvar $udirvar dirvar
	set value $dirvar
	set initialdir {}
	if {[string length $::config::default(datadir)]} {
		set initialdir $::config::default(datadir)
	}
	set tdirvar [tk_chooseDirectory -initialdir $initialdir -mustexist 1]
	if {![string length $tdirvar] || ![file isdirectory $tdirvar]} {
		return
	}
	set dirvar $tdirvar
	set ::config::default(datadir) $dirvar
	if {[check4Project $dirvar]} {
		return
	}
	set aantal [testDir $dirvar .fsa]
	set text "Data Directory"
	if {$aantal} {
		append text " ($aantal files)"
		$object configure -text $text
	} else {
		append text " (0 files)"
		$object configure -text $text
		tk_messageBox -icon error -message {No files found !} -type ok -parent .selector
	}
	guide
}

proc import {upfile textobject} {
	upvar $upfile importfile
	if {[string length $::config::default(assaydir)]} {
		set initialdir $::config::default(assaydir)
	} else {
		set initialdir {}
	}
	set timportfile [tk_getOpenFile -initialdir $initialdir -title "Assay import" -filetypes {"AssayFile .txt"}]
	set error 0
	if {![string length $timportfile]} {
		return
	}
	set importfile $timportfile
	if {[file exist $importfile]} {
		set ::config::default(assaydir) [file dirname $importfile]
		Kget
		set error [catch {readAssay $importfile} data]
		if {$error} {
			set message "Something went wrong while decrypting the assay file: '[file tail $importfile]'"
			set error 1
		} else {
			if {[catch {testassay $data} message]} {
				set importfile {}
				set error 1
			}
		}
	} else  {
		set message "File not found !"
		set error 1
	}
	if {$error} {
		tk_messageBox -type ok -title "Assay test" -icon error -message $message -parent .selector
		set message "No assay loaded"
	}
	append text "Assay File ($message)"
	$textobject configure -text $text
	guide
}

proc httpProgress {token total current} {
        global bar
        upvar #0 $token state
	if {$total} {
	        set status [expr $current.0/$total*100]
	        drawbar $bar $status "Transferring data: [ expr round($status)] %" black red 2
	} else {
	        drawbar $bar 100 "Transferring data" black red 1
	}
}

proc cookie {} {
	global tca_cookie
	puts "set tca_cookie [list $tca_cookie]"
}

proc KillBar {token} {
        global bar
        drawbar $bar 0 "Loading data into memory..."  black red 1
        load_data $token
	set markerlist $data::markers
	if {[info exist data::active_marker]} {
		set pos [lsearch $markerlist $data::active_marker]
		if {$pos == -1} {set pos 0}
	} else {
		set pos 0
	}
	if {[llength $markerlist]} {
	        $::markerbarW activate_marker [lindex $markerlist $pos]
#		$::gridW refresh
	} else {
		$::listboxW create_runinfo
		$::listboxW refresh
		$::gridW refresh
	}
	::Classy::busy remove
}

proc checkstatus {token} {
	global bar
	if {[info exist ${token}(error)]} {
		set error [set ${token}(error)]
		if {[string length $error]} {
			drawbar $bar 0 "Error..."  black
			tk_messageBox -parent . -message "Error(s): $error" -type ok
		}
	}
}

proc load_data {token {data {}}} {
	set error {}
	global dumpfile bar xrange markerbarW
	if {![string length $data]} {
	        if {[catch {http::data $token} data]} {
			checkstatus $token
		} else {
		        http::cleanup $token
		}
	}
	if {[info exist dumpfile] && ![file exist $dumpfile]} {
		set dst [open $dumpfile w]
		puts $dst $data
		close $dst
	}
        foreach line [split $data \n] {
                eval $line
        }
	if {[string length $error]} {
		drawbar $bar 0 "Error..."  black
		tk_messageBox -parent . -message "Error(s): $error" -type ok
		catch {$::markerbarW.marker configure -list {}}
		set ::data::active_marker {}
		return
	}
        foreach line $data::markerdata {
                foreach {mark val} $line break
                array set data::$mark $val
        }
        foreach read $data::reads {
                array unset array
		if {[info exist data::filedata($read)]} {
		        array set array $data::filedata($read)
		} else {
			continue
		}
                unset data::filedata($read)
		set data::standards($read) $array(standardsize1)
                if {![info exists array(standardscan1)]} {continue}
                set poslist $array(standardscan1)
                set baslist $array(standardsize1)
	        set range_start 0
	        set range_end [lindex $baslist end]
		set xrange($read) [list [lindex $baslist 0] [lindex $baslist end]]
		set poslist [linsert $poslist 0 0]
		set baslist [linsert $baslist 0 0]
		set startpos 0
		set endpos [llength $array(analyseddata1)]
#               catch {vector destroy x$read}
                vector create ::x$read
                x$read set [CreateX $startpos $endpos $baslist $poslist]
                foreach nr {1 2 3 4 5} color {blue green yellow red orange} {
			if {![info exist array(analyseddata$nr)]} {
				set prevnr [expr $nr -1]
	                        set signal $array(analyseddata$prevnr)
			} else {
	                        set signal $array(analyseddata$nr)
			}
                        vector create ::g${read}y${nr}
                        g${read}y${nr} set [CreateY $startpos $endpos $signal]
			vector create ::tempY
			::tempY expr g${read}y$nr>0
			::g${read}y$nr expr ::g${read}y$nr*::tempY
                }
        }
        array unset data::filedata
        $markerbarW refresh
}

proc senddata {page keyvaluelist {command {}}} {
	global tca_cookie tca_host draw bar version
	setroles
	lappend keyvaluelist version
	lappend keyvaluelist [list $version]
	set query [eval ::http::formatQuery $keyvaluelist]
	::Classy::busy
	if {[catch {tca_role} gentli_test]} {
		drawbar $bar 0 "$gentli_test"  red
		catch {unset tca_cookie}
		::Classy::busy remove
	} else {
		set ::config::role 1
		set ::tca_role $gentli_test
		drawbar $bar 0 "Sending request..."  black
		if {[string length $command]} {
			set token [::http::geturl https://$tca_host/test/$page -query $query -command $command -progress httpProgress -headers "Cookie \"sessionkey=$tca_cookie\""]
		} else {
			set token [::http::geturl https://$tca_host/test/$page -query $query -headers "Cookie \"sessionkey=$tca_cookie\""]
		        set data [http::data $token]
		        http::cleanup $token
		        drawbar $bar 0 "Data received..." black
			::Classy::busy remove
			return $data
		}
	}
}

proc assemble_nofiles {} {
	set nofiles {}
	set vectors [vector names ::x*]
	foreach v $vectors {
		lappend nofiles [string trim  $v x::]
	}
	return $nofiles
}

proc setroles {} {
	global bar
	if {![info exist ::tca_roles] || ![string length $::tca_roles]} {
		if {[catch {tca_roles} test]} {
			set ::tca_roles {}
			drawbar $bar 0 "$test" red
			return
		} else {
			set ::tca_roles $test
			set ::tca_role [tca_role]
		}
	}
	if {![info exist ::updateNow]} {set ::updateNow 1}
	if {$::updateNow && [tca_updateneeded]} {
		set message "An update is available on the server.\nTo avoid problems, the application should be closed during the update. Do you want to close the application now ?"
		set answer [tk_messageBox -parent $::mainW -title "Update" -type yesno -message "$message" -icon question]
		if {[string eq $answer yes]} {exit} else {
			set ::updateNow 0
		}
	}
#	.mainw.grid.bar.role configure -list $::tca_roles
}

proc ImportDir {dir} {
	global bar
	Classy::busy
	drawbar $bar 0 {Creating Standard files} black red 1
	set files [glob -nocomplain $dir/*.fsa]
	if {[string equal Enabled $config::default(changeILS)]} {set force force} else {set force ""}
	if {[catch {CreateStandard $files $force} errors]} {
#	if {[catch {CreateStandard $files} errors]} {}
		tk_messageBox -icon error -message $errors -type ok
		Classy::busy remove
		return
	}
	drawbar $bar 0 {Reading Files} black red 1
	set list {}
	set read 0
	set reads {}
	foreach file $files {
		array unset tempar
		set src [open $file]
		fconfigure $src -encoding binary -translation binary
		catch {read $src} data
		close $src
		if {[catch {abi2txt $data} tempdata]} {
			Classy::busy remove
			error "Error while trying to open '$file' (fsa) - $tempdata"
		}
		array set tempar $tempdata
		if {[info exist tempar(analyseddata1)]} {
			set tempar(abi_ana) 1
		}
		if {[info exist tempar(standardscan1)]} {
			set tempar(abi_sta) 1
		}
		if {![info exist tempar(analyseddata1)] || [string equal Enabled $config::default(reanalyse)]} {
			# get data from extra files
			if {[catch {ReadExtraFile $file} tempdata]} {
				Classy::busy remove
				error "Error while trying to open '$file' (extra)"
			}
			array set tempar $tempdata
		}
		set filedata($read) [array get tempar]
		lappend reads $read
		set index $read
		set label [file tail $file]
		set line {}
		foreach col $config::columns_sel {
			if {[string equal $col index]} {
				lappend line $col
				lappend line $read
			} elseif {[string equal $col well]} {
				lappend line $col
				if {[regexp -- $config::default(glob_well) $label match well] && [string length $well]} {
					lappend line $well
				} else {
					lappend line $tempar(tube)
				}
			} elseif {[string equal $col chromatogram]} {
				lappend line $col
				lappend line [file rootname [file tail $file]]
			} elseif {[string equal $col ILS]} {
				lappend line $col
				if {[info exist tempar(pac_sta)] && $tempar(pac_sta)} {
					set value PAC
				} else {
					set value ABI
				}
				lappend line $value
			} elseif {[string equal $col Act]} {
				lappend line $col
				lappend line {}
			} elseif {[string equal $col gs_read]} {
				lappend line $col
				lappend line $read
			} elseif {[string equal $col individual]} {
				lappend line $col
				if {[regexp -- $config::default(glob_individual) $label match individual] && [string length $individual]} {
					lappend line $individual
				} else {
					lappend line $tempar(SpNm1)
				}
			} elseif {[string equal $col str_marker]} {
				lappend line $col
				lappend line unknown
			} else {
				lappend line $col
				lappend line 0
			}
		}
		incr read
		lappend list $line
	}
	set markers unknown
	set experiments custom
	set ::data::datalist(unknown) $list
	array set means {}
	array set column {}
	array set runinfo {}
	array set pooldata [list pools pool1:1]
	array set paneldata {}
	set markerdata [list {unknown {finalpeaks2 {{}} shift2 {{}} label {{}} r_primer {{}} range_min {{}} finalpattern1 {{}} type {{}} finalpattern2 {{}} str_marker {{}} range_max {{}} finaldrops1 {{}} f_primer {{}} upp {{}} shared_project {{}} no1 {{}} mpp1 {{}} mpp2 {{}} notes {{}} maxdist {{}} altpatterns {{}} status {{}} ignore {{}} bins {{}} nopig {{}} marker_set {{}} finalpeaks1 {{}} color * project {{}} force {{}}}}]
	set d {}
	foreach var {experiments reads markers means() datalist() column() filedata() markerdata runinfo() pooldata() paneldata()} {
	        if {[regexp {(.*)\(\)} $var match var]} {
			if {![info exist $var]} {continue}
	                append d "array set data::$var \[list [array get $var]\]\n"
	        } else {
			if {![info exist $var]} {continue}
	                append d "set data::$var \[list [set $var]\]\n"
	        }
	}
	drawbar $bar 0 {Loading data into memory...} black red 1
	load_data null $d
	$::markerbarW activate_marker unknown
	drawbar $bar 0 {Data loaded...} black red 1
	Classy::busy remove
}

proc encryptLocal {file} {
	set src [open $file]
	set plaintext [read $src]
	close $src
	set enctext [encryptSimple $plaintext]
	set outfile [file rootname $file].enc
	set dst [open $outfile w]
	fconfigure $dst -encoding binary -translation binary
	puts -nonewline $dst $enctext
	close $dst
	return $outfile
}

proc readAssay {file} {
	switch [file extension $file] {
		.enc {
			set data [decrypt $file]
		}
		default {
#			set test [senddata encrypt "plaintext test"]
#			if {![string equal $test allowed]} {
#				#unknown file format
#				error "Invalid assay description file format."
#			}
			set src [open $file]
			set data [read $src]
			close $src
		}
	}
	regsub -all "\r" $data {} data
	return $data
}

proc decrypt {encfile} {
	set src [open $encfile]
	fconfigure $src -encoding binary -translation binary
	set text [read $src]
	close $src
	set data [decryptSimple $text]
	regsub -all "\r" $data {} data
	return $data
}

proc convert {upfile} {
	upvar $upfile file
	set question "Do you want to convert the assay file ?"
	set answer [tk_messageBox -parent $::mainW -title "Encryption" -type yesno -message "$question" -icon question]
	if {[string eq $answer yes]} {
		set test [senddata encrypt "plaintext test"]
		if {![string equal $test allowed]} {
			#unknown file format
			error "You are not allowed to perform this action."
		}
		switch [file extension $file] {
			.enc {
				set data [decrypt $file]
				set ext txt
				set type decrypt
			}
			.txt - .xls {
				set data [encrypt $file]
				set ext enc
				set type encrypt
			}
		}
		set outfile "[file rootname $file].$ext"
		if {[file exist $outfile]} {
			set question "May I overwrite the already existing ${type}ed file."
			set answer [tk_messageBox -parent $::mainW -title "$type" -type yesno -message "$question" -icon question]
			if {[string equal no $answer]} {
				set outfile [tk_getSaveFile -initialdir $config::default(assaydir) -filetypes {"ENCfile {.enc .txt}"} -parent $::mainW -initialfile $outfile]
				if {![string length $file]} {
					return
				} else {
#					set outfile [list $outfile]
					set ::config::default(assaydir) [file dirname $outfile]
				}
			}
		}
		set dst [open $outfile w]
		if {[string equal encrypt $type]} {fconfigure $dst -encoding binary -translation binary}
		puts -nonewline $dst $data
		close $dst
		return $outfile
	}
}

proc encrypt {file} {
	catch {encryptGentli $file} enctext
	return $enctext
}

proc encryptGentli {file} {
	set src [open $file]
	set plaintext [read $src]
	close $src
	set enctext [senddata encrypt [list plaintext $plaintext]]
	if {![string length $enctext]} {
		error
	}
	return $enctext
}

proc fetchInfo {file types} {
	set src [open $file]
	fconfigure $src -encoding binary -translation binary
	catch {read $src} data
	close $src
	set vardata [abi2txt $data]
	array set filedata $vardata
	set info {}
	foreach type $types {
		if {[info exist filedata($type)]} {
			lappend info $filedata($type)
		} else {
			lappend info {}
		}
	}
	return $info
}

#foreach a [array names filedata] {
#	set v [lrange $filedata($a) 0 5]
#	puts $a-$v
#}

proc TestStandard {file} {
	set src [open $file]
	fconfigure $src -encoding binary -translation binary
	catch {read $src} data
	close $src
	array set filedata [abi2txt $data]
	set info {}
	if {[info exist filedata(StdF1)] && [string length $filedata(StdF1)]} {
		lappend info $filedata(StdF1)
	} else {
		lappend info none
	}
	if {[info exist filedata(machinemodel)] && [string length $filedata(machinemodel)]} {
		lappend info $filedata(machinemodel)
	} elseif {[info exist filedata(machine)] && [string length $filedata(machine)]} {
		lappend info $filedata(machine)
	} else {
		lappend info none
	}
	if {[info exist filedata(standardsize1)] && [string length $filedata(standardsize1)]} {
		lappend info 1
	} else {
		lappend info 0
	}
	return $info
}

proc test4pac {} {
	global pacdir stds settings
	set pacs [glob -nocomplain $::tcl_dirtcl/apps/pac*]
	set pacdir [lindex [lsort -dictionary $pacs] end]
	package require pkgtools
	pkgtools::init $pacdir pac remove_baseline {}
	lappend ::auto_path [file join $pacdir lib]
	loadsettings
	if {[info exists ::config::settings]} {
		array set settings [array get config::settings]
	}
	load_stds
	if {[info exists ::config::stds]} {
		array set stds [array get config::stds]
	}
}

proc pacextra {file} {
	global currentout currentdir currentfile
	if {[file isdir $file]} {
		set files [glob $file/*.fsa $file/*.fsa.gz $file/*.fsa.zip]
	} else {
		set files [list $file]
	}
	foreach file $files {
		set currentout stdout
		set currentdir [file dir $file]
		set currentfile $file
		pcloaddata $file
	}
}

proc pcloaddata_old {file} {
	global data settings filedata currentfile analyze
	catch {unset data}
	if {![file exists $file]} {
		if {[file exists $file.gz]} {
			set file $file.gz
		} elseif {[file exists $file.zip]} {
			set file $file.zip
		} else {
			error "file $file not found"
		}
	}
	set unzippedfile [tempunzip $file file]
	set data(file) [file tail $file]
	if {[string equal [file extension $file] .txt]} {
		foreach line [split [file_read $unzippedfile] \n] {
			catch {array set data [split $line \t]}
		}
	} else {
		set f [open $unzippedfile "r"]
		fconfigure $f -encoding binary -translation binary
		array set data [abi2txt [read $f]]
		close $f
	}
	set extrafile [file root $file].extra
#	set extra 0
#	if {[file exists $extrafile]} {
#		array set data [split [string trimright [file_read $extrafile] \n] \t\n]
#	} elseif {[file exists $extrafile.zip]} {
#		array set data [split [string trimright [file_read [tempunzip $extrafile.zip]] \n] \t\n]
#	} elseif {[file exists $extrafile.gz]} {
#		array set data [split [string trimright [file_read [tempunzip $extrafile.gz]] \n] \t\n]
#	}
	tempunzip_close
	if {[info exist data(fieldorder)]} {
		set fieldorder [split $data(fieldorder) {}]
	} else {set fieldorder {}}
	set pac_ana 0
	foreach color {1 2 3 4 5} field $fieldorder {
		catch {unset rawdata}
		if {[info exist data(rawdata$color)]} {
			set rawdata $data(rawdata$color)
		} elseif {[info exist data(rawdata$field)]} {
			set rawdata $data(rawdata$field)
		}
		if {[info exists rawdata] && ([string equal Enabled $config::default(reanalyse)] || ![info exists data(analyseddata$color)])} {
			set data(analyseddata$color) [remove_baseline $rawdata 600 200]
			set extra 1
			set pac_ana 1
		}
	}
	if {![info exists data(standardsize1)]} {
		set restandard 1
	} elseif {[info exist analyze(standard)]} {
		if {$analyze(standard)} {
			set restandard 1
		} else {
			set restandard 0
		}
	} elseif {[string equal $config::default(restandard) Enabled]} {
		set restandard 1
	} else {
		set restandard 0
	}
	set pac_sta 0
	if {$restandard} {
		standardscn $file
		set pac_sta 1
		set extra 1
	}
	if {$extra} {pcsaveextra $file data $pac_sta $pac_ana}
	foreach {data(avgstep) data(dif)} $settings(machine,$data(machinemodel)) break
}

proc pcloaddata {file} {
	global data settings filedata currentfile analyze
	catch {unset data}
	if {![file exists $file]} {
		if {[file exists $file.gz]} {
			set file $file.gz
		} elseif {[file exists $file.zip]} {
			set file $file.zip
		} else {
			error "file $file not found"
		}
	}
	set unzippedfile [tempunzip $file file]
	set data(file) [file tail $file]
	if {[string equal [file extension $file] .txt]} {
		foreach line [split [file_read $unzippedfile] \n] {
			catch {array set data [split $line \t]}
		}
	} else {
		set f [open $unzippedfile "r"]
		fconfigure $f -encoding binary -translation binary
		array set data [abi2txt [read $f]]
		close $f
	}
	set extrafile [file root $file].extra
	set extra 0
	tempunzip_close
	if {[info exist data(fieldorder)]} {
		set fieldorder [split $data(fieldorder) {}]
#set fieldorder  {T A G C C}
	} else {set fieldorder {}}
	set pac_ana 0
	foreach color {1 2 3 4 5} field $fieldorder {
		catch {unset rawdata}
		if {[info exist data(rawdata$color)]} {
			set rawdata $data(rawdata$color)
		} elseif {[info exist data(rawdata$field)]} {
			set rawdata $data(rawdata$field)
		}
		if {[info exists rawdata] && ([string equal Enabled $config::default(reanalyse)] || ![info exists data(analyseddata$color)])} {
			set data(analyseddata$color) [remove_baseline $rawdata 600 200]
			set extra 1
			set pac_ana 1
		}
	}
	if {![info exists data(standardsize1)]} {
		set restandard 1
	} elseif {[info exist analyze(standard)]} {
		if {$analyze(standard)} {
			set restandard 1
		} else {
			set restandard 0
		}
	} elseif {[string equal $config::default(restandard) Enabled]} {
		set restandard 1
	} else {
		set restandard 0
	}
	set pac_sta 0
	if {$restandard} {
		standardscn $file
		set pac_sta 1
		set extra 1
	}
	if {$extra} {pcsaveextra $file data $pac_sta $pac_ana}
	foreach {data(avgstep) data(dif)} $settings(machine,$data(machinemodel)) break
}

proc pcsaveextra_old {file dataVar pac_sta pac_ana} {
        upvar $dataVar data
        set extrafile [file root $file].extra
        foreach color {1 2 3 4 5} {
                if {![info exists data(analyseddata$color)]} continue
                set temp {}
                foreach el $data(analyseddata$color) {
                        lappend temp [format %.0f $el]
                }
                append extra "analyseddata$color\t$temp\n"
        }
        if {[info exists data(standardsize1)]} {
                append extra "standardsize1\t$data(standardsize1)\nstandardscan1\t$data(standardscan1)\n"
                append extra "pac_sta\t$pac_sta\n"
                append extra "pac_ana\t$pac_ana\n"
        }
        # append extra StdF1\nst7\n
        set f [open $extrafile w]
        puts -nonewline $f $extra
        close $f
}

proc pcsaveextra {file dataVar pac_sta pac_ana} {
	global currentfile
        upvar $dataVar data
        set extrafile [file root $file].extra
        foreach color {1 2 3 4 5} {
                if {![info exists data(analyseddata$color)]} continue
                set temp {}
                foreach el $data(analyseddata$color) {
                        lappend temp [format %.0f $el]
                }
                append extra "analyseddata$color\t$temp\n"
        }
	if {![string length $data(standardscan1)]} {
		set pac_sta -1
	} elseif {[inlist $::data::otherExtra $currentfile]} {
		set pac_sta 2
	}
        if {[info exists data(standardsize1)]} {
                append extra "standardsize1\t$data(standardsize1)\nstandardscan1\t$data(standardscan1)\n"
                append extra "pac_sta\t$pac_sta\n"
                append extra "pac_ana\t$pac_ana\n"
        }
        # append extra StdF1\nst7\n
        set f [open $extrafile w]
        puts -nonewline $f $extra
        close $f
}

proc standardscn {file} {
	global data currentdir currentfile data resultscan resultsizes
	if {![info exist data(StdF1)]} {
		set data(StdF1) none
	}
	set sizes [getstdsizes]
	if {[llength $sizes] == 0} return
	# checks
	set checked {}
	set checkrounds 2
	for {set testround 1} {$testround <= $checkrounds} {incr testround} {
		set checked [standardscan_mtch $sizes resultsizes resultscan resultscore resultstep $checked]
		lappend ::resultscan_list "${currentfile}\t[join $resultscan \t]"
		set elen [llength $sizes]
		set len [llength $resultsizes]
		if {$len >=2} {break}
	}
	if {$len != $elen} {
		log IND_SER standardmissing 1.0 $currentfile "some peaks in standardscan missed: [list_lremove $sizes $resultsizes]"
	}
	if {$elen == $len || $len <2} {
#	if {($len < 2) || ($len < [expr {$elen-4}])} {}
		log IND_FAT standardmissing 1.0 $currentfile "not enough peaks in standardscan correct, missed: [list_lremove $sizes $resultsizes]"
		set data(standardsize1) {}
		set data(standardscan1) {}
		return
	} elseif {$len != $elen} {
		log IND_SER standardmissing 1.0 $currentfile "some peaks in standardscan missed: [list_lremove $sizes $resultsizes]"
	}
	log IND_INFO standardsizes $resultscore $currentfile $resultsizes
	log IND_INFO standardscan $resultscore $currentfile $resultscan
	log IND_INFO resultstep $resultstep
	set data(standardsize1) $resultsizes
	set data(standardscan1) $resultscan
	set data(avgstep) [expr {round([get resultstep $data(avgstep)])}]
	# save extra
	pacsaveextra $file data
}

proc standardscan_mtch {sizes resultsizesVar resultscanVar resultscoreVar resultstepVar checked} {
	global data stds settings values
	upvar $resultsizesVar resultsizes
	upvar $resultscanVar resultscan
	upvar $resultscoreVar resultscore
	upvar $resultstepVar resultstep
	# set sizes [getstdsizes]
	foreach {data(avgstep) data(dif)} $settings(machine,$data(machinemodel)) break
	set avgstep $data(avgstep)
	set calibname [list calib $data(StdF1) $data(machinemodel)]
	if {[info exists stds($calibname)]} {
		set calibs $stds($calibname)
	} else {
		set calibs $sizes
	}
	set pos 0
	foreach s $sizes {
		if {$s >= 50} break
		incr pos
	}
	if {$pos} {
		set sizes [lrange $sizes $pos end]
		set calibs [lrange $calibs $pos end]
	}
	# find standardscan
	if {![llength $checked]} {
		set colornum $data(Dye#1)
	} else {
		set lanes [lsort -decreasing [array names data DyeN*]]
		foreach lane $lanes {
			set colornum [string index $lane 4]
			if {![inlist $checked $colornum]} {break}
		}
	}
	lappend checked $colornum
	set slen [llength $sizes]
	set values $data(analyseddata$colornum)
	set fpeaks [standrd_peaks $values $sizes $avgstep]
	set peaks_poss [list_subindex $fpeaks 0]
	set flen [llength $fpeaks]
	if {$flen < [expr {$slen-5}]} {
		set resultsizes {}
		set resultscan {}
		set resultscore 1000000
		set resultstep {}
		return $checked
	}
	# find possible steps
	set sendmin [expr {$slen-5}]
	set pendmin [min [expr {$slen-5}] [expr {$flen-5}]]
	set resultscore 1000000
	set resultscan {}
	set resultsizes {}
	set resultstep {}
	set break 0
	for {set sstart 0} {$sstart < 5} {incr sstart} {
		for {set send [expr {$slen-1}]} {$send > $sendmin} {incr send -1} {
			for {set pend [expr {$flen-1}]} {$pend > $pendmin} {incr pend -1} {
				set pstartmax [max [expr {$pend - $slen + 5}] 0]
				for {set pstart 0} {$pstart < $pstartmax} {incr pstart} {
#puts -----
#putsvars sstart send pstart pend sizes calibs fpeaks testscan testsizes teststep
					set score [stdscan_match_one $sizes $calibs $fpeaks $sstart $send $pstart $pend testscan testsizes teststep]
					if {$score < $resultscore} {
						set resultparam [list $sstart $send $pstart $pend]
						set resultscore $score
						set resultstep $teststep
						set resultsizes $testsizes
						set resultscan $testscan
						if {($score < 1.5) || (($sstart > 0) && ($score < 5))} {
							set break 1
							break
						}
					}
				}
				if {$break} break
			}
			if {$break} break
		}
		if {$break || ($resultscore < 5)} break
	}
	return $checked
}

proc testfpeaks {list} {
	global data
#	set top 2500
	set top $::config::default(ILScutoff)
	set onder 0
	set newlist {}
	foreach group $list {
		foreach {size breedte} $group break
		if {$size < $top} {
			incr onder
		} else {
			lappend newlist $group
		}
	}
	if {$onder >= 20} {
		return [takeOtherStandard]
	} else {
		return $list
	}
}

proc takeOtherStandard {} {
	global currentfile
	set files [glob -nocomplain $::exp/*.extra]
	set newfpeaks {}
	if {[llength $files]} {
		set file [lindex $files 0]
		set src [open $file]
		while {![eof $src]} {
			set line [gets $src]
			array set temp [split $line \t]
		}
		close $src
		foreach size $temp(standardscan1) {
			lappend newfpeaks [list $size 100]
		}
		lappend ::data::otherExtra $currentfile
	} else {
		#no file found yet !
		lappend ::data::nootherExtra $currentfile
	}
	return $newfpeaks
}

proc standrd_peaks {values sizes avgstep} {
        global data
        set avgstep $data(avgstep)
        set slen [llength $sizes]
        # find first peaks (blob)
        set cvalues [convolve $values $avgstep 0]
        foreach noise {100 50 40} {
                set fpeaks [bot_fpeaks $cvalues $noise]
                if {[llength $fpeaks] >= $slen} break
        }
        set len [llength $fpeaks]
        if {!$len} {return {}}
        # take broadest peak as start blob
        set sfpeaks [lsort -integer -index 2 -decreasing $fpeaks]
        set peak [lindex $sfpeaks 0]
        set pos [lsearch $fpeaks $peak]
        # if not good, try second broadest
        if {[expr {[llength $fpeaks] - $pos}] < [expr {$slen-2}]} {
                set peak [lindex $sfpeaks 1]
                set pos [lsearch $fpeaks $peak]
                # if not good, try on height
                if {[expr {[llength $fpeaks] - $pos}] < [expr {$slen-2}]} {
                        set sfpeaks [lsort -real -index 1 -decreasing $fpeaks]
                        set peak [lindex $sfpeaks 0]
                        # if still not good, just take first
                        set peak [lindex $fpeaks 0]
                        if {[expr {[llength $fpeaks] - $pos}] < [expr {$slen-2}]} {
                                set sfpeaks [lsort -real -index 1 -decreasing $fpeaks]
                                set peak [lindex $sfpeaks 0]
                        }
                }
        }
        # median peak width
        set mw [median [list_subindex $fpeaks 2]]
        # find peaks starting after blob
#       set size [lindex $sizes 0]
#       set shift [min [max [expr {$size-30}] 5] 10]
#       set start [expr {[lindex $peak 0] + [expr {[lindex $peak 2]/2}] + ($shift * $avgstep)}]
        set start [expr {[lindex $peak 0]+[lindex $peak 2]/2}]
        foreach cutoff 50 {
                set fpeaks [fpeaks $values $cutoff $start $mw]
                if {[llength $fpeaks] >= $slen} break
        }
	set fpeaks [testfpeaks $fpeaks]
        set len [llength $fpeaks]
        set slen [llength $sizes]
        if {$len > [expr {$slen+1}]} {
                set fpeaks [lsort -index 1 -decreasing -real $fpeaks]
                set mpeak [lindex $fpeaks [expr {$slen*2/3}]]
                set min [max [expr {[lindex $mpeak 1]*0.3}] 50]
                set pos $slen
                for {} {$pos < $len} {incr pos} {
                        set h [lindex [lindex $fpeaks $pos] 1]
                        if {$h < $min} break
                }
                set fpeaks [lrange $fpeaks 0 [expr {$pos-1}]]
                set fpeaks [lsort -index 0 -integer $fpeaks]
        }
        return $fpeaks
}

proc addStandard_dialog {standard list} {
	set ::answer {}
	set parent [checkParent $::mainW]
	set top [toplevel .addstandard]
	wm title $top "Adding Standard"
	set frame [frame $top.frame]
	label $frame.header -text "Unknown Standard: " -font "helvetica 12 bold" -fg black
	label $frame.name -text "$standard" -font "helvetica 12 bold" -fg red
	grid $frame.header -sticky e -row 0 -column 0
	grid $frame.name -sticky w -row 0 -column 1
	label $frame.help -text {
The internal lane standard used is not yet defined.
Therefore, you should enter all reference peaks from this standard in the entry box below.
You can use the known standards as template by selecting one from the list.
	} -font "helvetica 10" -fg black
	grid $frame.help -row 1 -columnspan 2 -sticky nwse
	label $frame.like -text "Known standards :"
	catch {$frame.listbox destroy}
	rOptionMenu $frame.listbox -list $list -command test -text "Click me"
	grid $frame.like -sticky e -row 2 -column 0
	grid $frame.listbox -sticky w -row 2 -column 1
	set ::template {}
	entry $frame.entry -width 80 -textvariable ::template
	grid $frame.entry -columnspan 2
	grid $frame
	set buttonframe [frame $top.buttonframe]
	button $buttonframe.ok -text Add -command "set ::answer add;addStandard \"$standard\";destroy $top"
	button $buttonframe.cancel -text Cancel -command "set ::answer cancel;destroy $top"
	grid $buttonframe.ok $buttonframe.cancel
	grid $buttonframe
	wm withdraw $top
	update
	centerWindow $top $parent
	wm deiconify $top
	vwait ::answer
	return $::answer
}

proc addStandard {name} {
	global stds
	set ::config::stds([list sizes $name]) $::template
	set stds([list sizes $name]) $::template
	saveState
}

proc test {standard} {
	global stds
	set name [list sizes $standard]
	set value $stds($name)
	set value [string trim $value]
	set value [string trim $value \t]
	set ::template $value
}

proc test4Machine {machine} {
	global settings
	set names {}
	foreach a [array names settings] {
		foreach {t n} $a break
		if {![string equal $t machine]} {continue}
		lappend names $n
	}
	if {[inlist $names $machine]} {
		return
	} else {
		addMachine $machine
	}
}

proc addMachine {name} {
	global settings
	set ::config::settings(machine,$name) "6 3"
	set settings(machine,$name) "6 3"
	saveState
}

proc test4Standard {standard} {
	global stds
	set names {}
	foreach a [array names stds] {
		foreach {t n m} $a break
		if {![string equal $t sizes]} {continue}
		lappend names $n
	}
	if {[inlist $names $standard] && ![string equal $config::default(changeILS) Enabled]} {
#	if {[inlist $names $standard]} {}
		return [list known $names]
	} else {
		return [list unknown $names]
	}
}

proc log {args} {
	global currentdir currentout
	puts [join $args \t]
	puts $currentout $currentdir\t[join $args \t]
}

proc CreateStandard_old {files {force {}}} {
	global bar pacdir analyze
	set nr 1
	set first 1
	set forced_standards {}
	foreach file $files {
		set proc [expr $nr*100/[llength $files]]
		drawbar $bar $proc "Creating Standard files: $nr/[llength $files]" black red 1
		if {[string length $force] || ![file exist "[file rootname $file].extra"]} {
			if {$first} {
				test4pac
				set first 0
			}
			foreach {standard machine standardsize} [TestStandard $file] break
			if {!$standardsize} {
				set restandard 1
			} elseif {[info exist analyze(standard)]} {
				if {$analyze(standard)} {
					set restandard 1
				} else {
					set restandard 0
				}
			} elseif {[string equal $config::default(restandard) Enabled]} {
				set restandard 1
			} else {
				set restandard 0
			}
			if {$restandard} {
				foreach {type list} [test4Standard $standard] break
				if {[string equal $type unknown] && ![inlist $forced_standards $standard]} {
					set ::template {}
					while {![string length $::template]} {
						set answer [addStandard_dialog $standard $list]					
						if {![string equal add $answer]} {
							error "Action canceled by user."
						}
					}
					lappend forced_standards $standard
				}
			}
			test4Machine $machine
			if {[catch {pacextra $file} message]} {
				error "Error while creating '.extra' files:\n$message"
			}
		}
		incr nr
	}
	if {[llength [array names errors]]} {
		error [array get errors]
	}
}

proc CreateStandard {files {force {}}} {
	global bar pacdir analyze
	set nr 1
	set first 1
	set forced_standards {}
	set ::data::otherExtra {}
	set ::data::nootherExtra {}
	set parent .mainw
	foreach file $files {
		set proc [expr $nr*100/[llength $files]]
		drawbar $bar $proc "Creating Standard files: $nr/[llength $files]" black red 1
		if {[string length $force] || ![file exist "[file rootname $file].extra"]} {
			if {$first} {
				test4pac
				set first 0
			}
			foreach {standard machine standardsize} [TestStandard $file] break
			if {!$standardsize} {
				set restandard 1
			} elseif {[info exist analyze(standard)]} {
				if {$analyze(standard)} {
					set restandard 1
				} else {
					set restandard 0
				}
			} elseif {[string equal $config::default(restandard) Enabled]} {
				set restandard 1
			} else {
				set restandard 0
			}
			if {$restandard} {
				foreach {type list} [test4Standard $standard] break
				if {[string equal $type unknown] && ![inlist $forced_standards $standard]} {
					set ::template {}
					while {![string length $::template]} {
						set answer [addStandard_dialog $standard $list]					
						if {![string equal add $answer]} {
							error "Action canceled by user."
						}
					}
					lappend forced_standards $standard
				}
			}
			test4Machine $machine
			if {[catch {pacextra $file} message]} {
				error "Error while creating '.extra' files:\n$message"
			}
		}
		incr nr
	}
	if {[llength $::data::otherExtra]} {
		set message "One or more '.fsa' files contain incorrect Internal Lane Standard (ILS) data.\nIn order to give you some impression of the results, the ILS data has been taken from one of the other '.fsa' files. The ILS status of each file can be checked in the ListBox window."
		tk_messageBox -message $message -icon info -type ok -title "ILS issues" -parent $parent
		if {[llength $::data::nootherExtra]} {
#			set message "One or more '.fsa' files could not be analysed..."
#			tk_messageBox -message $message -icon info -type ok -title "ILS issues" -parent $parent
			CreateStandard $::data::nootherExtra
		}
	}
	if {[llength [array names errors]]} {
		error [array get errors]
	}
}

proc globRef {{auto 0}} {
	set tbl $::listboxW.t
	set refs {}
	foreach r [$tbl getcolumns 0] {
		foreach {testind testread} [fetchVal $r {individual gs_read}] break
		set testind [fetchVal $r individual]
		if {[regexp -- $config::default(glob_reference) $testind]} {
			lappend refs $testread
		}
	}
	if {$auto && [llength $refs] < 10} {
		set ::data::controlereads $refs
		createRef
	} elseif {!$auto} {
		set ::data::controlereads $refs
		if {[llength $refs] > 10} {
			set answer [tk_messageBox -message "More than 10 reference reads found. Is this correct?" -icon question -type yesno -title "Globbing references"]
			if {[string equal $answer no]} {return}
		}
		createRef
		updateDos
	}
}

proc createChecksum {folder} {
	set fileto [file join $folder "DONTDELETEME"]
	if {![file exist $fileto]} {return}
	set sums {}
	foreach file [glob -nocomplain $folder/*fsa] {
		lappend sums [crc::cksum -filename $file]
	}
	set enctext [encryptSimple $sums]
	set dst [open $fileto w]
	fconfigure $dst -encoding binary -translation binary
	puts -nonewline $dst $enctext
	close $dst
}

proc readChecksum {folder} {
	set fileto [file join $folder "DONTDELETEME"]
	if {![file exist $fileto]} {return}
	set src [open $fileto]
	fconfigure $src -encoding binary -translation binary
	set text [read $src]
	close $src
	if {[catch {decryptSimple $text} data]} {
		error "Error while trying to read democheck file."
	}
	return $data
}

proc standardscn_old {file} {
	global data currentdir currentfile data resultscan resultsizes
	set sizes [getstdsizes]
	if {[llength $sizes] == 0} return
	# checks
	set checked {}
	set checkrounds 2
	for {set testround 1} {$testround <= $checkrounds} {incr testround} {
		set checked [standardscan_mtch $sizes resultsizes resultscan resultscore resultstep $checked]
		lappend ::resultscan_list "${currentfile}\t[join $resultscan \t]"
		set elen [llength $sizes]
		set len [llength $resultsizes]
		if {$len >=2} {break}
	}
	if {($len < 2) || ($len < [expr {$elen-4}])} {
		log IND_FAT standardmissing 1.0 $currentfile "not enough peaks in standardscan correct, missed: [list_lremove $sizes $resultsizes]"
		set data(standardsize1) {}
		set data(standardscan1) {}
		return
	} elseif {$len != $elen} {
		log IND_SER standardmissing 1.0 $currentfile "some peaks in standardscan missed: [list_lremove $sizes $resultsizes]"
	}
	log IND_INFO standardsizes $resultscore $currentfile $resultsizes
	log IND_INFO standardscan $resultscore $currentfile $resultscan
	log IND_INFO resultstep $resultstep
	set data(standardsize1) $resultsizes
	set data(standardscan1) $resultscan
	set data(avgstep) [expr {round([get resultstep $data(avgstep)])}]
	# save extra
	pacsaveextra $file data
}

proc standardscan_mtch_old {sizes resultsizesVar resultscanVar resultscoreVar resultstepVar checked} {
	global data stds settings values
	upvar $resultsizesVar resultsizes
	upvar $resultscanVar resultscan
	upvar $resultscoreVar resultscore
	upvar $resultstepVar resultstep
	# set sizes [getstdsizes]
	foreach {data(avgstep) data(dif)} $settings(machine,$data(machinemodel)) break
	set avgstep $data(avgstep)
	set calibname [list calib $data(StdF1) $data(machinemodel)]
	if {[info exists stds($calibname)]} {
		set calibs $stds($calibname)
	} else {
		set calibs $sizes
	}
	set pos 0
	foreach s $sizes {
		if {$s >= 50} break
		incr pos
	}
	if {$pos} {
		set sizes [lrange $sizes $pos end]
		set calibs [lrange $calibs $pos end]
	}
	# find standardscan
	if {![llength $checked]} {
		set colornum $data(Dye#1)
	} else {
		set lanes [lsort -decreasing [array names data DyeN*]]
		foreach lane $lanes {
			set colornum [string index $lane 4]
			if {![inlist $checked $colornum]} {break}
		}
	}
	lappend checked $colornum
	set slen [llength $sizes]
	set values $data(analyseddata$colornum)
	set fpeaks [standard_peaks $values $sizes $avgstep]
	set peaks_poss [list_subindex $fpeaks 0]
	set flen [llength $fpeaks]
	if {$flen < [expr {$slen-5}]} {
		set resultsizes {}
		set resultscan {}
		return $checked
	}
	# find possible steps
	set sendmin [expr {$slen-5}]
	set pendmin [min [expr {$slen-5}] [expr {$flen-5}]]
	set resultscore 1000000
	set resultscan {}
	set resultsizes {}
	set resultstep {}
	set break 0
	for {set sstart 0} {$sstart < 5} {incr sstart} {
		for {set send [expr {$slen-1}]} {$send > $sendmin} {incr send -1} {
			for {set pend [expr {$flen-1}]} {$pend > $pendmin} {incr pend -1} {
				set pstartmax [max [expr {$pend - $slen + 5}] 0]
				for {set pstart 0} {$pstart < $pstartmax} {incr pstart} {
					set score [stdscan_match_one $sizes $calibs $fpeaks $sstart $send $pstart $pend testscan testsizes teststep]
					if {$score < $resultscore} {
						set resultparam [list $sstart $send $pstart $pend]
						set resultscore $score
						set resultstep $teststep
						set resultsizes $testsizes
						set resultscan $testscan
						if {($score < 1.5) || (($sstart > 0) && ($score < 5))} {
							set break 1
							break
						}
					}
				}
				if {$break} break
			}
			if {$break} break
		}
		if {$break || ($resultscore < 5)} break
	}
	return $checked
}



