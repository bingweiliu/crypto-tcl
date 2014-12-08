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
proc makesafeprime bits {
  set q [makeprime $bits]
  set p [expr 2*$q+1]
  while {![millerRabin $p] } {
    set q [makeprime $bits]
    set p [expr 2*$q+1]
  }
  return $p
}

#set p [makeprime 5]
set p 14
puts "p=$p"
for {set i 2} {$i<$p } {incr i} {
  set powerlist {}
  lappend powerlist 1 $i
  for {set j 2} {$j<$p } {incr j} {
  set power [expr $i**$j%$p]
  if {$power==1} {
  break
  } else {
  lappend powerlist $power
  }

  }
 puts "power of $i: $powerlist"
  set order [llength $powerlist]
  if {$order==$p-1} {lappend generator $i}
}
#puts "generators:$generator"
