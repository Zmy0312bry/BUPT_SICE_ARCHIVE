@echo off


echo 请选择对应的仿真波形：
echo 1. counter
echo 2. binary_to_bcd
echo 3. debounce
echo 4. div_100
echo 5. led_select
echo 6. segment7
set /p choice="请输入功能选项（1-6）: "

if "%choice%"=="1" goto counter
if "%choice%"=="2" goto binary_to_bcd
if "%choice%"=="3" goto debounce
if "%choice%"=="4" goto div_100
if "%choice%"=="5" goto led_select
if "%choice%"=="6" goto segment7
echo 输入错误，请输入1-6之间的数字。
goto end

:counter
REM 这里填写counter的代码
iverilog -o "tb_counter.vvp" "./tb/tb_counter.v" "./src/counter.v" "./src/binary_bcd.v" "./src/led_select.v" "./src/segment7.v" "./src/debounce.v" "./src/div_100.v"
vvp "tb_counter.vvp"
gtkwave "tb_counter.vcd"
goto end

:binary_to_bcd
REM 这里填写binary_to_bcd的代码
iverilog -o "tb_binary_bcd.vvp" "./tb/tb_binary_bcd.v" "./src/binary_bcd.v"
vvp "tb_binary_bcd.vvp"
gtkwave "tb_binary_bcd.vcd"
goto end

:debounce
iverilog -o "tb_debounce.vvp" "./tb/tb_debounce.v" "./src/debounce.v"
vvp "tb_debounce.vvp"
gtkwave "tb_debounce.vcd"
goto end

:div_100
iverilog -o "tb_div_100.vvp" "./tb/tb_div_100.v" "./src/div_100.v"
vvp "tb_div_100.vvp"
gtkwave "tb_div_100.vcd"
goto end

:led_select
iverilog -o "tb_led_select.vvp" "./tb/tb_led_select.v" "./src/led_select.v"
vvp "tb_led_select.vvp"
gtkwave "tb_led_select.vcd"
goto end

:segment7
iverilog -o "tb_segment7.vvp" "./tb/tb_segment7.v" "./src/segment7.v"
vvp "tb_segment7.vvp"
gtkwave "tb_segment7.vcd"
goto end

:end
pause
