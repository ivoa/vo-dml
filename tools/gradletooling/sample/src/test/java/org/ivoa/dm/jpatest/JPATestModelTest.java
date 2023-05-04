/*
 * Created on 21 Oct 2022 
 * Copyright 2022 Paul Harrison (paul.harrison@manchester.ac.uk)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License in file LICENSE
 */ 

package org.ivoa.dm.jpatest;

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
import org.ivoa.dm.sample.SampleModel;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 *  .
 * @author Paul Harrison (paul.harrison@manchester.ac.uk) 
 * @since 21 Oct 2022
 */
class JPATestModelTest extends AbstractTest {

    private Parent atest;

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
        final ReferredTo1 referredTo = new ReferredTo1("top level ref");
        final ReferredTo2 referredToin = new ReferredTo2("lower ref");
        Child refcont = new Child(referredToin);
        atest = Parent.createParent(a -> {
            ReferredTo3 ref3 = new ReferredTo3("ref in dtype");
            a.dval = new ADtype(1.1, "astring", ref3 );
            a.rval = referredTo;
            a.cval = refcont;
            
        });
       
    }

    /**
     * @throws java.lang.Exception
     */
    @AfterEach
    void tearDown() throws Exception {
    }

    @Test
    void jaxbtest() throws JAXBException,  ParserConfigurationException, TransformerFactoryConfigurationError, TransformerException{
        
        JAXBContext jc = JpatestModel.contextFactory();
        JpatestModel model = new JpatestModel();
        model.addContent(atest);
        model.processReferences();
        assertTrue(atest.cval.rval._id != 0, "id setting did not work");
        JpatestModel modelin = modelRoundTripXMLwithTest(model);
        System.out.println("generating schema");
        JpatestModel.writeXMLSchema();
    }
    @Test
    void jpaInitialCreateTest() {
        javax.persistence.EntityManager em = setupH2Db(SampleModel.pu_name());//the persistence unit is all under the one file....
        em.getTransaction().begin();
        atest.persistRefs(em); //IMPL need to save references explicitly as they are new.
        em.persist(atest);
        em.getTransaction().commit();
        Long id = atest.getId();

        //flush any existing entities
        em.clear();
        em.getEntityManagerFactory().getCache().evictAll();

        // now read back
        em.getTransaction().begin();
        List<Parent> par = em.createNamedQuery("Parent.findById", Parent.class)
                .setParameter("id", id).getResultList();
        em.getTransaction().commit();
        assertEquals(1, par.size());
        assertEquals("top level ref",par.get(0).rval.sval);
        assertEquals("lower ref",par.get(0).cval.rval.sval);
        assertEquals("ref in dtype",par.get(0).dval.dref.sval);
        
       

    }

}


