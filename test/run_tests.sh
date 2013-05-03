#!/bin/sh

export RUBYLIB=../lib

# Run the specified tests (or all of them)
for t in ${*:-[0-9]*.rb}
do ruby $t
done
