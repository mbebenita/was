#include "ti.hpp"

#include <map>
#include <queue>

using namespace AST;
using namespace TI;

bool
isListNode(NodePtr node)
{
    return node->kind == NodeKind::List;
}

bool isLiteralNode(NodePtr node)
{
    return node->kind == NodeKind::Literal;
}

bool
isListNode(NodePtr node, LiteralName name)
{
    if (node->kind != NodeKind::List)
        return false;
    ListNodePtr list = static_cast<ListNodePtr>(node);
    if (list->children.size() == 0 || !isLiteralNode(list->children[0]))
        return false;
    LiteralNodePtr firstChild = static_cast<LiteralNodePtr>(list->children[0]);
    return name == *(firstChild->str);
}

struct Signature {
    std::vector<InferredType> params;
    std::vector<InferredType> results;
};
typedef std::map<std::string, Signature> SignatureMap;

struct FunctionVars {
    Signature signature;
    std::map<std::string, InferredType> locals;
};
typedef std::map<std::string, FunctionVars> FunctionMap;

struct TopDownInferTypeContext {
    std::map<std::string, InferredType> blocksTypes;
    const std::map<std::string, InferredType>& vars;
    TopDownInferTypeContext(const std::map<std::string, InferredType>& vars_) : blocksTypes(), vars(vars_) {}
    TopDownInferTypeContext(const TopDownInferTypeContext& other) : blocksTypes(other.blocksTypes), vars(other.vars) {}
};

typedef std::pair<NodePtr, TopDownInferTypeContext> NodeQueueItem;
typedef std::queue<NodeQueueItem> NodeQueue;

void
parse_signature(ListNodePtr node, Signature& signature)
{
    for (Nodes::iterator it = node->children.begin() + 1; it != node->children.end(); it++) {
        if (isListNode(*it, "param")) {
            ListNodePtr param = static_cast<ListNodePtr>(*it);
            for (Nodes::iterator it2 = param->children.begin() + 1; it2 != param->children.end(); it2++) {
                InferredType type = parse_inferred_type(static_cast<LiteralNodePtr>(*it2)->str->c_str());
                signature.params.push_back(type);
            }
        } else if (isListNode(*it, "result")) {
            ListNodePtr result = static_cast<ListNodePtr>(*it);
            for (Nodes::iterator it2 = result->children.begin() + 1; it2 != result->children.end(); it2++) {
                InferredType type = parse_inferred_type(static_cast<LiteralNodePtr>(*it2)->str->c_str());
                signature.params.push_back(type);
            }
        }
    }
}

