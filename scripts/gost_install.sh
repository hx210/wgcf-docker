#!/bin/bash

local_gost_path="/usr/local/bin/gost"
arch=$(arch | sed s/aarch64/armv8/ | sed s/x86_64/amd64/)

latest=$(curl -sSL "https://api.github.com/repos/ginuerzh/gost/releases/latest" | grep "tag_name" | head -n 1 | cut -d : -f2 | sed 's/[ \"v,]//g')
temp_gost_bin_path="/tmp/gost_laster"

temp_gost_path="${temp_gost_bin_path}.gz"
wget -q -O "${temp_gost_path}" "https://github.com/ginuerzh/gost/releases/download/v$latest/gost-linux-$arch-$latest.gz"
gzip -fd "${temp_gost_path}"
chmod +x ${temp_gost_bin_path}
mv -f ${temp_gost_bin_path} ${local_gost_path}

gost -V
