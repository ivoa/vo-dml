package org.ivoa.vodml.annotation;
/*
 * Created on 12/08/2021 by Paul Harrison (paul.harrison@manchester.ac.uk).
 */

/**
 * Enumeration of VODML "roles". See the VO-DML standard for the meanings.
 * @author Paul Harrison (paul.harrison@manchester.ac.uk) 
 */
public enum VodmlRole {
    /** unknown type.
     */
    unknown, // special "null" value
    /** model.
     */
    model,
    /** objectType.
     */
    objectType,
    /** attribute.
     */
    attribute,
    /** composition.
     */
    composition,
    /** reference.
     */
    reference,
    /** dataType.
     */
    dataType,
    /** primitiveType.
     */
    primitiveType,
    /** enumeration.
     */
    enumeration

}
