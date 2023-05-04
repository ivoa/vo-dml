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
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.transform.TransformerConfigurationException;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactoryConfigurationError;

import com.fasterxml.jackson.core.JsonProcessingException;

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
    private LonLatPoint pos1;
    private SpaceSys spacesys;
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
        Unit metre = new Unit("metre");
        PhysicalCoordSpace coordspace = new SphericalCoordSpace();
        spacesys = new SpaceSys(coordspace, icrs);
        
        pos1 = new LonLatPoint(new RealQuantity(45.0, degree), new RealQuantity(22.0, degree),new RealQuantity(22.0, metre), spacesys );
        
        
        
    }
    @Test
    void TestCoordsXML() throws JAXBException, TransformerConfigurationException, ParserConfigurationException, TransformerFactoryConfigurationError, TransformerException {
        logger.debug("Starting XML test");
        JAXBContext jc = CoordsModel.contextFactory();
        CoordsModel model = new CoordsModel();
        model.addContent(icrs);
       // model.addContent(pos1); FIXME - need to think about the dtypes should be added to the top level  model object.
        CoordsModel modelin = modelRoundTripXMLwithTest(model);
        
    }
    
    @Test
    void testJSON() throws JsonProcessingException {
      
       CoordsModel model = new CoordsModel();
       model.addContent(icrs);
       CoordsModel modelin = modelRoundTripJSONwithTest(model);
       
 
    }
    
    
   @org.junit.jupiter.api.Test
     void testAstroCoordSys() throws JAXBException, ParserConfigurationException, TransformerException, JsonProcessingException {
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


         CoordsModel model = new CoordsModel();
         
         model.addReference(TIMESYS_TT);
         model.addReference(SPECSYS);
         model.addReference(ICRS_SYS);
         model.processReferences();
         CoordsModel modelin = modelRoundTripJSONwithTest(model);
         CoordsModel modelin2 = modelRoundTripJSONwithTest(model);
    }
    

}


