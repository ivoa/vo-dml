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

import com.fasterxml.jackson.core.JsonProcessingException;
import jakarta.xml.bind.JAXBContext;
import jakarta.xml.bind.JAXBException;

import java.util.ArrayList;
import java.util.List;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactoryConfigurationError;
import org.ivoa.vodml.testing.AbstractTest;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 *  .
 * @author Paul Harrison (paul.harrison@manchester.ac.uk)
 * @since 21 Oct 2022
 */
class JpatestModelTest extends AbstractTest {

  private Parent atest;

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
    final ReferredTo1 referredTo = new ReferredTo1("top level ref");
    final ReferredTo2 referredToin = new ReferredTo2("lower ref");
    Child refcont = new Child(referredToin);
    List<LChild> ll = new ArrayList<LChild>(//IMPL make mutable
        List.of(new LChild("First", 1), new LChild("Second", 2), new LChild("Third", 3)));

    atest =
            Parent.createParent(
                    a -> {
                        ReferredTo3 ref3 = new ReferredTo3(3,"ref in dtype");
                        a.dval = new ADtype(1.1, "astring","intatt", "base", ref3);
                        a.eval = new AEtype(1.2, "evals", "intatt_e", "basestre_e", ref3);

                        a.rval = referredTo;
                        a.cval = refcont;
                        a.lval = ll;
                        a.tval = new DThing(new Point(1.5,3.0), "thing");
                    });
  }

  /**
   * @throws java.lang.Exception
   */
  @AfterEach
  void tearDown() throws Exception {}

  @Test
  void jaxbtest()
      throws JAXBException,
          ParserConfigurationException,
          TransformerFactoryConfigurationError,
          TransformerException {

    JAXBContext jc = JpatestModel.contextFactory();
    JpatestModel model = new JpatestModel();
    model.addContent(atest);
    model.processReferences();
    assertTrue(atest.cval.rval._id != 0, "id setting did not work");
    JpatestModel modelin = modelRoundTripXMLwithTest(model);
  }

  @Test
  void jpaInitialCreateTest() {
    jakarta.persistence.EntityManager em =
        setupH2Db(JpatestModel.pu_name(),JpatestModel.modelDescription.allClassNames()); // the persistence unit is all under the one file....
    em.getTransaction().begin();
    JpatestModel model = new JpatestModel();
    model.addContent(atest);
    model.management().persistRefs(em); // IMPL need to save references explicitly as they are new.
    em.persist(atest);
    em.getTransaction().commit();
    Long id = atest.getId();

    // flush any existing entities
    em.clear();
    em.getEntityManagerFactory().getCache().evictAll();
    // now read back
    em.getTransaction().begin();
    List<Parent> par =
        em.createNamedQuery("Parent.findById", Parent.class).setParameter("id", id).getResultList();
    em.getTransaction().commit();
    assertEquals(1, par.size());
    assertEquals("top level ref", par.get(0).rval.sval);
    assertEquals("lower ref", par.get(0).cval.rval.sval);
    assertEquals("ref in dtype", par.get(0).dval.dref.sval);
    assertNotNull(par.get(0).dval.basestr); 
  }

  @Test
  void jpaUpdateOrderedTest() throws JsonProcessingException {
    jakarta.persistence.EntityManager em =
        setupH2Db(JpatestModel.pu_name(),JpatestModel.modelDescription.allClassNames()); // the persistence unit is all under the one file....
    em.getTransaction().begin();
    JpatestModel model = new JpatestModel();
    model.addContent(atest);
    model.management().persistRefs(em); // IMPL need to save references explicitly as they are new.
    em.persist(atest);
    em.getTransaction().commit();
    Long id = atest.getId();

    // flush any existing entities
    em.clear();
    em.getEntityManagerFactory().getCache().evictAll();

    // now read back
    Parent par =
        em.createNamedQuery("Parent.findById", Parent.class)
            .setParameter("id", id)
            .getResultList()
            .get(0);
    List<LChild> ll = par.getLval();
    assertEquals(3, ll.size());
    LChild a = ll.get(1);
    assertEquals(2, a.getIval());

    // create an update object
    String injson = "{\"sval\":\"Seconded\",\"ival\":2000,\"_id\":2}"; // assumes the id is 2
    LChild arepl = JpatestModel.jsonMapper().readValue(injson, LChild.class);

    em.getTransaction().begin();

    par.replaceInLval(arepl);
    em.merge(par);
    em.getTransaction().commit();
    // flush any existing entities
    em.clear();
    em.getEntityManagerFactory().getCache().evictAll();

    Parent par2 =
        em.createNamedQuery("Parent.findById", Parent.class)
            .setParameter("id", id)
            .getResultList()
            .get(0);
    List<LChild> ll2 = par2.getLval();
    assertEquals(3, ll2.size());
    LChild ain = ll2.get(1);
    assertEquals(2000, a.getIval());
  }
  
  @Test
  void jpaAddToListTest() {
       jakarta.persistence.EntityManager em =
        setupH2Db(JpatestModel.pu_name(),JpatestModel.modelDescription.allClassNames()); // the persistence unit is all under the one file....
    em.getTransaction().begin();
    JpatestModel model = new JpatestModel();
    model.addContent(atest);
    model.management().persistRefs(em); // IMPL need to save references explicitly as they are new.
    em.persist(atest);
    em.getTransaction().commit();
    em.getTransaction().begin();
    LChild l = atest.lval.get(0);
    LChild l2 = new LChild(l);
    atest.addToLval(l2);
    em.getTransaction().commit();
  }
}
