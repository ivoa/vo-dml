package org.ivoa.vodml.nav;
/*
 * Created on 28/03/2023 by Paul Harrison (paul.harrison@manchester.ac.uk).
 */

/**
 *  Describes the operations for copying an object of type T. This copy takes into account the fact that references should not be copied.
 * @author Paul Harrison (paul.harrison@manchester.ac.uk) 
 */
public interface ObjectCopier<T> {
    /**
     * copy and object.
     * @param o the object to be copied.
     * @return the copy of the original object.
     */
    public T objectCopy(T o);
}
