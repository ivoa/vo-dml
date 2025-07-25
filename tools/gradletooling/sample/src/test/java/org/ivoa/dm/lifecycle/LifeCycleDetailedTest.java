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

import java.util.Arrays;
import java.util.List;
import org.ivoa.dm.sample.SampleModel;
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
  static void setUpBeforeClass() throws Exception {}

  /**
   * @throws java.lang.Exception
   */
  @BeforeEach
  void setUp() throws Exception {
    final ReferredTo referredTo = new ReferredTo(3);

    List<ReferredLifeCycle> refcont =
        Arrays.asList(new ReferredLifeCycle("rc1"), new ReferredLifeCycle("rc2"));
    List<Contained> contained =
        Arrays.asList(new Contained("firstcontained"), new Contained("secondContained"));
    List<Contained> contained2 =
        Arrays.asList(new Contained("firstcontained-2"), new Contained("secondContained-2"));
    
    atest =
        ATest.createATest(
            a -> {
              a.ref1 = referredTo;
              a.contained = contained;
              a.refandcontained = refcont;
            });
    atest2 = new ATest2(Arrays.asList(referredTo), atest, refcont.get(0));
    atest3 =
        new ATest3(
            contained2, refcont.get(0)); // TODO this will create contradictions.... how best to test

    model = new LifecycleTestModel();
//    model.addContent(atest);
    model.addContent(atest2);
    model.addContent(atest3);
   
  }

  /**
   * @throws java.lang.Exception
   */
  @AfterEach
  void tearDown() throws Exception {}

  @Test
  void MultiContainedJPATest() {
    jakarta.persistence.EntityManager em =
        setupH2Db(LifecycleTestModel.pu_name(), LifecycleTestModel.modelDescription.allClassNames()); // IMPL build means that everything is in one
    // persistence unit.
    em.getTransaction().begin();
    model.management().persistRefs(em);
    em.persist(atest);
    em.persist(atest2);
    em.persist(atest3);
    em.getTransaction().commit();
    Long id = atest2.getId();

    // flush any existing entities
    em.clear();
    em.getEntityManagerFactory().getCache().evictAll();

    // now read back
    em.getTransaction().begin();
    List<ATest2> ats =
        em.createNamedQuery("ATest2.findById", ATest2.class).setParameter("id", id).getResultList();
    em.getTransaction().commit();
    dumpDbData(em, "lifecycle_dump.sql");
  }

  @Test
  void copyTest() {
   
    model.createContext();
    ATest atestprime = new ATest(atest);
    atest.ref1.test1 = 4; //change the original
    assertEquals(4, atestprime.ref1.test1); // the reference should have changed
    
    //now just change one of the contained
    atest.contained.get(0).test2 = "changed";
    assertEquals(
        "firstcontained",
        atestprime.contained.get(0)
            .test2); // new objects created for the contained so changing original should not affect the prime

    //now clone something with "contained" references
    ATest2 atest2prime = new ATest2(atest2);

    atest2.atest.refandcontained.get(0).test3 = "changed2";
    assertEquals("changed2", atest2.refcont.test3); // this is in atest3
    
    //TODO this API feels unnatural...
    atest2prime.updateClonedReferences();
    assertEquals(
        "rc1",
        atest2prime.atest.refandcontained.get(0)
            .test3); // this is what we want the copied atest2 has its "own" contained
    // references
    assertEquals("rc1", atest2prime.refcont.test3); // should be pointing to above

   //  assertEquals("rc1" ,atest3.refBad.test3);//TODO not sure which way we want these to work - it is actually a failure of design

  }
  
  @Test
  void deleteTest() {
       jakarta.persistence.EntityManager em =
        setupH2Db(LifecycleTestModel.pu_name(),LifecycleTestModel.modelDescription.allClassNames()); // IMPL build means that everything is in one
    // persistence unit.
    em.getTransaction().begin();
    model.management().persistRefs(em);
    em.persist(atest2);
    em.getTransaction().commit();
    Long id = atest2.getId();

    // flush any existing entities
    em.clear();
    em.getEntityManagerFactory().getCache().evictAll();
    ATest2 atest2in = em.createNamedQuery("ATest2.findById", ATest2.class).setParameter("id", id).getSingleResult();
    assertNotNull(atest2in);
    em.getTransaction().begin();
    atest2in.delete(em); //IMPL
    em.getTransaction().commit();
    
  }
}
