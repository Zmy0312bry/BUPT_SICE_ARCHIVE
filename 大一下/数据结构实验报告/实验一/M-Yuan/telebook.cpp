#include<iostream>
#include<cstring>
using namespace std;


struct DataType
{
    int ID;
    char name[10];
    char gender;
    char phone[13];
    char addr[31];
};


class PhoneBook
{
private:
    DataType user;
public:
    PhoneBook(){}
    PhoneBook(DataType X);
    void print()
    {
        cout<<"联系人id: "<<user.ID<<" 联系人姓名:"<<user.name<<" 联系人性别: "<<user.gender<<" 联系人电话： "
        <<user.phone<<" 联系人地址： "<<user.addr<<endl;
    }
    bool operator==(PhoneBook&p)
    {
        if(p.user.ID==user.ID)
            return true;
        return false;
    }

};


PhoneBook::PhoneBook(DataType X)
{
    //字符串不能直接赋值
        {user.ID=X.ID;
        strcpy(user.name, X.name);
        user.gender = X.gender;
        strcpy(user.phone, X.phone);
        strncpy(user.addr, X.addr, 30);}

}

//先实现线性表
template<class T,int N>
class SeqList
{
    private:
        T data[N];
        int length;
    public:
        SeqList(){length=0;};
        SeqList(T a[],int n);
        int GetLength(){return length;};
        void PrintList();
        void Insert(int i,T x);
        T Delete(int i);
        T Get(int i);
        int Locate(T x);//返回位置
};

template<class T ,int N>
SeqList<T,N>::SeqList(T a[],int n)
{
    if (n>N)throw "超出最大长度";
    for(int i=0;i<n;i++)
    {
        data[i]=a[i];
        length=n;
    }

}

template<class T ,int N>
void SeqList<T,N>::PrintList()
{
    cout<<"按顺序遍历各个元素"<<endl;
    for(int i=0;i<length;i++)
    {
        data[i].print();
    }
    cout<<endl;

}

template<class T ,int N>
void SeqList<T,N>::Insert(int i,T x)//第i个位置插入x的元素
{
    if(length>=N)throw"数组上溢";
    if(i<1||i>length+1)throw"访问位置出错";
    for(int j=length;j>=i;j--)
    {
        data[j]=data[j-1];
    }
    data[i-1]=x;
    length++;
}

template<class T ,int N>
T SeqList<T,N>::Get(int i)
{
    if (i<1||i>length)
    {
        throw"数据上溢";
    }
    else
    {
        return data[i-1];
    }
}

template<class T ,int N>
T SeqList<T,N>::Delete(int i)
{
    if(i<1||i>length)throw"位置异常";
    T x=data[i-1];
    for(int j=i-1;j<length-1;j++)
    {
        data[j]=data[j+1];
    }
    length--;
    return x;
}

template<class T ,int N>
int SeqList<T,N>::Locate(T x)
{
    for(int i=0;i<length;i++)
    {
        if(data[i]==x)return i+1;
    }
    return 0;

}




int main()
{
    
    DataType init_book[2]={{11111,"Mary",'F',"13000","beiyou"},{22222,"Lily",'M',"13001","beiyou"}};
    PhoneBook book1(init_book[0]);
    PhoneBook book2(init_book[1]);
    PhoneBook Book[2]={book1,book2};
    cout<<"打印列表";
    SeqList<PhoneBook,100> list(Book,2);
    list.PrintList();
    while (true)
    {
        cout<<"**********通讯录**********"<<endl;
        cout<<"*************************"<<endl;
        cout<<"*********输入1查询********"<<endl;
        cout<<"*********输入2增加********"<<endl;
        cout<<"*********输入3删除********"<<endl;
        cout<<"*********输入4定位********"<<endl;
        int num;
        cin>>num;
        if(num==1)
        {
            cout<<"*********输入1查询所有********"<<endl;
            cout<<"*********输入2查询单个********"<<endl;
            int i;
            cin>>i;
            if(i==1)
            {
                list.PrintList();
            }
            else if (i==2)
            {
                cout<<"输入编号:";
                int ii;
                cin>>ii;
                PhoneBook obj=list.Get(ii);
                obj.print();
            }
            else continue;
        }
       
       if(num==2)
       {
            char ch1[10],ch2,ch3[13],ch4[31];
            int mm,nn;
            DataType Temp;
            cout<<"输入id: ";
            cin>>mm;
            Temp.ID=mm;
            cout<<"输入姓名:";
            cin>>ch1;
            strcpy(Temp.name,ch1);
            cout<<"输入性别:";
            cin>>ch2;
            Temp.gender=ch2;
            cout<<"输入电话：";
            cin>>ch3;
            strcpy(Temp.phone,ch3);
            cout<<"输入地址：";
            cin>>ch4;
            strcpy(Temp.addr,ch4);
            nn=list.GetLength()+1;
            list.Insert(nn,Temp);
            PhoneBook obj1=list.Get(nn);
            obj1.print();
       }

       if(num==3)
       {
        int hh;
        cout<<"删除的数字：";
        cin>>hh;
        PhoneBook temp22=list.Delete(hh);
        temp22.print();
       }

       if(num==4)
       {
            int pp;
            cin>>pp;
            DataType tem ;
            tem.ID=pp;
            PhoneBook temp1(tem);
            int temp2=list.Locate(temp1);
            cout<<"位置是：" ;
            cout<< temp2<<endl;
       }
    }
    
    
    system("pause");
    return 0;
}