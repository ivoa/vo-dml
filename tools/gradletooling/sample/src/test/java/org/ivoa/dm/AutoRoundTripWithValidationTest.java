/*
 * Created on 4 May 2023 
 * Copyright 2023 Paul Harrison (paul.harrison@manchester.ac.uk)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License in file LICENSE
 */ 

package org.ivoa.dm;

import static org.junit.jupiter.api.Assertions.assertTrue;

import javax.xml.bind.JAXBException;

import org.ivoa.vodml.VodmlModel;
import org.ivoa.vodml.validation.ModelValidator.ValidationResult;
import org.junit.jupiter.api.Test;

/**
 *  .
 * @author Paul Harrison (paul.harrison@manchester.ac.uk) 
 * @since 4 May 2023
 */
public abstract class AutoRoundTripWithValidationTest<M extends VodmlModel<M>> extends AutoRoundTripTest<M> {
 @Test
    void validationTest() throws JAXBException {
        final M model = createModel(); 
        model.management().writeXMLSchema();
        
        ValidationResult vr = validateModel(model);
        if(!vr.isOk)
        {
            vr.printValidationErrors(System.out);
        }
        assertTrue(vr.isOk, "model instance is not valid");
    }
}


