/**
 */
package de.tbuchmann.bags2bags.bxtenddsl.corrmodel;

import org.eclipse.emf.ecore.EAttribute;
import org.eclipse.emf.ecore.EClass;
import org.eclipse.emf.ecore.EPackage;
import org.eclipse.emf.ecore.EReference;

/**
 * <!-- begin-user-doc -->
 * The <b>Package</b> for the model.
 * It contains accessors for the meta objects to represent
 * <ul>
 *   <li>each class,</li>
 *   <li>each feature of each class,</li>
 *   <li>each enum,</li>
 *   <li>and each data type</li>
 * </ul>
 * <!-- end-user-doc -->
 * @see de.tbuchmann.bags2bags.bxtenddsl.corrmodel.CorrModelFactory
 * @model kind="package"
 * @generated
 */
public interface CorrModelPackage extends EPackage {
	/**
	 * The package name.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	String eNAME = "corrmodel";

	/**
	 * The package namespace URI.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	String eNS_URI = "http://de/tbuchmann/bags2bags/bxtenddsl/corrmodel.ecore";

	/**
	 * The package namespace name.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	String eNS_PREFIX = "de.tbuchmann.bags2bags.bxtenddsl.corrmodel";

	/**
	 * The singleton instance of the package.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	CorrModelPackage eINSTANCE = de.tbuchmann.bags2bags.bxtenddsl.corrmodel.impl.CorrModelPackageImpl.init();

	/**
	 * The meta object id for the '{@link de.tbuchmann.bags2bags.bxtenddsl.corrmodel.impl.TransformationImpl <em>Transformation</em>}' class.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @see de.tbuchmann.bags2bags.bxtenddsl.corrmodel.impl.TransformationImpl
	 * @see de.tbuchmann.bags2bags.bxtenddsl.corrmodel.impl.CorrModelPackageImpl#getTransformation()
	 * @generated
	 */
	int TRANSFORMATION = 0;

	/**
	 * The feature id for the '<em><b>Correspondences</b></em>' containment reference list.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 * @ordered
	 */
	int TRANSFORMATION__CORRESPONDENCES = 0;

	/**
	 * The number of structural features of the '<em>Transformation</em>' class.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 * @ordered
	 */
	int TRANSFORMATION_FEATURE_COUNT = 1;

	/**
	 * The meta object id for the '{@link de.tbuchmann.bags2bags.bxtenddsl.corrmodel.impl.CorrImpl <em>Corr</em>}' class.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @see de.tbuchmann.bags2bags.bxtenddsl.corrmodel.impl.CorrImpl
	 * @see de.tbuchmann.bags2bags.bxtenddsl.corrmodel.impl.CorrModelPackageImpl#getCorr()
	 * @generated
	 */
	int CORR = 1;

	/**
	 * The feature id for the '<em><b>Rule Id</b></em>' attribute.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 * @ordered
	 */
	int CORR__RULE_ID = 0;

	/**
	 * The feature id for the '<em><b>Source</b></em>' containment reference list.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 * @ordered
	 */
	int CORR__SOURCE = 1;

	/**
	 * The feature id for the '<em><b>Target</b></em>' containment reference list.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 * @ordered
	 */
	int CORR__TARGET = 2;

	/**
	 * The number of structural features of the '<em>Corr</em>' class.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 * @ordered
	 */
	int CORR_FEATURE_COUNT = 3;

	/**
	 * The meta object id for the '{@link de.tbuchmann.bags2bags.bxtenddsl.corrmodel.impl.CorrElemImpl <em>Corr Elem</em>}' class.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @see de.tbuchmann.bags2bags.bxtenddsl.corrmodel.impl.CorrElemImpl
	 * @see de.tbuchmann.bags2bags.bxtenddsl.corrmodel.impl.CorrModelPackageImpl#getCorrElem()
	 * @generated
	 */
	int CORR_ELEM = 2;

	/**
	 * The number of structural features of the '<em>Corr Elem</em>' class.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 * @ordered
	 */
	int CORR_ELEM_FEATURE_COUNT = 0;

