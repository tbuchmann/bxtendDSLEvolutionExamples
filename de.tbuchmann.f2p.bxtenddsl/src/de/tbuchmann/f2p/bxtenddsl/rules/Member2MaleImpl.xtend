package de.tbuchmann.f2p.bxtenddsl.rules;

import Families.FamiliesFactory
import Families.Family
import Families.FamilyMember
import Persons.Male
import Persons.Person
import de.tbuchmann.f2p.bxtenddsl.trafo.FamiliesToPersons
import java.util.Date
import java.util.Map

class Member2MaleImpl extends Member2Male {	
	new(FamiliesToPersons trafo) {
		super(trafo)
	}
	
	override protected onMaleCreation(Male male) {
		if (birthdays.containsKey(male.corr.source().member)) {
			male.birthday = birthdays.get(male.corr.source().member)
		}
	}

	// Every mapping is resolved against the baseline of the last synchronisation (generated):
	// a renamed target name wins over an unchanged source, the source wins if both changed.
	override protected conflictPolicy() {
		Elem2Elem.ConflictPolicy.DETECT_CHANGES
	}

	override protected filterMember(FamilyMember member) {
		if (member.hasCorr) {
			if ((unwrap(member.corr.target.get(0))) !== null)
				birthdays.put(member, (unwrap(member.corr.target.get(0)) as Person).birthday)
		}
		return member.sonsInverse !== null || member.fatherInverse !== null
	}
	
	override protected malNameFrom(String memName, Family fatherInverse, Family sonsInverse) {
		new Type4malName((fatherInverse ?: sonsInverse).name + ", " + memName)
	}
	
	override protected personsInverseFrom(Family sonsInverse, Family fatherInverse) {
		new Type4personsInverse(Register2Register.target((sonsInverse ?: fatherInverse).familiesInverse.corr).t)
	}
	
	override protected memNameFrom(FamilyMember member, String malName) {
		val familyName = malName.split(", ").get(0)
		val memberName = malName.split(", ").get(1)
		
		if (member.eContainer === null || (member.eContainer as Family).name != familyName) {
			val preferExisting = trafo.getOption(FamiliesToPersons.OPT_PREFER_EXISTING_FAMILY_TO_NEW)
			val index = FamilyIndex.of(trafo)
			var Family family = null
			if (preferExisting == true) {
				val candidates = index.families(srcRoot, familyName)
				family = candidates.findFirst[father === null] ?: candidates.head
			}
			if (family === null) {
				family = FamiliesFactory.eINSTANCE.createFamily() => [
					name = familyName
					familiesInverse = srcRoot
				]
				index.added(family)
			}
			
			val preferParent = trafo.getOption(FamiliesToPersons.OPT_PREFER_CREATING_PARENT_TO_CHILD)
			if (preferParent == false || (family.father !== null && family.father !== member)) {
				family.sons += member
			} else {
				family.father = member
			}
		}
		
		new Type4memName(memberName)
	}
	
	// Equivalence: a father/son member "m" of family "f" corresponds to an unmatched Male named "f, m"
	override protected findMatchingMale(FamilyMember member) {
		val family = member.fatherInverse ?: member.sonsInverse
		if (family === null || trgRoot === null) return null
		val expected = family.name + ", " + member.name
		trgRoot.persons.filter(Male).findFirst[!it.hasCorr && name == expected]
	}

	override protected findMatchingFamilyMember(Male male) {
		val parts = male.name?.split(", ")
		if (parts === null || parts.size != 2 || srcRoot === null) return null
		FamilyIndex.of(trafo).families(srcRoot, parts.get(0)).map[#[father] + sons].flatten
				.findFirst[it !== null && !it.hasCorr && name == parts.get(1)]
	}

	Map<FamilyMember, Date> birthdays = newHashMap()
}
