package org.ivoa.vodml.jpa;
/*
 * Created on 29/03/2022 by Paul Harrison (paul.harrison@manchester.ac.uk).
 */

import jakarta.persistence.EntityManager;

/**
 * Interface to implement some common manipulations in JPA.
 * This interface will be implemented on ObjectTypes.
 */
public interface JPAManipulationsForObjectType <ID> extends JPAManipulations {
 
   /**
    * Get the database ID.
    * @return the database ID.
    */
   ID getId();

   /**
    * Delete the entity from the database. This will take into account any ordering necessary because of any contained references.
    * If there are no contained references - then this will be equivalent to em.delete(this), however there might be some efficiency built in via bulk deletion.
    * @param em the entity manager
    */
   void delete(EntityManager em);


}
