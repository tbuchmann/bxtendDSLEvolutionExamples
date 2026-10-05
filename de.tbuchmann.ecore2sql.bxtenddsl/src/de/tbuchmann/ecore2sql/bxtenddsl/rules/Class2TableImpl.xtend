package de.tbuchmann.ecore2sql.bxtenddsl.rules;

import de.tbuchmann.ecore2sql.bxtenddsl.corrmodel.Corr
import de.tbuchmann.ecore2sql.bxtenddsl.corrmodel.Transformation
import de.tbuchmann.ecore2sql.bxtenddsl.trafo.Ecore2Sql
import java.util.List
import java.util.Map
import org.eclipse.emf.ecore.EClass
import sql.Table

import static extension de.tbuchmann.ecore2sql.bxtenddsl.rules.SqlSupport.*

class Class2TableImpl extends Class2Table {	
	new(Ecore2Sql trafo) {
		super(trafo)
	}

	override protected filterT(Table t) {
		t.hasAnnotation("class")
	}

	override protected onTCreation(Table t) {
		val s = t.getCorr.flatSrc.head as EClass
		t.setKind(s.abstract)
		t.annotate("class")
		t.ensurePrimaryKey
		if (t.owningSchema !== null) {
			t.ensureEObjectColumn(t.owningSchema)
		}
	}

	override protected onTDeletion(Table t) {
		t.removeFromEObjectTable
	}

	// Generalisation and abstract are not mappings: their counterparts (a foreign key per super class, an annotation)
	// have no feature in Ecore. The side that changed since the last synchronisation wins, the target wins for
	// a class that has just been created from a table.
	val Map<Corr, List<EClass>> lastSupers = newHashMap
	val Map<Corr, Boolean> lastAbstract = newHashMap

	override afterSynch() {
		super.afterSynch() // the creation hooks of the tables created by synch()
		val corrs = (corrModel.contents.get(0) as Transformation).correspondences
		corrs.filter[it.ruleId == "Class2Table"].toList.forEach[reconcile]
	}

	def private reconcile(Corr corr) {
		val s = corr.flatSrc.head as EClass
		val t = corr.flatTrg.head as Table

		t.syncEObjectColumnName

		val srcSupers = s.ESuperTypes.filter[hasCorr(it)].toList
		val trgSupers = t.ownedForeignKeys.filter[hasAnnotation("superType")].map[referencedTable].filterNull
			.filter[hasCorr(it)].map[it.getCorr.flatSrc.head as EClass].toList
		val lastS = lastSupers.get(corr)
		val supersFromTarget = if (lastS === null) srcSupers.empty && !trgSupers.empty
				else srcSupers.toSet == lastS.toSet && trgSupers.toSet != lastS.toSet
		if (supersFromTarget) {
			s.ESuperTypes.clear()
			s.ESuperTypes += trgSupers
		}
		val supers = s.ESuperTypes.filter[hasCorr(it)].toList
		t.reconcileInheritance(supers.map[it.getCorr.flatTrg.head as Table].toList, t.owningSchema)
		lastSupers.put(corr, supers)

		val trgAbstract = t.hasAnnotation("abstract")
		val lastA = lastAbstract.get(corr)
		if (lastA === null || (s.abstract == lastA && trgAbstract != lastA)) {
			s.abstract = trgAbstract
		} else {
			t.setKind(s.abstract)
		}
		lastAbstract.put(corr, s.abstract)
	}
}
