#include <iostream>
#define nullptr NULL
using namespace std;

template <typename T>
class LinkedList {
private:
  struct Node {
    T data;
    Node* next;
    Node(const T& value) : data(value), next(nullptr) {}
  };

  Node* head;
  int size=0;

public:
  LinkedList() : head(nullptr), size(0) {}
  LinkedList(const T* arr, int size) : head(nullptr) {
    for (int i = 0; i < size; i++) {
        insert(arr[i]);
    }
  }

  ~LinkedList() {
    destroy();
  }

void insert(const T& value, int position = -1) {
    Node* newNode = new Node(value);
    if (head == nullptr || position == 0) {
        newNode->next = head;
        head = newNode;
    } else if (position == -1) {
        Node* current = head;
        while (current->next != nullptr) {
            current = current->next;
        }
        current->next = newNode;
    } else {
        Node* current = head;
        int currentPos = 0;
        while (currentPos < position - 1 && current->next != nullptr) {
            current = current->next;
            currentPos++;
        }
        newNode->next = current->next;
        current->next = newNode;
    }
    size++;
}

  void print() const {
      Node* current = head;
      while (current != nullptr) {
          std::cout << current->data;
          if (current->next != nullptr) {
              std::cout << " -> ";
          }
          current = current->next;
      }
      std::cout << std::endl;
  }

  void autoInsert(const T& value) {
    Node* newNode = new Node(value);
    if (head == nullptr || head->data > value) {
        newNode->next = head;
        head = newNode;
    } else {
        Node* current = head;
        while (current->next != nullptr && current->next->data < value) {
            current = current->next;
        }
        newNode->next = current->next;
        current->next = newNode;
    }
    size++;
  }

  bool remove(const T& value) {
    if (head == nullptr) {
      return false;
    }

    if (head->data == value) {
      Node* temp = head;
      head = head->next;
      delete temp;
      size--;
      return true;
    }

    Node* current = head;
    while (current->next != nullptr) {
      if (current->next->data == value) {
        Node* temp = current->next;
        current->next = current->next->next;
        delete temp;
        size--;
        return true;
      }
      current = current->next;
    }

    return false;
  }

  int findByValue(const T& value) const {
      Node* current = head;
      int index = 0;
      while (current != nullptr) {
          if (current->data == value) {
              return index;
          }
          current = current->next;
          index++;
      }
      return -1;
  }
  void sort() {
    if (head == nullptr || head->next == nullptr) {
        return;
    }

    bool swapped;
    do {
        swapped = false;
        Node* current = head;
        while (current->next != nullptr) {
          if (current->data > current->next->data) {
            T temp = current->data;
            current->data = current->next->data;
            current->next->data = temp;
            swapped = true;
          }
          current = current->next;
        }
    } while (swapped);
  }

  T findByIndex(int index) const {
      Node* current = head;
      for (int i = 0; i < index; i++) {
          current = current->next;
      }
      return current->data;
  }

  int getSize() const {
    return size;
  }

  void destroy() {
    Node* current = head;
    while (current != nullptr) {
      Node* temp = current;
      current = current->next;
      delete temp;
    }
    head = nullptr;
    size = 0;
  }
};

int main() {
  // 创建一个数组
  int arr[] = {10,20,30,40,50,60,70,80,90,100};
  // 使用数组初始化链表
  LinkedList<int> myList(arr, sizeof(arr) / sizeof(arr[0]));
  // 打印链表
  myList.print();
  // 在链表中自动插入值为35的节点
  myList.autoInsert(35);
  // 在链表的末尾插入值为45的节点
  myList.insert(45);
  // 打印链表
  myList.print();
  // 在链表的头部插入值为55的节点
  myList.insert(55, 0);
  // 打印链表
  myList.print();
  // 在链表的第5个位置插入值为120的节点
  myList.insert(120, 5);
  // 打印链表
  myList.print();
  // 从链表中删除值为35的节点，并打印操作结果
  cout << "Removed 35: " << (myList.remove(35) ? "Success" : "Failed") << endl;
  // 尝试从链表中删除值为110的节点，并打印操作结果
  cout << "Removed 110: " << (myList.remove(110) ? "Success" : "Failed") << endl;
  // 打印链表
  myList.print();
  // 对链表进行排序
  myList.sort();
  // 打印链表
  myList.print();
  // 查找值为45的节点，并打印结果
  cout << "Find value 45: " << myList.findByValue(45)<<endl;
  // 查找第1个节点，并打印结果
  cout << "Find index 1: " << myList.findByIndex(1)<<endl;
  // 打印链表的大小
  cout<<myList.getSize()<<endl;
  // 销毁链表
  myList.destroy();
}