package de.tbuchmann.set2oset.bxtenddsl.rules

import de.tbuchmann.set2oset.bxtenddsl.corrmodel.Corr
import de.tbuchmann.set2oset.bxtenddsl.corrmodel.CorrElem
import de.tbuchmann.set2oset.bxtenddsl.corrmodel.CorrModelFactory
import de.tbuchmann.set2oset.bxtenddsl.corrmodel.MultiElem
import de.tbuchmann.set2oset.bxtenddsl.corrmodel.SingleElem
import de.tbuchmann.set2oset.bxtenddsl.corrmodel.Transformation
import de.tbuchmann.set2oset.bxtenddsl.trafo.Set2OSet
import java.util.ArrayList
import java.util.HashMap
import java.util.LinkedHashMap
import java.util.List
import java.util.Map
import java.util.Objects
import java.util.Set
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtend.lib.annotations.Data
import org.eclipse.xtext.xbase.lib.Functions.Function0
import org.eclipse.xtext.xbase.lib.Functions.Function1

abstract class Elem2Elem {
	val public String ruleId
	
	val protected Set2OSet trafo
	val protected Resource sourceModel
	val protected Resource targetModel
	val protected Resource corrModel
	
	protected List<EObject> createdElems
	protected List<EObject> spareElems
	
	/**
	 * Set by synch() while it calls sourceToTarget / targetToSource of a rule with several matchers: only the
	 * matches whose elements have no corr yet are processed.
	 */
	protected boolean onlyUnmatched = false
	
	/**
	 * Elements created by synch() since the last afterSynch(): their creation hooks are called after
	 * all rules have been synchronised, so that the hooks see the final containment, as in sourceToTarget.
	 */
	val protected List<EObject> createdSrcElems = new ArrayList<EObject>()
	val protected List<EObject> createdTrgElems = new ArrayList<EObject>()
	protected Set<EObject> detachedCorrElems
	
	val protected static sourcePackage = sets.SetsPackage::eINSTANCE
	val protected static targetPackage = osets.OsetsPackage::eINSTANCE
	val protected static sourceFactory = sets.SetsFactory::eINSTANCE
	val protected static targetFactory = osets.OsetsFactory::eINSTANCE
	val static corrFactory = CorrModelFactory::eINSTANCE
	
	static protected Map<EObject, Corr> elementsToCorr = newHashMap()
	
	/**
	 * Baseline for ConflictPolicy.DETECT_CHANGES: per corr, the values of the mapped features of every
	 * mapping on both sides (index 2 * i for the source and 2 * i + 1 for the target side of mapping i)
	 * at the end of the last synchronisation.
	 */
	static protected Map<Corr, List<List<Object>>> baselineOf = newHashMap()
	
	/**
	 * Group rules (one group matcher): the key of the group each corr represented when it was last updated.
	 * It only decides ties in detachRekeyedElems.
	 */
	static protected Map<Corr, String> groupKeyOf = newHashMap()
	
	/**
	 * Assigns every corr to the one group that owns it, before the groups are matched with the corrs, and detaches
	 * the elements of the other groups from the corr. The owner is the group that contains most of the corr's
	 * elements; on a tie the group whose key is the key the corr represented at its last update; then the first
	 * group. Without it the result would depend on the order in which the groups are processed: a corr that
	 * still contains an element of another (not yet processed) group would look like a minority group for the
	 * group that actually keeps the corr.
	 */
	def protected <T extends EObject> void detachRekeyedElems(List<List<T>> groups, Function1<? super T, String> keyOf,
			boolean src) {
		val counts = new LinkedHashMap<Corr, Map<Integer, Integer>>()
		for (var gi = 0; gi < groups.size(); gi++) {
			for (element : groups.get(gi)) {
				val corr = elementsToCorr.get(element)
				if (corr !== null && corr.ruleId == this.ruleId) {
					var perGroup = counts.get(corr)
					if (perGroup === null) {
						perGroup = new HashMap<Integer, Integer>()
						counts.put(corr, perGroup)
					}
					perGroup.put(gi, perGroup.getOrDefault(gi, 0) + 1)
				}
			}
		}
		
		val owner = new HashMap<Corr, Integer>()
		for (entry : counts.entrySet()) {
			var max = 0
			for (count : entry.value.values()) {
				if (count > max) max = count
			}
			val oldKey = groupKeyOf.get(entry.key)
			val maxCount = max
			val tied = entry.value.entrySet().filter[e | e.value == maxCount].map[e | e.key].toList().sort()
			var best = tied.head
			if (oldKey !== null) {
				val sameKey = tied.findFirst[gi | oldKey == keyOf.apply(groups.get(gi).get(0))]
				if (sameKey !== null) {
					best = sameKey
				}
			}
			owner.put(entry.key, best)
		}
		
		for (var gi = 0; gi < groups.size(); gi++) {
			for (element : groups.get(gi).toList()) {
				val corr = elementsToCorr.get(element)
				val ownerGroup = if (corr !== null) owner.get(corr)
				if (ownerGroup !== null && ownerGroup != gi) {
					val corrElems = if (src) corr.source else corr.target
					corrElems.filter(MultiElem).forEach[elements.remove(element)]
					elementsToCorr.remove(element)
				}
			}
		}
	}
	
