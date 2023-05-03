/*
 * Created on 21 Oct 2022 
 * Copyright 2022 Paul Harrison (paul.harrison@manchester.ac.uk)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License in file LICENSE
 */ 

package org.ivoa.dm.lifecycle;

import static org.junit.jupiter.api.Assertions.*;

import java.io.IOException;
import java.util.Arrays;
import java.util.List;

import javax.xml.bind.JAXBContext;
import javax.xml.bind.JAXBException;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.transform.TransformerConfigurationException;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactoryConfigurationError;

import org.ivoa.dm.AbstractTest;
import org.ivoa.dm.AutoRoundTripTest;
import org.ivoa.vodml.VodmlModel;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 *  .
 * @author Paul Harrison (paul.harrison@manchester.ac.uk) 
 * @since 21 Oct 2022
 */
class LifecycleTestModelTest extends AutoRoundTripTest<LifecycleTestModel> {

    private ATest atest;
    private ATest2 atest2;

    /**
     * @throws java.lang.Exception
     */
    @BeforeAll
    static void setUpBeforeClass() throws Exception {
    }

    /**
     * @throws java.lang.Exception
     */
    @BeforeEach
    void setUp() throws Exception {

    }

    /**
     * @throws java.lang.Exception
     */
    @AfterEach
    void tearDown() throws Exception {
    }

  

    /**
     * {@inheritDoc}
     * overrides @see org.ivoa.vodml.validation.AutoRoundTripTest#createModel()
     */
    @Override
    public LifecycleTestModel createModel() {
        final ReferredTo referredTo = new ReferredTo(3);
        List<Contained> contained = Arrays.asList(new Contained("firstcontained"),new Contained("secondContained"));
        List<ReferredLifeCycle> refcont = Arrays.asList(new ReferredLifeCycle("rc1"), new ReferredLifeCycle("rc2"));
        atest = ATest.createATest(a -> {
            a.ref1 = referredTo;
            a.contained = contained;
            a.refandcontained = refcont;
            
        });
        atest2 = new ATest2(referredTo, refcont.get(0));
        
        LifecycleTestModel model = new LifecycleTestModel();
        model.addContent(atest);
        model.addContent(atest2);
        model.makeRefIDsUnique();
        assertTrue(atest.refandcontained.get(1).getId() != 0, "id setting did not work");
        return model;
    }

    /**
     * {@inheritDoc}
     * overrides @see org.ivoa.vodml.validation.AutoRoundTripTest#testModel(org.ivoa.vodml.VodmlModel)
     */
    @Override
    public void testModel(LifecycleTestModel m) {
        // TODO actually test something in the model.
        
        
    }

}


