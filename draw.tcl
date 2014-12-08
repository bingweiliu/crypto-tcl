#!/usr/bin/tclsh

set WIDTH 680
set HEIGHT 400
set fontsize 20
set INIT 400
set END 2000
set INTVL 200
package require Tk
pack  [canvas .c -width $WIDTH -height $HEIGHT]

#set n [expr (($END-$INIT)/$INTVL)+1]
set barwidth [expr $WIDTH/((($END-$INIT)/$INTVL)+1)]
set t [list 4997755.8 13183430.6 36918907.0 70127162.8 116527761.4 158540846.8 166410210.3 333055108.2 567018311.9]

for {set i $INIT} {$i<=$END } {incr i $INTVL} {
 lappend bits $i
} 

set st [lsort -real $t]
set max [lindex $st end]
set min [lindex $st 0]
set fig_height [expr $HEIGHT-2*$fontsize]

set count 0
foreach a $bits b $t {
set h [expr int($b*$fig_height/$max)]
set left [expr $count*$barwidth]
set right [expr $left+$barwidth]
.c create rect $left [expr $fig_height-$h+20] $right [expr $fig_height+20] -fill [format #%06x [expr int($b*0xFFFFFF/$max)]]
.c create tex [expr $left+int($barwidth/2)] [expr $fig_height+20+10] -font {Arial 10} -text $a
.c create tex [expr $left+int($barwidth/2)] [expr $fig_height-$h+10] -font {Arial 10} -text $b
incr count
}
