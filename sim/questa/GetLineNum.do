# Alec Vercruysse
# 2023-04-12
# Note that the target string is regex, and needs to be double-escaped.
# e.g. to match a (, you need \\(.
proc GetLineNum {fname target} {
    set f [open $fname]
    set linectr 1
    while {[gets $f line] != -1} {
         if {[regexp $target $line]} {
             close $f
             return $linectr
         }
         incr linectr
     }
    close $f
    return -code error \
         [append "target string not found " $target " not found by GetLineNum.do for coverage exclusion in " $fname]
}
