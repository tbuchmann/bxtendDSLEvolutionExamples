package de.tbuchmann.bags2bags.bxtenddsl.rules;

import bags1.Element
import de.tbuchmann.bags2bags.bxtenddsl.corrmodel.Corr
import de.tbuchmann.bags2bags.bxtenddsl.corrmodel.CorrModelFactory
import de.tbuchmann.bags2bags.bxtenddsl.corrmodel.MultiElem
import de.tbuchmann.bags2bags.bxtenddsl.corrmodel.Transformation
import de.tbuchmann.bags2bags.bxtenddsl.trafo.BagsToBags
import java.util.List
import java.util.Map
import java.util.Set
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.util.EcoreUtil

class Element2ElementImpl extends Element2Element {
	new(BagsToBags trafo) {
		super(trafo)
	}

	// group key: the value (equal values form one group)
	override protected groupSElem(Element sElem) {
		sElem.value
	}
	override protected filterS(List<Element> s) {
		!s.empty
	}

	// bags1 -> bags2: group value and its size as multiplicity
	override protected tValue_multiplicityFrom(List<Element> s) {
		new Type4tValue_multiplicity(s.get(0).value, s.size())
	}

	// bags2 -> bags1: create/reuse as many source elements as the multiplicity says
	override protected sFrom(SrcMultiElemUpdater<Element> sUpdater, String tValue, int multiplicity) {
		for (var i = 0; i < multiplicity; i++) {
			sUpdater.update[true].value = tValue
		}
		new Type4s(sUpdater.finish())
	}

	// ---------------------------------------------------------------------------------------
	// Concurrent synchronisation of element groups (hand-written, see SYNCH_EVOLUTION.md).
	// A baseline of the group value and multiplicity at the end of the last synchronisation
	// tells which side changed.
	// ---------------------------------------------------------------------------------------

	val Map<Corr, String> lastValue = newHashMap
	val Map<Corr, Integer> lastMultiplicity = newHashMap

	override sourceToTarget(Set<EObject> _detachedCorrElems) {
		val delta = super.sourceToTarget(_detachedCorrElems)
		recordBaselines()
		delta
	}

	override targetToSource(Set<EObject> _detachedCorrElems) {
		val delta = super.targetToSource(_detachedCorrElems)
		recordBaselines()
		delta
	}

	/**
	 * 1. Regroup source elements (new ones, or ones whose value drifted from the group value).
	 * 2. Reconcile every surviving group: value and multiplicity are resolved independently;
	 *    a side that changed since the baseline wins, the source wins if both changed. A group that
	 *    shrank while its value was renamed on the target is one conflict over the whole group:
	 *    the source wins both axes.
	 * 3. Pull target elements without correspondence into new source groups.
	 * 4. Cascading delete of groups whose source or target side vanished.
	 */
	// this rule implements synch() itself, so the transformation synchronises rule by rule
	override boolean supportsSynch() {
		true
	}

