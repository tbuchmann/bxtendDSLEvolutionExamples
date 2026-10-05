package de.tbuchmann.ast2dag.bxtenddsl.rules;

import de.tbuchmann.ast2dag.bxtenddsl.trafo.Ast2Dag
import ast.Variable
import java.util.List
import ast.Operator

class Variable2VariableImpl extends Variable2Variable {	
	new(Ast2Dag trafo) {
		super(trafo)
	}
	
	override protected groupSElem(Variable sElem) {
		sElem.name
	}
	override protected filterS(List<Variable> s) {
		!s.empty
	}
	
	override protected tName_tLeftInverse_tRightInverseFrom(List<Variable> s) {
		val leftInverse = s.filter[leftInverse !== null].map[unwrap(leftInverse.corr.target.get(0)) as dag.Operator]
		val rightInverse = s.filter[rightInverse !== null].map[unwrap(rightInverse.corr.target.get(0)) as dag.Operator]
		new Type4tName_tLeftInverse_tRightInverse(s.get(0).name, leftInverse.toList(), rightInverse.toList())
	}
	
	override protected sFrom(SrcMultiElemUpdater<Variable> sUpdater, String tName, List<List<Operator>> tLefS,
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
		new Type4s(sUpdater.finish().map[name = tName; it])
	}
}
