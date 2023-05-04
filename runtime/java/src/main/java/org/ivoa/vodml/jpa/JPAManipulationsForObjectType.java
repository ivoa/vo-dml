package org.ivoa.vodml.jpa;
/*
 * Created on 29/03/2022 by Paul Harrison (paul.harrison@manchester.ac.uk).
 */

import javax.persistence.EntityManager;

/**
 * Interface to implement some common manipulations in JPA.
 */
public interface JPAManipulationsForObjectType <ID> extends JPAManipulations {
 
   /**
    * Get the database ID.
    * @return
    */
   ID getId();
   
 

}
