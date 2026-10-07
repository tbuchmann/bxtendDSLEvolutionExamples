package de.tbuchmann.pdb12pdb2.bxtenddsl.rules;

import de.tbuchmann.pdb12pdb2.bxtenddsl.trafo.Pdb12Pdb2
import pdb1.Person

class Person2PersonImpl extends Person2Person {
	new(Pdb12Pdb2 trafo) {
		super(trafo)
	}

	// pdb1 -> pdb2: "<firstName> <lastName>"
	override protected nameFrom(String firstName, String lastName) {
		new Type4name(firstName + " " + lastName)
	}

	// pdb2 -> pdb1: split the name into first and last name
	override protected firstName_lastNameFrom(Person s, String name) {
		// A person that was touched on the target since the last synchronisation (any mapped
		// attribute, not only the name) gets a fresh split under the current option; an untouched
		// person keeps its previous split (hippocraticness).
		val t = if (s.hasCorr && !s.corr.target.empty) unwrap(s.corr.target.get(0)) as pdb2.Person
		val touched = t !== null && changedOnTarget(s.corr, s, t)
		if (name == s.firstName + " " + s.lastName && !touched) {
			new Type4firstName_lastName(s.firstName, s.lastName)

		} else {
			val preferFirstSpace = trafo.getOption(Pdb12Pdb2.OPT_PREFER_USING_FIRST_SPACE_TO_LAST)
			val spacePosition = if (preferFirstSpace == true) name.indexOf(" ") else name.lastIndexOf(" ")
			new Type4firstName_lastName(name.substring(0, spacePosition), name.substring(spacePosition + 1))
		}
	}

	// Equivalence: a source person and a target person are equivalent if "firstName lastName" == name
	override protected findMatchingPerson(Person s) {
		// persons are matched by their full name
		val key = s.firstName + " " + s.lastName
		trgRoot?.persons?.findFirst[p | !hasCorr(p) && p.name == key]
	}

	override protected findMatchingPerson_2(pdb2.Person t) {
		srcRoot?.persons?.findFirst[p | !hasCorr(p) && p.firstName + " " + p.lastName == t.name]
	}

	// Every mapping is resolved against the baseline of the last synchronisation (generated):
	// the side that changed wins, the source wins if both changed.
	override protected conflictPolicy() {
		Elem2Elem.ConflictPolicy.DETECT_CHANGES
	}
}
