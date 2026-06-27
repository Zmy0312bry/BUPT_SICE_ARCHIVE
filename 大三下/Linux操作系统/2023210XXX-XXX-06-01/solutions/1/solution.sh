#!/bin/bash
# 1. 两种方式将小写字母替换为大写字母，并重定向到 output.txt
rm -f output.txt

echo "1. 使用 tr 命令" > "output.txt"
cat "linux.txt" | tr 'a-z' 'A-Z' >> "output.txt"

echo "" >> "output.txt"
echo "2. 使用 tr 命令的字符集写法" >> "output.txt"
cat "linux.txt" | tr '[:lower:]' '[:upper:]' >> "output.txt"

cat "output.txt"
