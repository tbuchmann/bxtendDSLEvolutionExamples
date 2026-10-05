package de.tbuchmann.set2oset.bxtenddsl.rules;

import de.tbuchmann.set2oset.bxtenddsl.trafo.Set2OSet
import osets.Element

class Element2ElementImpl extends Element2Element {	
	new(Set2OSet trafo) {
		super(trafo)
	}
	
	override protected onTCreation(Element t) {
		// Append t to the end of the list. The elements of one run are created in the order of the
		// containment list, so a candidate for the tail is every element without successor, except
		// t itself and the elements after t that were not linked yet.
		val elements = trgRoot.elements
		val index = elements.indexOf(t)
		val tail = elements.filter[e | e !== t && e.next === null
				&& !(e.previous === null && elements.indexOf(e) > index)].last
		if (tail !== null) {
			t.previous = tail
		}
	}
	
	override protected onTDeletion(Element t) {
		t.previous?.setNext(t.next)
	}

	// Every mapping is resolved against the baseline of the last synchronisation (generated):
	// a value changed only on the target is propagated back, the source wins if both changed.
	override protected conflictPolicy() {
		Elem2Elem.ConflictPolicy.DETECT_CHANGES
	}

}
