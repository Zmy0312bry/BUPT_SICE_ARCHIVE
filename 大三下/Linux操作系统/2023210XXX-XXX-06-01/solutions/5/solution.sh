#!/bin/bash
# 5: 统计 rfc2460.txt 文件中英文单词出现次数，并从高到低列出前30个单词及出现次数
rm -rf output.txt

cat rfc2460.txt \
  | tr -s '[:space:]' '\n' \
  | tr -d '[:punct:]' \
  | grep -E '^[a-zA-Z]+$' \
  | tr '[:upper:]' '[:lower:]' \
  | sort \
  | uniq -c \
  | sort -rn \
  | head -30 > "output.txt"

cat "output.txt"
