#include<iostream>
#include<cstring>
using namespace std;

struct HNode//定义哈夫曼的节点
{
    int weight;
    int parent;
    int lchild;
    int rchild;
};//左孩子右孩子双亲都有所以先后创建无所谓
struct HCode//定义编码表
{
    char data;
    char* code;
};

class Huffman
{
    private:
        HNode* HTree;
        HCode* HCodeTable;
        int N;//编码节点数量
        void code(int i,char* newnode);
        void Through(int signal,char word,char*code);
    public:
        void CreateHTree(int a[],int category,char content[]);//category种类，a为权重
        int GetCate(char content[]);
        void CreateCodeTable();
        void Encode(char*s,char*d);
        void Decode(char*s,char*d);
        bool IsRepeat(char *content,char w);//辅助函数帮忙字母判断是否在数组里
        void CountWeight(int *a,int n,char cin[],char* content);//n是输入的字符多少
        void SelectMin(int &x,int &y,int start,int finish);

};

bool Huffman::IsRepeat(char* m,char w)
{
    while (*m!='\0')
    {
        if(w==*m)
        {
            return true;
        }
        m++;
    }
    return false;
}

void Huffman::CountWeight(int *a,int n,char cin[],char* content)
{
    int temp[256]={0};
    int numnow=0;
    for(int i=0;i<n;i++)
    {
        char mm=cin[i];
        int mmtemp=static_cast<int>(mm);
        temp[mmtemp]++;
        if(!IsRepeat(content,mm))
        {
            *(content+numnow)=mm;
            numnow++;
        }  
    }
    for(int j=0;j<numnow;j++)
    {
        char aa=*(content+j);
        int aatemp=static_cast<int>(aa);
        a[j]=temp[aatemp];
    }//保证content中和传入数组中一一对应
}

int Huffman::GetCate(char content[])
{
    int i=0;
    while (content[i]!='\0')
    {
        i++;
    }
    return i;
}

void Huffman::SelectMin(int& x,int &y, int start,int finish)
{
    int min1=0,min2=0;//不妨设min2>min1
    if(finish-start==1)//排除特殊情况
    {
        x=start;
        y=finish;
    }
    if(finish-start==0)
    {
        x=y=start;
    }
    for(int i=start;i<finish;i++)
    {
        if(HTree[i].parent==-1)
        {
            if(HTree[i].weight<=HTree[min2].weight)
            {
                if(HTree[i].weight<HTree[min1].weight)//这里要写小于,否则无法处理相等情况
                {
                    int temp=min1;
                    min1=i;
                    min2=temp;
                }
                else
                {
                    min2=i;
                }
            }
        }
    }
    x=min1;
    y=min2;
}

void Huffman::CreateHTree(int a[],int category,char content[])
{
    N=category;
    HCodeTable=new HCode[N];
    HTree=new HNode[2*N-1];
    //先初始化叶子节点
    for(int i=0;i<N;i++)
    {
        HTree[i].weight=a[i];
        HTree[i].lchild=HTree[i].rchild=HTree[i].parent=-1;//初始化为无
        HCodeTable[i].data=content[i];
    }
    //筛选最小的节点进行构造非叶子节点
    int x=0,y=0;
    for(int i=N;i<2*N-1;i++)
    {
        SelectMin(x,y,0,i);
        HTree[x].parent=HTree[y].parent=i;
        HTree[i].weight=HTree[x].weight+HTree[y].weight;
        HTree[i].lchild=x;
        HTree[i].rchild=y;
        HTree[i].parent=-1;
    }
}

void Huffman::code(int i,char* newcode)//传入的是根节点的编号应为2N-2
{
    if(HTree[i].lchild==-1)//没有左孩子
    {
        HCodeTable[i].code=newcode;
        return;//跳出
    }//正则二叉树，没有左孩子也不会有右孩子
    code(HTree[i].lchild,newcode+'0');
    code(HTree[i].rchild,newcode+'1');
}
void Huffman::CreateCodeTable()
{
    code(2*N-2,"");
}

void Huffman::Through(int signal,char word,char*code)//未使用遍历是因为本身已经创建了哈夫曼树，那就从根节点开始查找
{
    if(HTree[signal].lchild==-1)//已经到达叶子节点
    {
        if(word==HCodeTable[signal].data)
        {
            strcat(code,HCodeTable[signal].code);//拼接字符串
        }
    }
    else
    {
        Through(HTree[signal].lchild,word,code);
        Through(HTree[signal].rchild,word,code);
    }
}

void Huffman::Encode(char *word,char*code)//code为输出的编码，word为输入的值
{
    while (*word!='\0')
    {
        int root=2*N-2;
        Through(root,*word,code);
        word++;
    }
}

void Huffman::Decode(char *code,char *word)
{
    while (*code!='\0')
    {
        int node=2*N-2;        
        if(HTree[node].lchild!=-1)//判断是不是叶子节点
        {
            if(*code=='0')
            {
                node=HTree[node].lchild;
            }
            if(*code=='1')
            {
                node=HTree[node].rchild;
            }
            code++;
        }
        else
        {
            *word=HCodeTable[node].data;
            word++;//后移一位
        }
    }
    
}

int main()
{
    char ch[256];
    cout<<"请输入想要存储的字符串:";
    cin>>ch;
    Huffman tree;
    int weight[256];
    char content[256];
    int num=0;
    while (ch[num]!='\0')
    {
        num++;
    }
    
    tree.CountWeight(weight,num,ch,content);
    int catrgory=tree.GetCate(content);
    tree.CreateHTree(weight,catrgory,content);
    tree.CreateCodeTable();
    char word[256];
    char *code;
    cout<<"请输入您要编码的字符串：";
    cin>>word;
    tree.Encode(word,code);
    
    system("pause");
    return 0;
}