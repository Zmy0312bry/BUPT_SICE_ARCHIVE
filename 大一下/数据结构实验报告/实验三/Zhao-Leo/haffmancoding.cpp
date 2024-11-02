#include <iostream>
#include <queue>
#include <vector>

using namespace std;

// Define the Huffman tree node structure
struct HuffmanNode {
  char data;
  int frequency;
  HuffmanNode* left;
  HuffmanNode* right;

  HuffmanNode(char data, int frequency) {
    this->data = data;
    this->frequency = frequency;
    left = right = nullptr;
  }
};

// Define a custom comparator for the priority queue
struct Compare {
  bool operator()(HuffmanNode* a, HuffmanNode* b) {
    return a->frequency > b->frequency;
  }
};

// Huffman coding/decoding class
class HuffmanCodec {
private:
  HuffmanNode* root;

  // Helper function to build the Huffman tree
  void buildTree(const string& s) {
    // Count the frequency of each character
    vector<int> frequency(256, 0);
    for (char c : s) {
      frequency[c]++;
    }

    // Create a priority queue of Huffman nodes
    priority_queue<HuffmanNode*, vector<HuffmanNode*>, Compare> pq;
    for (int i = 0; i < 256; i++) {
      if (frequency[i] > 0) {
        pq.push(new HuffmanNode(i, frequency[i]));
      }
    }

    // Build the Huffman tree
    while (pq.size() > 1) {
      HuffmanNode* left = pq.top();
      pq.pop();
      HuffmanNode* right = pq.top();
      pq.pop();

      HuffmanNode* newNode = new HuffmanNode('$', left->frequency + right->frequency);
      newNode->left = left;
      newNode->right = right;

      pq.push(newNode);
    }

    root = pq.top();
  }

  // Helper function to generate the Huffman codes
  void generateCodes(HuffmanNode* node, string code, vector<string>& codes) {
    if (node == nullptr) {
      return;
    }

    if (node->data != '$') {
      codes[node->data] = code;
    }

    generateCodes(node->left, code + "0", codes);
    generateCodes(node->right, code + "1", codes);
  }

public:
 HuffmanNode *getroot(){return root;}
  void printCodes(HuffmanNode* node, string str) {
  if (node == nullptr) {
    return;
  }

  if (node->data != '$') {
    cout << node->data << ": " << str << "\n";
  }

  printCodes(node->left, str + "0");
  printCodes(node->right, str + "1");
}
  // Constructor
  HuffmanCodec(const string& s) {
    buildTree(s);
  }

  // Function to encode a string
  string encode(const string& s) {
    vector<string> codes(256, "");
    generateCodes(root, "", codes);

    string encodedString = "";
    for (char c : s) {
      encodedString += codes[c];
    }

    return encodedString;
  }

  // Function to decode a string
  string decode(const string& encodedString) {
    string decodedString = "";
    HuffmanNode* current = root;

    for (char c : encodedString) {
      if (c == '0') {
        current = current->left;
      } else {
        current = current->right;
      }

      if (current->data != '$') {
        decodedString += current->data;
        current = root;
      }
    }

    return decodedString;
  }

  ~HuffmanCodec() {
    delete root;
  }
};

int main() {
  string inputString = "";
  getline(cin, inputString);
  HuffmanCodec huffmanCodec(inputString);

  string encodedString = huffmanCodec.encode(inputString);
  cout << "Encoded string: " << encodedString << endl;

  string decodedString = huffmanCodec.decode(encodedString);
  cout << "Decoded string: " << decodedString << endl;

  huffmanCodec.printCodes(huffmanCodec.getroot(),"");
  return 0;
}