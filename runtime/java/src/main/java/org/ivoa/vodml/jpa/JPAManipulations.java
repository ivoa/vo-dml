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

   /**
    * Deep clone entity by detaching. Note that references are left alone.
    * @param em the entity manager
 * <pre>
 *    MyEntity to_clone = entityManager.find(MyEntity.class, ID);
 *    to_clone.jpaClone(entityManager);
 *    entityManager.merge(to_clone);
 * </pre>
    * 
    * @deprecated - use the copy constructor instead.
    */
   @Deprecated(forRemoval = true)
   void jpaClone(EntityManager em);

   /**
    * Persist any references in the object tree. This exists to aid initial persistence of
    * a model instance, as no JPA operations (apart from refresh) are cascaded to references.
    * References lifecycle is expected to be managed separately.
    * @param em the entity manager
    * @deprecated use the method at the model level - as it is only then that "contained" references can be determined.
    */
   @Deprecated
   void persistRefs(EntityManager em);

}
