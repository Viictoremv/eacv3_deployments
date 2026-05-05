#!/bin/bash
mkdir -p ~/.ssh
cp /mnt/host/.ssh/id_rsa ~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa
