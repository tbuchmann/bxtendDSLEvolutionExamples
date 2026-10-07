package de.tbuchmann.ecore2sql.bxtenddsl.rules;

import de.tbuchmann.ecore2sql.bxtenddsl.trafo.Ecore2Sql
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EClassifier
import org.eclipse.emf.ecore.EReference
import org.eclipse.emf.ecore.EcoreFactory
import org.eclipse.emf.ecore.util.EcoreUtil
import sql.Property
import sql.Table

import static extension de.tbuchmann.ecore2sql.bxtenddsl.rules.SqlSupport.*

// bidirectional cross reference: one relation table for both ends, created for the end with the smaller name
class Reference2RelationImpl extends Reference2Relation {	
	new(Ecore2Sql trafo) {
		super(trafo)
	}

	// a reference or attribute that stops satisfying the filter of its rule (for example a reference that lost its
	// opposite, an attribute that became multi-valued) moves to the other rule
	override protected dissolveOnFilterMismatch() {
		true
	}

	// only one of the two ends (the one with the smaller name) creates the table
	override protected filterS(EReference s) {
		!s.containment && s.EOpposite !== null && !s.EOpposite.containment
			&& s.endName.compareTo(s.EOpposite.endName) < 0
	}

	// tables that stem from a bidirectional cross reference (annotation based)
	override protected filterT(Table t) {
		t.hasAnnotation("cross") && t.hasAnnotation("bidirectional")
	}

	// table name <class>_<ref>_inverse_<target class>_<opposite>
	override protected tNameFrom(String sName, EReference eOpposite, EClass eContainingClass, EClassifier eType) {
		new Type4tName(eContainingClass.name + "_" + sName + "_inverse_" + eType.name + "_" + eOpposite.name)
	}

	// the two ends created from a relation table: the keys "source" and "target" reference the tables of the classes,
	// the names are encoded in the name of the table (<source class>_<name>_inverse_<target class>_<opposite name>)
	override protected onSCreation(EReference s) {
		val t = s.getCorr.flatTrg.head as Table
		val sourceKey = t.ownedForeignKeys.findFirst[column.name == "source"]
		val targetKey = t.ownedForeignKeys.findFirst[column.name == "target"]
		if (sourceKey !== null && targetKey !== null && sourceKey.referencedTable !== null
				&& targetKey.referencedTable !== null && hasCorr(sourceKey.referencedTable)
				&& hasCorr(targetKey.referencedTable) && t.name.contains("_inverse_")) {
			val sourceClass = sourceKey.referencedTable.getCorr.flatSrc.head as EClass
			val targetClass = targetKey.referencedTable.getCorr.flatSrc.head as EClass
			val parts = t.name.split("_inverse_")
			s.name = parts.get(0).withoutPrefix(sourceClass.name + "_")
			s.EType = targetClass
			s.upperBound = if (t.hasAnnotation("forwardSingle")) 1 else -1
			val opposite = EcoreFactory.eINSTANCE.createEReference()
			opposite.name = parts.get(1).withoutPrefix(targetClass.name + "_")
			opposite.EType = sourceClass
			opposite.upperBound = if (t.hasAnnotation("backwardSingle")) 1 else -1
			sourceClass.EStructuralFeatures += s
			targetClass.EStructuralFeatures += opposite
			s.EOpposite = opposite
			opposite.EOpposite = s
		}
	}

	def private String withoutPrefix(String name, String prefix) {
		if (name.startsWith(prefix)) name.substring(prefix.length) else name
	}

	// the other end of a bidirectional reference has no correspondence of its own: it goes with the end that has one
	override protected onSDeletion(EReference s) {
		if (s.EOpposite !== null && !hasCorr(s.EOpposite)) {
			EcoreUtil.delete(s.EOpposite)
		}
	}

	// new relation table: columns "source" and "target" with foreign keys, multiplicities as annotations
	override protected onTCreation(Table t) {
		val s = t.getCorr.flatSrc.head as EReference
		val source = s.EContainingClass.getCorr.flatTrg.head as Table
		val target = s.EType.getCorr.flatTrg.head as Table
		source.owningSchema.ownedTables += t
		t.newColumn("source", "int") => [properties += Property.NOT_NULL; newForeignKey(source)]
		t.newColumn("target", "int") => [properties += Property.NOT_NULL; newForeignKey(target)]
		t.annotate("cross", "bidirectional", if (s.upperBound == 1) "forwardSingle" else "forwardMulti",
			if (s.EOpposite.upperBound == 1) "backwardSingle" else "backwardMulti")
	}

	// sort key of a reference end
	def private String endName(EReference r) {
		r.EContainingClass.name + "_" + r.name
	}
}