	/**
	 * A copy of a collection value, so that later changes of the collection are detectable.
	 */
	def protected static Object snap(Object value) {
		if (value instanceof List<?>) {
			val copy = new ArrayList<Object>()
			for (element : value as List<?>) {
				copy.add(snapElement(element))
			}
			return copy
		} else {
			return snapElement(value)
		}
	}
	
	/**
	 * The value itself, or for a model element the element together with the values of its attributes: a mapping
	 * (for example a name computed from the names of two referenced activities) depends on them, so a change of such an
	 * attribute is a change of the feature that references the element.
	 */
	def private static Object snapElement(Object value) {
		if (value instanceof EObject) {
			val element = value as EObject
			val snapshot = new ArrayList<Object>()
			snapshot.add(element)
			for (attribute : element.eClass().getEAllAttributes()) {
				val attributeValue = element.eGet(attribute)
				snapshot.add(if (attributeValue instanceof List<?>) new ArrayList<Object>(attributeValue as List<?>) else attributeValue)
			}
			return snapshot
		} else {
			return value
		}
	}
	
	/**
	 * Merges the concurrent changes of a multivalued, correspondence resolved mapping into the source
	 * collection, so that applying the forward mapping afterwards yields the union of both sides:
	 * the counterparts of the elements that were added to the target collection since the baseline are added
	 * to the source collection, the counterparts of the elements that were removed from the target collection
	 * are removed from it. The elements added to or removed from the source collection are handled by the
	 * forward mapping itself.
	 *
	 * @param baseTrg the baseline values of the target side (the first value is the collection)
	 */
	def protected void mergeCollections(Object baseTrg, Object curSrc, Object curTrg) {
		val base = (baseTrg as List<?>).get(0) as List<?>
		val src = curSrc as List<EObject>
		val trg = curTrg as List<EObject>
		for (added : trg.filter[e | !base.contains(e)].toList()) {
			val counterpart = counterpartOf(added)
			if (counterpart !== null && !src.contains(counterpart)) {
				src.add(counterpart)
			}
		}
		for (removed : base.filter(EObject).filter[e | !trg.contains(e)].toList()) {
			val counterpart = counterpartOf(removed)
			if (counterpart !== null) {
				src.remove(counterpart)
			}
		}
	}
	
	/**
	 * The single element on the other side of the corr of the given element, or null.
	 */
	def private EObject counterpartOf(EObject element) {
		val corr = elementsToCorr.get(element)
		if (corr === null) {
			return null
		}
		val other = if (corr.flatTrg.contains(element)) corr.flatSrc else corr.flatTrg
		if (other.size == 1) other.head else null
	}
	
	/**
	 * The copies of the given values as a list (see snap).
	 */
	def protected static List<Object> snapAll(Object... values) {
		val result = new ArrayList<Object>()
		for (value : values) {
			result.add(snap(value))
		}
		return result
	}
	
	new(String ruleId, Set2OSet trafo) {
		this.ruleId = ruleId
		this.trafo = trafo
		sourceModel = trafo.source
		targetModel = trafo.target
		corrModel = trafo.corr;
		(corrModel.contents.get(0) as Transformation).correspondences.forEach[c |
			c.flatSrc.forEach[e | elementsToCorr.put(e, c)]
			c.flatTrg.forEach[e | elementsToCorr.put(e, c)]
		]
	}
	
