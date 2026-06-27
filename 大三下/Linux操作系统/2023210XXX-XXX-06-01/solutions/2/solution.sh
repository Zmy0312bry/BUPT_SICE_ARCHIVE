#!/bin/bash
# 2. 使用 tr 命令删除所有空格字符
rm -f output.txt

tr -d ' ' < domains.txt > output.txt

cat output.txt
