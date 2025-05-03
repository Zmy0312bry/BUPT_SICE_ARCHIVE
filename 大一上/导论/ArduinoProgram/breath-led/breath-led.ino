/*void setup() {
  // put your setup code here, to run once:
  pinMode(9,OUTPUT);
}

void loop() {
  // put your main code here, to run repeatedly:
  analogWrite(9,127+127*sin(0.001*millis()));
}*/
void setup() { }
void loop()
{
bln(6);
bln(11); 
bln(10); 
bin(6,11);
bin(6,10);
bin(10,11);
bin3(6,10,11);
}
void bln(int num)
{
int brightness = 0;
int fadeAmount = 5;
do {
analogWrite(num, brightness); //点亮LED
brightness = brightness + fadeAmount;
if (brightness >= 255)
fadeAmount = -fadeAmount ; //亮度翻转
delay(30); //延时30毫秒
} while( brightness>=0);
}
void bin(int m,int n)
{
  int brightness = 0;
int fadeAmount = 5;
do {
analogWrite(m, brightness); 
analogWrite(n, brightness);
brightness = brightness + fadeAmount;
if (brightness >= 255)
fadeAmount = -fadeAmount ; //亮度翻转
delay(30); //延时30毫秒
} while( brightness>=0);
}
void bin3(int m,int n,int k)
{
  int brightness = 0;
int fadeAmount = 5;
do {
analogWrite(m, brightness); 
analogWrite(n, brightness);
analogWrite(k, brightness);
brightness = brightness + fadeAmount;
if (brightness >= 255)
fadeAmount = -fadeAmount ; //亮度翻转
delay(30); //延时30毫秒
} while( brightness>=0);
}
