package org.ivoa.vodml.nav;
/*
 * Created on 28/03/2023 by Paul Harrison (paul.harrison@manchester.ac.uk).
 */

public interface ObjectCopier<T> {
    public T objectCopy(T o);
}
