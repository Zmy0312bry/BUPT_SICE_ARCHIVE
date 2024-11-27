@echo off
:: ���iverilog�����Ƿ����
where iverilog >nul 2>&1
if errorlevel 1 (
    echo iverilog������ã���ȷ��iverilog�Ѱ�װ����ӵ�PATH���������С�
    goto end
)
echo ��ѡ���Ӧ�ķ��沨�Σ�
echo 1. div_clk
echo 2. segment7
echo 3. select_disp
echo 4. key_input
echo 5. led_disp
echo 6. led_matrix
echo 7. digi_screen
echo 8. controller
echo 9. beep
echo 10. water_detection
echo 11. debounce

set /p choice="�����빦��ѡ��: "

if "%choice%"=="1" goto div_clk
if "%choice%"=="2" goto segment7
if "%choice%"=="3" goto select_disp
if "%choice%"=="4" goto key_input
if "%choice%"=="5" goto led_disp
if "%choice%"=="6" goto led_matrix
if "%choice%"=="7" goto digi_screen
if "%choice%"=="8" goto controller
if "%choice%"=="9" goto beep
if "%choice%"=="10" goto water_detection
if "%choice%"=="11" goto debounce

echo �������������1-6֮������֡�
goto end

:div_clk
REM ������дdiv_clk�Ĵ���
if not exist "./simulation/div_clk" (
    mkdir "./simulation/div_clk"
)
cd "./simulation/div_clk"
iverilog -o "tb_div_clk.vvp" "../../tests/tb_div_clk.v" "../../components/div_clk.v"
vvp "tb_div_clk.vvp" 
gtkwave "tb_div_clk.vcd"
goto end

:segment7
REM ������дsegment�Ĵ���
if not exist "./simulation/segment7" (
    mkdir "./simulation/segment7"
)
cd "./simulation/segment7"
iverilog -o "tb_segment7.vvp" "../../tests/tb_segment7.v" "../../components/segment7.v"
vvp "tb_segment7.vvp"
gtkwave "tb_segment7.vcd"

:select_disp
REM ������дselect_disp�Ĵ���
if not exist "./simulation/select_disp" (
    mkdir "./simulation/select_disp"
)
cd "./simulation/select_disp"
iverilog -o "tb_select_disp.vvp" "../../tests/tb_select_disp.v" "../../components/select_disp.v"
vvp "tb_select_disp.vvp"
gtkwave "tb_select_disp.vcd"

:key_input
REM ������дkey_input�Ĵ���
if not exist "./simulation/key_input" (
    mkdir "./simulation/key_input"
)
cd "./simulation/key_input"
iverilog -o "tb_key_input.vvp" "../../tests/tb_key_input.v" "../../components/key_input.v"
vvp "tb_key_input.vvp"
gtkwave "tb_key_input.vcd"

:led_disp
REM ������дled_disp�Ĵ���
if not exist "./simulation/led_disp" (
    mkdir "./simulation/led_disp"
)
cd "./simulation/led_disp"
iverilog -o "tb_led_disp.vvp" "../../tests/tb_led_disp.v" "../../components/led_disp.v" "../../components/segment7.v" "../../components/select_disp.v" "../../components/div_clk.v" "../../components/key_pulse.v"
vvp "tb_led_disp.vvp"
gtkwave "tb_led_disp.vcd"

:led_matrix
REM ������дled_matrix�Ĵ���
if not exist "./simulation/led_matrix" (
    mkdir "./simulation/led_matrix"
)
cd "./simulation/led_matrix"
iverilog -o "tb_led_matrix.vvp" "../../tests/tb_led_matrix.v" "../../components/led_matrix.v" "../../components/div_clk.v" "../../components/digi_screen.v"
vvp "tb_led_matrix.vvp"
gtkwave "tb_led_matrix.vcd"

:digi_screen
REM ������дdigi_screen�Ĵ���
if not exist "./simulation/digi_screen" (
    mkdir "./simulation/digi_screen"
)
cd "./simulation/digi_screen"
iverilog -o "tb_digi_screen.vvp" "../../tests/tb_digi_screen.v" "../../components/digi_screen.v"
vvp "tb_digi_screen.vvp"
gtkwave "tb_digi_screen.vcd"

:controller
REM ������дcontroller�Ĵ���
if not exist "./simulation/controller" (
    mkdir "./simulation/controller"
)
cd "./simulation/controller"
iverilog -o "tb_controller.vvp" "../../tests/tb_controller.v" "../../components/controller.v" "../../components/debounce.v"
vvp "tb_controller.vvp"
gtkwave "tb_controller.vcd"

:beep
REM ������дbeep�Ĵ���
if not exist "./simulation/beep" (
    mkdir "./simulation/beep"
)
cd "./simulation/beep"
iverilog -o "tb_beep.vvp" "../../tests/tb_beep.v" "../../components/beep.v" "../../components/div_clk.v"
vvp "tb_beep.vvp"
gtkwave "tb_beep.vcd"

:water_detection
REM ������дwater_detection�Ĵ���
if not exist "./simulation/water_detection" (
    mkdir "./simulation/water_detection"
)
cd "./simulation/water_detection"
iverilog -o "tb_water_detection.vvp" "../../tests/tb_water_detection.v" "../../components/water_detection.v" "../../components/div_clk.v" "../../components/beep.v" "../../components/controller.v" "../../components/led_matrix.v" "../../components/led_disp.v" "../../components/digi_screen.v" "../../components/key_input.v" "../../components/segment7.v" "../../components/select_disp.v" "../../components/kv_map.v" "../../components/debounce.v"
vvp "tb_water_detection.vvp"
gtkwave "tb_water_detection.vcd"

:debounce
REM ������дdebounce�Ĵ���
if not exist "./simulation/debounce" (
    mkdir "./simulation/debounce"
)   
cd "./simulation/debounce"
iverilog -o "tb_debounce.vvp" "../../tests/tb_debounce.v" "../../components/debounce.v"
vvp "tb_debounce.vvp"
gtkwave "tb_debounce.vcd"

:end
