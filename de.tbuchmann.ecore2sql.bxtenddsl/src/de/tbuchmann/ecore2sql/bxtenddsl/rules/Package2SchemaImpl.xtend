package de.tbuchmann.ecore2sql.bxtenddsl.rules;

import de.tbuchmann.ecore2sql.bxtenddsl.trafo.Ecore2Sql
import sql.Schema

import static extension de.tbuchmann.ecore2sql.bxtenddsl.rules.SqlSupport.*

class Package2SchemaImpl extends Package2Schema {	
	new(Ecore2Sql trafo) {
		super(trafo)
	}

	// new schema: annotation and the EObject root table
	override protected onTCreation(Schema t) {
		t.annotate("package")
		t.eObjectTable
	}
}
