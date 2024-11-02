#include <stack>
#include <iostream>
using namespace std;
enum PRIO
{
   NONE = 0,
   ADD_SUB,
   MUL_DEV,
   LEFT_BR
};
enum PRE
{
   START,
   NUM,
   OPER
};
char x[255] = {0};

void setOper()
{
   x['+'] = ADD_SUB;
   x['-'] = ADD_SUB;
   x['*'] = MUL_DEV;
   x['/'] = MUL_DEV;
   x['('] = LEFT_BR;
}

bool isDigital(char c)
{
   return c >= '0' && c <= '9';
}

void run(stack<char> &s, stack<float> &v)
{
   if (s.empty())
      throw "s empty error";
   if (v.empty())
      throw "v empty error";
   char o = s.top();
   s.pop();
   float x[2];
   x[0] = v.top();
   v.pop();
   if (v.empty())
      throw "v empty error";
   x[1] = v.top();
   v.pop();
   switch (o)
   {
   case '+':
      v.push(x[1] + x[0]);
      break;
   case '-':
      v.push(x[1] - x[0]);
      break;
   case '*':
      v.push(x[1] * x[0]);
      break;
   case '/':
      v.push(x[1] / x[0]);
      break;
   default:
      throw "oper error";
   }
}
bool isOper(char c)
{
   return x[c] != NONE;
}
float calc(char *k)
{
   stack<char> s;
   stack<float> v;
   int i = 0;
   int value = 0;
   char c;
   PRE status = START;
   while (c = k[i])
   {
      if (isDigital(c))
      {
         if (status == NUM)
         {
            value = value * 10 + c - '0';
         }
         else
         {
            value = c - '0';
            status = NUM;
         }
      }
      else
      {
         if (status == NUM)
         {
            v.push(value);
         }
         status = OPER;
         if (c == ')')
         {
            while (!s.empty() && s.top() != '(')
            {
               run(s, v);
            }
            if (s.empty())
               throw "s empty error";
            s.pop();
         }
         else if (isOper(c))
         {
            if (!s.empty() && s.top() != '(' && x[s.top()] >= x[c])
            {
               run(s, v);
            }
            s.push(c);
         }
         else
         {
            throw "error";
         }
      }
      i++;
   }
   if (status == NUM)
   {
      v.push(value);
   }
   while (v.size() != 1 || s.size() != 0)
   {
      run(s, v);
   }
   return v.top();
}
int main()
{
   char s[100000];
   while (1)
   {
      try
      {
         cin >> s;
         setOper();
         cout << calc(s) << endl;
      }
      catch (const char *e)
      {
         cout << e << endl;
      }
   }
}