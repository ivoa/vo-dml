package org.ivoa.vodml.jaxb;
/*
 * Created on 26/09/2022 by Paul Harrison (paul.harrison@manchester.ac.uk).
 */

import javax.xml.bind.JAXBContext;
import javax.xml.bind.JAXBException;

public interface JaxbManagement {

   /**
    * make all the referenced IDs within the model instance unique.
    */
    void makeRefIDsUnique();

}
