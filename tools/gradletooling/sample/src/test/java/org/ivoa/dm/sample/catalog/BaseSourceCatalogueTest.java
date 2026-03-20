/*
 * Created on 10 Nov 2022
 * Copyright 2022 Paul Harrison (paul.harrison@manchester.ac.uk)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License in file LICENSE
 */

package org.ivoa.dm.sample.catalog;

import org.ivoa.dm.filter.PhotometricSystem;
import org.ivoa.dm.sample.SampleModel;
import org.ivoa.dm.sample.catalog.inner.SourceCatalogue;

/**
 * Base catalo  .
 * @author Paul Harrison (paul.harrison@manchester.ac.uk)
 * @since 10 Nov 2022
 */
public  class BaseSourceCatalogueTest extends org.ivoa.vodml.testing.AutoRoundTripTest<SampleModel> {

   private static CatalogExample example;

   @Override
   protected String setSerializationDumpPrefix() {
     return "interoperability/java/sample";
   }

  protected static SourceCatalogue sc;
  protected static PhotometricSystem ps;

  @org.junit.jupiter.api.BeforeAll
  static void setUp() {
      example = new CatalogExample();
      sc = example.sc;
      ps = example.ps;
  }

   @Override
   public SampleModel createModel() {
      return example.createModel();
   }

   @Override
   public void testModel(SampleModel sampleModel) {
        example.checkModel(sampleModel.getContent(SourceCatalogue.class));
   }


}
