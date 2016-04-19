#!/bin/bash

clean() {
    rm -rf /etc/firewalld/direct /etc/firewalld/icmptypes \
           /etc/firewalld/ipsets /etc/firewalld/services \
           /etc/firewalld/zones
}

fail() {
    echo "Test '$1' failed with exit code '$2'"
    exit $2
}

echo "*** This testsuite messes with your firewall settings so ***"
echo "*** do not run it in production environments ***"

sleep 5

basedir="$(readlink -f ${0} | rev | cut -d '/' -f 4- | rev)"

echo "Starting FirewallD server"
# Kill existing one. We need to start the lastest one from the repo.
while true; do
    old_fwd=$(pgrep firewalld)
    if [ "x" != "x$old_fwd" ]; then
        sudo kill $old_fwd > /dev/null 2>&1
    else
        break
    fi
done

clean
sudo $basedir/src/firewalld || exit 1

pushd $basedir/src/tests > /dev/null 2>&1
for x in firewall*.sh firewall*.py; do
    echo "Restarting FirewallD configuration"
    sudo $basedir/src/firewall-cmd -q --complete-reload
    echo "Running test: $x"
    # Pass 'y' to any asked questions
    echo 'y' | sudo ./$x || fail $x $?
done
popd > /dev/null 2>&1

exit 0
