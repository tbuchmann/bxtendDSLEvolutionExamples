package de.tbuchmann.ast2dag.bxtenddsl.rules;

import dag.Operator
import dag.Variable
import dag.Number
import java.util.List
import dag.Expression
import de.tbuchmann.ast2dag.bxtenddsl.trafo.Ast2Dag

class Model2ModelImpl extends Model2Model {	
	new(Ast2Dag trafo) {
		super(trafo)
	}
	
	override protected exprsFrom(Operator expOpeT, Variable expVarT, Number expNumT) {
		new Type4exprs(exprsFrom(expOpeT ?: expVarT ?: expNumT))
	}
	
	override protected exprFrom(List<List<ast.Operator>> expOpeS, List<List<ast.Variable>> expVarS,
			List<List<ast.Number>> expNumS) {
		var expr = if (!expOpeS.empty) {
			expOpeS.flatten().get(0)
		} else if (!expVarS.empty) {
			expVarS.flatten().get(0)
		} else if (!expNumS.empty) {
			expNumS.flatten().get(0)
		} else {
			return new Type4expr(null)
		}
		
		while (expr.leftInverse !== null || expr.rightInverse !== null) {
			if (expr.leftInverse !== null) {
				expr = expr.leftInverse
			} else {
				expr = expr.rightInverse
			}
		}
		new Type4expr(expr)
	}
	
	def private List<Expression> exprsFrom(Expression expr) {
		if (expr === null) {
			return newArrayList()
		} else if (expr instanceof Variable || expr instanceof Number) {
			return newArrayList(expr)
		} else {
			return newArrayList() => [
				it += expr
				it += exprsFrom((expr as Operator).left)
				it += exprsFrom((expr as Operator).right)
			]
		}
	}
}
