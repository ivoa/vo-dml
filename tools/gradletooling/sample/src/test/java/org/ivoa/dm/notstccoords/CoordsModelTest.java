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

import javax.xml.bind.JAXBContext;
import javax.xml.bind.JAXBException;

import org.ivoa.dm.AbstractTest;
import org.ivoa.dm.ivoa.RealQuantity;
import org.ivoa.dm.ivoa.Unit;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

/**
 *  .
 * @author Paul Harrison (paul.harrison@manchester.ac.uk) 
 * @since 5 Nov 2021
 */
class CoordsModelTest extends AbstractTest {

    /** logger for this class */
    private static final org.slf4j.Logger logger = org.slf4j.LoggerFactory
            .getLogger(CoordsModelTest.class);
    private CelestialPoint pos1;
    private CoordSys spacesys;
    private SpaceFrame icrs;
    
    /**
     * @throws java.lang.Exception
     */
    @BeforeAll
    static void setUpBeforeClass() throws Exception {
    }

    
    @org.junit.jupiter.api.BeforeEach
    void setUp() {
        
        
        RefLocation ssbc = new StdRefLocation("BARYCENTRE");
        icrs = new SpaceFrame().withEquinox("J2000").withRefPosition(ssbc).withSpaceRefFrame("ICRS");
        
        
        RefLocation geocentric = new StdRefLocation("GEOCENTRIC");
        SpaceFrame fk4 = new SpaceFrame().withEquinox("B1950").withRefPosition(geocentric).withSpaceRefFrame("FK4");
        
        Unit degree = new Unit("degree");
        PhysicalCoordSpace coordspace = new SphericalCoordSpace();
        spacesys = new SpaceSys(coordspace, icrs);
        pos1 = new CelestialPoint(new RealQuantity(45.0, degree), new RealQuantity(22.0, degree), spacesys );
        
        
        
    }
    @Test
    void TestCoordsXML() throws JAXBException {
        logger.debug("Starting XML test");
        JAXBContext jc = CoordsModel.contextFactory();
        CoordsModel model = new CoordsModel();
        model.addContent(icrs);
       // model.addContent(pos1); FIXME - need to think about the dtypes should be added to the top level  model object.
        //TODO actually test
        
    }

}


