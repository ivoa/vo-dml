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

import jakarta.xml.bind.JAXBException;
import jakarta.xml.bind.PropertyException;
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

    /**
     * perform and XML serialization round trip test on a model instance.
     * @param <T> The type of the model.
     * @param model the model to perform the round trip on.
     * @return the round-tripped model.
     * @throws PropertyException if there is a problem with property setup.
     * @throws TransformerConfigurationException if there is an error in the setup of the transformer.
     * @throws ParserConfigurationException if there was an error in the parser setup.
     * @throws JAXBException  if there is a general JAX exception.
     * @throws TransformerFactoryConfigurationError if there is an error in the setup of the transformer.
     * @throws TransformerException if there is an error in the setup of the transformer.
     */
    public <T extends VodmlModel<T>> T modelRoundTripXMLwithTest( VodmlModel<T> model) throws PropertyException, TransformerConfigurationException, ParserConfigurationException, JAXBException, TransformerFactoryConfigurationError, TransformerException
    {
        RoundTripResult<T> result = roundtripXML(model);
        assertTrue(result.isValid, "reading xml back had errors");
        assertNotNull(result.retval,"returned object from XML serialization null");
        return result.retval;
    }

    /**
     * Perform a JSON serialization round-trip on a model instance.
     * @param <T> the type of the model.
     * @param model the model instance to round-trip.
     * @return the instance of the model as a result of the round-trip.
     * @throws JsonProcessingException if there is a JSON problem.
     */
    public <T extends VodmlModel<T>> T modelRoundTripJSONwithTest(T model) throws JsonProcessingException
    {
        RoundTripResult<T> result = roundTripJSON(model);
        assertTrue(result.isValid, "reading xml back had errors");
        assertNotNull(result.retval,"returned object from JSON serialization null");
        return result.retval;
    }

   /**
    * Perform a database round-trip on an entity from the model.
 * @param <M> the model type.
 * @param <I> The type of the primary key of the entity.
 * @param <T> the type of the entity.
 * @param modelManagement the management interface for the model.
 * @param entity the entity to round-trip.
 * @return the round-tripped instance of the entity.
 */
public <M, I, T extends JPAManipulationsForObjectType<I>> T modelRoundTripRDBwithTest(ModelManagement<M> modelManagement, T entity)
    {
        RoundTripResult<T> result = roundtripRDB(modelManagement, entity);
        assertTrue(result.isValid, "reading rdb back had errors");
        assertNotNull(result.retval,"returned object from rdb serialization null");
        return result.retval;
    }





}


