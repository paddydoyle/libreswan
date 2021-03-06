#!/bin/sh

set -eux

base=results
basedir=${HOME}/${base}

testingdir=$(pwd)/testing
utilsdir=$(pwd)/testing/utils
webdir=$(pwd)/testing/web

timestamp=$(date -d @$(git log -n1 --format="%ct") +%Y-%m-%d-%H%M)
gitstamp=$(make showversion)
version=${timestamp}-${gitstamp}
destdir=${basedir}/$(hostname)/${version}

echo ${version} ${destdir}

mkdir -p ${destdir}
log=${destdir}/log


# Rebuild/run; but only if previous attempt didn't crash badly.
for target in distclean kvm-install kvm-retest kvm-shutdown ; do
    # because "make ... | tee bar" does not see make's exit code, use
    # a file as a hack.
    ok=${destdir}/${target}.ok
    if test ! -r ${ok} ; then
	make ${target}
	touch ${ok}
    fi 2>&1 | tee -a ${log}
    # above created file?
    test -r ${ok}
done


# Always sync up the results
(
    cd testing/pluto
    rsync --archive --relative --itemize-changes */OUTPUT ${destdir}
    touch ${destdir}/rsync.ok
) 2>&1 | tee -a ${log}
test -r ${destdir}/rsync.ok


(
    cd ${basedir}/$(hostname)/${version}
    ${utilsdir}/json-results.py */OUTPUT > results.new
    for json in results ; do
	mv ${json}.new ${json}.json
    done
    # So that this directory is imune to later changes, just copy the
    # index page, along with all dependencies.
    cp ${webdir}/i3.html ${destdir}/index.html
    cp -r ${basedir}/js ${destdir}
    cp ${webdir}/*.js ${destdir}/js
    touch ${destdir}/i3.ok
) 2>&1 | tee -a ${log}
test -r ${destdir}/i3.ok


: cd ${basedir}/$(hostname)
# This directory contains no html so generating json isn't very
# useful.
: # ${utilsdir}/json-summary.py --rundir . */table.json > table.new
: # ${utilsdir}/json-graph.py */table.json > graph.new
: mv old to new


(
    cd ${basedir}
    ${webdir}/json-summary.py */*/results.json > summary.new
    for json in summary ; do
	mv ${json}.new ${json}.json
    done
    cp ${webdir}/i1.html ${basedir}/index.html
    cp ${webdir}/*.js ${basedir}/js/
    touch ${destdir}/i1.ok
) 2>&1 | tee -a ${log}
test -r ${destdir}/i1.ok
