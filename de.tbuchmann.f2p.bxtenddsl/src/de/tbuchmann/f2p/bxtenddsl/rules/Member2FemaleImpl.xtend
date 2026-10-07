package de.tbuchmann.f2p.bxtenddsl.rules;

import Families.FamiliesFactory
import Families.Family
import Families.FamilyMember
import Persons.Female
import Persons.Person
import de.tbuchmann.f2p.bxtenddsl.corrmodel.SingleElem
import de.tbuchmann.f2p.bxtenddsl.trafo.FamiliesToPersons
import java.util.Date
import java.util.Map
import java.util.Set
import org.eclipse.emf.ecore.EObject

class Member2FemaleImpl extends Member2Female {	
	new(FamiliesToPersons trafo) {
		super(trafo)
	}
	
	// the birthday exists only in Persons: restore it for a person that is re-created for a known member
	override protected onFemaleCreation(Female female) {
		if (birthdays.containsKey(female.corr.source().member)) {
			female.birthday = birthdays.get(female.corr.source().member)
		}
	}

	// Every mapping is resolved against the baseline of the last synchronisation (generated):
	// a renamed target name wins over an unchanged source, the source wins if both changed.
	override protected conflictPolicy() {
		Elem2Elem.ConflictPolicy.DETECT_CHANGES
	}

	// only mothers and daughters; remember the birthday of members that already have a person
	override protected filterMember(FamilyMember member) {
		if (member.hasCorr) {
			if (member.corr.target.get(0) !== null && member.corr.target.get(0) instanceof SingleElem) {
				var p = (unwrap(member.corr.target.get(0)) as Person)
				if (p !== null)
					birthdays.put(member, p.birthday)				
			}
		}
		return member.daughtersInverse !== null || member.motherInverse !== null
	}
	
	// Persons name: "<family>, <member>"
	override protected femNameFrom(String memName, Family motherInverse, Family daughtersInverse) {
		new Type4femName((motherInverse ?: daughtersInverse).name + ", " + memName)
	}
	
	// the person goes to the register that corresponds to the register of the family
	override protected personsInverseFrom(Family daughtersInverse, Family motherInverse) {
		new Type4personsInverse(Register2Register.target((daughtersInverse ?: motherInverse).familiesInverse.corr).t)
	}
	
	// Persons -> Families: split the name; put the member into an existing or new family
	// (reusing a family with a free mother slot, depending on the options) as mother or daughter
	override protected memNameFrom(FamilyMember member, String femName) {
		if (femName !== null) { 
		val familyName = femName.split(", ").get(0)
		val memberName = femName.split(", ").get(1)
		
		if (member.eContainer === null || (member.eContainer as Family).name != familyName) {
			val preferExisting = trafo.getOption(FamiliesToPersons.OPT_PREFER_EXISTING_FAMILY_TO_NEW)
			val index = FamilyIndex.of(trafo)
			var Family family = null
			if (preferExisting == true) {
				val candidates = index.families(srcRoot, familyName)
				family = candidates.findFirst[mother === null] ?: candidates.head
			}
			if (family === null) {
				family = FamiliesFactory.eINSTANCE.createFamily() => [
					name = familyName
					familiesInverse = srcRoot
				]
				index.added(family)
			}
			
			val preferParent = trafo.getOption(FamiliesToPersons.OPT_PREFER_CREATING_PARENT_TO_CHILD)
			if (preferParent == false || (family.mother !== null && family.mother !== member)) {
				family.daughters += member
			} else {
				family.mother = member
			}
		}
		
		new Type4memName(memberName)
	   }
	}
	
	// Equivalence: a mother/daughter member "m" of family "f" corresponds to an unmatched Female named "f, m"
	override protected findMatchingFemale(FamilyMember member) {
		val family = member.motherInverse ?: member.daughtersInverse
		if (family === null || trgRoot === null) return null
		val expected = family.name + ", " + member.name
		trgRoot.persons.filter(Female).findFirst[!it.hasCorr && name == expected]
	}

	override protected findMatchingFamilyMember(Female female) {
		val parts = female.name?.split(", ")
		if (parts === null || parts.size != 2 || srcRoot === null) return null
		FamilyIndex.of(trafo).families(srcRoot, parts.get(0)).map[#[mother] + daughters].flatten
				.findFirst[it !== null && !it.hasCorr && name == parts.get(1)]
	}

	// birthdays of the members, see filterMember
	Map<FamilyMember, Date> birthdays = newHashMap()
	
}
