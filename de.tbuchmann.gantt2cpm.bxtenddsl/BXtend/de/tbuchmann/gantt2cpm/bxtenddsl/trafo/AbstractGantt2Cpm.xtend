package de.tbuchmann.gantt2cpm.bxtenddsl.trafo

import de.tbuchmann.gantt2cpm.bxtenddsl.corrmodel.Corr
import de.tbuchmann.gantt2cpm.bxtenddsl.corrmodel.CorrModelFactory
import de.tbuchmann.gantt2cpm.bxtenddsl.corrmodel.MultiElem
import de.tbuchmann.gantt2cpm.bxtenddsl.corrmodel.SingleElem
import de.tbuchmann.gantt2cpm.bxtenddsl.corrmodel.Transformation
import de.tbuchmann.gantt2cpm.bxtenddsl.rules.Elem2Elem
import de.ubt.ai1.m2m.bxtenddsl.BXtendTransformation
import java.util.HashMap
import java.util.HashSet
import java.util.Iterator
import java.util.List
import java.util.Set
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl
import org.eclipse.emf.ecore.util.EcoreUtil
import org.eclipse.emf.ecore.xmi.impl.XMIResourceFactoryImpl

abstract class AbstractGantt2Cpm implements BXtendTransformation {
	val protected Resource sourceModel
	val protected Resource targetModel
	val protected Resource corrModel
	
	val List<Elem2Elem> rules
	
	new() {
		val ResourceSet set = new ResourceSetImpl()
		set.resourceFactoryRegistry.extensionToFactoryMap.put("xmi", new XMIResourceFactoryImpl())
		
		sourceModel = set.createResource(URI.createURI("source.xmi"))
		targetModel = set.createResource(URI.createURI("target.xmi"))
		corrModel = set.createResource(URI.createURI("corr.xmi"))
		corrModel.contents.add(CorrModelFactory.eINSTANCE.createTransformation)
		
		rules = createRules()
	}
	new(Resource source, Resource target, Resource correspondence) {
		sourceModel = source
		targetModel = target
		corrModel = correspondence
		if (corrModel.contents.size() == 0) {
			corrModel.contents.add(CorrModelFactory.eINSTANCE.createTransformation)
		}
		
		rules = createRules()
	}
	
	override void sourceToTarget() {
		purgeOrphanedElements()
		val createdElems = new HashMap<Elem2Elem, List<EObject>>()
		val spareElems = new HashMap<Elem2Elem, List<EObject>>()
		var Set<EObject> detachedCorrElems = new HashSet<EObject>()
		
		for (rule : rules) {
			val delta = rule.sourceToTarget(detachedCorrElems)
			createdElems.put(rule, delta.createdElems)
			spareElems.put(rule, delta.spareElems)
			detachedCorrElems = delta.detachedCorrElems
		}
		for (Corr corr : (corrModel.contents.get(0) as Transformation).correspondences) {
			for (EObject trg : corr.flatTrg.filter[eContainer === null]) {
				targetModel.contents += trg
			}
		}
		
		for (rule : rules) {
			for (createdElem : createdElems.get(rule)) {
				rule.onTrgElemCreation(createdElem)
			}
		}
		for (rule : rules) {
			for (spareElem : spareElems.get(rule)) {
				rule.onTrgElemDeletion(spareElem)
				EcoreUtil.delete(spareElem, false)
			}
		}
		for (rule : rules) {
			rule.rebaseline()
		}
		deleteUnreferencedTargetElements()
	}
	override void targetToSource() {
		purgeOrphanedElements()
		val createdElems = new HashMap<Elem2Elem, List<EObject>>()
		val spareElems = new HashMap<Elem2Elem, List<EObject>>()
		var Set<EObject> detachedCorrElems = new HashSet<EObject>()
		
		for (rule : rules) {
			val delta = rule.targetToSource(detachedCorrElems)
			createdElems.put(rule, delta.createdElems)
			spareElems.put(rule, delta.spareElems)
			detachedCorrElems = delta.detachedCorrElems
		}
		for (Corr corr : (corrModel.contents.get(0) as Transformation).correspondences) {
			for (EObject src : corr.flatSrc.filter[eContainer === null]) {
				sourceModel.contents += src
			}
		}
		
		for (rule : rules) {
			for (createdElem : createdElems.get(rule)) {
				rule.onSrcElemCreation(createdElem)
			}
		}
		for (rule : rules) {
			for (spareElem : spareElems.get(rule)) {
				rule.onSrcElemDeletion(spareElem)
				EcoreUtil.delete(spareElem, false)
			}
		}
		for (rule : rules) {
			rule.rebaseline()
		}
		deleteUnreferencedSourceElements()
	}
	def void synch() {
		purgeOrphanedElements()
		if (rules.exists[!supportsSynch]) {
			// At least one rule (a rule with a group matcher) cannot be synchronised on its own: reconcile
			// by one forward pass followed by one backward pass over all rules. Both passes are idempotent
			// (they update existing correspondences), so concurrent insertions and moves are not discarded.
			sourceToTarget()
			targetToSource()
		} else {
			for (rule : rules) {
				rule.dissolveMismatchedPairs()
			}
			for (rule : rules) {
				rule.synch()
			}
			// the synchronisation can change what the filters depend on (for example a name that is propagated from
			// the other side): pairs that became stale are dissolved and the rules run again for their elements
			var dissolved = false
			for (rule : rules) {
				if (rule.dissolveMismatchedPairs()) {
					dissolved = true
				}
			}
			if (dissolved) {
				for (rule : rules) {
					rule.synch()
				}
			}
			for (rule : rules) {
				rule.afterSynch()
			}
			for (rule : rules) {
				rule.rebaseline()
			}
		}
	}

