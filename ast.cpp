#include "ast.hpp"

#include <cstring>

using namespace AST;

Node::~Node()
{ }

LiteralNodePtr
NodeFactory::createLiteralNode(LiteralType type_, StringPtr str_)
{
    return new LiteralNode(type_, str_);
}

LiteralNodePtr
NodeFactory::createFlag(LiteralName prefix, LiteralNodePtr node)
{
    std::string s(prefix);
    s.insert(s.size(), *(node->str));
    delete node;
    return new LiteralNode(LiteralType::Flag, new std::string(s));
}

LiteralNodePtr
NodeFactory::createLiteralNode(LiteralName keyword)
{
    return new LiteralNode(LiteralType::Keyword, new std::string(keyword));
}

ListNodePtr
NodeFactory::createListNode()
{
    return new ListNode();
}

ListNodePtr
NodeFactory::createListNode(LiteralName keyword)
{
    ListNode* node = new ListNode();
    node->append(NodeFactory::createLiteralNode(keyword));
    return node;
}

ListNodePtr
NodeFactory::createListNode(LiteralName keyword, Nodes& nodes)
{
    ListNode* node = new ListNode();
    node->append(NodeFactory::createLiteralNode(keyword));
    node->move(nodes);
    return node;
}

ListNodePtr
NodeFactory::createListNode(LiteralName keyword, NodePtr child)
{
    ListNode* node = new ListNode();
    node->append(NodeFactory::createLiteralNode(keyword));
    node->append(child);
    return node;
}

ListNodePtr
NodeFactory::createListNode(LiteralName keyword, NodePtr child1, NodePtr child2)
{
    ListNode* node = new ListNode();
    node->append(NodeFactory::createLiteralNode(keyword));
    node->append(child1);
    node->append(child2);
    return node;
}

ListNodePtr
NodeFactory::createListNode(LiteralName keyword, NodePtr child1, NodePtr child2, NodePtr child3)
{
    ListNode* node= new ListNode();
    node->append(NodeFactory::createLiteralNode(keyword));
    node->append(child1);
    node->append(child2);
    node->append(child3);
    return node;
}

ListNodePtr
NodeFactory::createListNode(LiteralName keyword, InferredType inferredType) {
    ListNode* node = createListNode(keyword);
    node->children[0]->inferredType = inferredType;
    static_cast<LiteralNode*>(node->children[0])->showInferredType = true;
    return node;
}

ListNodePtr
NodeFactory::createListNode(LiteralName keyword, InferredType inferredType, NodePtr child) {
    ListNode* node = createListNode(keyword, child);
    node->children[0]->inferredType = inferredType;
    static_cast<LiteralNode*>(node->children[0])->showInferredType = true;
    return node;
}

ListNodePtr
NodeFactory::createListNode(LiteralName keyword, InferredType inferredType, NodePtr child1, NodePtr child2) {
    ListNode* node = createListNode(keyword, child1, child2);
    node->children[0]->inferredType = inferredType;
    static_cast<LiteralNode*>(node->children[0])->showInferredType = true;
    return node;
}

LiteralNode::~LiteralNode()
{
    if (str)
        delete str;
}

void
LiteralNode::print(std::ostream& out)
{
    if (showInferredType) {
        switch (inferredType) {
          case InferredType::I32: out << "i32."; break;
          case InferredType::I64: out << "i64."; break;
          case InferredType::F32: out << "f32."; break;
          case InferredType::F64: out << "f64."; break;
          case InferredType::Any: out << "any."; break;
          case InferredType::Void: out << "void."; break;
          case InferredType::Unknown: out << "unk."; break;
        }
    }
    out << str->c_str();
}

ListNode::~ListNode()
{
    for (Nodes::iterator it = children.begin(); it != children.end(); it++)
        delete *it;
}

void
ListNode::print(std::ostream& out)
{
    out << "(";
    bool printSpace = false;
    for (std::vector<Node*>::iterator p = children.begin(); p != children.end(); p++) {
        if (printSpace)
            out << " ";
        else
            printSpace = true;
        (*p)->print(out);
    }
    out << ")";
}

