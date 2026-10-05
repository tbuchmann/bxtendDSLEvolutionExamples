package de.tbuchmann.ecore2sql.bxtenddsl.rules

import java.util.List
import org.eclipse.emf.ecore.util.EcoreUtil
import org.eclipse.emf.ecore.EClassifier
import org.eclipse.emf.ecore.EcorePackage
import sql.Action
import sql.Column
import sql.ForeignKey
import sql.ModelElement
import sql.Property
import sql.Schema
import sql.SqlFactory
import sql.Table

/**
 * Structure of the SQL schema that has no counterpart in the Ecore model (root table, primary and foreign keys,
 * annotations). Not generated; used by the hooks of the rule implementations.
 */
class SqlSupport {
	static val F = SqlFactory.eINSTANCE

	def static void annotate(ModelElement owner, String... annotations) {
		for (a : annotations) {
			if (!owner.hasAnnotation(a)) {
				owner.ownedAnnotations += F.createAnnotation => [annotation = a]
			}
		}
	}

	def static boolean hasAnnotation(ModelElement owner, String annotation) {
		owner.ownedAnnotations.exists[it.annotation == annotation]
	}

	def static Table eObjectTable(Schema schema) {
		var table = schema.ownedTables.findFirst[name == "EObject"]
		if (table === null) {
			table = F.createTable => [name = "EObject"]
			val id = F.createColumn => [name = "id"; type = "int"]
			id.properties += Property.NOT_NULL
			id.properties += Property.AUTO_INCREMENT
			table.ownedColumns += id
			table.ownedPrimaryKey = F.createPrimaryKey => [column = id]
			schema.ownedTables += table
		}
		table
	}

	def static Column newColumn(Table owner, String name, String type) {
		val col = F.createColumn => [it.name = name; it.type = type]
		owner.ownedColumns += col
		col
	}

	def static ForeignKey newForeignKey(Column column, Table referenced) {
		val key = F.createForeignKey => [it.column = column; referencedTable = referenced]
		column.owningTable.ownedForeignKeys += key
		key.ownedEvents += F.createEvent
		key
	}

	/** primary key column "id" of a class table */
	def static void ensurePrimaryKey(Table table) {
		if (table.ownedPrimaryKey === null) {
			val id = table.newColumn("id", "int")
			id.properties += Property.NOT_NULL
			table.ownedPrimaryKey = F.createPrimaryKey => [column = id]
		}
	}

	/** the column in the EObject table that references the class table */
	def static void ensureEObjectColumn(Table table, Schema schema) {
		val root = schema.eObjectTable
		// the keys that reference the table are few; the keys of the EObject table are one per class
		if (!table.referencingForeignKeys.exists[owningTable === root]) {
			val col = root.newColumn(table.name, "int")
			col.properties += Property.UNIQUE
			col.newForeignKey(table)
		}
	}

	def static List<Table> classTables(Schema schema) {
		schema.ownedTables.filter[hasAnnotation("class")].toList
	}

	def static String sqlType(EClassifier eType) {
		switch (eType) {
			case EcorePackage.Literals.EINT: "int"
			case EcorePackage.Literals.ELONG: "int"
			case EcorePackage.Literals.EBOOLEAN: "boolean"
			case EcorePackage.Literals.EDATE: "date"
			case EcorePackage.Literals.ESTRING: "varchar(30)"
			case EcorePackage.Literals.EDOUBLE: "double"
		}
	}

	def static EClassifier ecoreType(String sqlType) {
		switch (sqlType) {
			case "int": EcorePackage.Literals.EINT
			case "boolean": EcorePackage.Literals.EBOOLEAN
			case "date": EcorePackage.Literals.EDATE
			case "varchar(30)": EcorePackage.Literals.ESTRING
			case "double": EcorePackage.Literals.EDOUBLE
		}
	}

	def static ForeignKey newForeignKey(Column column, Table referenced, Action onDelete) {
		val key = column.newForeignKey(referenced)
		key.ownedEvents.head.action = onDelete
		key
	}

	/**
	 * Brings the foreign keys of a class table that represent the generalisation in line with its super tables: one
	 * "superType" key per super table; a class without super class references the EObject table ("root").
	 */
	def static void reconcileInheritance(Table table, List<Table> supers, Schema schema) {
		for (key : table.ownedForeignKeys.filter[hasAnnotation("superType")].toList) {
			if (!supers.contains(key.referencedTable)) {
				EcoreUtil.delete(key)
			}
		}
		for (sup : supers) {
			if (!table.ownedForeignKeys.exists[hasAnnotation("superType") && referencedTable === sup]) {
				table.ownedPrimaryKey.column.newForeignKey(sup).annotate("superType")
			}
		}
		for (key : table.ownedForeignKeys.filter[hasAnnotation("root")].toList) {
			if (!supers.empty || schema === null || key.referencedTable !== schema.eObjectTable) {
				EcoreUtil.delete(key)
			}
		}
		if (supers.empty && schema !== null && !table.ownedForeignKeys.exists[hasAnnotation("root")]) {
			table.ownedPrimaryKey.column.newForeignKey(schema.eObjectTable).annotate("root")
		}
	}

	/** removes the column of a class table (and its key) from the EObject table */
	def static void removeFromEObjectTable(Table table) {
		for (key : table.referencingForeignKeys.filter[owningTable !== null && owningTable.name == "EObject"].toList) {
			val column = key.column
			EcoreUtil.delete(key)
			if (column !== null) {
				EcoreUtil.delete(column)
			}
		}
	}

	def static void setKind(Table table, boolean isAbstract) {
		table.ownedAnnotations.removeIf[annotation == "abstract" || annotation == "concrete"]
		table.annotate(if (isAbstract) "abstract" else "concrete")
	}

	/** the column of a class table in the EObject table is named like the table */
	def static void syncEObjectColumnName(Table table) {
		for (key : table.referencingForeignKeys.filter[owningTable !== null && owningTable.name == "EObject"].toList) {
			if (key.column !== null && key.column.name != table.name) {
				key.column.name = table.name
			}
		}
	}

	/**
	 * Brings the annotations of the given kinds in line with the wanted ones: annotations of these kinds that are not
	 * wanted are removed, the missing ones added. Other annotations (for example user annotations) are not touched.
	 */
	def static void setAnnotations(ModelElement owner, List<String> kinds, List<String> wanted) {
		owner.ownedAnnotations.removeIf[kinds.contains(annotation) && !wanted.contains(annotation)]
		for (a : wanted) {
			owner.annotate(a)
		}
	}
}
