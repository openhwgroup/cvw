# Privileged Test Generators

Create a test generator in this folder with the name testgen-NAME.py. Then, to generate and compile these tests, use:

```bash
sh run.sh NAME
```

For example, for `testgen-CAUSE.py`, we would run `sh run.sh CAUSE`.

This bash file is super basic, so only allows for a single argument after the name.
Provide -sim as the second argument to simulate the compiled tests using wally.

```bash
sh run.sh NAME -sim
```

To compile tests without running them in OVPsim, provide -c as the second argument

```bash
sh run.sh NAME -c
```

The test generator also has a really nice feature that grabs the location of begin_signature after compiling the tests. For example, running `sh run.sh EPC` will output something like this at the end:

```verilog
rv64p = '{
    'rv64p/WALLY-MEPC', '5000',
    'rv64p/WALLY-SEPC', '4000'
};

rv32p = '{
    'rv32p/WALLY-MEPC', '5000',
    'rv32p/WALLY-SEPC', '4000'
};
```