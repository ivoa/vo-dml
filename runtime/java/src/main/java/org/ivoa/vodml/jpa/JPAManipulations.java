package org.ivoa.vodml.jpa;
/*
 * Created on 29/03/2022 by Paul Harrison (paul.harrison@manchester.ac.uk).
 */

import jakarta.persistence.EntityManager;

/**
 * Interface to implement some common manipulations in JPA.
 */
public interface JPAManipulations {
   /**
 * descend through an object tree to force loading of lazily loaded collections.
 */
   void forceLoad();

}