void
infer_types_top_down(ListNodePtr module)
{
    SignatureMap types;
    for (Nodes::iterator p = module->children.begin(); p != module->children.end(); p++) {
        if (isListNode(*p, "type")) {
            ListNodePtr type = static_cast<ListNodePtr>(*p);
            LiteralNodePtr typeName = static_cast<LiteralNodePtr>(type->children[1]);
            Signature signature;
            parse_signature(static_cast<ListNodePtr>(type->children[2]), signature);
            types.insert(std::make_pair(*(typeName->str), signature));
        }
    }
    SignatureMap importTypes;
    FunctionMap functions;
    NodeQueue queue;
    for (Nodes::iterator p = module->children.begin(); p != module->children.end(); p++) {
        if (isListNode(*p, "import")) {
            ListNodePtr import = static_cast<ListNodePtr>(*p);
            LiteralNodePtr importName = static_cast<LiteralNodePtr>(import->children[1]);
            NodePtr type = import->children[4];
            if (isLiteralNode(type)) {
                SignatureMap::iterator found = types.find(*(static_cast<LiteralNodePtr>(type)->str));
                if (found != types.end())
                    importTypes.insert(std::make_pair(*(importName->str), found->second));
            } else if (isListNode(type)) {
                Signature signature;
                parse_signature(static_cast<ListNodePtr>(type), signature);
                importTypes.insert(std::make_pair(*(importName->str), signature));
            }
        } else if (isListNode(*p, "func")) {
            ListNodePtr func = static_cast<ListNodePtr>(*p);
            const std::string& funcName = *(static_cast<LiteralNodePtr>(func->children[1])->str);
            functions.insert(std::make_pair(funcName, FunctionVars()));
            FunctionVars& vars = functions.find(funcName)->second;
            for (Nodes::iterator it = func->children.begin() + 1; it != func->children.end(); it++) {
                if (isListNode(*it, "param")) {
                    ListNodePtr param = static_cast<ListNodePtr>(*it);
                    InferredType type = parse_inferred_type(
                        static_cast<LiteralNodePtr>(param->children[2])->str->c_str());
                    vars.signature.params.push_back(type);
                    vars.locals.insert(std::make_pair(*(static_cast<LiteralNodePtr>(param->children[1])->str), type));
                } else if (isListNode(*it, "result")) {
                    ListNodePtr result = static_cast<ListNodePtr>(*it);
                    InferredType type = parse_inferred_type(
                        static_cast<LiteralNodePtr>(result->children[1])->str->c_str());
                    vars.signature.results.push_back(type);
                } else if (isListNode(*it, "local")) {
                    ListNodePtr local = static_cast<ListNodePtr>(*it);
                    InferredType type = parse_inferred_type(
                        static_cast<LiteralNodePtr>(local->children[2])->str->c_str());
                    vars.locals.insert(std::make_pair(*(static_cast<LiteralNodePtr>(local->children[1])->str), type));
                }
            }
            queue.push(NodeQueueItem(func, TopDownInferTypeContext(vars.locals)));
        }
    }

    for (; !queue.empty(); queue.pop()) {
        NodePtr item = queue.front().first;
        const TopDownInferTypeContext& ctx = queue.front().second;
        if (!isListNode(item) || static_cast<ListNodePtr>(item)->children.size() == 0 ||
            !isLiteralNode(static_cast<ListNodePtr>(item)->children[0]))
            continue;
        LiteralNodePtr itemNameNode = static_cast<LiteralNodePtr>(static_cast<ListNodePtr>(item)->children[0]);
        itemNameNode->inferTypeIfUnknown(item->inferredType);
        if (isListNode(item, "func")) {
            ListNodePtr func = static_cast<ListNodePtr>(item);
            Nodes::iterator it = func->children.begin() + 1;
            if (it != func->children.end() && isLiteralNode(*it)) it++;
            while (it != func->children.end() && isListNode(*it, "param")) it++;
            InferredType type = InferredType::Void;
            if (it != func->children.end() && isListNode(*it, "result")) {
                type = parse_inferred_type(static_cast<LiteralNodePtr>(
                    static_cast<ListNodePtr>(*it)->children[1])->str->c_str());
                it++;
            }
            while (it != func->children.end() && isListNode(*it, "local")) it++;
            for (; it != func->children.end(); it++) {
                NodePtr i = *it;
                i->inferTypeIfUnknown(it + 1 == func->children.end() ? type : InferredType::Any);
                queue.push(NodeQueueItem(i, ctx));
            }
        } else if (isListNode(item, "block") || isListNode(item, "loop") ||
                   isListNode(item, "then") || isListNode(item, "else")) {
            ListNodePtr block = static_cast<ListNodePtr>(item);
            Nodes::iterator it = block->children.begin() + 1;
            TopDownInferTypeContext blockCtx(ctx);
            if (it != block->children.end() && isLiteralNode(*it)) {
                blockCtx.blocksTypes.insert(std::make_pair(*(static_cast<LiteralNodePtr>(*it)->str), block->inferredType));
                it++;
            }
            if (it != block->children.end() && isListNode(item, "loop") && isLiteralNode(*it)) {
                blockCtx.blocksTypes.insert(std::make_pair(*(static_cast<LiteralNodePtr>(*it)->str), InferredType::Any));
                it++;
            }
            for (; it != block->children.end(); it++) {
                NodePtr i = *it;
                if (!isListNode(i))
                    continue;
                i->inferTypeIfUnknown(it + 1 == block->children.end() ? block->inferredType : InferredType::Any);
                queue.push(NodeQueueItem(i, blockCtx));
            }
        } else if (isListNode(item, "if")) {
            ListNodePtr if_ = static_cast<ListNodePtr>(item);
            if_->children[1]->inferTypeIfUnknown(InferredType::I32);
            queue.push(NodeQueueItem(if_->children[1], ctx));
            if_->children[2]->inferTypeIfUnknown(if_->inferredType);
            queue.push(NodeQueueItem(if_->children[2], ctx));
            if (if_->children.size() > 2) {
                if_->children[3]->inferTypeIfUnknown(if_->inferredType);
                queue.push(NodeQueueItem(if_->children[3], ctx));
            }
        } else if (isListNode(item, "call")) {
            ListNodePtr call = static_cast<ListNodePtr>(item);
            FunctionMap::iterator foundFn = functions.find(*(static_cast<LiteralNodePtr>(call->children[1])->str));
            if (foundFn == functions.end()) continue;
            const FunctionVars& vars = foundFn->second;
            for (size_t i = 0; i < vars.signature.params.size(); i++) {
                call->children[2 + i]->inferTypeIfUnknown(vars.signature.params[i]);
                queue.push(NodeQueueItem(call->children[2 + i], ctx));
            }
        } else if (isListNode(item, "call_import")) {
            ListNodePtr call = static_cast<ListNodePtr>(item);
            SignatureMap::iterator found = importTypes.find(*(static_cast<LiteralNodePtr>(call->children[1])->str));
            if (found == importTypes.end()) continue;
            const Signature& signature = found->second;
            for (size_t i = 0; i < signature.params.size(); i++) {
                call->children[2 + i]->inferTypeIfUnknown(signature.params[i]);
                queue.push(NodeQueueItem(call->children[2 + i], ctx));
            }
        } else if (isListNode(item, "call_indirect")) {
            ListNodePtr call = static_cast<ListNodePtr>(item);
            SignatureMap::iterator found = types.find(*(static_cast<LiteralNodePtr>(call->children[1])->str));
            if (found == types.end()) continue;
            const Signature& signature = found->second;
            call->children[2]->inferTypeIfUnknown(InferredType::I32);
            queue.push(NodeQueueItem(call->children[2], ctx));
            for (size_t i = 0; i < signature.params.size(); i++) {
                call->children[3 + i]->inferTypeIfUnknown(signature.params[i]);
                queue.push(NodeQueueItem(call->children[3 + i], ctx));
            }
        } else if (isListNode(item, "select")) {
            ListNodePtr select = static_cast<ListNodePtr>(item);
            select->children[1]->inferTypeIfUnknown(select->inferredType);
            queue.push(NodeQueueItem(select->children[1], ctx));
            select->children[2]->inferTypeIfUnknown(select->inferredType);
            queue.push(NodeQueueItem(select->children[2], ctx));
            select->children[3]->inferTypeIfUnknown(InferredType::I32);
            queue.push(NodeQueueItem(select->children[3], ctx));
        } else if (isListNode(item, "br")) {
            ListNodePtr br = static_cast<ListNodePtr>(item);
            if (br->children.size() > 2) {
                InferredType type = ctx.blocksTypes.find(*(static_cast<LiteralNodePtr>(br->children[1])->str))->second;
                br->children[2]->inferTypeIfUnknown(type);
                queue.push(NodeQueueItem(br->children[2], ctx));
            }
        } else if (isListNode(item, "br_if")) {
            ListNodePtr br = static_cast<ListNodePtr>(item);
            br->children[2]->inferTypeIfUnknown(InferredType::I32);
            queue.push(NodeQueueItem(br->children[2], ctx));
            if (br->children.size() > 3) {
                InferredType type = ctx.blocksTypes.find(*(static_cast<LiteralNodePtr>(br->children[1])->str))->second;
                br->children[3]->inferTypeIfUnknown(type);
                queue.push(NodeQueueItem(br->children[3], ctx));
            }
        } else if (isListNode(item, "br_table")) {
            ListNodePtr br = static_cast<ListNodePtr>(item);
            size_t childrenCount = br->children.size();
            if (childrenCount > 3) {
                size_t i = childrenCount > 4 && isListNode(br->children[childrenCount - 2]) ?
                    childrenCount - 2 : childrenCount - 1;
                br->children[i]->inferTypeIfUnknown(InferredType::I32);
                queue.push(NodeQueueItem(br->children[i], ctx));
                if (i + 1 > childrenCount) {
                    InferredType type = ctx.blocksTypes.find(*(static_cast<LiteralNodePtr>(br->children[1])->str))->second;
                    br->children[i + 1]->inferTypeIfUnknown(type);
                    queue.push(NodeQueueItem(br->children[i + 1], ctx));
                }
            }
        } else if (isListNode(item, "set_local")) {
            ListNodePtr local = static_cast<ListNodePtr>(item);
            InferredType type = ctx.vars.find(*(static_cast<LiteralNodePtr>(local->children[1])->str))->second;
            local->children[2]->inferTypeIfUnknown(type);
            queue.push(NodeQueueItem(local->children[2], ctx));
        } else if (isListNode(item, "store") || isListNode(item, "store/8") ||
                   isListNode(item, "store/16") || isListNode(item, "store/32")) {
            ListNodePtr store = static_cast<ListNodePtr>(item);
            size_t i = store->children.size() - 2;
            store->children[i]->inferTypeIfUnknown(InferredType::I32);
            queue.push(NodeQueueItem(store->children[i], ctx));
            store->children[i + 1]->inferTypeIfUnknown(store->inferredType);
            queue.push(NodeQueueItem(store->children[i + 1], ctx));
        } else if (isListNode(item, "load/8u") || isListNode(item, "load/8s") ||
                   isListNode(item, "load/16u") || isListNode(item, "load/16s") ||
                   isListNode(item, "load/32u") || isListNode(item, "load/32s") ||
                   isListNode(item, "load")) {
            ListNodePtr load = static_cast<ListNodePtr>(item);
            size_t i = load->children.size() - 1;
            load->children[i]->inferTypeIfUnknown(InferredType::I32);
            queue.push(NodeQueueItem(load->children[i], ctx));
        } else if (isListNode(item, "extend_s/i32") || isListNode(item, "extend_u/i32") ||
                   isListNode(item, "convert_s/i32") || isListNode(item, "convert_u/i32") ||
                   isListNode(item, "reinterpret/i32")) {
            ListNodePtr convert = static_cast<ListNodePtr>(item);
            convert->children[1]->inferTypeIfUnknown(InferredType::I32);
            queue.push(NodeQueueItem(convert->children[1], ctx));
        } else if (isListNode(item, "wrap/i64") || isListNode(item, "reinterpret/i64") ||
                   isListNode(item, "convert_s/i64") || isListNode(item, "convert_u/i64")) {
            ListNodePtr convert = static_cast<ListNodePtr>(item);
            convert->children[1]->inferTypeIfUnknown(InferredType::I64);
            queue.push(NodeQueueItem(convert->children[1], ctx));
        } else if (isListNode(item, "promote/f32") || isListNode(item, "reinterpret/f32") ||
                   isListNode(item, "trunc_s/f32") || isListNode(item, "trunc_u/f32")) {
            ListNodePtr convert = static_cast<ListNodePtr>(item);
            convert->children[1]->inferTypeIfUnknown(InferredType::F32);
            queue.push(NodeQueueItem(convert->children[1], ctx));
        } else if (isListNode(item, "demote/f64") || isListNode(item, "reinterpret/f64") ||
                   isListNode(item, "trunc_s/f64") || isListNode(item, "trunc_u/f64")) {
            ListNodePtr convert = static_cast<ListNodePtr>(item);
            convert->children[1]->inferTypeIfUnknown(InferredType::F64);
            queue.push(NodeQueueItem(convert->children[1], ctx));
        } else if (isListNode(item, "shl") || isListNode(item, "shr_s") || isListNode(item, "shr_u")) {
            ListNodePtr shift = static_cast<ListNodePtr>(item);
            shift->children[1]->inferTypeIfUnknown(shift->inferredType);
            queue.push(NodeQueueItem(shift->children[1], ctx));
            shift->children[2]->inferTypeIfUnknown(InferredType::I32);
            queue.push(NodeQueueItem(shift->children[2], ctx));
        } else if (isListNode(item, "eqz")) {
            ListNodePtr eqz = static_cast<ListNodePtr>(item);
            // !!! cannot infer type here
            itemNameNode->inferredType = InferredType::Any;
            eqz->children[1]->inferTypeIfUnknown(InferredType::Any);
            queue.push(NodeQueueItem(eqz->children[1], ctx));
            eqz->inferredType = InferredType::I32; // fixes type set by parser
        } else if (isListNode(item, "lt") || isListNode(item, "lt_s") || isListNode(item, "lt_u") ||
                   isListNode(item, "le") || isListNode(item, "le_s") || isListNode(item, "le_u") ||
                   isListNode(item, "gt") || isListNode(item, "gt_s") || isListNode(item, "gt_u") ||
                   isListNode(item, "ge") || isListNode(item, "ge_s") || isListNode(item, "ge_u") ||
                   isListNode(item, "eq") || isListNode(item, "ne")) {
            ListNodePtr cmp = static_cast<ListNodePtr>(item);
            // !!! cannot infer type here
            itemNameNode->inferredType = InferredType::Any;
            cmp->children[1]->inferTypeIfUnknown(InferredType::Any);
            queue.push(NodeQueueItem(cmp->children[1], ctx));
            cmp->children[2]->inferTypeIfUnknown(InferredType::Any);
            queue.push(NodeQueueItem(cmp->children[2], ctx));
            cmp->inferredType = InferredType::I32; // fixes type set by parser
        } else {
            ListNodePtr expr = static_cast<ListNodePtr>(item);
            for (Nodes::iterator it = expr->children.begin() + 1; it != expr->children.end(); it++) {
                if (!isListNode(*it))
                    continue;
                (*it)->inferTypeIfUnknown(expr->inferredType);
                queue.push(NodeQueueItem(*it, ctx));
            }
        }
    }
}

