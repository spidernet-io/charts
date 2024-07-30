#!/bin/bash

#echo "----------- start ssh---------"
#service ssh start

echo "=---------- ulimit ----------------"
ulimit -a

echo "----------- env: LD_LIBRARY_PATH ------------------"
echo ${LD_LIBRARY_PATH}

echo "----------- env: PATH ------------------"
echo ${PATH}

echo "----------- env: HPCX_DIR ------------------"
echo ${PATH}

echo "----------- show_gids ------------------"
show_gids

echo "----------- nvidia-smi topo ------------------"
nvidia-smi topo -m || true

echo "----------- wait looply.... ---------- "
/usr/bin/sleep infinity
