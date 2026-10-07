package de.tbuchmann.ecore2sql.bxtenddsl.rules;

import de.tbuchmann.ecore2sql.bxtenddsl.corrmodel.Transformation
import de.tbuchmann.ecore2sql.bxtenddsl.corrmodel.Corr
import de.tbuchmann.ecore2sql.bxtenddsl.trafo.Ecore2Sql
import java.util.List
import java.util.Map
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EReference
import org.eclipse.emf.ecore.EcoreFactory
import org.eclipse.emf.ecore.util.EcoreUtil
import sql.Column
import sql.ForeignKey
import sql.SqlFactory

import static extension de.tbuchmann.ecore2sql.bxtenddsl.rules.SqlSupport.*

// containment reference: the table of the contained class gets a column with a key to the table of the container
class Containment2ColumnImpl extends Containment2Column {	
	new(Ecore2Sql trafo) {
		super(trafo)
	}

	// a reference or attribute that stops satisfying the filter of its rule (for example a reference that lost its
	// opposite, an attribute that became multi-valued) moves to the other rule
	override protected dissolveOnFilterMismatch() {
		true
	}

	override protected filterS(EReference s) {
		s.containment
	}

	override protected filterT(Column t) {
		t.hasAnnotation("containment")
	}

	// the key that belongs to this column
	override protected filterFk(ForeignKey fk, Column t) {
		fk.column === t && fk.hasAnnotation("containment")
	}

	// column name encodes the reference name (and the opposite name for bidirectional ones)
	override protected tNameFrom(String sName, EReference eOpposite) {
		new Type4tName(if (eOpposite === null) sName + "_inverse" else eOpposite.name + "_inverse_" + sName)
	}

	// a containment reference created from a column and its key: the container is the class of the referenced table,
	// the contained class that of the table with the column; the names are encoded in the name of the column
	override protected onSCreation(EReference s) {
		val corr = s.getCorr
		val column = corr.flatTrg.get(0) as Column
		val key = corr.flatTrg.get(1) as ForeignKey
		if (key.referencedTable !== null && column.owningTable !== null && hasCorr(key.referencedTable)
				&& hasCorr(column.owningTable)) {
			val container = key.referencedTable.getCorr.flatSrc.head as EClass
			val contained = column.owningTable.getCorr.flatSrc.head as EClass
			s.containment = true
			s.EType = contained
			s.upperBound = if (column.hasAnnotation("multi")) -1 else 1
			if (column.hasAnnotation("bidirectional") && column.name.contains("_inverse_")) {
				val names = column.name.split("_inverse_")
				s.name = names.get(1)
				val opposite = EcoreFactory.eINSTANCE.createEReference()
				opposite.name = names.get(0)
				opposite.EType = container
				opposite.upperBound = 1
				contained.EStructuralFeatures += opposite
				s.EOpposite = opposite
				opposite.EOpposite = s
			} else {
				s.name = if (column.name.endsWith("_inverse")) column.name.substring(0, column.name.length - "_inverse".length) else column.name
			}
			container.EStructuralFeatures += s
		}
	}

	// the other end of a bidirectional reference has no correspondence of its own: it goes with the end that has one
	override protected onSDeletion(EReference s) {
		if (s.EOpposite !== null && !hasCorr(s.EOpposite)) {
			EcoreUtil.delete(s.EOpposite)
		}
	}

	// new column and key: type, annotations and delete event
	override protected onTCreation(Column t) {
		t.type = "int"
		t.annotate(t.getCorr.flatSrc.head as EReference)
	}

	override protected onFkCreation(ForeignKey fk) {
		fk.column = fk.getCorr.flatTrg.head as Column
		fk.ownedEvents += SqlFactory.eINSTANCE.createEvent
		fk.annotate(fk.getCorr.flatSrc.head as EReference)
	}

	// annotations that describe the reference
	def private annotate(sql.ModelElement element, EReference s) {
		wanted(s).forEach[a | element.annotate(a)]
	}

	def private wanted(EReference s) {
		#["containment", if (s.EOpposite === null) "unidirectional" else "bidirectional",
			if (s.upperBound == 1) "single" else "multi"]
	}

	// The annotations and the name of the column depend on the reference (opposite, multiplicity, names). The side that
	// changed since the last synchronisation wins (the source if both changed): a column that became bidirectional
	// or unidirectional adds or removes the opposite end.
	val Map<Corr, List<Object>> lastState = newHashMap

	override afterSynch() {
		super.afterSynch()
		val corrs = (corrModel.contents.get(0) as Transformation).correspondences
		for (corr : corrs.filter[it.ruleId == "Containment2Column"].toList) {
			if (corr.flatSrc.size >= 1 && corr.flatTrg.size >= 2) {
				val s = corr.flatSrc.head as EReference
				val column = corr.flatTrg.get(0) as Column
				val key = corr.flatTrg.get(1) as ForeignKey
				val srcState = state(s)
				val trgState = state(column)
				val last = lastState.get(corr)
				if (last !== null && srcState == last && trgState != last) {
					applyTargetState(s, trgState)
				} else {
					val annotations = wanted(s)
					val kinds = #["unidirectional", "bidirectional", "single", "multi"]
					column.setAnnotations(kinds, annotations)
					key.setAnnotations(kinds, annotations)
				}
				lastState.put(corr, state(s))
			}
		}
	}

	// [bidirectional, multi, name, name of the opposite]
	def private List<Object> state(EReference s) {
		val List<Object> result = newArrayList(s.EOpposite !== null, s.upperBound != 1, s.name, s.EOpposite?.name)
		result
	}

	def private List<Object> state(Column column) {
		val bidirectional = column.hasAnnotation("bidirectional") && column.name.contains("_inverse_")
		val names = column.name.split("_inverse_")
		val List<Object> result = if (bidirectional) {
			newArrayList(true, column.hasAnnotation("multi"), names.get(1), names.get(0))
		} else {
			newArrayList(false, column.hasAnnotation("multi"),
				if (column.name.endsWith("_inverse")) column.name.substring(0, column.name.length - "_inverse".length) else column.name,
				null)
		}
		result
	}

	def private void applyTargetState(EReference s, List<Object> state) {
		s.name = state.get(2) as String
		s.upperBound = if (state.get(1) as Boolean) -1 else 1
		if (state.get(0) as Boolean) {
			if (s.EOpposite === null) {
				val opposite = EcoreFactory.eINSTANCE.createEReference()
				opposite.name = state.get(3) as String
				opposite.EType = s.EContainingClass
				opposite.upperBound = 1
				(s.EType as EClass).EStructuralFeatures += opposite
				s.EOpposite = opposite
				opposite.EOpposite = s
			} else {
				s.EOpposite.name = state.get(3) as String
			}
		} else if (s.EOpposite !== null) {
			val opposite = s.EOpposite
			s.EOpposite = null
			EcoreUtil.delete(opposite)
		}
	}
}
