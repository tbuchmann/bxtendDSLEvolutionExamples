/**
 */
package de.tbuchmann.gantt2cpm.bxtenddsl.corrmodel;

import org.eclipse.emf.common.util.EList;

import org.eclipse.emf.ecore.EObject;

/**
 * <!-- begin-user-doc -->
 * A representation of the model object '<em><b>Multi Elem</b></em>'.
 * <!-- end-user-doc -->
 *
 * <p>
 * The following features are supported:
 * </p>
 * <ul>
 *   <li>{@link de.tbuchmann.gantt2cpm.bxtenddsl.corrmodel.MultiElem#getElements <em>Elements</em>}</li>
 * </ul>
 *
 * @see de.tbuchmann.gantt2cpm.bxtenddsl.corrmodel.CorrModelPackage#getMultiElem()
 * @model
 * @generated
 */
public interface MultiElem extends CorrElem {
	/**
	 * Returns the value of the '<em><b>Elements</b></em>' reference list.
	 * The list contents are of type {@link org.eclipse.emf.ecore.EObject}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the value of the '<em>Elements</em>' reference list.
	 * @see de.tbuchmann.gantt2cpm.bxtenddsl.corrmodel.CorrModelPackage#getMultiElem_Elements()
	 * @model
	 * @generated
	 */
	EList<EObject> getElements();

} // MultiElem
