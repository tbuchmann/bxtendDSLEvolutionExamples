package de.tbuchmann.f2p.bxtenddsl.rules

import Families.Family
import Families.FamilyRegister
import java.util.ArrayList
import java.util.HashMap
import java.util.List
import java.util.Map
import java.util.WeakHashMap

/**
 * The families of a register by name, in the order of the register. The hooks that find the family of a person look
 * a family up by its name once per person; scanning all families each time makes a batch quadratic.
 * The index is shared by the rules of one transformation (see of) and is built again if the number of families
 * differs from the number at the last update. A family that a hook creates is reported with added. It assumes that the
 * names of existing families do not change while persons are propagated to families.
 */
class FamilyIndex {
	static val Map<Object, FamilyIndex> INDEXES = new WeakHashMap

	def static FamilyIndex of(Object transformation) {
		synchronized (INDEXES) {
			INDEXES.computeIfAbsent(transformation, [new FamilyIndex])
		}
	}

	val Map<String, List<Family>> byName = new HashMap
	var FamilyRegister register
	var int indexedSize = -1

	/** The families of the register with the given name, in the order of the register. */
	def List<Family> families(FamilyRegister register, String name) {
		if (this.register !== register || indexedSize != register.families.size) {
			rebuild(register)
		}
		byName.getOrDefault(name, emptyList)
	}

	/**
	 * To be called after a family was created and added to the register. Nothing to do if the index has not been built
	 * for this register (nobody looked a family up yet): the next lookup builds it.
	 */
	def void added(Family family) {
		val container = family.eContainer
		if (register === null || container !== register) {
			return
		}
		// only if this family is the one change since the index was built; otherwise the next lookup builds it again
		if (indexedSize + 1 == register.families.size) {
			byName.computeIfAbsent(family.name, [new ArrayList]).add(family)
			indexedSize = register.families.size
		}
	}

	def private void rebuild(FamilyRegister register) {
		byName.clear()
		for (family : register.families) {
			byName.computeIfAbsent(family.name, [new ArrayList]).add(family)
		}
		this.register = register
		indexedSize = register.families.size
	}
}
