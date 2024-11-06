/*
 * Created on 21 Oct 2022
 * Copyright 2022 Paul Harrison (paul.harrison@manchester.ac.uk)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License in file LICENSE
 */

package org.ivoa.dm.lifecycle;

import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.Arrays;
import java.util.List;
import org.ivoa.vodml.testing.AutoRoundTripTest;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.BeforeEach;

/**
 * Test for lifecycle proposal .
 *
 * JSON and Rdb serialization work with this model - however XML serialization does not - the ReferredLifeCycle("rc1") object gets represented twice.
 * The XML serialization appears to work properly, but the XML is not valid because there are two objects with the same id (they really are the same object of course).
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
  static void setUpBeforeClass() throws Exception {}

  /**
   * @throws java.lang.Exception
   */
  @BeforeEach
  void setUp() throws Exception {}

  /**
   * @throws java.lang.Exception
   */
  @AfterEach
  void tearDown() throws Exception {}

  /**
   * {@inheritDoc}
   * overrides @see org.ivoa.vodml.validation.AutoRoundTripTest#createModel()
   */
  @Override
  public LifecycleTestModel createModel() {
    final ReferredTo referredTo = new ReferredTo(3);
     List<ReferredLifeCycle> refcont =
        Arrays.asList(new ReferredLifeCycle("rc1"), new ReferredLifeCycle("rc2"));
    List<Contained> contained =
        Arrays.asList(new Contained("firstcontained", refcont.get(0)), new Contained("secondContained", refcont.get(1)));
   
    atest =
        ATest.createATest(
            a -> {
              a.ref1 = referredTo;
              a.contained = contained;
              a.refandcontained = refcont;
            });
    atest2 = new ATest2( Arrays.asList(referredTo), atest, refcont.get(0));

    LifecycleTestModel model = new LifecycleTestModel();
   // model.addContent(atest);
    model.addContent(atest2);
    model.processReferences();
    assertTrue(atest.refandcontained.get(1).getId() != 0, "id setting did not work");
    return model;
  }

  /**
   * {@inheritDoc}
   * overrides @see org.ivoa.vodml.validation.AutoRoundTripTest#testModel(org.ivoa.vodml.VodmlModel)
   */
  @Override
  public void testModel(LifecycleTestModel m) {

//    List<ATest> ratest = m.getContent(ATest.class);
//    ratest.get(0).getRefandcontained().get(0).setTest3("changed");
    List<ATest2> ratest2 = m.getContent(ATest2.class);
    ratest2.get(0).atest.getRefandcontained().get(0).setTest3("changed");
    m.processReferences();
    System.out.println("ref and contained val =" + ratest2.get(0).getRefcont().getTest3());
  }
}
