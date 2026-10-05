package de.tbuchmann.ast2dag.bxtenddsl.rules;

import de.tbuchmann.ast2dag.bxtenddsl.trafo.Ast2Dag
import java.util.List
import ast.Number
import ast.Operator

class Number2NumberImpl extends Number2Number {	
	new(Ast2Dag trafo) {
		super(trafo)
	}
	
	override protected groupSElem(Number sElem) {
		sElem.value.toString()
	}
	override protected filterS(List<Number> s) {
		!s.empty
	}
	
	override protected tValue_tLeftInverse_tRightInverseFrom(List<Number> s) {
		val leftInverse = s.filter[leftInverse !== null].map[unwrap(leftInverse.corr.target.get(0)) as dag.Operator]
		val rightInverse = s.filter[rightInverse !== null].map[unwrap(rightInverse.corr.target.get(0)) as dag.Operator]
		new Type4tValue_tLeftInverse_tRightInverse(s.get(0).value, leftInverse.toList(), rightInverse.toList())
	}
	
	override protected sFrom(SrcMultiElemUpdater<Number> sUpdater, int tValue, List<List<Operator>> tLefS,
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
		new Type4s(sUpdater.finish().map[value = tValue; it])
	}
}
