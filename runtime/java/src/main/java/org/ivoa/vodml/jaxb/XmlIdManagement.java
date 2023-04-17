/*
 * Created on 2 Sep 2021 
 * Copyright 2021 Paul Harrison (paul.harrison@manchester.ac.uk)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License in file LICENSE
 */ 

package org.ivoa.vodml.jaxb;

/**
 * Necessary functions to manipulate xml IDs.
 * @author Paul Harrison (paul.harrison@manchester.ac.uk) 
 * @since 2 Sep 2021
 */
public interface XmlIdManagement {

     String getXmlId();
     
     void setXmlId (String id);
     
     boolean hasNaturalKey();

     @SuppressWarnings("rawtypes")
     Class idType();
    
}


