package de.tbuchmann.ecore2sql.bxtenddsl.rules;

import de.tbuchmann.ecore2sql.bxtenddsl.trafo.Ecore2Sql
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EReference
import sql.Action
import sql.Column
import sql.ForeignKey

import static extension de.tbuchmann.ecore2sql.bxtenddsl.rules.SqlSupport.*

// single valued, unidirectional cross reference: a column with a foreign key in the table of the class
class Reference2ColumnImpl extends Reference2Column {	
	new(Ecore2Sql trafo) {
		super(trafo)
	}

	// a reference or attribute that stops satisfying the filter of its rule (for example a reference that lost its
	// opposite, an attribute that became multi-valued) moves to the other rule
	override protected dissolveOnFilterMismatch() {
		true
	}

	// single-valued, non-containment references without opposite
	override protected filterS(EReference s) {
		!s.containment && s.upperBound == 1 && s.EOpposite === null
	}

	// columns that stem from such a reference (annotation based)
	override protected filterT(Column t) {
		t.hasAnnotation("cross") && t.hasAnnotation("single") && t.hasAnnotation("unidirectional")
	}

	override protected filterFk(ForeignKey fk, Column t) {
		fk.column === t && fk.hasAnnotation("cross") && fk.hasAnnotation("single") && fk.hasAnnotation("unidirectional")
	}

	// a reference created from a column: the containing class cannot be mapped (eContainingClass is derived), the
	// reference is added to the class of the table that owns the column
	override protected onSCreation(EReference s) {
		val column = s.getCorr.flatTrg.head as Column
		if (column.owningTable !== null && hasCorr(column.owningTable)) {
			(column.owningTable.getCorr.flatSrc.head as EClass).EStructuralFeatures += s
		}
	}

	// new column: type and annotations
	override protected onTCreation(Column t) {
		t.type = "int"
		t.annotate("cross", "unidirectional", "single")
	}

	// new key: attach to its column, on delete set null
	override protected onFkCreation(ForeignKey fk) {
		fk.column = fk.getCorr.flatTrg.head as Column
		fk.ownedEvents += sql.SqlFactory.eINSTANCE.createEvent => [action = Action.SET_NULL]
		fk.annotate("cross", "unidirectional", "single")
	}
	
}