	/**
	 * The meta object id for the '{@link de.tbuchmann.bags2bags.bxtenddsl.corrmodel.impl.SingleElemImpl <em>Single Elem</em>}' class.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @see de.tbuchmann.bags2bags.bxtenddsl.corrmodel.impl.SingleElemImpl
	 * @see de.tbuchmann.bags2bags.bxtenddsl.corrmodel.impl.CorrModelPackageImpl#getSingleElem()
	 * @generated
	 */
	int SINGLE_ELEM = 3;

	/**
	 * The feature id for the '<em><b>Element</b></em>' reference.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 * @ordered
	 */
	int SINGLE_ELEM__ELEMENT = CORR_ELEM_FEATURE_COUNT + 0;

	/**
	 * The number of structural features of the '<em>Single Elem</em>' class.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 * @ordered
	 */
	int SINGLE_ELEM_FEATURE_COUNT = CORR_ELEM_FEATURE_COUNT + 1;

	/**
	 * The meta object id for the '{@link de.tbuchmann.bags2bags.bxtenddsl.corrmodel.impl.MultiElemImpl <em>Multi Elem</em>}' class.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @see de.tbuchmann.bags2bags.bxtenddsl.corrmodel.impl.MultiElemImpl
	 * @see de.tbuchmann.bags2bags.bxtenddsl.corrmodel.impl.CorrModelPackageImpl#getMultiElem()
	 * @generated
	 */
	int MULTI_ELEM = 4;

	/**
	 * The feature id for the '<em><b>Elements</b></em>' reference list.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 * @ordered
	 */
	int MULTI_ELEM__ELEMENTS = CORR_ELEM_FEATURE_COUNT + 0;

	/**
	 * The number of structural features of the '<em>Multi Elem</em>' class.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 * @ordered
	 */
	int MULTI_ELEM_FEATURE_COUNT = CORR_ELEM_FEATURE_COUNT + 1;


	/**
	 * Returns the meta object for class '{@link de.tbuchmann.bags2bags.bxtenddsl.corrmodel.Transformation <em>Transformation</em>}'.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the meta object for class '<em>Transformation</em>'.
	 * @see de.tbuchmann.bags2bags.bxtenddsl.corrmodel.Transformation
	 * @generated
	 */
	EClass getTransformation();

	/**
	 * Returns the meta object for the containment reference list '{@link de.tbuchmann.bags2bags.bxtenddsl.corrmodel.Transformation#getCorrespondences <em>Correspondences</em>}'.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the meta object for the containment reference list '<em>Correspondences</em>'.
	 * @see de.tbuchmann.bags2bags.bxtenddsl.corrmodel.Transformation#getCorrespondences()
	 * @see #getTransformation()
	 * @generated
	 */
	EReference getTransformation_Correspondences();

	/**
	 * Returns the meta object for class '{@link de.tbuchmann.bags2bags.bxtenddsl.corrmodel.Corr <em>Corr</em>}'.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the meta object for class '<em>Corr</em>'.
	 * @see de.tbuchmann.bags2bags.bxtenddsl.corrmodel.Corr
	 * @generated
	 */
	EClass getCorr();

	/**
	 * Returns the meta object for the attribute '{@link de.tbuchmann.bags2bags.bxtenddsl.corrmodel.Corr#getRuleId <em>Rule Id</em>}'.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the meta object for the attribute '<em>Rule Id</em>'.
	 * @see de.tbuchmann.bags2bags.bxtenddsl.corrmodel.Corr#getRuleId()
	 * @see #getCorr()
	 * @generated
	 */
	EAttribute getCorr_RuleId();

	/**
	 * Returns the meta object for the containment reference list '{@link de.tbuchmann.bags2bags.bxtenddsl.corrmodel.Corr#getSource <em>Source</em>}'.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the meta object for the containment reference list '<em>Source</em>'.
	 * @see de.tbuchmann.bags2bags.bxtenddsl.corrmodel.Corr#getSource()
	 * @see #getCorr()
	 * @generated
	 */
	EReference getCorr_Source();

