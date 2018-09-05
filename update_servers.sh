#!/bin/bash

sudo sed -i.bak -r 's/(archive|security).ubuntu.com/old-releases.ubuntu.com/g' /etc/apt/sources.list

#also need to remove us. sources
sudo sed -i '/us.old-releases.ubuntu.com/c\' /etc/apt/sources.list
