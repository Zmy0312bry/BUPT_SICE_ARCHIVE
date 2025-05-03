int threshold =400;
void setup ( )
{
Serial.begin(9600);
pinMode(10, OUTPUT); 
}
void loop( )
{
int n = analogRead(A3);
Serial.println(n);
if (n>threshold )
digitalWrite(10, HIGH); 
else
digitalWrite(10, LOW);
delay(200);
}