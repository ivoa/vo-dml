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

    /**
     * Get the XML ID.
     * @return a suitable XML ID
     */
    String getXmlId();

    /**
     * set internal Identifier from XML ID.
     * @param id the XML ID
     */
    void setXmlId (String id);

    /**
     * Does the type have a natural key (i.e. one of the attributes) rather than having a surrogate key generated.
     * @return true is the type has a natural key .
     */
    boolean hasNaturalKey();

  
    /**
     * Create and XMLID.
     * @param i the key value;
     * @return the XMLID as NCName.
     */
    static String createXMLId(long i)
    {
        return  new StringBuffer("id_").append(i).toString(); // XML ids must be NCNames.

    }
    /**
     * Parse XML ID into a long ID.
     * @param id the xml ID.
     * @return the key as long.
     */
    static Long parseXMLId(String id)
    {
        return Long.parseLong(id.substring(id.indexOf('_')+1));
    }

}


