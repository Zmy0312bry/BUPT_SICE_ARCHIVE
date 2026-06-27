依次运行下面的命令即可。
rtl_sdr -f 432000000 -s 1200000  -p 44 -n 3000000 -g 30 -S data.dat

uv run main.py config.toml -output-dir result

uv run timestamp.py
