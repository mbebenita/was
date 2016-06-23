#ifndef TI_HPP_
#define TI_HPP_

#include "ast.hpp"

namespace TI {
    void infer_types(AST::NodePtr module, bool topDown = false);
} // end namespace TI


#endif /* TI_HPP_ */
