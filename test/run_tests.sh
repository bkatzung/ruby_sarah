#!/bin/sh

# Run the specified tests (or all of them)
for t in ${*:-[0-9]*.rb}
do ruby $t
done