void
ListNode::append(Node* node)
{
    children.push_back(node);
}

void
ListNode::insertAt(Node* node, size_t index)
{
    children.insert(children.begin() + index, node);
}

void
ListNode::move(std::vector<Node*> &group)
{
    children.insert(children.end(), group.begin(), group.end());
    group.clear();
}

void
ListNode::moveWrapped(Nodes& group, LiteralName name)
{
    for (Nodes::iterator p = group.begin(); p != group.end(); p++) {
        children.push_back(NodeFactory::createListNode(name, *p));
    }
    group.clear();
}

ListNodePtr
LabeledNodes::toBlockNode(LiteralName name)
{
    ListNode* block = NodeFactory::createListNode(name);
    if (label) {
        block->append(label);
        label = nullptr;
    }
    block->move(nodes);
    return block;
}

void
LabeledNodes::fromNodes(Nodes& items)
{
    items.swap(nodes);
}

void
LabeledNodes::prependInnerBlock(LabeledNodes& inner)
{
    AST::Node* innerBlock = inner.toBlockNode("block");
    nodes.insert(nodes.begin(), innerBlock);
}

void
VarDefinitions::toASTNodes(const char* nodeName, Nodes& target) {
    for (iterator p = begin(); p != end(); p++) {
        ListNode* node = NodeFactory::createListNode(nodeName);
        node->append(p->name);
        node->append(p->type);
        target.push_back(node);
    }
    clear();
}

void
VarDefinitions::fromNames(Nodes& names, LiteralNodePtr type) {
    Nodes::iterator p = names.begin();
    if (p == names.end()) {
        delete type;
        return;
    }
    VarDefinition def;
    def.name = *p;
    def.type = type;
    push_back(def);
    for (p++; p != names.end(); p++) {
        VarDefinition def2;
        def2.name = *p;
        def2.type = new LiteralNode(type->type, new std::string(*(type->str)), type->inferredType);
        push_back(def2);
    }
    names.clear();
}

NodePtr
NodeFactory::createIdentifier(const char* str)
{
    return new AST::LiteralNode(LiteralType::Identifier, new std::string(str));
}

NodePtr
NodeFactory::createText(const char* str)
{
    return new AST::LiteralNode(LiteralType::Text, new std::string(str));
}

NodePtr
NodeFactory::createIntConstant(const char* str)
{
    int i = strlen(str);
    InferredType type = InferredType::I32;
    if (i > 3 && str[i - 3] == 'i' && str[i - 2] == '6' && str[i - 1] == '4') {
      type = InferredType::I64;
      i -= 3;
    } else if (i > 3 && str[i - 3] == 'i' && str[i - 2] == '3' && str[i - 1] == '2') {
      i -= 3;
    }
    return new LiteralNode(LiteralType::Const, new std::string(str, i), type);
}

NodePtr
NodeFactory::createFloatConstant(const char* str)
{
    int i = strlen(str);
    InferredType type = InferredType::F64;
    if (i > 3 && str[i - 3] == 'f' && str[i - 2] == '3' && str[i - 1] == '2') {
      type = InferredType::F32;
      i -= 3;
    } else if (i > 1 && str[i - 1] == 'f') {
      type = InferredType::F32;
      i--;
    } else if (i > 3 && str[i - 3] == 'f' && str[i - 2] == '6' && str[i - 1] == '4') {
      i -= 3;
    }
    return new LiteralNode(LiteralType::Const, new std::string(str, i), type);
}

InferredType
AST::parse_inferred_type(LiteralName str)
{
    if (strlen(str) == 3) {
        if (str[0] == 'i') {
            if (str[1] == '3' && str[2] == '2')
                return InferredType::I32;
            else if (str[1] == '6' && str[2] == '4')
                return InferredType::I64;
        } else if (str[0] == 'f') {
            if (str[1] == '3' && str[2] == '2')
                return InferredType::F32;
            else if (str[1] == '6' && str[2] == '4')
                return InferredType::F64;
        }
    }
    return InferredType::Unknown;
}

void
Node::inferTypeIfUnknown(InferredType type)
{
    if (inferredType != InferredType::Unknown)
        return;
    inferredType = type;
}
