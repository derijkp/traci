##########adjusting class OptionMenu
Classy::OptionMenu subclass rOptionMenu
rOptionMenu method init {args} {
        private $object var
        super init
        set indicatoron [option get $object indicatorOn IndicatorOn]
        if {[string equal $indicatoron ""]} {set indicatoron 0}
        $object configure -indicatoron $indicatoron
        if {"$args" != ""} {eval $object configure $args}
        return $object
}
rOptionMenu method _mkmenu {} {
        private $object options var
        $object.menu delete 0 end
	set variable [getprivate $object var]
        if ![llength $options(-images)] {
                foreach val $options(-list) {
                        $object.menu add radiobutton -indicatoron 1 -label $val -variable $variable -command [varsubst {object val} {
#                                set [getprivate $object var] $val
                                $object command
                        }]
                }
        } else {
                foreach val $options(-list) image $options(-images) {
                        $object.menu add command -image $image -command [varsubst {object val image} {
                                set [getprivate $object var] $val
                                $object configure -image $image
                                $object command
                        }]
                }
        }
}
