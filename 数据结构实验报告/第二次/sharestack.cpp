#include<iostream>
using namespace std;

#define maxsize 4 //默认长度为4的栈
template<class T>
class sharestack
{
public:
    sharestack();
    sharestack(const int size);//初始化自定义的栈
    void push (T, bool);//入栈
    T pop(bool);//出栈
    bool isfull();//判断栈满
    void printstack();//打印栈
private:
    int stacksize;
    T* stack;
    int top[2];
};

template<class T>
sharestack<T>::sharestack()//无参构造函数
{
    stacksize = maxsize;
    stack = new T[maxsize];
    top[0] = -1;//左栈的栈顶
    top[1] = stacksize;//右栈的栈顶
}

template<class T>
sharestack<T>::sharestack(const int size)
{
    stacksize = size;
    stack = new T[stacksize];
    top[0] = -1;
    top[1] = stacksize;
}

template<class T>
bool sharestack<T>::isfull()//左栈顶+1等于右栈则满
{
    if(top[0]+1==top[1])
    return true;
    else{return false;}
}

template<class T>
void sharestack<T>::push(T x, bool flag)//flag是决定往哪个栈进行入栈的,0左栈，1右栈
{
    if(isfull()) throw "栈满\n";
    if(!flag)
    {
        top[0]++;
        *(stack+top[0]) = x;//stack指向数组，指向数组下一个元素
    }
    if(flag)
    {
        top[1]--;
        *(stack+top[1]) = x;
    }

}

template<class T>
T sharestack<T>::pop(bool flag)//出栈，flag=0左栈，=1为右栈
{
    if(!flag)
    {
        if(top[0]!=-1)//判断是否为空
        {
            top[0]--;
            T temp = *(stack+top[0]+1);
            return temp;
        }
        else throw "栈空";
    }
    if(flag)
    {
        if(top[1]!=stacksize)
        {
            top[1]++;
            T temp = *(stack+top[1]-1);
            return temp;
        }
        else throw "栈空";
    }
    throw "flag错误";
}

template<class T>
void sharestack<T>::printstack()
{

        if(top[0]!=-1)
        {
            for(int i=0;i<=top[0];i++)
            {
                cout<<*(stack+i)<<"|";
            }
        }
        if(top[1]-top[0]-1)
        {
            for(int i=0;i<(top[1]-top[0]-1);i++)
            {
                cout<<"null"<<"|";
            }
        }
        if(top[1]!=stacksize)
        {
            cout<<*(stack+top[1]);
            for(int i=top[1]+1;i<stacksize;i++)
            {
                cout<<"|"<<*(stack+i);
            }
        }
}

int main()
{
    sharestack<int> stack01;//构造无参共享栈
    sharestack<int> stack02(6);//构造长度为6的共享栈
    cout<<"进行无参构造初始化测试"<<endl;
    stack01.push(23,0);
    stack01.push(88,0);
    stack01.push(45,1);
    stack01.push(99,1);
    stack01.printstack();
    cout<<endl;
    cout<<"进行弹出测试"<<endl;
    int temp=0;
    temp = stack01.pop(0);
    cout<<"弹出的是："<<temp<<endl;
    stack01.push(77,1);
    stack01.printstack();
    cout<<endl;
    cout<<"进行左栈空栈测试"<<endl;
    int temp1=0;
    temp1=stack01.pop(0);
    cout<<"弹出的是:"<<temp1<<endl;
    stack01.printstack();
    cout<<endl;
    cout<<"进行右栈的空栈测试"<<endl;
    stack01.pop(1);
    stack01.printstack();
    cout<<endl;
    stack01.pop(1);
    stack01.pop(1);
    stack01.printstack();
    stack01.pop(0);//会退出程序的代码
    cout<<endl;
    cout<<"进行自定义构造共享栈"<<endl;
    stack02.push(1,0);
    stack02.push(2,1);
    stack02.printstack();
    cout<<endl;
    system("pause");
    return 0;
}