#!/usr/bin/env bash
check_test () {
  output=$(./$1)
  found=$(echo $output | grep -c "$2")
  echo "$found"
}
echo "starting Imperas rv64ic"
coproc rv64 {(check_test "sim-wally-batch" "All tests ran without failures.")}
echo "starting busybear"
coproc busybear {(check_test "sim-busybear-batch" "loaded 100000 instructions")}
IFS= read -r -d '' -u "${rv64[0]}" rv64_out
[[ $rv64_out -eq 1 ]] && echo "rv64ic passed" || echo "rv64ic failed"
IFS= read -r -d '' -u "${busybear[0]}" busybear_out
[[ $busybear_out -eq 1 ]] && echo "busybear passed" || echo "busybear failed"

#wait $(jobs -p)
[[ $rv64_out -eq 1 && $busybear_out -eq 1 ]] && echo "all passed" || echo "not all passed"
