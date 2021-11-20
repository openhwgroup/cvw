for index in {89..181}
do 
    instrs=$(($index*1000000))
    echo "y" | nice -n 5 ./genCheckpoint.sh $instrs
done
