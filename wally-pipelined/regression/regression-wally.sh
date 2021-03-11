#!/usr/bin/env bash
check_test () {
  output=$(timeout 2m ./"$1" 2>/dev/null)
  found=$(echo $output | grep -c "$2")
  echo "$found"
}
echo "-----------------------"
echo "starting all regression tests!"
echo "note: this could take up to 3 minutes to run"
echo "-----------------------"
echo "checking verilator"
verilator_out=$(cd ..; ./lint-wally 2>&1)
[[ -z $verilator_out ]] && echo "verilator passed" || echo "verilator failed"
echo "starting Imperas rv64ic"
sleep 1
exec 3< <(check_test "sim-wally-batch" "All tests ran without failures.")
#echo "starting Imperas rv32ic"
#sleep 1
#exec 5< <(check_test "sim-wally-rv32ic" "All tests ran without failures.")
#echo "starting busybear"
sleep 1
exec 4< <(check_test "sim-busybear-batch" "loaded 100000 instructions")
echo "-----------------------"
echo "waiting for tests to finish..."
echo "-----------------------"
rv64_out=$(cat <&3)
[[ $rv64_out -eq 1 ]] && echo "rv64ic passed" || echo "rv64ic failed"
#rv32_out=$(cat <&5)
#[[ $rv32_out -eq 1 ]] && echo "rv32ic passed" || echo "rv32ic failed"
busybear_out=$(cat <&4)
[[ $busybear_out -eq 1 ]] && echo "busybear passed" || echo "busybear failed"

[[ -z $verilator_out && $rv64_out -eq 1 && $busybear_out -eq 1 ]] && echo "all passed" || echo "not all passed"
#[[ -z $verilator_out && $rv32_out -eq 1 && $rv64_out -eq 1 && $busybear_out -eq 1 ]] && echo "all passed" || echo "not all passed"
