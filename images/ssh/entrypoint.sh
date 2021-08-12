#!/bin/bash

function main() {
    echo 'Generating user key'
    su encirsh -c "ssh-keygen -t rsa -f /home/${USER}/.ssh/id_rsa -q -P ''"
    su encirsh -c "cat /home/${USER}/.ssh/id_rsa.pub > /home/${USER}/.ssh/authorized_keys"
    echo 'Key generated and added to authorized_keys'
    cat /home/${USER}/.ssh/id_rsa
    /usr/sbin/sshd -D
}

main
