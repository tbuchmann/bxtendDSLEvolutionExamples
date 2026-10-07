package de.tbuchmann.ecore2sql.bxtenddsl.rules;

import de.tbuchmann.ecore2sql.bxtenddsl.corrmodel.Corr
import de.tbuchmann.ecore2sql.bxtenddsl.corrmodel.Transformation
import de.tbuchmann.ecore2sql.bxtenddsl.trafo.Ecore2Sql
import java.util.List
import java.util.Map
import org.eclipse.emf.ecore.EAttribute
import org.eclipse.emf.ecore.EClass
import sql.Property
import sql.Table

import static extension de.tbuchmann.ecore2sql.bxtenddsl.rules.SqlSupport.*

class Attribute2TableImpl extends Attribute2Table {	
	new(Ecore2Sql trafo) {
		super(trafo)
	}
	
	// a reference or attribute that stops satisfying the filter of its rule (for example a reference that lost its
	// opposite, an attribute that became multi-valued) moves to the other rule
	override protected dissolveOnFilterMismatch() {
		true
	}

	// multi-valued attributes only
	override protected filterS(EAttribute s) {
		s.upperBound != 1
	}

	// tables that stem from a multi-valued attribute (annotation based)
	override protected filterT(Table t) {
		t.hasAnnotation("attribute") && t.hasAnnotation("multi")
	}

	// an attribute created from a table: the owner is the class of the table that the id key references
	override protected onSCreation(EAttribute s) {
		val t = s.getCorr.flatTrg.head as Table
		val key = t.ownedForeignKeys.head
		if (key !== null && key.referencedTable !== null && hasCorr(key.referencedTable)) {
			val owner = key.referencedTable.getCorr.flatSrc.head as EClass
			val prefix = owner.name + "_"
			s.name = if (t.name.startsWith(prefix)) t.name.substring(prefix.length) else t.name
			s.upperBound = -1
			val value = t.ownedColumns.findFirst[name == "value"]
			if (value !== null) {
				s.EType = value.type.ecoreType
			}
			owner.EStructuralFeatures += s
		}
	}

	// Name and owner of a multi-valued attribute: its table is named <class>_<attribute> and its id key references the
	// table of the class. Not a feature mapping, because the owner is a reference of the key: the side that changed
	// since the last synchronisation wins (the source if both changed).
	val Map<Corr, List<Object>> lastState = newHashMap

	override afterSynch() {
		super.afterSynch()
		val corrs = (corrModel.contents.get(0) as Transformation).correspondences
		corrs.filter[it.ruleId == "Attribute2Table"].toList.forEach[reconcile]
	}

	def private void reconcile(Corr corr) {
		val s = corr.flatSrc.head as EAttribute
		val t = corr.flatTrg.head as Table
		val key = t.ownedForeignKeys.head
		if (s.EContainingClass === null || key === null || key.referencedTable === null || !hasCorr(key.referencedTable)) {
			return
		}
		val trgOwner = key.referencedTable.getCorr.flatSrc.head as EClass
		val prefix = trgOwner.name + "_"
		val trgName = if (t.name.startsWith(prefix)) t.name.substring(prefix.length) else t.name
		val last = lastState.get(corr)
		val List<Object> srcState = newArrayList(s.name, s.EContainingClass)
		val List<Object> trgState = newArrayList(trgName, trgOwner)
		if (last !== null && srcState == last && trgState != last) {
			s.name = trgName
			if (trgOwner !== s.EContainingClass) {
				trgOwner.EStructuralFeatures += s
			}
		} else {
			t.name = s.EContainingClass.name + "_" + s.name
			val srcOwnerTable = s.EContainingClass.getCorr.flatTrg.head as Table
			if (key.referencedTable !== srcOwnerTable) {
				key.referencedTable = srcOwnerTable
			}
		}
		lastState.put(corr, newArrayList(s.name, s.EContainingClass))
	}

	// new table: columns "id" (foreign key to the owner class table) and "value"
	override protected onTCreation(Table t) {
		val s = t.corr.flatSrc.head as EAttribute
		val owner = s.EContainingClass.corr.flatTrg.head as Table
		t.annotate("attribute", "multi")
		owner.owningSchema.ownedTables += t
		t.newColumn("id", "int") => [
			properties += Property.NOT_NULL
			newForeignKey(owner)
		]
		t.newColumn("value", s.EType.sqlType) => [properties += Property.NOT_NULL]
	}
	
	// table name <class>_<attribute>
	override protected tNameFrom(String sName, EClass eContainingClass) {
		new Type4tName(eContainingClass.name + "_" + sName)
	}
	
}
