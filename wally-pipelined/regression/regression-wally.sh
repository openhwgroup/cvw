#!/usr/bin/env bash
check_test () {
  output=$(./$1)
  found=$(echo $output | grep -c "$2")
  echo "$found"
}
echo "checking verilator"
verilator_out=$(cd ..; ./lint-wally 2>&1)
[[ -z $verilator_out ]] && echo "verilator passed" || echo "verilator failed"
echo "starting Imperas rv64ic"
sleep 1
exec 3< <(check_test "sim-wally-batch" "All tests ran without failures.")
echo "starting busybear"
sleep 1
exec 4< <(check_test "sim-busybear-batch" "loaded 100000 instructions")
rv64_out=$(cat <&3)
[[ $rv64_out -eq 1 ]] && echo "rv64ic passed" || echo "rv64ic failed"
busybear_out=$(cat <&4)
[[ $busybear_out -eq 1 ]] && echo "busybear passed" || echo "busybear failed"

#wait $(jobs -p)
[[ -z $verilator_out && $rv64_out -eq 1 && $busybear_out -eq 1 ]] && echo "all passed" || echo "not all passed"
