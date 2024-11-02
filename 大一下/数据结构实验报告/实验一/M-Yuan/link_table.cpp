#include<iostream>
using namespace std;

template<class T>
struct Node
{
    T data;
    struct Node<T>*next;
};


template<typename T>
class LinkList
{
    public:
        LinkList()
        {
            front=new Node<T>;
            front->next=NULL;
        }
        LinkList(T a[],int n);
        void LinkListLast(T a[],int n);
        ~LinkList();
        void PrintList();
        int GetLength();
        Node<T>* Get(int x); //第x个节点的位置
        int Locate(T x);  //值为x的位置
        void Insert(int n,T x);
        void Delete(int n);

    private:
        Node<T>*front;
};

template<class T>
void LinkList<T>::LinkListLast(T a[],int n)
{
    Node<T>*r=front;
    for(int i=0;i<n;i++)
    {
        Node<T>*s=new Node<T>;
        s->data=a[i];
        r->next=s;
        r=s;
    }
    r->next=NULL;

}


template<class T>
void LinkList<T>::Delete(int n)
{
    Node<T>*p=front;
    if(n<=0)throw"位置错误";
 
    else
    {
        p=Get(n-1);
        Node<T>*q=p->next;
        p->next=q->next;
        delete q;
    }

}

template<class T>
void LinkList<T>::Insert(int n,T x)
{
    int N=this->GetLength();
    if(n<=N+1)
    {
        Node<T>*p=Get(n-1);
        Node<T>*s=new Node<T>;
        s->data=x;
        s->next=p->next;
        p->next=s;
    }
    else throw"插入错误";
}

template<class T>
int LinkList<T>::Locate(T x)
{
    Node<T>*p=new Node<T>;
    p=front;
    int i=0;
    while (p)
    {
        if(p->data==x)return i;
        p=p->next;
        i++;
    }
    return -1;
}

template<class T>
Node<T>* LinkList<T>::Get(int n)
{
    int N=this->GetLength();
    Node<T>*p=front;
    if (n>N||n<0)throw "越位！";
    else
    {
        int i=0;
        while (i!=n)
        {
            p=p->next;
            i++;
        }
    }
    return p;        
    
}

template<class T>
LinkList<T>::LinkList(T a[],int n)
{
    front=new Node<T>;
    front->next=NULL;
    for(int i=n-1;i>=0;i--)
    {
        Node<T>*s=new Node<T>;
        s->data=a[i];
        s->next=front->next;
        front->next=s;
    }
}

template<class T>
LinkList<T>::~LinkList()
{
    Node<T>*p=front;
    while (p)
    {
        p=p->next;
        delete front;
        front=p;
    }
    
}

template<class T>
int LinkList<T>::GetLength()
{
    int i=-1;
    Node<T>*p=front;
    while (p)
    {
        p=p->next;       
        i++;
    }
    return i;
}

template<class T>
void LinkList<T>::PrintList()
{
    int N=GetLength();
    Node<T>*p=front;
    if(N>0)
    {
        cout<<"front->";
        for(int i=1;i<=N-1;i++)
        {
            p=p->next;
            cout<<p->data<<"->";
        }
        p=p->next;
        cout<<p->data;
    }
    else if (N==-1)
    {
        cout<<"链表已经析构";
    }
    

    else
        cout<<"NULL";
    
    
}

int main()
{
    int a[10] = {10, 45, 33, 22, 49, 4, 1, 38, 64, 91};

    // 初始化测试
    LinkList<int> test(a, 10);
    cout << "初始化测试: ";
    test.PrintList();
    cout << endl;

    // 边界情况测试
    cout << "边界情况测试:" << endl;

    // 在空链表中插入节点
    LinkList<int> emptyList;
    cout << "在空链表中插入节点: ";
    emptyList.Insert(1, 100); // 在空链表中的位置1插入元素100
    emptyList.PrintList();
    cout << endl;

    // 在链表的首部插入节点
    cout << "在链表的首部插入节点: ";
    test.Insert(1, 99); // 在第1个位置插入元素99
    test.PrintList();
    cout << endl;

    // 在链表的尾部插入节点
    cout << "在链表的尾部插入节点: ";
    test.Insert(test.GetLength() + 1, 88); // 在链表尾部插入元素88
    test.PrintList();
    cout << endl;

    // 删除链表的头节点
    cout << "删除链表的头节点: ";
    test.Delete(1); // 删除链表的第一个节点
    test.PrintList();
    cout << endl;

    // 删除链表的尾节点
    cout << "删除链表的尾节点: ";
    test.Delete(test.GetLength()); // 删除链表的最后一个节点
    test.PrintList();
    cout << endl;

    // 查找链表中第一个节点和最后一个节点
    cout << "查找链表中第一个节点和最后一个节点: ";
    int firstNode = test.Get(1)->data;
    int lastNode = test.Get(test.GetLength())->data;
    cout << "第一个节点值为 " << firstNode << ", 最后一个节点值为 " << lastNode << endl;

    // 异常情况测试
    cout << "异常情况测试:" << endl;

    // 尝试在不存在的位置插入节点
    try {
        cout << "尝试在不存在的位置插入节点: ";
        test.Insert(20, 100); // 在不存在的位置20插入元素100
    } catch (const char* msg) {
        cout << "错误提示: " << msg << endl;
    }

    // 尝试删除不存在的位置的节点
    try {
        cout << "尝试删除不存在的位置的节点: ";
        test.Delete(20); // 删除不存在的位置20的节点
    } catch (const char* msg) {
        cout << "错误提示: " << msg << endl;
    }

    // 在空链表中进行节点的删除、查找等操作
    cout << "在空链表中进行节点的删除、查找等操作: ";
    emptyList.Delete(1); // 删除空链表的节点
    int result = emptyList.Locate(10); // 在空链表中查找元素10
    cout << "查找结果为: " << result << endl;

    // 在链表中查找一个不存在的元素
    cout << "在链表中查找一个不存在的元素: ";
    int position = test.Locate(1000); // 在链表中查找不存在的元素1000
    cout << "查找结果为: " << position << endl;

    system("pause");
    return 0;
}