#!/usr/bin/tclsh
proc tobc e {
	set e [string map {** ^} $e]
	join [subst [exec echo $e | bc]] ""
}

proc tobinary d { tobc "obase=2;$d" }

proc todecimal b { tobc "ibase=2;$b" }

proc modexp {m e n} {
	set P 1
	foreach bit [split [tobinary $e] ""] {
	if $bit {
	set P [expr {($P*$P*$m)%$n}]
	} else {
		set P [expr {($P*$P)%$n}]
	}
	}
set P
}

proc randomlessthan n {
	set a 1
	foreach d [split $n ""] {append a [expr int(rand()*10)]}
	set result [expr {($a%$n)}]
#	puts "a=$a,result=$result"
	if {$result==0} {return 1} else {return $result}
}


proc millerRabinTrial {n d k} {
	set minusOne [expr {$n-1}] ;# we need to compare to -1
	set a [randomlessthan $n] ;# choose a random a
	set M [modexp $a $d $n] ;# compute ad
	if {$M == 1} {return 1} ;# quit if its already 1
	for {set i 0} {$i<$k} {incr i} {
		if {$M eq $minusOne} {return 1}
		set M [expr {($M*$M)%$n}]
		if {$M eq 1} {return 0} ;# oddity (1)
	}
	if {$M == 1} {return 1} else {return 0} ;# oddity (2)
}

set MAXTEST 20
proc millerRabin n {
	regexp {^(.*1)(0*)$} [tobinary ($n-1)] -> first last
	set d [todecimal $first]
	set k [string length $last]
	for {set i 0} {$i<$::MAXTEST} {incr i} {
	if {[millerRabinTrial $n $d $k]==0} {return 0}
	}
	return 1 ;# probably a prime number
}

proc randomnumber bits {
	for {set i 0} {$i<$bits-2} {incr i} {
	append s [expr int(rand()*2)]
	}
	todecimal 1${s}1 ;# extra 1s to make odd n-bit number
}

proc makeprime bits {
	while {![millerRabin [set p [randomnumber $bits]]]} {}
	set p
}

proc RSAkey bits {
 set p [makeprime $bits]
 set q [makeprime $bits]
 set n [expr $p*$q]
 set phi [expr ($p-1)*($q-1)]
 for {set e 3} {[gcd $e $phi]!=1} {incr e} {}
 set d [invert $e $phi]
 list $n $e $d ;# modulus, public, private exponent!
}

proc Euclid {a n} {
 set equations [list 1 0 $n 0 1 $a] ;# start of algorithm
 set r -1
 while {$r} {
  lassign $equations a b x c d y
  set q [expr {$x/$y}]
  set e [expr {$a-$q*$c}]
  set f [expr {$b-$q*$d}]
  set r [expr {$x-$y*$q}]
  set equations [list $c $d $y $e $f $r]
 }
 lrange $equations 0 2 ;# return A B GCD
}

proc gcd {a n} {lindex [Euclid $a $n] end}
proc invert {a n} {
 set b [lindex [Euclid $a $n] 1] ;# middle element
 expr {$b%$n}
}

proc encrypt {m e n} {modexp $m $e $n}
proc decrypt {c d n} {modexp $c $d $n}

proc testtime {} {
set WIDTH 400
set HEIGHT 400
set fontsize 20
set INIT 400
set END 2000
set INTVL 200
package require Tk
pack  [canvas .c -width $WIDTH -height $HEIGHT]

set n [expr (($END-$INIT)/$INTVL)+1]
set barwidth [expr $WIDTH/$n]
for {set i $INIT} {$i<=$END } {incr i $INTVL} {
 lappend bits $i
 lappend t [lindex [split [time {RSAkey $i} 10] " "] 0]
}
puts $bits
puts $t
set st [lsort -real $t]
set max [lindex $st end]
set min [lindex $st 0]
set range [expr $max-$min]
set fig_height [expr $HEIGHT-2*$fontsize]
puts "n=$n,width=$barwidth,max=$max,min=$min,range=$range"
set count 0
foreach a $bits b $t {
set h [expr int($b*$fig_height/$max)]
set left [expr $count*$barwidth]
set right [expr $left+$barwidth]
puts "$h,$left,$right"
.c create rect $left [expr $fig_height-$h+20] $right [expr $fig_height+20] -fill [format #%06x [expr int($b*0xFFFFFF/$max)]]
.c create tex [expr $left+int($barwidth/2)] [expr $fig_height+20+10] -font {Arial 10} -text $a
.c create tex [expr $left+int($barwidth/2)] [expr $fig_height-$h+10] -font {Arial 10} -text $b
incr count
}

}

proc makesafeprime bits {
  set q [makeprime $bits]
  set p [expr 2*$q+1]
  while {![millerRabin $p] } {
    set q [makeprime $bits]
    set p [expr 2*$q+1]
  }
  set p
}

proc isgenerator {element p} {
  #if {[modexp $element [expr $p-1] $p] == 1} { return 1} else {return 0}
  set q [expr ($p-1)/2]
if {$element == 1} {return 0}
 if {[modexp $element 2 $p]==1} {
	return 0
 } else {
	if {[modexp $element $q $p]==1} {
	return 0
	} else {return 1}
 }
}


proc findgenerator {p} {
#  for {set i 2} {![isgenerator $i $p]} {incr i} {}
  set g [randomlessthan $p]
  while {![isgenerator $g $p]} {
    set g [randomlessthan $p]
  }
  set g
#  set i
}

proc dh bits {
set p [makesafeprime $bits]
puts "p=$p"
set c [modexp [findgenerator $p] 2 $p]
set a [randomlessthan $p]
set b [randomlessthan $p]
set A [modexp $c $a $p]
set B [modexp $c $b $p]
set Ab [modexp $A $b $p]
set Ba [modexp $B $a $p]
return [list $a $b $A $B $Ab $Ba]
#puts "c=$c,a=$a,b=$b,A=$A,B=$B,Ab=$Ab,Ba=$Ba"
}

puts [dh 10]
#set q [expr ($p-1)/2]
#puts [modexp 2 2 $p]
#puts [modexp 2 $q $p]
#puts [modexp 2 2*$q $p]
#set g [randomlessthan $p]
#while {![isgenerator $g $p]} {
#set g [randomlessthan $p]
#}
