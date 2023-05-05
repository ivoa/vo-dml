/*
 * Created on 5 Nov 2021 
 * Copyright 2021 Paul Harrison (paul.harrison@manchester.ac.uk)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License in file LICENSE
 */ 

package org.ivoa.dm.notstccoords;

import org.ivoa.dm.ivoa.RealQuantity;
import org.ivoa.dm.ivoa.Unit;
import org.ivoa.vodml.testing.AutoRoundTripWithValidationTest;

/**
 * An example test for the "not coords" model.
 * note that this test runs JSON and XML serialisation test as well as validating the model instance.
 * @author Paul Harrison (paul.harrison@manchester.ac.uk) 
 * @since 5 Nov 2021
 */
class CoordsModelTest extends AutoRoundTripWithValidationTest<CoordsModel> {

    /** logger for this class */
    private static final org.slf4j.Logger logger = org.slf4j.LoggerFactory
            .getLogger(CoordsModelTest.class);

   @Override
   public CoordsModel createModel() {
      //see https://github.com/mcdittmar/ivoa-dm-examples/blob/master/assets/examples/coords/current/instances/astrocoordsys.jovial for jovial version of this test.
      Unit deg = new Unit("deg");
      SpaceSys ICRS_SYS = new SpaceSys().withFrame(
            SpaceFrame.createSpaceFrame( f-> {
                     f.refPosition = new StdRefLocation("TOPOCENTRE");
                     f.spaceRefFrame="ICRS";
                     f.planetaryEphem="DE432";
                  }
            ));

      TimeSys TIMESYS_TT = new TimeSys().withFrame(
            TimeFrame.createTimeFrame( f -> {
               f.refPosition = new StdRefLocation("TOPOCENTRE");
               f.timescale = "TT";
               f.refDirection = new CustomRefLocation()
                     .withEpoch("J2014.25")
                     .withPosition(
                           LonLatPoint.createLonLatPoint(p-> {
                                    p.lon = new RealQuantity(6.752477,deg);
                                    p.lat = new RealQuantity(-16.716116,deg);
                                    p.dist = new RealQuantity(8.6, new Unit("ly"));
                                    p.coordSys = ICRS_SYS;
                                 }
                           )
                     );
            })
      );
      GenericSys SPECSYS = new GenericSys().withFrame(
            GenericFrame.createGenericFrame(f -> {
                     f.refPosition = new StdRefLocation("TOPOCENTRE");
                     f.planetaryEphem = "DE432";
                  }
            )
      );


      CoordsModel modelInstance = new CoordsModel();

      modelInstance.addReference(TIMESYS_TT);
      modelInstance.addReference(SPECSYS);
      modelInstance.addReference(ICRS_SYS);
      modelInstance.processReferences();
      return modelInstance;
   }

   @Override
   public void testModel(CoordsModel coordsModel) {
      //TODO actually make some specialist tests on returned model instance.
   }
}