	@Data static class CorrModelDelta {
		List<EObject> createdElems
		List<EObject> spareElems
		Set<EObject> detachedCorrElems
	}
	
	def abstract CorrModelDelta sourceToTarget(Set<EObject> _detachedCorrElems);
	def void onTrgElemCreation(EObject trgElem) {}
	def void onTrgElemDeletion(EObject trgElem) {}
	
	def abstract CorrModelDelta targetToSource(Set<EObject> _detachedCorrElems);
	def void onSrcElemCreation(EObject srcElem) {}
	def void onSrcElemDeletion(EObject srcElem) {}

	def abstract void synch();
	
	/**
	 * Returns if this rule can be synchronised on its own by synch(). The generated rules of rules with a group
	 * matcher return false (the synch() of such a rule is empty). If any rule returns false, the transformation
	 * synchronises by running sourceToTarget() and targetToSource() for all rules.
	 */
	def boolean supportsSynch() {
		return true
	}
	
	/**
	 * Called by the transformation after all rules have been synchronised: calls the creation hooks for the
	 * elements that synch() created. (The deletion hooks are called by synch() right before an element is deleted.)
	 */
	def void afterSynch() {
		for (elem : createdTrgElems.toList()) {
			onTrgElemCreation(elem)
		}
		for (elem : createdSrcElems.toList()) {
			onSrcElemCreation(elem)
		}
		createdTrgElems.clear()
		createdSrcElems.clear()
	}

	/**
	 * Decides how differing values of mapped features are reconciled for a matched
	 * source/target pair in synch(). Features that are mapped in only one direction or
	 * not mapped at all are never affected.
	 * SOURCE_WINS: the source values overwrite the target values.
	 * TARGET_WINS: the target values overwrite the source values.
	 * CUSTOM: the rule's resolveConflict hook decides.
	 * DETECT_CHANGES (default): every mapping is resolved on its own against a baseline of the mapped feature values
	 * at the end of the last synchronisation: if only the source side changed, the forward mapping is applied;
	 * if only the target side changed, the backward mapping; if both changed (or there is no baseline yet),
	 * the source wins. Mappings without features on both sides are applied forward, then backward.
	 */
	enum ConflictPolicy {
		SOURCE_WINS,
		TARGET_WINS,
		CUSTOM,
		DETECT_CHANGES
	}
	def protected ConflictPolicy conflictPolicy() {
		return ConflictPolicy.DETECT_CHANGES
	}

	def protected boolean hasCorr(EObject obj) {
		return elementsToCorr.containsKey(obj)
	}
	def protected Corr getCorr(EObject obj) {
		val corr = elementsToCorr.get(obj)
		if (corr === null) {
			throw new IllegalArgumentException("No correspondence was created for the given object!")
		} else {
			return corr
		}
	}
	def protected int getCorrElemPosition(EObject element) {
		val source = element.corr.source
		for (var i = 0; i < source.size(); i++) {
			if (source.get(i) instanceof SingleElem && (source.get(i) as SingleElem).element == element) {
				return i
			} else if (source.get(i) instanceof MultiElem && (source.get(i) as MultiElem).elements.contains(element)) {
				return i
			}
		}
		
		val target = element.corr.target
		for (var i = 0; i < target.size(); i++) {
			if (target.get(i) instanceof SingleElem && (target.get(i) as SingleElem).element == element) {
				return i
			} else if (target.get(i) instanceof MultiElem && (target.get(i) as MultiElem).elements.contains(element)) {
				return i
			}
		}
		
		throw new AssertionError("Invalid mapping in elementsToCorr map!")
	}
	
	def protected SingleElem wrap(EObject obj) {
		val singleElem = corrFactory.createSingleElem() => [it.element = obj]
		corrModel.contents += singleElem
		return singleElem
	}
	def protected static dispatch EObject unwrap(SingleElem elem) {
		return elem.element
	}
	def protected MultiElem wrap(List<? extends EObject> objs) {
		val multiElem = corrFactory.createMultiElem() => [it.elements += objs]
		corrModel.contents += multiElem
		return multiElem
	}
	def protected static dispatch List<? extends EObject> unwrap(MultiElem elem) {
		return elem.elements
	}
	
