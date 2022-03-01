for index in {450..500}
do 
    instrs=$(($index*1000000))
    echo "y" | nice -n 5 ./genCheckpoint.sh $instrs 0
done
