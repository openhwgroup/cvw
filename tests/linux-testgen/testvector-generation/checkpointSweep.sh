for index in {0..105}
do 
    instrs=$(((400+$index)*1000000))
    echo "y" | ./genCheckpoint.sh $instrs
done
