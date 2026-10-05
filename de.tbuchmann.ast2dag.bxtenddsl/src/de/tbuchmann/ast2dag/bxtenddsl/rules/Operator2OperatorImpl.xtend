package de.tbuchmann.ast2dag.bxtenddsl.rules;

import de.tbuchmann.ast2dag.bxtenddsl.trafo.Ast2Dag
import ast.Operator
import java.util.List
import dag.ArithmeticOperator

class Operator2OperatorImpl extends Operator2Operator {	
	new(Ast2Dag trafo) {
		super(trafo)
	}
	
	override protected groupSElem(Operator sElem) {
		computeKey(sElem)
	}
	override protected filterS(List<Operator> s) {
		!s.empty
	}
	
	override protected compareSource(Source lhs, Source rhs) {
		if (computeKey(lhs.s.get(0)).contains(computeKey(rhs.s.get(0)))) {
			return -1
		} else if (computeKey(rhs.s.get(0)).contains(computeKey(lhs.s.get(0)))) {
			return 1
		} else {
			return 0
		}
	}
	
	override protected compareTarget(Target lhs, Target rhs) {
		if (lhs.t.isParent(rhs.t)) {
			return -1
		} else if (rhs.t.isParent(lhs.t)) {
			return 1
		} else {
			return 0
		}
	}
	
	override protected tOp_tLeftInverse_tRightInverseFrom(List<Operator> s) {
		val op = ArithmeticOperator.get(s.get(0).op.literal)
		val leftInverse = s.filter[leftInverse !== null].map[unwrap(leftInverse.corr.target.get(0)) as dag.Operator]
		val rightInverse = s.filter[rightInverse !== null].map[unwrap(rightInverse.corr.target.get(0)) as dag.Operator]
		new Type4tOp_tLeftInverse_tRightInverse(op, leftInverse.toList(), rightInverse.toList())
	}
	
	override protected sFrom(SrcMultiElemUpdater<Operator> sUpdater, ArithmeticOperator tOp, List<List<Operator>> tLefS,
			List<List<Operator>> tRigS) {
		if (tLefS.empty && tRigS.empty) {
			sUpdater.update[leftInverse === null && rightInverse === null]
		}
		for (tLeftInverse : tLefS.flatten()) {
			sUpdater.update[leftInverse == tLeftInverse].leftInverse = tLeftInverse
		}
		for (tRightInverse : tRigS.flatten()) {
			sUpdater.update[rightInverse == tRightInverse].rightInverse = tRightInverse
		}
		new Type4s(sUpdater.finish().map[op = ast.ArithmeticOperator.get(tOp.literal); it])
	}
	
	def private dispatch String computeKey(ast.Operator operator) {
		val opString = switch operator.op {
			case operator.op == ADD: "+"
			case operator.op == SUBTRACT: "-"
			case operator.op == MULTIPLY: "*"
			case operator.op == DIVIDE: "/"
		}
		return "(" + computeKey(operator.left) + opString + computeKey(operator.right) + ")"
	}
	def private dispatch String computeKey(ast.Variable variable) {
		return variable.name.replace("$", "$$").replace("(", "$(").replace(")", "$)").replace("~", "$~")
				.replace("+", "$+").replace("-", "$-").replace("*", "$*").replace("/", "$/")
	}
	def private dispatch computeKey(ast.Number number) {
		return "~" + number.value.toString()
	}
	
	def private boolean isParent(dag.Operator operator, dag.Operator other) {
		if (operator.left == other || operator.right == other) {
			return true
		}
		
		return (operator.left instanceof dag.Operator && (operator.left as dag.Operator).isParent(other))
				|| (operator.right instanceof dag.Operator && (operator.right as dag.Operator).isParent(other))
	}
}
