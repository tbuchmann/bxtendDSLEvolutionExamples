package de.tbuchmann.pn2pnw.bxtenddsl.rules;

import de.tbuchmann.pn2pnw.bxtenddsl.trafo.Pn2Pnw
import pnw.TPEdge
import pnw.PTEdge
import java.util.List
import pnw.Transition
import pnw.Place

class Transition2TransitionImpl extends Transition2Transition {	
	new(Pn2Pnw trafo) {
		super(trafo)
	}
	
	override protected groupTpEdgesElem(TPEdge tpEdgesElem) {
		tpEdgesElem.fromTransition.toString()
	}
	override protected filterTpEdges(List<TPEdge> tpEdges, Transition t) {
		if (tpEdges.empty) t.outTPEdges.empty else tpEdges.get(0).fromTransition == t
	}
	
	override protected groupPtEdgesElem(PTEdge ptEdgesElem) {
		ptEdgesElem.toTransition.toString()
	}
	override protected filterPtEdges(List<PTEdge> ptEdges, List<TPEdge> tpEdges, Transition t) {
		if (ptEdges.empty) t.inPTEdges.empty else ptEdges.get(0).toTransition == t
	}
	
	override protected tpEdgesFrom(TrgMultiElemUpdater<TPEdge> tpEdgesUpdater, Transition t, List<Place> trgT) {
		for (place : trgT) {
			val tpEdge = tpEdgesUpdater.update[it.fromTransition == t && it.toPlace == place]
			tpEdge.fromTransition = t
			tpEdge.toPlace = place
		}
		new Type4tpEdges(tpEdgesUpdater.finish())
	}
	override protected ptEdgesFrom(TrgMultiElemUpdater<PTEdge> ptEdgesUpdater, Transition t, List<Place> srcT) {
		for (place : srcT) {
			val ptEdge = ptEdgesUpdater.update[it.fromPlace == place && it.toTransition == t]
			ptEdge.fromPlace = place
			ptEdge.toTransition = t
		}
		new Type4ptEdges(ptEdgesUpdater.finish())
	}
	
	override protected trgT2PFrom(List<TPEdge> tpEdges) {
		new Type4trgT2P(tpEdges.map[Place2Place.source(toPlace.corr).s])
	}
	override protected srcP2TFrom(List<PTEdge> ptEdges) {
		new Type4srcP2T(ptEdges.map[Place2Place.source(fromPlace.corr).s])
	}
}
