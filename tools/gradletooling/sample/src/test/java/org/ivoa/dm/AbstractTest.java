/*
 * Created on 5 Nov 2021 
 * Copyright 2021 Paul Harrison (paul.harrison@manchester.ac.uk)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License in file LICENSE
 */ 

package org.ivoa.dm;

import static org.junit.jupiter.api.Assertions.*;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;

import org.ivoa.vodml.ModelManagement;

/**
 * Base Class for the test classes .
 * @author Paul Harrison (paul.harrison@manchester.ac.uk) 
 * @since 5 Nov 2021
 */
public abstract class AbstractTest extends org.javastro.ivoa.tests.AbstractJAXBJPATest {


    protected  <T> T roundTripJSON( T model, ModelManagement<T> m, Class<T> clazz) throws JsonProcessingException {
        ObjectMapper mapper = m.jsonMapper();
        String json = mapper.writerWithDefaultPrettyPrinter().writeValueAsString(model);
        System.out.println("JSON output"); 
        System.out.println(json);
        T retval = mapper.readValue(json, clazz);
        assertNotNull(retval);
        return retval;

    }

}