	def protected static void assertRuleId(Corr corr, String... ruleIds) {
		if (!ruleIds.contains(corr.ruleId)) {
			throw new AssertionError("The given corr doesn't have any of the asserted rule ids!")
		}
	}
	
	def protected Corr updateOrCreateCorrSrc(CorrElem elem, CorrElem... additionalElems) {
		return updateOrCreateCorr(elem, true, additionalElems)
	}
	def protected Corr updateOrCreateCorrTrg(CorrElem elem, CorrElem... additionalElems) {
		return updateOrCreateCorr(elem, false, additionalElems)
	}
	
	@Data protected static class CorrElemType {
		String clazz
		boolean multivalued
	}
	def protected List<CorrElem> getOrCreateSrc(Corr corr, CorrElemType... srcTypes) {
		if (srcTypes.empty) throw new IllegalArgumentException("The source elements to create may not be empty!")
		
		var List<CorrElem> source = corr.source
		if (corr.flatSrc.empty) {
			for (type : srcTypes) {
				val corrElem = if (!type.multivalued) {
					val eClass = sourcePackage.getEClassifier(type.clazz) as EClass
					corrFactory.createSingleElem() => [it.element = sourceFactory.create(eClass)]
				} else {
					corrFactory.createMultiElem()
				}
				source += corrElem
			}
			createdElems += corr.flatSrc
			corr.flatSrc.forEach[e | elementsToCorr.put(e, corr)]
		}
		return source
	}
	def protected List<CorrElem> getOrCreateTrg(Corr corr, CorrElemType... trgTypes) {
		if (trgTypes.empty) throw new IllegalArgumentException("The target elements to create may not be empty!")
		
		var List<CorrElem> target = corr.target
		if (corr.flatTrg.empty) {
			for (type : trgTypes) {
				val corrElem = if (!type.multivalued) {
					val eClass = targetPackage.getEClassifier(type.clazz) as EClass
					corrFactory.createSingleElem() => [it.element = targetFactory.create(eClass)]
				} else {
					corrFactory.createMultiElem()
				}
				target += corrElem
			}
			createdElems += corr.flatTrg
			corr.flatTrg.forEach[e | elementsToCorr.put(e, corr)]
		}
		return target
	}
	
	protected static abstract class MultiElemUpdater<T extends EObject> {
		List<T> outdated
		List<T> updated
		val Function0<T> elemFactory
		val Elem2Elem rule
		val Corr corr
		var boolean finished
		
		new(List<T> outdated, Function0<T> elemFactory, Elem2Elem rule, Corr corr) {
			this.outdated = newArrayList() => [it += outdated]
			this.updated = newArrayList()
			this.elemFactory = elemFactory
			this.rule = rule
			this.corr = corr
			this.finished = false
		}
		
		def protected T update(Function1<? super T, Boolean> predicate) {
			if (finished) throw new IllegalStateException("Finish was already called on this MultiElemUpdater!")
			
			val existing = outdated.findFirst[predicate.apply(it)]
			if (outdated.remove(existing)) {
				updated += existing
				return existing
			} else {
				val created = elemFactory.apply()
				rule.createdElems += created
				elementsToCorr.put(created, corr)
				updated += created
				return created
			}
		}
		
		def protected List<T> finish() {
			if (finished) throw new IllegalStateException("Finish was already called on this MultiElemUpdater!")
			finished = true
			
			rule.spareElems += outdated
			return updated
		}
	}
	protected static class SrcMultiElemUpdater<T extends EObject> extends MultiElemUpdater<T> {
		new(List<T> outdated, String elemClass, Elem2Elem rule, Corr corr) {
			super(outdated, [sourceFactory.create(sourcePackage.getEClassifier(elemClass) as EClass) as T], rule, corr)
		}
	}
	protected static class TrgMultiElemUpdater<T extends EObject> extends MultiElemUpdater<T> {
		new(List<T> outdated, String elemClass, Elem2Elem rule, Corr corr) {
			super(outdated, [targetFactory.create(targetPackage.getEClassifier(elemClass) as EClass) as T], rule, corr)
		}
	}
	
