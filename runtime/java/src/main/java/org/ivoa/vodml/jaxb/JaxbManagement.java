package org.ivoa.vodml.jaxb;
/*
 * Created on 26/09/2022 by Paul Harrison (paul.harrison@manchester.ac.uk).
 */

public interface JaxbManagement {

   /**
    * Processing the references in the model necessary before serialization
    * and after de-serialization.
    * e.g. make all the referenced IDs within the model instance unique.
    */
    void processReferences();

}
