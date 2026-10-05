package de.tbuchmann.pdb12pdb2.bxtenddsl.rules;

import de.tbuchmann.pdb12pdb2.bxtenddsl.trafo.Pdb12Pdb2

class Database2DatabaseImpl extends Database2Database {
	new(Pdb12Pdb2 trafo) {
		super(trafo)
	}

	// Equivalence: databases with the same name
	override protected findMatchingDatabase(pdb1.Database s) {
		targetModel.allContents.filter(pdb2.Database).findFirst[d | !hasCorr(d) && d.name == s.name]
	}

	override protected findMatchingDatabase_2(pdb2.Database t) {
		sourceModel.allContents.filter(pdb1.Database).findFirst[d | !hasCorr(d) && d.name == t.name]
	}

	// Every mapping is resolved against the baseline of the last synchronisation (generated). The persons
	// of both sides are merged if both changed them (mergeCollections).
	override protected conflictPolicy() {
		Elem2Elem.ConflictPolicy.DETECT_CHANGES
	}
}
