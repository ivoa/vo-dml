/*
 * Created on 5 Nov 2021
 * Copyright 2021 Paul Harrison (paul.harrison@manchester.ac.uk)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License in file LICENSE
 */

package org.ivoa.dm.notstccoords;

import static org.junit.jupiter.api.Assertions.*;

import java.util.List;

import org.ivoa.dm.ivoa.RealQuantity;
import org.ivoa.dm.ivoa.Unit;
import org.ivoa.vodml.testing.AutoDBRoundTripTest;

/**
 * An example test for the "not coords" model.
 * note that this test runs JSON and XML serialisation test as well as validating the model instance.
 * @author Paul Harrison (paul.harrison@manchester.ac.uk)
 * @since 5 Nov 2021
 */
class CoordsModelDbTest extends AutoDBRoundTripTest<CoordsModel,Long,AnObject> {

  /** logger for this class */
  private static final org.slf4j.Logger logger =
      org.slf4j.LoggerFactory.getLogger(CoordsModelDbTest.class);
private AnObject a;

  @Override
  public CoordsModel createModel() {
    // see
    // https://github.com/mcdittmar/ivoa-dm-examples/blob/master/assets/examples/coords/current/instances/astrocoordsys.jovial for jovial version of this test.
    Unit deg = new Unit("deg");
    SpaceSys ICRS_SYS =
        new SpaceSys()
            .withFrame(
                SpaceFrame.createSpaceFrame(
                    f -> {
                      f.refPosition = new StdRefLocation("TOPOCENTER");
                      f.spaceRefFrame = "ICRS";
                      f.planetaryEphem = "DE432";
                    }));

    TimeSys TIMESYS_TT =
        new TimeSys()
            .withFrame(
                TimeFrame.createTimeFrame(
                    f -> {
                      f.refPosition = new StdRefLocation("TOPOCENTER");
                      f.timescale = "TT";
                      f.refDirection =
                          new CustomRefLocation()
                              .withEpoch("J2014.25")
                              .withPosition(
                                  LonLatPoint.createLonLatPoint(
                                      p -> {
                                        p.lon = new RealQuantity(6.752477, deg);
                                        p.lat = new RealQuantity(-16.716116, deg);
                                        p.dist = new RealQuantity(8.6, new Unit("ly"));
                                        p.coordSys = ICRS_SYS;
                                      }));
                    }));
    GenericSys SPECSYS =
        new GenericSys()
            .withFrame(
                GenericFrame.createGenericFrame(
                    f -> {
                      f.refPosition = new StdRefLocation("TOPOCENTER");
                      f.planetaryEphem = "DE432";
                    }));



    // note that this cannot be added directly as it is a dtype...
    LonLatPoint llp = new LonLatPoint(new RealQuantity(45.0, deg), new RealQuantity(15.0, deg), new RealQuantity(1.5, new Unit("Mpc")), ICRS_SYS);
    a = new AnObject(llp);
    CoordsModel modelInstance = new CoordsModel();

    modelInstance.addReference(TIMESYS_TT);
    modelInstance.addReference(SPECSYS);
    modelInstance.addReference(ICRS_SYS);
    modelInstance.addContent(a);
    
    
   

    return modelInstance;
  }

  @Override
  public void testModel(CoordsModel coordsModel) {
     List<AnObject> ts = coordsModel.getContent(AnObject.class);
     assertNotNull(ts);
     assertEquals(1, ts.size());
     AnObject ts1 = ts.get(0);
     SpaceSys ss = ts1.getPosition().getCoordSys();
     assertNotNull(ss);
    
  }

/**
 * {@inheritDoc}
 * overrides @see org.ivoa.vodml.testing.AutoDBRoundTripTest#entityForDb()
 */
@Override
public AnObject entityForDb() {
    return a;
    
}

/**
 * {@inheritDoc}
 * overrides @see org.ivoa.vodml.testing.AutoDBRoundTripTest#testEntity(org.ivoa.vodml.jpa.JPAManipulationsForObjectType)
 */
@Override
public void testEntity(AnObject e) {
    SpaceSys ss = e.getPosition().getCoordSys();
    assertNotNull(ss);
    
}
}