	override Resource getCorr() {
		return corrModel
	}
	override Resource getSource() {
		return sourceModel
	}
	override Resource getTarget() {
		return targetModel
	}
	
	def protected abstract List<Elem2Elem> createRules();
	
	/**
	 * Removes elements that were detached from their resource without EcoreUtil.delete (for example by a plain
	 * containment setter) from all correspondences. EcoreUtil.delete also removes the references of the
	 * correspondence model to the deleted element, a plain setter does not; the correspondence would keep the
	 * dead element in its group and look larger than the group it corresponds to.
	 */
	def private void purgeOrphanedElements() {
		for (corr : (corrModel.contents.get(0) as Transformation).correspondences.toList()) {
			for (corrElem : (corr.source + corr.target).toList()) {
				if (corrElem instanceof MultiElem) {
					val multi = corrElem as MultiElem
					multi.elements.removeAll(multi.elements.filter[eResource === null].toList())
				} else if (corrElem instanceof SingleElem) {
					val single = corrElem as SingleElem
					if (single.element !== null && single.element.eResource === null) {
						single.element = null
					}
				}
			}
		}
	}
	
	def private Iterator<Corr> detectSourceDeletions() {
		corrModel.allContents.filter(typeof(Corr)).filter[c |
			c.flatSrc.empty
		]
	}
	def private Iterator<Corr> detectTargetDeletions() {
		corrModel.allContents.filter(typeof(Corr)).filter[c |
			c.flatTrg.empty
		]
	}
	def private void deleteUnreferencedTargetElements() {
		val List<EObject> deletionList = newArrayList;
		
		detectSourceDeletions().forEach[c |
			val rule = rules.findFirst[ruleId == c.ruleId]
			c.flatTrg.forEach[rule.onTrgElemDeletion(it)]
			deletionList += c.flatTrg
			deletionList += c
		]
		deletionList.forEach[e | EcoreUtil.delete(e, true)]
	}
	def private void deleteUnreferencedSourceElements() {
		val List<EObject> deletionList = newArrayList; 
		
		detectTargetDeletions().forEach[c |
			val rule = rules.findFirst[ruleId == c.ruleId]
			c.flatSrc.forEach[rule.onSrcElemDeletion(it)]
			deletionList += c.flatSrc
			deletionList += c
		]
		deletionList.forEach[e | EcoreUtil.delete(e, true)]
	}
}