	override void synch() {
		for (e : sourceModel.allContents.filter(Element).toList) {
			val corr = elementsToCorr.get(e)
			if (corr === null) {
				e.addToTargetElem
			} else if (corr.trgElem !== null) {
				val last = lastValue.get(corr)
				if (last !== null && e.value != last) {
					corr.multi.elements.remove(e)
					elementsToCorr.remove(e)
					e.addToTargetElem
				}
			}
			// else: the target group was deleted concurrently - its source elements are deleted in step 4
		}

		for (corr : groupCorrs) {
			val t = corr.trgElem
			val srcs = corr.flatSrc.filter(Element).toList
			if (t !== null && !srcs.empty) {
				val groupValue = srcs.head.value
				val lastV = lastValue.get(corr)
				val lastM = lastMultiplicity.get(corr)
				val shrunk = lastM !== null && srcs.size < lastM
				if (lastV === null || groupValue != lastV) {
					t.value = groupValue
				} else if (t.value != lastV && !shrunk) {
					srcs.forEach[value = t.value]
				} else if (t.value != lastV && shrunk) {
					t.value = groupValue
				}

				val sourceChanged = lastM === null || lastM != srcs.size
				val targetChanged = lastM === null || lastM != t.multiplicity
				if (sourceChanged) {
					t.multiplicity = srcs.size
				} else if (targetChanged) {
					while (corr.multi.elements.size < t.multiplicity) {
						corr.multi.elements += corr.newSourceElem(t)
					}
					while (corr.multi.elements.size > t.multiplicity) {
						val victim = corr.multi.elements.get(0)
						corr.multi.elements.remove(victim)
						elementsToCorr.remove(victim)
						EcoreUtil.delete(victim)
					}
				}
				lastValue.put(corr, t.value)
				lastMultiplicity.put(corr, t.multiplicity)
			}
		}

		for (t : targetModel.allContents.filter(bags2.Element).filter[!hasCorr(it)].toList) {
			val corr = CorrModelFactory.eINSTANCE.createCorr() => [it.ruleId = "Element2Element"]
			val sources = newArrayList
			corr.source += wrap(sources)
			corr.target += wrap(t)
			(corrModel.contents.get(0) as Transformation).correspondences += corr
			elementsToCorr.put(t, corr)
			for (var i = 0; i < t.multiplicity; i++) {
				corr.multi.elements += corr.newSourceElem(t)
			}
			lastValue.put(corr, t.value)
			lastMultiplicity.put(corr, t.multiplicity)
		}

		for (corr : groupCorrs) {
			if (corr.flatSrc.empty) {
				corr.flatTrg.forEach[elementsToCorr.remove(it); EcoreUtil.delete(it)]
				remove(corr)
			} else if (corr.flatTrg.empty) {
				corr.flatSrc.forEach[elementsToCorr.remove(it); EcoreUtil.delete(it)]
				remove(corr)
			}
		}
	}

	def private void addToTargetElem(Element e) {
		val bag = if (e.bag !== null && e.bag.hasCorr) {
			unwrap(e.bag.corr.target.get(0)) as bags2.MyBag
		} else {
			trgRoot
		}
		var t = bag.elements.findFirst[value == e.value]
		if (t === null) {
			t = targetFactory.create(targetPackage.getEClassifier("Element") as EClass) as bags2.Element
			t.value = e.value
			bag.elements += t
		}
		var corr = elementsToCorr.get(t)
		if (corr === null) {
			corr = CorrModelFactory.eINSTANCE.createCorr() => [it.ruleId = "Element2Element"]
			corr.source += wrap(newArrayList(e))
			corr.target += wrap(t)
			(corrModel.contents.get(0) as Transformation).correspondences += corr
			elementsToCorr.put(t, corr)
		} else {
			corr.multi.elements += e
		}
		elementsToCorr.put(e, corr)
	}

	def private Element newSourceElem(Corr corr, bags2.Element t) {
		val el = sourceFactory.create(sourcePackage.getEClassifier("Element") as EClass) as Element
		el.value = t.value
		el.bag = if (t.bag !== null && t.bag.hasCorr) {
			unwrap(t.bag.corr.source.get(0)) as bags1.MyBag
		} else {
			srcRoot
		}
		elementsToCorr.put(el, corr)
		el
	}

	def private recordBaselines() {
		for (corr : groupCorrs) {
			val t = corr.trgElem
			if (t !== null) {
				lastValue.put(corr, t.value)
				lastMultiplicity.put(corr, t.multiplicity)
			}
		}
	}

	def private remove(Corr corr) {
		(corrModel.contents.get(0) as Transformation).correspondences.remove(corr)
		lastValue.remove(corr)
		lastMultiplicity.remove(corr)
	}

	def private List<Corr> groupCorrs() {
		(corrModel.contents.get(0) as Transformation).correspondences.filter[it.ruleId == "Element2Element"].toList
	}

	def private bags2.Element trgElem(Corr corr) {
		corr.flatTrg.head as bags2.Element
	}

	def private MultiElem multi(Corr corr) {
		corr.source.head as MultiElem
	}
}
