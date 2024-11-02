#include <iostream>
#include <cmath>
#define nullptr NULL
using namespace std;
class Polynomial
{
private:
    struct Term
    {
        int coefficient;
        int exponent;
        Term *next;
        Term(int coefficient, int exponent) : coefficient(coefficient), exponent(exponent), next(nullptr) {}
    };
    Term *head;
    int size;

public:
    Polynomial() : head(nullptr), size(0) {}
    Polynomial(int size) : head(nullptr), size(size) {}
    Polynomial(const int *coefficients, const int *exponents, int size) : head(nullptr), size(size)
    {
        for (int i = 0; i < size; i++)
        {
            insertTerm(coefficients[i], exponents[i]);
        }
    }
    ~Polynomial()
    {
        destroy();
    }
    void insertTerm(int coefficient, int exponent)
    {
        if (coefficient == 0)
        {
            return;
        }
        Term *current = this->head;
        Term *prev = nullptr;
        while (current != nullptr && current->exponent < exponent)
        {
            prev = current;
            current = current->next;
        }
        if (current != nullptr && current->exponent == exponent)
        {
            current->coefficient += coefficient;
            if (current->coefficient == 0)
            {
                if (prev != nullptr)
                {
                    prev->next = current->next;
                }
                else
                {
                    this->head = current->next;
                }
                delete current;
            }
        }
        else
        {
            Term *newTerm = new Term(coefficient, exponent);
            if (prev != nullptr)
            {
                newTerm->next = prev->next;
                prev->next = newTerm;
            }
            else
            {
                newTerm->next = this->head;
                this->head = newTerm;
            }
        }
    }
    Polynomial operator+(const Polynomial &other) const
    {
        Polynomial result;
        Term *current1 = this->head;
        Term *current2 = other.head;

        while (current1 != nullptr && current2 != nullptr)
        {
            if (current1->exponent == current2->exponent)
            {
                result.insertTerm(current1->coefficient + current2->coefficient, current1->exponent);
                current1 = current1->next;
                current2 = current2->next;
            }
            else if (current1->exponent < current2->exponent)
            {
                result.insertTerm(current1->coefficient, current1->exponent);
                current1 = current1->next;
            }
            else
            {
                result.insertTerm(current2->coefficient, current2->exponent);
                current2 = current2->next;
            }
        }

        while (current1 != nullptr)
        {
            result.insertTerm(current1->coefficient, current1->exponent);
            current1 = current1->next;
        }

        while (current2 != nullptr)
        {
            result.insertTerm(current2->coefficient, current2->exponent);
            current2 = current2->next;
        }

        return result;
    }

    Polynomial operator-(const Polynomial &other) const
    {
        Polynomial result;
        Term *current1 = this->head;
        Term *current2 = other.head;

        while (current1 != nullptr && current2 != nullptr)
        {
            if (current1->exponent == current2->exponent)
            {
                result.insertTerm(current1->coefficient - current2->coefficient, current1->exponent);
                current1 = current1->next;
                current2 = current2->next;
            }
            else if (current1->exponent < current2->exponent)
            {
                result.insertTerm(current1->coefficient, current1->exponent);
                current1 = current1->next;
            }
            else
            {
                result.insertTerm(-current2->coefficient, current2->exponent);
                current2 = current2->next;
            }
        }

        while (current1 != nullptr)
        {
            result.insertTerm(current1->coefficient, current1->exponent);
            current1 = current1->next;
        }

        while (current2 != nullptr)
        {
            result.insertTerm(-current2->coefficient, current2->exponent);
            current2 = current2->next;
        }

        return result;
    }

    friend std::ostream &operator<<(std::ostream &os, const Polynomial &polynomial)
    {
        Polynomial::Term *current = polynomial.head;
        bool firstTerm = true;
        while (current != nullptr)
        {
            if (current->coefficient == 0)
            {
                current = current->next;
                continue;
            }
            if (firstTerm && current->coefficient < 0)
            {
                os << "-";
            }
            if (!firstTerm)
            {
                if (current->coefficient < 0)
                {
                    os << " - ";
                }
                else
                {
                    os << " + ";
                }
            }

            if (current->exponent == 0 || current->coefficient != -1)
            {
                if (current->coefficient < 0)
                {
                    os << -(current->coefficient);
                }
                else
                {
                    if (current->coefficient != 1 || current->exponent == 0)
                    {
                        os << current->coefficient;
                    }
                }
            }
            if (current->exponent != 0)
            {
                os << "x";
                if (current->exponent != 1)
                {
                    os << "^" << current->exponent;
                }
            }
            current = current->next;
            firstTerm = false;
        }
        return os;
    }

    float evaluate(float x) const
    {
        float result = 0.0;
        for (Term *term = this->head; term != nullptr; term = term->next)
        {
            result += term->coefficient * pow(x, term->exponent);
        }
        return result;
    }

    Polynomial derivative() const
    {
        Polynomial result;
        Term *current = this->head;
        while (current != nullptr)
        {
            if (current->exponent != 0)
            {
                result.insertTerm(current->coefficient * current->exponent, current->exponent - 1);
            }
            current = current->next;
        }
        return result;
    }

    Polynomial operator*(const Polynomial &other) const
    {
        Polynomial result;
        for (Term *term1 = this->head; term1 != nullptr; term1 = term1->next)
        {
            for (Term *term2 = other.head; term2 != nullptr; term2 = term2->next)
            {
                result.insertTerm(term1->coefficient * term2->coefficient, term1->exponent + term2->exponent);
            }
        }
        return result;
    }
    void destroy()
    {
        Term *current = head;
        while (current != nullptr)
        {
            Term *next = current->next;
            delete current;
            current = next;
        }
        head = nullptr;
    }
};
int main()
{
    // 测试样例1
    int coefficients1[] = {1, 0, 2, 0, 4, 5};
    int exponents1[] = {1, 2, 3, 4, 5, 6};
    Polynomial p1(coefficients1, exponents1, 6);
    cout << p1 << endl;
    cout << "The evaluation of p1 is " << p1.evaluate(1) << endl;
    // 测试样例2
    int coefficients2[] = {-1, 2, -3, 4, -5};
    int exponents2[] = {0, 1, 2, 3, 4};
    Polynomial p2(coefficients2, exponents2, 5);
    cout << p2 << endl;
    cout << "The evaluation of p2 is " << p2.evaluate(-1) << endl;
    // 测试样例3
    int coefficients3[] = {1, -1, 1, -1, 1};
    int exponents3[] = {0, 1, 2, 3, 4};
    Polynomial p3(coefficients3, exponents3, 5);
    cout << p3 << endl;
    cout << "The evaluation of p3 is " << p3.evaluate(2) << endl;
    Polynomial p4 = p1 + p2;
    cout << p4 << endl;
    Polynomial p5 = p1 - p2;
    cout << p5 << endl;
    Polynomial p6 = p1.derivative();
    cout << p6 << endl;
    Polynomial p7 = p1 * p2;
    cout << p7 << endl;
    p1.destroy();
    p2.destroy();
    p3.destroy();
    p4.destroy();
    p5.destroy();
    p6.destroy();
    p7.destroy();
    return 0;
}