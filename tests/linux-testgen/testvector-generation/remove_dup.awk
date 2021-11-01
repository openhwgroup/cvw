#!/usr/bin/awk -f

BEGIN{
    old = "first"
}

{
    if($1 != old){
	if(old != "first"){
	    print oldAll
	}
    }
    old=$1
    oldAll=$0
}

END{
    print oldAll
}

