/*
 * Created on 5 Nov 2021 
 * Copyright 2021 Paul Harrison (paul.harrison@manchester.ac.uk)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License in file LICENSE
 */ 

package org.ivoa.vodml.testing;

import static org.junit.jupiter.api.Assertions.*;

import javax.xml.bind.JAXBException;
import javax.xml.bind.PropertyException;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.transform.TransformerConfigurationException;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactoryConfigurationError;

import com.fasterxml.jackson.core.JsonProcessingException;

import org.ivoa.vodml.ModelManagement;
import org.ivoa.vodml.VodmlModel;
import org.ivoa.vodml.jpa.JPAManipulationsForObjectType;
import org.ivoa.vodml.validation.AbstractBaseValidation;

/**
 * Base Class for the test classes .
 * @author Paul Harrison (paul.harrison@manchester.ac.uk) 
 * @since 5 Nov 2021
 */
public abstract class AbstractTest extends AbstractBaseValidation {


//    abstract <T> ModelManagement<T> getModelManagement();

    public <T extends VodmlModel<T>> T modelRoundTripXMLwithTest(T model) throws PropertyException, TransformerConfigurationException, ParserConfigurationException, JAXBException, TransformerFactoryConfigurationError, TransformerException
    {
        RoundTripResult<T> result = roundtripXML(model.management());
        assertTrue(result.isValid, "reading xml back had errors");
        assertNotNull(result.retval,"returned object from XML serialization null");
        return result.retval;
    }

    public <T extends VodmlModel<T>> T modelRoundTripJSONwithTest(T model) throws JsonProcessingException
    {
        RoundTripResult<T> result = roundTripJSON(model.management());
        assertTrue(result.isValid, "reading xml back had errors");
        assertNotNull(result.retval,"returned object from JSON serialization null");
        return result.retval;
    }

   public <M, I, T extends JPAManipulationsForObjectType<I>> T modelRoundTripRDBwithTest(ModelManagement<M> modelManagement, T entity)
    {
        RoundTripResult<T> result = roundtripRDB(modelManagement, entity);
        assertTrue(result.isValid, "reading rdb back had errors");
        assertNotNull(result.retval,"returned object from rdb serialization null");
        return result.retval;
    }





}


