#include "U8glib.h"
U8GLIB_SSD1306_128X64 u8g(U8G_I2C_OPT_NONE);
#define setFont_L u8g.setFont(u8g_font_9x15)
unsigned int dutyCycle; //占空比
unsigned int tempMin = 20; //零速温度
unsigned int tempMax = 33; //满速温度
double temp;
void setup( ) {
Serial.begin(9600); //波特率配置串口通讯
analogReference(INTERNAL); //调用板载1.1V基准源
}
void loop( ) {

double analogVotage = 1.1*(double)analogRead(A3)/1023;
temp = 100*analogVotage; //电压换算成温度
if (temp <= tempMin)
dutyCycle = 0;
else if (temp < tempMax)
dutyCycle = (temp-tempMin)*255/(tempMax-tempMin);
else
dutyCycle = 255;
analogWrite(10, dutyCycle); //产生PWM，控制电机转速
u8g.firstPage();
do{
  setFont_L;
  u8g.setPrintPos(1,20);
  u8g.print("Temp: ");
  u8g.print(temp);
  u8g.setPrintPos(1,40);
  u8g.print(dutyCycle);
}while(u8g.nextPage());
delay(100); //控制刷新速度
}