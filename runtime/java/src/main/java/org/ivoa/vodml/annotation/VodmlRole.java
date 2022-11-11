package org.ivoa.vodml.annotation;
/*
 * Created on 12/08/2021 by Paul Harrison (paul.harrison@manchester.ac.uk).
 */

/**
 * Enumeration of VODML "roles". See the VO-DML standard for the meanings.
 * @author Paul Harrison (paul.harrison@manchester.ac.uk) 
 */
public enum VodmlRole {
    unknown, // special "null" value
    model,
    objectType,
    attribute,
    composition,
    reference,
    dataType,
    primitiveType,
    enumeration

}