struct BottomUpInferTypeContext {
    SignatureMap types;
    SignatureMap importTypes;
    SignatureMap functionTypes;
    std::map<std::string, InferredType> locals;
};

InferredType
infer_expression_type(NodePtr item, BottomUpInferTypeContext& ctx)
{
    InferredType result = InferredType::Unknown;
    ListNodePtr expr = static_cast<ListNodePtr>(item);
    LiteralNodePtr exprNameNode = static_cast<LiteralNodePtr>(expr->children[0]);

    if (isListNode(expr, "block") || isListNode(expr, "loop") ||
               isListNode(expr, "then") || isListNode(expr, "else")) {
        Nodes::iterator it = expr->children.begin() + 1;
        result = InferredType::Void;
        for (; it != expr->children.end(); it++) {
            NodePtr i = *it;
            if (!isListNode(i))
                continue;
            result = infer_expression_type(*it, ctx);
        }
    } else if (isListNode(expr, "if")) {
        infer_expression_type(expr->children[1], ctx);
        infer_expression_type(expr->children[2], ctx);
        if (expr->children.size() > 2)
            result = infer_expression_type(expr->children[3], ctx);
        else
            result = InferredType::Void;
    } else if (isListNode(expr, "call")) {
        SignatureMap::iterator found = ctx.functionTypes.find(*(static_cast<LiteralNodePtr>(expr->children[1])->str));
        if (found != ctx.functionTypes.end()) {
            const Signature& signature = found->second;
            for (size_t i = 0; i < signature.params.size(); i++) {
                infer_expression_type(expr->children[2 + i], ctx);
            }
            result = signature.results.size() > 0 ? signature.results[0] : InferredType::Void;
        }
    } else if (isListNode(expr, "call_import")) {
        SignatureMap::iterator found = ctx.importTypes.find(*(static_cast<LiteralNodePtr>(expr->children[1])->str));
        if (found != ctx.importTypes.end()) {
            const Signature& signature = found->second;
            for (size_t i = 0; i < signature.params.size(); i++) {
                infer_expression_type(expr->children[2 + i], ctx);
            }
            result = signature.results.size() > 0 ? signature.results[0] : InferredType::Void;
        }
    } else if (isListNode(expr, "call_indirect")) {
        SignatureMap::iterator found = ctx.types.find(*(static_cast<LiteralNodePtr>(expr->children[1])->str));
        if (found != ctx.types.end()) {
            const Signature& signature = found->second;
            infer_expression_type(expr->children[2], ctx);
            for (size_t i = 0; i < signature.params.size(); i++) {
                infer_expression_type(expr->children[3 + i], ctx);
            }
            result = signature.results.size() > 0 ? signature.results[0] : InferredType::Void;
        }
    } else if (isListNode(expr, "select")) {
        result = infer_expression_type(expr->children[1], ctx);
        infer_expression_type(expr->children[2], ctx);
        infer_expression_type(expr->children[3], ctx);
    } else if (isListNode(expr, "br")) {
        if (expr->children.size() > 2) {
            result = infer_expression_type(expr->children[2], ctx);
        }
        result = InferredType::Void;
    } else if (isListNode(expr, "br_if")) {
        infer_expression_type(expr->children[2], ctx);
        if (expr->children.size() > 3) {
            infer_expression_type(expr->children[3], ctx);
        }
        result = InferredType::Void;
    } else if (isListNode(expr, "br_table")) {
        size_t childrenCount = expr->children.size();
        if (childrenCount > 3) {
            size_t i = childrenCount > 4 && isListNode(expr->children[childrenCount - 2]) ?
                childrenCount - 2 : childrenCount - 1;
            infer_expression_type(expr->children[i], ctx);
            if (i + 1 > childrenCount) {
                infer_expression_type(expr->children[i + 1], ctx);
            }
        }
        result = InferredType::Void;
    } else if (isListNode(expr, "get_local")) {
        std::map<std::string, InferredType>::iterator found =
            ctx.locals.find(*(static_cast<LiteralNodePtr>(expr->children[1])->str));
        if (found != ctx.locals.end())
            result = found->second;
    } else if (isListNode(expr, "eqz")) {
        exprNameNode->inferredType = // override op name type
            infer_expression_type(expr->children[1], ctx);
        result = InferredType::I32;
    } else if (isListNode(expr, "lt") || isListNode(expr, "lt_s") || isListNode(expr, "lt_u") ||
               isListNode(expr, "le") || isListNode(expr, "le_s") || isListNode(expr, "le_u") ||
               isListNode(expr, "gt") || isListNode(expr, "gt_s") || isListNode(expr, "gt_u") ||
               isListNode(expr, "ge") || isListNode(expr, "ge_s") || isListNode(expr, "ge_u") ||
               isListNode(expr, "eq") || isListNode(expr, "ne")) {
        exprNameNode->inferredType = // override op name type
            infer_expression_type(expr->children[1], ctx);
        infer_expression_type(expr->children[2], ctx);
        result = InferredType::I32;
    } else if (isListNode(expr, "unreachable")) {
        result = InferredType::Any;
    } else if (isListNode(expr, "nop")) {
        result = InferredType::Void;
    } else {
        result = exprNameNode->inferredType;
        for (Nodes::iterator it = expr->children.begin() + 1; it != expr->children.end(); it++) {
            if (!isListNode(*it))
                continue;
            InferredType exprResult = infer_expression_type(*it, ctx);
            if (result == InferredType::Unknown) // using first known operand type
                result = exprResult;
        }
    }
    exprNameNode->inferTypeIfUnknown(result);
    expr->inferTypeIfUnknown(result);
    return result;
}

