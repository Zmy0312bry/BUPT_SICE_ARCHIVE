#include <iostream>
#include <cstdio>
#define nullptr NULL

template <class T>
struct tuple // 稀疏矩阵的三元组
{
    int x;
    int y;
    T value;
    tuple *next = nullptr;
};

// 稀疏矩阵类
template <class T>
class Matrix
{
private:
    int rows, cols;
    tuple<T> *data = nullptr;

public:
    Matrix(int rows, int cols)
    {
        this->rows = rows;
        this->cols = cols;
    }; // 构造函数
    Matrix(T *data, int rows, int cols);
    // 添加元素
    void set(int rows, int cols, T value);
    Matrix<T> operator*(Matrix<T> &other); // 打印矩阵
    void print();
    Matrix<T> transpose();
    void deleteZero();
    ~Matrix();
};
template <class T>
Matrix<T>::~Matrix() // 析构函数
{
    tuple<T> *p = data;
    tuple<T> *q = nullptr;
    while (p != nullptr)
    {
        q = p;
        p = p->next;
        delete q;
    }
}

template <class T>
void Matrix<T>::deleteZero() // 删除值为0的元素
{
    tuple<T> *p = data;
    tuple<T> *q = nullptr;
    while (p != nullptr)
    {
        if (p->value == 0)
        {
            if (q == nullptr)
            {
                data = p->next;
            }
            else
            {
                q->next = p->next;
            }
        }
        else
        {
            q = p;
        }
        p = p->next;
    }
}

template <class T>
Matrix<T>::Matrix(T *value, int rows, int cols) // 构造函数
{
    this->rows = rows;
    this->cols = cols;
    for (int i = 0; i < rows; i++)
    {
        for (int j = 0; j < cols; j++)
        {
            if (*(value + i * cols + j) != 0)
            {
                set(i, j, *(value + i * cols + j));
            }
        }
    }
}

template <class T>
void Matrix<T>::set(int row, int col, T value) // 添加元素
{
    tuple<T> *t = new tuple<T>;
    t->x = row;
    t->y = col;
    t->value = value;
    if (data == nullptr)
    {
        data = t;
    }
    else
    {
        tuple<T> *p = data;
        while (p->next != nullptr)
        {
            p = p->next;
        }
        p->next = t;
    }
}

template <typename T>
Matrix<T> Matrix<T>::operator*(Matrix<T> &other)
{
    if (this->cols != other.rows)
    {
        throw std::invalid_argument("Matrices are not compatible for multiplication.");
    }

    Matrix<T> result(this->rows, other.cols);

    for (int i = 0; i < this->rows; i++) {
    for (int j = 0; j < other.cols; j++) {
        T sum = 0;
        for(int k = 0; k < this->cols; k++) {
            tuple<T> *p = this->data;
            tuple<T> *q = other.data;
            while (p != nullptr && q != nullptr) {// 两个矩阵的元素相乘
                if (p->x == i && p->y == k && q->x == k && q->y == j) {
                    sum += p->value * q->value;
                    p = p->next;
                    q = q->next;
                } else if (p->x == i && p->y == k) {
                    q = q->next;
                } else if (q->x == k && q->y == j) {
                    p = p->next;
                } else if(p->x != i && p->y != k && q->x != k && q->y != j) {
                    p = p->next;
                } else {
                    q = q->next;
                }
            }
        }
        result.set(i, j, sum);
    }}
    result.deleteZero();
    return result;
}

template <class T>
void Matrix<T>::print() {
    for (int i = 0; i < this->rows; i++) {
        for (int j = 0; j < this->cols; j++) {
            tuple<T> *p = this->data;
            while (p != nullptr) {
                if (p->x == i && p->y == j) {
                    printf("%3d ", p->value);
                    break;
                }
                p = p->next;
            }
            if (p == nullptr) {
                printf("%3d ", 0);
            }
        }
        printf("\n");
    }
}

template <class T>
Matrix<T> Matrix<T>::transpose()
{
    Matrix<T> result(cols, rows);
    tuple<T> *p = this->data;
    while (p != nullptr)
    {
        result.set(p->y, p->x, p->value);
        p = p->next;
    }
    return result;
}
int main()
{
    // 设置矩阵A和B的元素
    int arrayA[6][7] = {
         1, 12,  9, 0, 0,  0, 0,
         0,  0,  0, 0, 5,  0, 0,
        -3,  0,  0, 0, 0, 14, 0,
         0,  0, 13, 0, 0,  0, 0,
         0, 18,  0, 0, 0,  0, 0,
        15,  0,  0, 0, 0,  0, 0};
    Matrix<int> A(&arrayA[0][0], 6, 7);
    int arrayB[7][8] = {
     1, 9, 0, 0, 0, 0, 2, 0,
    -1, 0, 0, 0, 3, 0, 0, 0,
     0, 0, 0, 8, 0, 0, 0, 0,
     0, 0, 4, 0, 0, 0, 0, 0,
     0, 7, 0, 0, 0, 0, 0, 1,
     0, 0, 0, 0, 0, 6, 0, 0,
     5, 0, 0, 0, 0, 0, 0, 0,
    };
    Matrix<int> B(&arrayB[0][0], 7, 8);
    // 计算矩阵A和B的乘积
    Matrix<int> C = A * B;
    // 打印矩阵C
    A.print();
    printf("\n");
    B.print();
    printf("\n");
    C.print();
    printf("\n");
    Matrix<int> D=C.transpose();
    D.print();
    return 0;
}