	/**
	 * Returns the meta object for the containment reference list '{@link de.tbuchmann.bags2bags.bxtenddsl.corrmodel.Corr#getTarget <em>Target</em>}'.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the meta object for the containment reference list '<em>Target</em>'.
	 * @see de.tbuchmann.bags2bags.bxtenddsl.corrmodel.Corr#getTarget()
	 * @see #getCorr()
	 * @generated
	 */
	EReference getCorr_Target();

	/**
	 * Returns the meta object for class '{@link de.tbuchmann.bags2bags.bxtenddsl.corrmodel.CorrElem <em>Corr Elem</em>}'.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the meta object for class '<em>Corr Elem</em>'.
	 * @see de.tbuchmann.bags2bags.bxtenddsl.corrmodel.CorrElem
	 * @generated
	 */
	EClass getCorrElem();

	/**
	 * Returns the meta object for class '{@link de.tbuchmann.bags2bags.bxtenddsl.corrmodel.SingleElem <em>Single Elem</em>}'.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the meta object for class '<em>Single Elem</em>'.
	 * @see de.tbuchmann.bags2bags.bxtenddsl.corrmodel.SingleElem
	 * @generated
	 */
	EClass getSingleElem();

	/**
	 * Returns the meta object for the reference '{@link de.tbuchmann.bags2bags.bxtenddsl.corrmodel.SingleElem#getElement <em>Element</em>}'.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the meta object for the reference '<em>Element</em>'.
	 * @see de.tbuchmann.bags2bags.bxtenddsl.corrmodel.SingleElem#getElement()
	 * @see #getSingleElem()
	 * @generated
	 */
	EReference getSingleElem_Element();

	/**
	 * Returns the meta object for class '{@link de.tbuchmann.bags2bags.bxtenddsl.corrmodel.MultiElem <em>Multi Elem</em>}'.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the meta object for class '<em>Multi Elem</em>'.
	 * @see de.tbuchmann.bags2bags.bxtenddsl.corrmodel.MultiElem
	 * @generated
	 */
	EClass getMultiElem();

	/**
	 * Returns the meta object for the reference list '{@link de.tbuchmann.bags2bags.bxtenddsl.corrmodel.MultiElem#getElements <em>Elements</em>}'.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the meta object for the reference list '<em>Elements</em>'.
	 * @see de.tbuchmann.bags2bags.bxtenddsl.corrmodel.MultiElem#getElements()
	 * @see #getMultiElem()
	 * @generated
	 */
	EReference getMultiElem_Elements();

	/**
	 * Returns the factory that creates the instances of the model.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the factory that creates the instances of the model.
	 * @generated
	 */
	CorrModelFactory getCorrModelFactory();

	/**
	 * <!-- begin-user-doc -->
	 * Defines literals for the meta objects that represent
	 * <ul>
	 *   <li>each class,</li>
	 *   <li>each feature of each class,</li>
	 *   <li>each enum,</li>
	 *   <li>and each data type</li>
	 * </ul>
	 * <!-- end-user-doc -->
	 * @generated
	 */
	interface Literals {
		/**
		 * The meta object literal for the '{@link de.tbuchmann.bags2bags.bxtenddsl.corrmodel.impl.TransformationImpl <em>Transformation</em>}' class.
		 * <!-- begin-user-doc -->
		 * <!-- end-user-doc -->
		 * @see de.tbuchmann.bags2bags.bxtenddsl.corrmodel.impl.TransformationImpl
		 * @see de.tbuchmann.bags2bags.bxtenddsl.corrmodel.impl.CorrModelPackageImpl#getTransformation()
		 * @generated
		 */
		EClass TRANSFORMATION = eINSTANCE.getTransformation();

		/**
		 * The meta object literal for the '<em><b>Correspondences</b></em>' containment reference list feature.
		 * <!-- begin-user-doc -->
		 * <!-- end-user-doc -->
		 * @generated
		 */
		EReference TRANSFORMATION__CORRESPONDENCES = eINSTANCE.getTransformation_Correspondences();

