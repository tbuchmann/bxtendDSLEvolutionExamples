package de.tbuchmann.set2oset.bxtenddsl.rules;

import de.tbuchmann.set2oset.bxtenddsl.trafo.Set2OSet

class Set2OsetImpl extends Set2Oset {	
	new(Set2OSet trafo) {
		super(trafo)
	}

	// Every mapping is resolved against the baseline of the last synchronisation (generated); the
	// elements of both sides are merged if both changed them.
	override protected conflictPolicy() {
		Elem2Elem.ConflictPolicy.DETECT_CHANGES
	}

}
