#include <iostream>
#include <stack>
#include <queue>
using namespace std;

template <class T>
struct Node
{
  T data;
  Node<T>* lch;
  Node<T>* rch;
};
template <class T> 
class BiTree
{
protected:
  Node<T> *root;
  void Create(Node<T>* &R, T data[],int i,int n);
  void Release(Node<T>* R);
public:
  BiTree():root(NULL){};
  BiTree(T data[],int n);
  void PreOrder(Node<T>* R);
  void InOrder(Node<T>* R);
  void PostOrder(Node<T>* R);
  void LevelOrder(Node<T>* R);
  void noderootPath(T target);
  // void rootnodePath(Node<T>* &x);
  bool searchPath(T target,Node<T>* R,stack<Node<T>*> &stk);
  ~BiTree();
  Node<T>* GetRoot(){return root;};
  int GetTotalNode(Node<T> *R);
  int getheight(Node<T> *R);
  int countleaf(Node<T> *R);
};
template <class T>
BiTree<T>::BiTree(T data[],int n)
{
  Create(root,data,1,n);
}

template <class T>
BiTree<T>::~BiTree()
{
  Release(root);
}

template <class T>
void BiTree<T>::Release(Node<T>* R)
{
  if(R!=NULL)
  {
    Release(R->lch);
    Release(R->rch);
    delete R;
  }
}

template <class T>
void BiTree<T>::Create(Node<T>* &R, T data[],int i,int n) // i代表位置，从1开始
{
  if(i<=n && data[i-1]!='0')// 0代表空节点
  {
    R=new Node<T>;
    R->data=data[i-1];
    R->lch=R->rch=NULL;
    Create(R->lch,data,2*i,n); // 2*i代表左孩子，2*i+1代表右孩子
    Create(R->rch,data,2*i+1,n);
  }
}

template <class T>
void BiTree<T>::PreOrder(Node<T>* R)
{
  if(R!=NULL)
  {
    cout<<R->data<<" ";
    PreOrder(R->lch);
    PreOrder(R->rch);
  }
}

template <class T>
void BiTree<T>::InOrder(Node<T>* R)
{
  if(R!=NULL)
  {
    InOrder(R->lch);
    cout<<R->data<<" ";
    InOrder(R->rch);
  }
}

template <class T>
void BiTree<T>::PostOrder(Node<T>* R)
{
  if(R!=NULL)
  {
    PostOrder(R->lch);
    PostOrder(R->rch);
    cout<<R->data<<" ";
  }
}

template <class T>
void BiTree<T>::LevelOrder(Node<T>* R)
{
  Node<T> *p;
  queue<Node<T>*> q;
  q.push(R);
  while(!q.empty())
  {
    p=q.front();
    q.pop();
    cout<<p->data<<" ";
    if(p->lch!=NULL)
      q.push(p->lch);
    if(p->rch!=NULL)
      q.push(p->rch);
  }
}

template <class T>
int BiTree<T>::GetTotalNode(Node<T> *R)
{
  if(R==NULL)
    return 0;
  else
    return GetTotalNode(R->lch)+GetTotalNode(R->rch)+1;
}

template <class T>
int BiTree<T>::getheight(Node<T> *R)
{
  if(R==NULL)
    return 0;
  else
  {
    int m=getheight(R->lch);
    int n=getheight(R->rch);
    return m>n?m+1:n+1;
  }
}

template <class T>
int BiTree<T>::countleaf(Node<T> *R)
{
  if(R==NULL)
    return 0;
  else if(R->lch==NULL && R->rch==NULL)
    return 1;
  else
    return countleaf(R->lch)+countleaf(R->rch);
}

template <class T>
void BiTree<T>::noderootPath(T target)
{
  stack<Node<T>*> stk;
  searchPath(target,root,stk);
  if(stk.empty())
    cout<<"No path"<<endl;
  else
  {
    cout<<"Path: ";
    Node<T>* out;
    while(!stk.empty())
    {
      out=stk.top();
      if(stk.size()==1)
        cout<<out->data;
      else
        cout<<out->data<<"->";
      stk.pop();
    }
    cout<<endl;
  }
}

template <class T>
bool BiTree<T>::searchPath(T target,Node<T>* R,stack<Node<T>*> &stk)
{
  if(R==NULL)
    return false;
  if(R->data==target)
  {
    stk.push(R);
    return true;
  }
  if(searchPath(target,R->lch,stk) || searchPath(target,R->rch,stk))
  {
    stk.push(R);
    return true;
  }
  return false;
}

// template <class T>
// void BiTree<T>::rootnodePath(Node<T>* &x)
// {
//   T target=x->data;
//   stack<Node<T>*> stk;
//   searchPath(target,root,stk);
//   if(stk.empty())
//     cout<<"No path"<<endl;
//   else
//   {
//     cout<<"Path to "<<x->data<<" : ";
//     Node<T>* out;
//     stack<Node<T>*> stk0;
//     while(!stk.empty())
//     {
//       out=stk.top();
//       stk0.push(out);
//       stk.pop();
//     }
//     while(!stk0.empty())
//     {
//       out=stk0.top();
//       if(stk0.size()==1)
//         cout<<out->data;
//       else
//         cout<<out->data<<"->";
//       stk0.pop();
//     }
//     cout<<endl;
//   }
// }

int main()
{
  char data[]="ABCDE0F0G0H00IJ";//0代表空节点,从1开始存储,从上到下，从左到右,根节点为A,左孩子为B,右孩子为C,左孩子的左孩子为D,右孩子的右孩子为J.
  BiTree<char> tree(data,15);//15代表节点个数
  cout<<"PreOrder: ";//前序遍历
  tree.PreOrder(tree.GetRoot());
  cout<<endl;
  cout<<"InOrder: ";//中序遍历
  tree.InOrder(tree.GetRoot());
  cout<<endl;
  cout<<"PostOrder: ";//后序遍历
  tree.PostOrder(tree.GetRoot());
  cout<<endl;
  cout<<"LevelOrder: ";//层次遍历
  tree.LevelOrder(tree.GetRoot());
  cout<<endl;
  cout<<"Total Node: "<<tree.GetTotalNode(tree.GetRoot())<<endl;//节点个数
  cout<<"Height: "<<tree.getheight(tree.GetRoot())<<endl;//树的高度
  cout<<"Leaf Node: "<<tree.countleaf(tree.GetRoot())<<endl;//叶子节点个数
  tree.noderootPath('H');//节点H到根节点的路径
  // Node<char> *root=tree.GetRoot();
  // Node<char> *x=root->lch->rch->rch;//节点H
  // tree.rootnodePath(x);//根节点到节点H的路径
  return 0;
}