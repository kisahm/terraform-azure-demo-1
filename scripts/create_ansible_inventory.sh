#!/bin/bash

echo "[master]" > ./inventory
for ip in $(terraform output -json master_node_ips|jq '.'|egrep -v "(\[|\])"|cut -d'"' -f2); do
    echo "$ip ansible_host=$ip" >> ./inventory
done

echo "[worker]" >> ./inventory
for ip in $(terraform output -json worker_node_ips|jq '.'|egrep -v "(\[|\])"|cut -d'"' -f2); do
    echo "$ip ansible_host=$ip" >> ./inventory
done