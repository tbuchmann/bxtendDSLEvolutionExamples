package de.tbuchmann.set2oset.bxtenddsl.rules;

import de.tbuchmann.set2oset.bxtenddsl.trafo.Set2OSet
import osets.Element

class Element2ElementImpl extends Element2Element {	
	new(Set2OSet trafo) {
		super(trafo)
	}
	
	// The element that was appended last. It is the tail of the list as long as it has no successor, so the search
	// for the tail (linear in the size of the list) is only needed if it is not usable.
	var Element lastTail = null

	override protected onTCreation(Element t) {
		// Append t to the end of the list. The elements of one run are created in the order of the
		// containment list, so a candidate for the tail is every element without successor, except
		// t itself and the elements after t that were not linked yet.
		var tail = lastTail
		if (tail === null || tail === t || tail.next !== null || tail.eContainer !== t.eContainer) {
			tail = findTail(t)
		}
		if (tail !== null) {
			t.previous = tail
		}
		lastTail = t
	}

	def private Element findTail(Element t) {
		val elements = trgRoot.elements
		val index = elements.indexOf(t)
		var Element tail = null
		for (var i = 0; i < elements.size; i++) {
			val e = elements.get(i)
			if (e !== t && e.next === null && !(e.previous === null && i > index)) {
				tail = e // the last candidate in the order of the containment list
			}
		}
		tail
	}
	
	override protected onTDeletion(Element t) {
		t.previous?.setNext(t.next)
		if (t === lastTail) {
			lastTail = null
		}
	}

	// Every mapping is resolved against the baseline of the last synchronisation (generated):
	// a value changed only on the target is propagated back, the source wins if both changed.
	override protected conflictPolicy() {
		Elem2Elem.ConflictPolicy.DETECT_CHANGES
	}

}
