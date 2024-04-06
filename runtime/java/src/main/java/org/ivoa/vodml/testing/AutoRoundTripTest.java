/*
 * Created on 3 May 2023 
 * Copyright 2023 Paul Harrison (paul.harrison@manchester.ac.uk)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License in file LICENSE
 */ 

package org.ivoa.vodml.testing;

import com.fasterxml.jackson.core.JsonProcessingException;
import org.ivoa.vodml.VodmlModel;
import org.ivoa.vodml.validation.AbstractBaseValidation;
import org.junit.jupiter.api.Test;

import jakarta.xml.bind.JAXBException;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.transform.TransformerConfigurationException;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactoryConfigurationError;
import java.io.IOException;

import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * An abstract base Test that does XML and JSON serialization round-trip tests .
 * @author Paul Harrison (paul.harrison@manchester.ac.uk) 
 * @since 3 May 2023
 */
public abstract class AutoRoundTripTest <M extends VodmlModel<M>> extends AbstractBaseValidation {
    
    
    /**
     * Create the model instance.
     * @return the model to round-trip
     */
    public abstract  M createModel();
    
    /**
     * Run some tests on the model.
     * @param m the model to be tested
     */
    public abstract void testModel(M m);
    
    
   
  
    
    @Test
    void testXmlRoundTrip() throws JAXBException, TransformerConfigurationException, ParserConfigurationException, TransformerFactoryConfigurationError, TransformerException, IOException {
        
        M model = createModel();
        RoundTripResult<M> result = roundtripXML(model);
        assertTrue(result.isValid, "reading XML back had errors");
        assertNotNull(result.retval,"returned object from XML serialization null");
        testModel(result.retval);
    }

    @Test
    void testJSONRoundTrip() throws JsonProcessingException  {
        
        M model = createModel();
        RoundTripResult<M> result = roundTripJSON(model);
        assertTrue(result.isValid, "reading JSON back had errors");
        assertNotNull(result.retval,"returned object from JSON serialization null");
        testModel(result.retval);
    }

   
    


}


