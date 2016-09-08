#!/bin/bash

fdisk /dev/xvdb <<EOF
o
n
p



w
EOF