void
infer_types_bottom_up(ListNodePtr module)
{
    BottomUpInferTypeContext ctx;
    SignatureMap& types = ctx.types;
    for (Nodes::iterator p = module->children.begin(); p != module->children.end(); p++) {
        if (isListNode(*p, "type")) {
            ListNodePtr type = static_cast<ListNodePtr>(*p);
            LiteralNodePtr typeName = static_cast<LiteralNodePtr>(type->children[1]);
            Signature signature;
            parse_signature(static_cast<ListNodePtr>(type->children[2]), signature);
            types.insert(std::make_pair(*(typeName->str), signature));
        }
    }
    SignatureMap& importTypes = ctx.importTypes;
    SignatureMap& functionTypes = ctx.functionTypes;
    for (Nodes::iterator p = module->children.begin(); p != module->children.end(); p++) {
        if (isListNode(*p, "import")) {
            ListNodePtr import = static_cast<ListNodePtr>(*p);
            LiteralNodePtr importName = static_cast<LiteralNodePtr>(import->children[1]);
            NodePtr type = import->children[4];
            if (isLiteralNode(type)) {
                SignatureMap::iterator found = types.find(*(static_cast<LiteralNodePtr>(type)->str));
                if (found != types.end())
                    importTypes.insert(std::make_pair(*(importName->str), found->second));
            } else if (isListNode(type)) {
                Signature signature;
                parse_signature(static_cast<ListNodePtr>(type), signature);
                importTypes.insert(std::make_pair(*(importName->str), signature));
            }
        } else if (isListNode(*p, "func")) {
            ListNodePtr func = static_cast<ListNodePtr>(*p);
            const std::string& funcName = *(static_cast<LiteralNodePtr>(func->children[1])->str);
            Signature signature;
            for (Nodes::iterator it = func->children.begin() + 1; it != func->children.end(); it++) {
                if (isListNode(*it, "param")) {
                    ListNodePtr param = static_cast<ListNodePtr>(*it);
                    InferredType type = parse_inferred_type(
                        static_cast<LiteralNodePtr>(param->children[2])->str->c_str());
                    signature.params.push_back(type);
                } else if (isListNode(*it, "result")) {
                    ListNodePtr result = static_cast<ListNodePtr>(*it);
                    InferredType type = parse_inferred_type(
                        static_cast<LiteralNodePtr>(result->children[1])->str->c_str());
                    signature.results.push_back(type);
                }
            }
            functionTypes.insert(std::make_pair(funcName, signature));
        }
    }
    for (Nodes::iterator p = module->children.begin(); p != module->children.end(); p++) {
        if (isListNode(*p, "func")) {
            ListNodePtr func = static_cast<ListNodePtr>(*p);
            ctx.locals.clear();
            Nodes::iterator it = func->children.begin() + 1;
            for (; it != func->children.end(); it++) {
                if (isListNode(*it, "param")) {
                    ListNodePtr param = static_cast<ListNodePtr>(*it);
                    InferredType type = parse_inferred_type(
                        static_cast<LiteralNodePtr>(param->children[2])->str->c_str());
                    ctx.locals.insert(std::make_pair(*(static_cast<LiteralNodePtr>(param->children[1])->str), type));
                } else if (isListNode(*it, "local")) {
                    ListNodePtr local = static_cast<ListNodePtr>(*it);
                    InferredType type = parse_inferred_type(
                        static_cast<LiteralNodePtr>(local->children[2])->str->c_str());
                    ctx.locals.insert(std::make_pair(*(static_cast<LiteralNodePtr>(local->children[1])->str), type));
                } else if (isListNode(*it, "result")) {
                    // nop
                } else if (isListNode(*it)){
                    infer_expression_type(static_cast<ListNodePtr>(*it), ctx);
                }
            }
        }
    }
}

void
TI::infer_types(NodePtr node, bool topDown)
{
    if (!isListNode(node, "module"))
        return;
    if (topDown)
        infer_types_top_down(static_cast<ListNodePtr>(node));
    else
        infer_types_bottom_up(static_cast<ListNodePtr>(node));
}
