/*
 * Created on 8 Oct 2022 
 * Copyright 2022 Paul Harrison (paul.harrison@manchester.ac.uk)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License in file LICENSE
 */ 

package org.ivoa.vodml;

import java.util.Map;

/**
 *  .
 * @author Paul Harrison (paul.harrison@manchester.ac.uk) 
 * @since 8 Oct 2022
 */
public interface ModelDescription  {
    
    /**
     * A map from the UTYPE to the class that implements that model element.
     * @return the map.
     */
    @SuppressWarnings("rawtypes")
    Map<String, Class > utypeToClassMap();
    
    /**
     * mapping between XML namespace and the schema file for that namespace.
     * @return the mapping with namespace as the key and schema filename as the value
     */
    Map<String,String> schemaMap();
    
    /**
     * The main namespace for the top level model element.
     * @return the namespace for the model.
     */
    String xmlNamespace();

}


