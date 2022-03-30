package org.ivoa.vodml.nav;
/*
 * Created on 29/03/2022 by Paul Harrison (paul.harrison@manchester.ac.uk).
 */

/**
 * Interface to walk collections in order to force loading by JPA.
 */
public interface JPACollectionTraverser {
   void walkCollections();
}
