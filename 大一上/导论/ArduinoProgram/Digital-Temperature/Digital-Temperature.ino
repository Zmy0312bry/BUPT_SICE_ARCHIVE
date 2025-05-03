#include "U8glib.h"
U8GLIB_SSD1306_128X64 u8g(U8G_I2C_OPT_NONE);
#define setFont_L u8g.setFont(u8g_font_7x13)
unsigned int tempMin = 10; //亮灯温度
unsigned int tempMax = 25; //报警温度
void setup( ) {
Serial.begin(9600); //串口初始化
analogReference(INTERNAL); //调用板载1.1V基准源
pinMode(11, OUTPUT);
digitalWrite(11, LOW);
}

void loop() {
double analogVotage = 1.1*(double)analogRead(A3)/1023;
double temp = 100*analogVotage; //计算温度
unsigned int dutyCycle; //占空比
if (temp <= tempMin) { //小于亮灯门限值
dutyCycle = 0; digitalWrite(11, LOW);
}
else if (temp < tempMax) { //小于报警门限
dutyCycle = (temp-tempMin)*255/(tempMax-tempMin);
digitalWrite(11, LOW);
}
else{ //发光二极管亮度最大值，并启动声音报警
dutyCycle = 255; digitalWrite(11, HIGH);
}
analogWrite(10, dutyCycle); //控制发光二极管发光
Serial.print("Temp: "); Serial.print(temp);
Serial.print(" Degrees Duty cycle: ");
Serial.println(dutyCycle);
u8g.firstPage();
do
{
  setFont_L;
  u8g.setPrintPos(1,15);
  u8g.print(temp);
  u8g.print(" degrees");
  u8g.setPrintPos(1,30);
  u8g.print("in Celsius");
  u8g.setPrintPos(1, 45);
  u8g.print("Degrees Duty cycle:");
  u8g.setPrintPos(1, 60);
  u8g.print(dutyCycle);
}while(u8g.nextPage());
delay(100);
}