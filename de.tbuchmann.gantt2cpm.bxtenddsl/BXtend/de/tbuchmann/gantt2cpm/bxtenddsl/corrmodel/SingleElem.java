/**
 */
package de.tbuchmann.gantt2cpm.bxtenddsl.corrmodel;

import org.eclipse.emf.ecore.EObject;

/**
 * <!-- begin-user-doc -->
 * A representation of the model object '<em><b>Single Elem</b></em>'.
 * <!-- end-user-doc -->
 *
 * <p>
 * The following features are supported:
 * </p>
 * <ul>
 *   <li>{@link de.tbuchmann.gantt2cpm.bxtenddsl.corrmodel.SingleElem#getElement <em>Element</em>}</li>
 * </ul>
 *
 * @see de.tbuchmann.gantt2cpm.bxtenddsl.corrmodel.CorrModelPackage#getSingleElem()
 * @model
 * @generated
 */
public interface SingleElem extends CorrElem {
	/**
	 * Returns the value of the '<em><b>Element</b></em>' reference.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the value of the '<em>Element</em>' reference.
	 * @see #setElement(EObject)
	 * @see de.tbuchmann.gantt2cpm.bxtenddsl.corrmodel.CorrModelPackage#getSingleElem_Element()
	 * @model
	 * @generated
	 */
	EObject getElement();

	/**
	 * Sets the value of the '{@link de.tbuchmann.gantt2cpm.bxtenddsl.corrmodel.SingleElem#getElement <em>Element</em>}' reference.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @param value the new value of the '<em>Element</em>' reference.
	 * @see #getElement()
	 * @generated
	 */
	void setElement(EObject value);

} // SingleElem
