#!/bin/bash

# Source: http://blog.ronnyegner-consulting.de/2009/10/07/useful-asm-scripts-and-queries/

/etc/init.d/oracleasm querydisk -d `/etc/init.d/oracleasm listdisks -d` \
  | cut -f2,10,11 -d" " \
  | perl -pe 's/"(.*)".*\[(.*), *(.*)\]/$1 $2 $3/g;' \
  | while read v_asmdisk v_minor v_major; do \
      v_device=`ls -la /dev | grep " ${v_minor}, *${v_major} " | awk '{print $10}'`;
      echo "ASM disk ${v_asmdisk} based on /dev/${v_device} [${v_minor}, ${v_major}]";
    done

exit
