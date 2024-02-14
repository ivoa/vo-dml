/*
 * Created on 27 Jun 2023 
 * Copyright 2023 Paul Harrison (paul.harrison@manchester.ac.uk)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License in file LICENSE
 */ 

package org.ivoa.dm.lifecycle;

import static org.junit.jupiter.api.Assertions.*;

import java.util.AbstractMap;
import java.util.Arrays;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.ivoa.dm.sample.SampleModel;
import org.ivoa.dm.sample.catalog.inner.SourceCatalogue;
import org.ivoa.vodml.ModelContext;
import org.ivoa.vodml.testing.AbstractTest;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 *  .
 * @author Paul Harrison (paul.harrison@manchester.ac.uk) 
 * @since 27 Jun 2023
 */
public class LifeCycleDetailedTest extends AbstractTest {
    private ATest atest;
    private ATest2 atest2;
    private LifecycleTestModel model;
    private ATest3 atest3;

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
        final ReferredTo referredTo = new ReferredTo(3);
        List<Contained> contained = Arrays.asList(new Contained("firstcontained"),new Contained("secondContained"));
        List<ReferredLifeCycle> refcont = Arrays.asList(new ReferredLifeCycle("rc1"), new ReferredLifeCycle("rc2"));
        atest = ATest.createATest(a -> {
            a.ref1 = referredTo;
            a.contained = contained;
            a.refandcontained = refcont;
            
        });
        atest2 = new ATest2(atest, referredTo, refcont.get(0));
        atest3 = new ATest3(contained, refcont.get(0));//TODO this will create contradictions.... how best to test
        
        model = new LifecycleTestModel();
        model.addContent(atest);
        model.addContent(atest2);
    }

    /**
     * @throws java.lang.Exception
     */
    @AfterEach
    void tearDown() throws Exception {
        
        
    }

    @Test
    void MultiContainedJPATest() {
        jakarta.persistence.EntityManager em = setupH2Db(SampleModel.pu_name());//IMPL build means that everything is in one persistence unit.
        em.getTransaction().begin();
        atest2.persistRefs(em);
        atest.persistRefs(em);
        em.persist(atest2);
        em.persist(atest);
        em.persist(atest3);
        em.getTransaction().commit();
        Long id = atest2.getId();
        
         //flush any existing entities
        em.clear();
        em.getEntityManagerFactory().getCache().evictAll();

        // now read back
        em.getTransaction().begin();
        List<ATest2> ats = em.createNamedQuery("ATest2.findById", ATest2.class)
                .setParameter("id", id).getResultList();
         em.getTransaction().commit();
         dumpDbData(em, "lifecycle_dump.sql");
    }
    
    @Test
    void copyTest() {
        model.createContext();
        ATest atestprime = new ATest(atest);
        atest.ref1.test1 = 4;
        assertEquals(4, atestprime.ref1.test1); //the reference should have changed
        atest.contained.get(0).test2 = "changed";
        assertEquals("firstcontained",atestprime.contained.get(0).test2); // new objects created for the contained so changing original should not affect the prime
        
        
        
        
        
        ATest2 atest2prime = new ATest2(atest2);
        
        
        atest2.atest.refandcontained.get(0).test3 = "changed2";
        assertEquals("changed2", atest2.refcont.test3); // this is in atest3
        
        atest2prime.updateClonedReferences();
        assertEquals("rc1" ,atest2prime.atest.refandcontained.get(0).test3);// this is what we want the copied atest2 has its "own" contained references
        assertEquals("rc1", atest2prime.refcont.test3); // should be pointing to above
        
       // assertEquals("rc1" ,atest3.refBad.test3);//TODO not sure which way we want these to work.
        
         
    }
   

}