	def private Corr updateOrCreateCorr(CorrElem elem, boolean src, CorrElem... additionalElems) {
		Objects.requireNonNull(elem, "The parameter 'elem' must not be null!")
		Objects.requireNonNull(additionalElems, "The parameter 'additionalElems' must not be null!")
		if (additionalElems.contains(null)) {
			throw new IllegalArgumentException("The additional elements must not contain null!")
		}
		
		val elems = new ArrayList<CorrElem>() => [
			it += elem
			it += additionalElems
		]
		val flatElems = elems.map[if (it instanceof SingleElem) #[element] else (it as MultiElem).elements].flatten()
		if (flatElems.exists[it === null]) {
			throw new IllegalArgumentException("A corr must not be created from a null element!")
		}
		
		var corrCount = new LinkedHashMap<Corr, Integer>
		for (e : flatElems) {
			val corr = elementsToCorr.get(e)
			if (corr !== null && corrCount.containsKey(corr)) {
				corrCount.put(corr, corrCount.get(corr) + 1)
			} else if (corr !== null) {
				corrCount.put(corr, 1)
			}
		}
		val corrs = corrCount.keySet.toList()
		val corrsElems = if (src) corrs.map[source] else corrs.map[target]
		val corrsFlatElems = if (src) corrs.map[flatSrc] else corrs.map[flatTrg]
		
		val anyDetachedElem = flatElems.exists[detachedCorrElems.contains(it)]
		val corr = if (corrs.size() == 0) {
			corrFactory.createCorr()
			
		} else if (corrs.size() == 1 && corrs.head().ruleId == ruleId && !anyDetachedElem
				&& (corrsFlatElems.head().size() == corrCount.values.head()
					// the elems keep the majority of the corr: the corr (and its other side) survives,
					// the elems that moved away are detached and regrouped by their own update
					|| corrCount.values.head() * 2 > corrsFlatElems.head().size())) {
			for (element : corrsFlatElems.head().filter[e | !flatElems.contains(e)].toList()) {
				elementsToCorr.remove(element)
				detachedCorrElems += element
			}
			corrsElems.head().clear()
			corrs.head()

		} else if (corrs.size() == 1 && corrs.head().ruleId == ruleId && !anyDetachedElem
				&& corrsElems.head().exists[it instanceof MultiElem]) {
			// the elems are a minority of a group: only they leave the group, the rest keeps the corr
			val leaving = flatElems.filter[e | elementsToCorr.get(e) === corrs.head()].toSet()
			corrsElems.head().filter(MultiElem).forEach[elements.removeAll(leaving)]
			leaving.forEach[e | elementsToCorr.remove(e)]
			corrFactory.createCorr()

		} else if (corrs.size() > 1 && !anyDetachedElem && corrs.forall[it.ruleId == this.ruleId]
				&& corrsElems.forall[ces | ces.exists[it instanceof MultiElem]]) {
			// the elems merge several groups: the corr that holds most of the elems survives (the first one
			// on a tie), the other corrs only lose the elems that join the group
			var survivor = 0
			for (var i = 1; i < corrs.size(); i++) {
				if (corrCount.get(corrs.get(i)) > corrCount.get(corrs.get(survivor))) {
					survivor = i
				}
			}
			for (var i = 0; i < corrs.size(); i++) {
				if (i == survivor) {
					for (element : corrsFlatElems.get(i).filter[e | !flatElems.contains(e)].toList()) {
						elementsToCorr.remove(element)
						detachedCorrElems += element
					}
					corrsElems.get(i).clear()
				} else {
					val corrToLeave = corrs.get(i)
					val leaving = flatElems.filter[e | elementsToCorr.get(e) === corrToLeave].toSet()
					corrsElems.get(i).filter(MultiElem).forEach[elements.removeAll(leaving)]
					leaving.forEach[e | elementsToCorr.remove(e)]
				}
			}
			corrs.get(survivor)
			
		} else {
			for (var i = 0; i < corrs.size(); i++) {
				for (element : corrsFlatElems.get(i)) {
					elementsToCorr.remove(element)
					detachedCorrElems += element
				}
				corrsElems.get(i).clear()
			}
			corrFactory.createCorr()
		}
		
		corr.ruleId = ruleId
		if (src) {
			corr.source += elems
			corr.flatSrc.forEach[e | elementsToCorr.put(e, corr)]
		} else {
			corr.target += elems
			corr.flatTrg.forEach[e | elementsToCorr.put(e, corr)]
		}
		(corrModel.contents.get(0) as Transformation).correspondences += corr
		
		return corr
	}
}