		/**
		 * The meta object literal for the '{@link de.tbuchmann.bags2bags.bxtenddsl.corrmodel.impl.CorrImpl <em>Corr</em>}' class.
		 * <!-- begin-user-doc -->
		 * <!-- end-user-doc -->
		 * @see de.tbuchmann.bags2bags.bxtenddsl.corrmodel.impl.CorrImpl
		 * @see de.tbuchmann.bags2bags.bxtenddsl.corrmodel.impl.CorrModelPackageImpl#getCorr()
		 * @generated
		 */
		EClass CORR = eINSTANCE.getCorr();

		/**
		 * The meta object literal for the '<em><b>Rule Id</b></em>' attribute feature.
		 * <!-- begin-user-doc -->
		 * <!-- end-user-doc -->
		 * @generated
		 */
		EAttribute CORR__RULE_ID = eINSTANCE.getCorr_RuleId();

		/**
		 * The meta object literal for the '<em><b>Source</b></em>' containment reference list feature.
		 * <!-- begin-user-doc -->
		 * <!-- end-user-doc -->
		 * @generated
		 */
		EReference CORR__SOURCE = eINSTANCE.getCorr_Source();

		/**
		 * The meta object literal for the '<em><b>Target</b></em>' containment reference list feature.
		 * <!-- begin-user-doc -->
		 * <!-- end-user-doc -->
		 * @generated
		 */
		EReference CORR__TARGET = eINSTANCE.getCorr_Target();

		/**
		 * The meta object literal for the '{@link de.tbuchmann.bags2bags.bxtenddsl.corrmodel.impl.CorrElemImpl <em>Corr Elem</em>}' class.
		 * <!-- begin-user-doc -->
		 * <!-- end-user-doc -->
		 * @see de.tbuchmann.bags2bags.bxtenddsl.corrmodel.impl.CorrElemImpl
		 * @see de.tbuchmann.bags2bags.bxtenddsl.corrmodel.impl.CorrModelPackageImpl#getCorrElem()
		 * @generated
		 */
		EClass CORR_ELEM = eINSTANCE.getCorrElem();

		/**
		 * The meta object literal for the '{@link de.tbuchmann.bags2bags.bxtenddsl.corrmodel.impl.SingleElemImpl <em>Single Elem</em>}' class.
		 * <!-- begin-user-doc -->
		 * <!-- end-user-doc -->
		 * @see de.tbuchmann.bags2bags.bxtenddsl.corrmodel.impl.SingleElemImpl
		 * @see de.tbuchmann.bags2bags.bxtenddsl.corrmodel.impl.CorrModelPackageImpl#getSingleElem()
		 * @generated
		 */
		EClass SINGLE_ELEM = eINSTANCE.getSingleElem();

		/**
		 * The meta object literal for the '<em><b>Element</b></em>' reference feature.
		 * <!-- begin-user-doc -->
		 * <!-- end-user-doc -->
		 * @generated
		 */
		EReference SINGLE_ELEM__ELEMENT = eINSTANCE.getSingleElem_Element();

		/**
		 * The meta object literal for the '{@link de.tbuchmann.bags2bags.bxtenddsl.corrmodel.impl.MultiElemImpl <em>Multi Elem</em>}' class.
		 * <!-- begin-user-doc -->
		 * <!-- end-user-doc -->
		 * @see de.tbuchmann.bags2bags.bxtenddsl.corrmodel.impl.MultiElemImpl
		 * @see de.tbuchmann.bags2bags.bxtenddsl.corrmodel.impl.CorrModelPackageImpl#getMultiElem()
		 * @generated
		 */
		EClass MULTI_ELEM = eINSTANCE.getMultiElem();

		/**
		 * The meta object literal for the '<em><b>Elements</b></em>' reference list feature.
		 * <!-- begin-user-doc -->
		 * <!-- end-user-doc -->
		 * @generated
		 */
		EReference MULTI_ELEM__ELEMENTS = eINSTANCE.getMultiElem_Elements();

	}

} //CorrModelPackage
