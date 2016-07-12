
namespace eval ::tcloptics {
    namespace export lens key index lens_compose lens_view lens_set

    proc lens {args} {
        return $args
    }

    proc key {k} {
        return [list key $k]
    }

    proc index {i} {
        return [list index $i]
    }

    proc lens_compose {args} {
        return [concat {*}$args]
    }

    proc lens_view {_d lens} {
        upvar $_d d

        if {[llength $lens] == 0} {
            return $d
        }

        foreach target $lens {
            if {$target == "each"} {
                if {![_islist $d]} {
                    error "lens_view shape incompatibility (expected a list!); attempted to apply lens '$lens' to '$d'."
                }

                set accumulator [list]

                foreach v $d {
                    lappend accumulator [lens_view v [lrange $lens 1 end]]
                }

                return $accumulator
            } elseif {$target == "values"} { 
                if {![_isdict $d]} {
                    error "lens_view shape incompatibility (expected a dict!); attempted to apply lens '$lens' to $d'."
                }

                set accumulator [list]

                dict for {k v} $d {
                    lappend accumulator [lens_view v [lrange $lens 1 end]]
                }

                return $accumulator
            } elseif {$target == "keys"} {
                if {![_isdict $d]} {
                    error "lens_view shape incompatibility (expected a dict!); attempted to apply lens '$lens' to $d'."
                }

                return [dict keys $d]
            } else {
                if {[llength $target] != 2} {
                    error "lens_view encountered an ill-formed lens: '$lens'; specifically, '$target'."
                }

                switch [lindex $target 0] {
                    "index" {
                        if {![_islist $d]} {
                            error "lens_set shape incompatibility (expected a list!); attempted to apply lens '$lens' to '$d'."
                        }

                        set idx [lindex $target 1]
                        set nestedLayer [lindex $d $idx]
                        return [lens_view nestedLayer [lrange $lens 1 end]]
                    }

                    "key" {
                        if {![_isdict $d]} {
                            error "lens_view shape incompatibility (expected a dict!); attempted to apply lens '$lens' to $d'."
                        }

                        set key [lindex $target 1]
                        set nestedLayer [dict get $d $key]
                        return [lens_view nestedLayer [lrange $lens 1 end]]
                    }

                    default {
                        error "lens_view encountered an ill-formed lens: '$lens'; specifically, '$target'."
                    }
                }
            }
        }
    }

    proc lens_set {_d lens v} {
        upvar $_d d

        if {[llength $lens] == 0} {
            return $v
        }

        if {[llength $lens] == 1} {
            set target [lindex $lens 0]

            if {$target == "each"} {
                if {![_islist $d]} {
                    error "lens_set shape incompatibility (expected a list!); attempted to apply lens '$lens' to '$d'."
                }

                set idx 0
                foreach nestedLayer $d {
                    lset d $idx $v
                    incr idx
                }
            } elseif {$target == "values"} {
                if {![_isdict $d]} {
                    error "lens_set shape incompatibility (expected a dict!); attempted to apply lens '$lens' to '$d'."
                }

                dict for {k v2} $d {
                    dict set d $k $v
                }
            } elseif {$target == "keys"} {
                error "lens_set does not support the traversal lens 'keys': '$lens'."
            } else {
                if {[llength $target] != 2} {
                    error "lens_set encountered an ill-formed lens: '$lens'; specifically, '$target'."
                }

                switch [lindex $target 0] {
                    "index" {
                        if {![_islist $d]} {
                            error "lens_set shape incompatibility (expected a list!); attempted to apply lens '$lens' to '$d'."
                        }

                        set idx [lindex $target 1]
                        lset d $idx $v
                    }

                    "key" {
                        if {![_isdict $d]} {
                            error "lens_set shape incompatibility (expected a dict!); attempted to apply lens '$lens' to '$d'."
                        }

                        set key [lindex $target 1]
                        dict set d $key $v
                    }
                }
            }

            return
        }

        foreach target $lens {
            if {$target == "each"} {
                if {![_islist $d]} {
                    error "lens_set shape incompatibility (expected a list!); attempted to apply lens '$lens' to '$d'."
                }

                set idx 0
                foreach nestedLayer $d {
                    lens_set nestedLayer [lrange $lens 1 end] $v
                    lset d $idx $nestedLayer
                    incr idx
                }

                return
            } elseif {$target == "values"} {
                if {![_isdict $d]} {
                    error "lens_set shape incompatibility (expected a dict!); attempted to apply lens '$lens' to '$d'."
                }

                dict for {k v2} $d {
                    set nestedLayer [dict get $d $k]
                    lens_set nestedLayer [lrange $lens 1 end] $v
                    dict set d $k $nestedLayer
                }

                return
            } elseif {$target == "keys"} {
                error "lens_set does not support the traversal lens 'keys': '$lens'."
            } else {
                if {[llength $target] != 2} {
                    error "lens_set encountered an ill-formed lens: '$lens'; specifically, '$target'."
                }

                switch [lindex $target 0] {
                    "index" {
                        if {![_islist $d]} {
                            error "lens_set shape incompatibility (expected a list!); attempted to apply lens '$lens' to '$d'."
                        }

                        set idx [lindex $target 1]
                        set nestedLayer [lindex $d $idx]
                        lens_set nestedLayer [lrange $lens 1 end] $v
                        lset d $idx $nestedLayer
                        return
                    }

                    "key" {
                        if {![_isdict $d]} {
                            error "lens_set shape incompatibility (expected a dict!); attempted to apply lens '$lens' to '$d'."
                        }

                        set key [lindex $target 1]
                        set nestedLayer [dict get $d $key]
                        lens_set nestedLayer [lrange $lens 1 end] $v
                        dict set d $key $nestedLayer
                        return
                    }
                    
                    default {
                        error "lens_set encountered an ill-formed lens: '$lens'; specifically, '$target'."
                    }
                }
            }
        }
    }

    proc _isdict {v} {
        expr {![catch {dict size $v}]}
    }

    proc _islist {v} {
        return [string is list -strict $v]
    }
}

package provide tcloptics

