#include "U8glib.h"
U8GLIB_SSD1306_128X64 u8g(U8G_I2C_OPT_NONE);
#define setFont_L u8g.setFont(u8g_font_9x15)
int count = 0;
void setup() {
  pinMode(8, INPUT);
  Serial.begin(9600);
  Serial.println(count);
  u8g.firstPage();
  do {
    setFont_L;
    u8g.setPrintPos(1, 20);
    u8g.print(count);
  } while (u8g.nextPage());
}
void loop() {
  if (digitalRead(8) == HIGH) {    // 如果按键按下
    delay(20);                     // 延迟20ms，去抖动
    if (digitalRead(8) == HIGH) {  // 再次检测按键
      count++;                     // 按键计数加1
      Serial.println(count);
      u8g.firstPage();
      do {
        setFont_L;
        u8g.setPrintPos(1, 20);
        u8g.print(count);
      } while (u8g.nextPage());
      while (digitalRead(8) == LOW);  // 等待按键释放
    }
  }
}