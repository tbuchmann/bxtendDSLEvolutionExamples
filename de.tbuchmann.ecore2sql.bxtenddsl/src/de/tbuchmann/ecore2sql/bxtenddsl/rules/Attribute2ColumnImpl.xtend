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

	// single-valued attributes only
	override protected filterS(EAttribute s) {
		s.upperBound == 1
	}

	// columns that stem from an attribute (annotation based)
	override protected filterT(Column t) {
		t.hasAnnotation("attribute") && t.hasAnnotation("single")
	}

	// mark the new column so that filterT recognises it
	override protected onTCreation(Column t) {
		t.annotate("attribute", "single")
	}
	
	// Ecore type -> SQL type
	override protected typeFrom(EClassifier eType) {
		new Type4type(eType.sqlType)
	}
	
	// SQL type -> Ecore type
	override protected eTypeFrom(String type) {
		new Type4eType(type.ecoreType)
	}
	
}
