##########building ColorButton
Widget subclass ColorButton

ColorButton method init {args} {
	super init
	private $object options
	button $object.b  -command [subst {$object push}] -highlightthickness 3 -width 1 -borderwidth 2
balloon $object.b colorbutton
	grid $object.b -sticky nwse
	grid columnconfigure $object 0 -weight 1
	grid rowconfigure $object 0 -weight 1
}

ColorButton addoption -relief {relief Relief {raised}} {
	Classy::todo $object refresh
}

ColorButton addoption -color {color Color {}} {
	Classy::todo $object refresh
}

ColorButton addoption -target {target Target {}} {
	Classy::todo $object refresh
}

ColorButton addoption -incolor {incolor InColor {grey}} {
	Classy::todo $object refresh
}

ColorButton method refresh {} {
	private $object options
	set relief $options(-relief)
	set incolor $options(-incolor)
	set colorname $options(-color)
	set initial [string toupper [string index $colorname 0]]
	set color [colorname2color $options(-color)]
	if {[string length $color]} {
		append todo " -highlightbackground $color"
	}
	if {[string length $relief]} {
		switch $relief {
			raised {
				append todo " -bg $incolor -activebackground $incolor -text $initial"
			}
			sunken {
				append todo " -bg $color -activebackground $color -text {}"
			}
		}
		append todo " -relief $relief"
	}
	eval $object.b configure $todo
}

ColorButton method push_new {args} {
	private $object options
	set target  $options(-target)
	if {![string length $target]} {
		return
	}
	set grids [winfo children $target]
	set color $options(-color)
	switch $options(-relief) {
		raised {
			$object configure -relief sunken
			foreach grid $grids {
				if {![string length [grid info $grid]]} {continue}
				set colors [lindex [$grid configure -colors] end]
				if {[lsearch $colors $color]<0} {lappend colors $color}
				$grid configure -colors $colors
			}
		}
		sunken {
			$object configure -relief raised
			foreach grid $grids {
				if {![string length [grid info $grid]]} {continue}
				set colors [lindex [$grid configure -colors] end]
				if {[lsearch $colors $color]>=0} {
					set pos [lsearch $colors $color]
					set colors [lreplace $colors $pos $pos]
					$grid configure -colors $colors
				}
			}
		}
	}
}

ColorButton method push {args} {
	private $object options
	set target  $options(-target)
	if {![string length $target]} {
		return
	}
	set grids [winfo children $target]
	set color $options(-color)
	set currentColors [$::gridW cget -colors]
	if {[string equal all $currentColors]} {set currentColors {blue green yellow red orange}}
	switch $options(-relief) {
		raised {
			# activate color
			$object configure -relief sunken
			lappend currentColors $color
		}
		sunken {
			# deactivate color
			$object configure -relief raised
			set pos [lsearch $currentColors $color]
			set currentColors [lreplace $currentColors $pos $pos]
		}
	}
	$::gridW configure -colors $currentColors
}

