#ifndef AST_HPP_
#define AST_HPP_

#include <memory>
#include <vector>
#include <string>
#include <ostream>

namespace AST {

    enum NodeKind {
        List,
        Literal
    };

    enum InferredType {
        Unknown,
        Void,
        I32,
        I64,
        F32,
        F64,
        Any
    };

    class Node;
    typedef Node* NodePtr;

    class Node {
      public:
        NodeKind kind;
        InferredType inferredType;

        Node(NodeKind kind_) : kind(kind_), inferredType(InferredType::Unknown) {}
        Node(NodeKind kind_, InferredType inferredType_) : kind(kind_), inferredType(inferredType_) {}
        virtual ~Node() {}

        virtual void print(std::ostream& out) = 0;
        void inferTypeIfUnknown(InferredType type);
    };

    typedef std::vector<NodePtr> Nodes;

    class LiteralNode;
    typedef LiteralNode* LiteralNodePtr;
    class ListNode;
    typedef ListNode* ListNodePtr;
    typedef const char* LiteralName;
    typedef std::string* StringPtr;

    enum LiteralType {
      Keyword,
      Const,
      Text,
      Identifier,
      Flag,
      Bookmark
    };


    class NodeFactory {
      public:
        static LiteralNodePtr createLiteralNode(LiteralType type_, StringPtr str_);
        static LiteralNodePtr createLiteralNode(LiteralName keyword);
        static ListNodePtr createListNode();
        static ListNodePtr createListNode(LiteralName keyword);
        static ListNodePtr createListNode(LiteralName keyword, Nodes& nodes);
        static ListNodePtr createListNode(LiteralName keyword, NodePtr child);
        static ListNodePtr createListNode(LiteralName keyword, NodePtr child1, NodePtr child2);
        static ListNodePtr createListNode(LiteralName keyword, NodePtr child1, NodePtr child2, NodePtr child3);
        static ListNodePtr createListNode(LiteralName keyword, InferredType inferredType);
        static ListNodePtr createListNode(LiteralName keyword, InferredType inferredType, NodePtr child);
        static ListNodePtr createListNode(LiteralName keyword, InferredType inferredType, NodePtr child1, NodePtr child2);

        static NodePtr createIdentifier(const char* str);
        static NodePtr createText(const char* str);
        static NodePtr createIntConstant(const char* str);
        static NodePtr createFloatConstant(const char* str);
        static LiteralNodePtr createFlag(LiteralName prefix, LiteralNodePtr node);
    };

    class LiteralNode : public Node {
      public:
        LiteralType type;
        StringPtr str;
        bool showInferredType;

        LiteralNode(LiteralType type_, StringPtr str_) : Node(NodeKind::Literal), type(type_), str(str_), showInferredType(false) {}
        LiteralNode(LiteralType type_, StringPtr str_, InferredType inferredType) : Node(NodeKind::Literal, inferredType), type(type_), str(str_), showInferredType(false) {}

        void print(std::ostream& out);
    };

    class ListNode : public Node {
      public:
        Nodes children;

        ListNode() : Node(NodeKind::List) {}

        void append(NodePtr node);
        void insertAt(NodePtr node, size_t index);
        void move(Nodes& group);
        void moveWrapped(Nodes& group, LiteralName name);

        void print(std::ostream& out);
    };

    typedef ListNode* ListNodePtr;

    struct LabeledNodes {
        Nodes nodes;
        NodePtr label;
        LabeledNodes(): nodes(), label(nullptr) {}

        ListNodePtr toBlockNode(LiteralName name);
        void fromNodes(Nodes& items);
        void prependInnerBlock(LabeledNodes& inner);
    };

    struct MemoryOperator {
        LiteralName name;
        InferredType type;
        MemoryOperator() : name(nullptr), type(InferredType::Unknown) {}
        MemoryOperator(LiteralName name_, InferredType type_) : name(name_), type(type_) {}
    };

    struct MemoryAddress {
        NodePtr base;
        LiteralNodePtr offset;
        LiteralNodePtr flags;
        MemoryAddress() : base(nullptr), offset(nullptr), flags(nullptr) {}
        MemoryAddress(Node* base_, LiteralNode* offset_, LiteralNode* flags_) : base(base_), offset(offset_), flags(flags_) {}
    };

    struct VarDefinition {
        NodePtr name;
        NodePtr type;
        VarDefinition(): name(nullptr), type(nullptr) {}
    };

    class VarDefinitions : public std::vector<VarDefinition> {
      public:
        void toASTNodes(const char* nodeName, Nodes& nodes);
        void fromNames(Nodes& names, NodePtr type);
    };

    template<typename T>
    T& append_to(T& a, T& b) { a.insert(a.end(), b.begin(), b.end()); return a; }
    template<typename T>
    std::vector<T>& append_item_to(std::vector<T>& a, T b) { a.push_back(b); return a; }

    InferredType parse_inferred_type(LiteralName str);

}  /* end namespace AST */

#endif /* AST_HPP_ */
