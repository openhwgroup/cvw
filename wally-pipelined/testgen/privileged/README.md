# Privileged Test Generators

Create a test generator in this folder with the name testgen-NAME.py. Then, to generate and compile these tests, use

```bash
sh run.sh NAME
```

For example, for `testgen-CAUSE.py`, we would run `sh run.sh CAUSE`.

Provide -sim as the second argument to simulate the compiled tests using wally.

```bash
sh run.sh NAME -sim
```