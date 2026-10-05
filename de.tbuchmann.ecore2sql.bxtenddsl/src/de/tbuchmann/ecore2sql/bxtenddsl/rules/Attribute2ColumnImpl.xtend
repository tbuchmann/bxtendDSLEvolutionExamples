package de.tbuchmann.ecore2sql.bxtenddsl.rules;

import de.tbuchmann.ecore2sql.bxtenddsl.trafo.Ecore2Sql
import org.eclipse.emf.ecore.EAttribute
import org.eclipse.emf.ecore.EClassifier
import sql.Column

import static extension de.tbuchmann.ecore2sql.bxtenddsl.rules.SqlSupport.*

class Attribute2ColumnImpl extends Attribute2Column {	
	new(Ecore2Sql trafo) {
		super(trafo)
	}
	
	// a reference or attribute that stops satisfying the filter of its rule (for example a reference that lost its
	// opposite, an attribute that became multi-valued) moves to the other rule
	override protected dissolveOnFilterMismatch() {
		true
	}

	// a name changed on both sides: the benchmark expects the target to win
	override protected conflictWinner() {
		Elem2Elem.Side.TARGET
	}

	override protected filterS(EAttribute s) {
		s.upperBound == 1
	}

	override protected filterT(Column t) {
		t.hasAnnotation("attribute") && t.hasAnnotation("single")
	}

	override protected onTCreation(Column t) {
		t.annotate("attribute", "single")
	}
	
	override protected typeFrom(EClassifier eType) {
		new Type4type(eType.sqlType)
	}
	
	override protected eTypeFrom(String type) {
		new Type4eType(type.ecoreType)
	}
	
}
