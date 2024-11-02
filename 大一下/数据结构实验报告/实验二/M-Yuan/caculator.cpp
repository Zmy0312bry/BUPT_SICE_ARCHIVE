#include<iostream>
#include<stack>
using namespace std;
enum PRIO {RIGHT_BR=0,ADD_SUB,MUL_DEV,LEFT_BR}; //设置优先级
enum PRE {START, NUM, OPER}; //前一个数据类型
char x[255]={0};

template<class T>
class mystack : public std::stack<T>//继承库函数，修改pop函数
{
public:
    T pop()
    {
        if (this->empty()) 
        {
            throw std::out_of_range("Stack is empty");
        }//空则返回报错
        T topElement = this->top();
        std::stack<T>::pop();
        return topElement;
    }
};

void setOper()
{
    x['+']=ADD_SUB;//'+'对应的ASCII码值对应的数组为优先级1,下皆同理
    x['-']=ADD_SUB;
    x['*']=MUL_DEV;
    x['/']=MUL_DEV;
    x['(']=LEFT_BR;
}

bool isDigital(char c)//判断是否为数字
{
    if((c>='0')&& (c<='9')) return true;
    else return false;
}

float TurnToNum(char a)//将输入的转为数字
{
    float temp=0;
    temp=(a-48);
    return temp;
}

 float calc(char *k)
 {
    mystack<char> fu;//符栈
    mystack<float> shu;//数栈
    PRE status=START;//初始状态
    setOper();//给符号赋初值
    float num;//接受数字
    char ch;//接受符号
    float testshu;
    char testfu;
    while(*k!='\0')//遍历输入的k
    {
        if(isDigital(*k))//如果是数字
        {
            if (status==NUM)//处理前一个是数字
            {
                num=num*10+TurnToNum(*k);
                status=NUM;
            }
            else//处理其他情况，前边是符号或者数字
            {
                num=TurnToNum(*k);
                status=NUM;
            }
            
        }
        else//遇到了符号
        {
            ch=*k;
            if(status==NUM)
            {
            shu.push(num);//将数字压入栈

            testshu=shu.top();/*测试数据*/
            }

            if(fu.empty())
            //如果为开始且符栈为空，则直接压栈
            {
                fu.push(ch);
                testfu=fu.top();/*测试数据*/
                status=OPER;
            }
            else if (x[ch]>x[fu.top()])
            {
                fu.push(ch);
                testfu=fu.top();/*测试数据*/
                status=OPER;
            }
            
            else if(x[fu.top()]==LEFT_BR)
            //如果左边是左括号，直接压栈
            {
                fu.push(ch);
                testfu=fu.top();/*测试数据*/
                status=OPER;
            }
            else if(x[ch]==0)
            //即遇到右括号的情况，需要弹栈到左括号
            {
                while(x[fu.top()]!=LEFT_BR)
                //栈顶不为左括号时
                {
                    float a,b;
                    b=shu.pop();
                    a=shu.pop();
                    switch (fu.top())//判断符号进行计算
                    {
                    case '+':
                        {float result1=a+b;
                        fu.pop();
                        shu.push(result1);
                        testshu=shu.top();
                        break;}
                    
                    case '-':
                        {float result2=a-b;
                        fu.pop();
                        shu.push(result2);
                        testshu=shu.top();
                        break;}
                    
                    case '*':
                       {float result3=a*b;
                        fu.pop();
                        shu.push(result3);
                        testshu=shu.top();
                        break;}
                    
                    case '/':
                        {float result4=a/b;
                        fu.pop();
                        shu.push(result4);
                        testshu=shu.top();
                        break;}
                    } 
                }
                if(fu.top()=='(')
                {
                    fu.pop();
                }
                status=OPER;
            }
            else
            //出现较低优先级进行弹栈情况
            {
                float a,b;//分别接收第一第二个元素
                b=shu.pop();
                a=shu.pop();
                //要符合以上进栈规则，那么此时弹栈运算符只能是*或/
                if(fu.top()=='*')
                {
                    float result=a*b;
                    shu.push(result);
                    fu.pop();
                }
                if(fu.top()=='/')
                {
                    float result=a/b;
                    shu.push(result);
                    fu.pop();
                }
                fu.push(ch);
                status=OPER;
            }
        }
        k++;
    }

    if(*k=='\0'&&status==NUM)//将最后一个数字压栈
    {
        shu.push(num);
    }

    //最后判断符栈数栈中还剩下什么
    if(fu.empty())//符栈为空则直接输出
    {
        return shu.pop();
    }
    else
    {
        while(!fu.empty())
        {
            float a,b;
            b=shu.pop();
            a=shu.pop();
            switch (fu.top())//判断符号进行计算
                {
                    case '+':
                        {float result=a+b;
                        fu.pop();
                        shu.push(result);
                        break;}
                    
                    case '-':
                        {float result1=a-b;
                        fu.pop();
                        shu.push(result1);
                        break;}
                    
                    case '*':
                        {float result2=a*b;
                        fu.pop();
                        shu.push(result2);
                        break;}
                    
                    case '/':
                        {float result3=a/b;
                        fu.pop();
                        shu.push(result3);
                        break;}
                }

        }
        float final=shu.pop();
        return final;
    }
 }

 int main()
 {
    char duihua;
    cout<<"************************************"<<endl;
    cout<<"      欢迎使用C++计算器      "<<endl;
    cout<<"************************************"<<endl;
    cout<<"温馨提示：请确认您的输入法为英文输入法"<<endl;
    cout<<"使用注意事项："<<endl;
    cout<<"1、本计算器只允许输入正整数"<<endl;
    cout<<"2、本计算器只允许输入+-*/和()六种运算符"<<endl;
    cout<<"************************************"<<endl;
    cout<<"您是否准备好开始使用该计算器并已经确认您的输入法"<<endl;
    cout<<"如果确认请输入y,如果不确认,请输入n"<<endl;
    cin>>duihua;
    if(duihua=='y'){
    char question[100];
    cout<<"请输入您计算的公式："<<endl;
    char non[1];
    cin.getline(non,1);//因为输入y产生的回车会默认使getline获取所以需要有缓冲
    cin.getline(question,100);
    char *q=question;
    while((*q)!='\0')
    {
        cout<<*q<<" ";
        q++;
    }
    cout<<endl;
    float m =calc(question);
    cout<<"您的结果："<<endl;
    cout<<m<<endl;
    }
    else 
    {
        return 0;
    }
    system("pause");
    return 0;
 }