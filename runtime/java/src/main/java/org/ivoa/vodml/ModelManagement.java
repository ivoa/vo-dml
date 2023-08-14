/*
 * Created on 6 Oct 2022 
 * Copyright 2022 Paul Harrison (paul.harrison@manchester.ac.uk)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License in file LICENSE
 */ 

package org.ivoa.vodml;

import java.io.IOException;
import java.util.List;

import jakarta.xml.bind.JAXBContext;
import jakarta.xml.bind.JAXBException;

import com.fasterxml.jackson.databind.ObjectMapper;

/**
 * Functions related to model processing functionality.
 * This functionality is generated as static functions in the model class, but as it is not possible to have
 * static functions implementing an interface, there is and additional static function management() that will return an
 * instance of this interface which is simple a facade to the static functions.
 * 
 * The point of doing this is to allow generic code that processes multiple models to be written more easily.
 * 
 * @author Paul Harrison (paul.harrison@manchester.ac.uk) 
 * @since 6 Oct 2022
 */
public interface ModelManagement <T>{
    
    /**
     * Get the model itself
     * @return the top level model object.
     */
    T theModel();
    
    
    /**
     * return the content to the model.
     * @return the model content
     */
    List<Object> getContent();
    
     /**
      * the persistence unit name used by the model.
     * @return the name
     */
    String pu_name();
     /**
      * Write XML schema for the model.
     */
    void writeXMLSchema();
    
    /**
     * The context factory that can be used for full XML serialization.
     * @return the context factory.
     * @throws JAXBException if something goes wrong with the creation of the context.
     */
    JAXBContext contextFactory()  throws JAXBException;
    
    /**
     * Utility method for discovering if model has referenced types.
     * @return true if the model has references.
     */
    boolean hasReferences();
    
    /**
     * Return a Jackson objectMapper suitable for JSON serialzation.
     * @return the objectmapper.
     */
    ObjectMapper jsonMapper();
}


