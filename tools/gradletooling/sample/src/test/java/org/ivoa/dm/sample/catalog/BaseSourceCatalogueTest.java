/*
 * Created on 10 Nov 2022 
 * Copyright 2022 Paul Harrison (paul.harrison@manchester.ac.uk)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License in file LICENSE
 */ 

package org.ivoa.dm.sample.catalog;

import static org.ivoa.dm.filter.PhotometryFilter.createPhotometryFilter;
import static org.ivoa.dm.sample.catalog.LuminosityMeasurement.createLuminosityMeasurement;
import static org.ivoa.dm.sample.catalog.SDSSSource.createSDSSSource;
import static org.ivoa.dm.sample.catalog.SkyCoordinate.createSkyCoordinate;
import static org.ivoa.dm.sample.catalog.inner.SourceCatalogue.createSourceCatalogue;
import static org.junit.jupiter.api.Assertions.*;

import java.util.Arrays;
import java.util.Date;
import java.util.List;

import org.ivoa.dm.filter.PhotometricSystem;
import org.ivoa.dm.filter.PhotometryFilter;
import org.ivoa.dm.ivoa.RealQuantity;
import org.ivoa.dm.sample.catalog.inner.SourceCatalogue;
import org.ivoa.vodml.stdtypes.Unit;
import org.ivoa.vodml.testing.AbstractTest;

/**
 *  .
 * @author Paul Harrison (paul.harrison@manchester.ac.uk) 
 * @since 10 Nov 2022
 */
public abstract class BaseSourceCatalogueTest extends AbstractTest {

    protected SourceCatalogue sc;
    protected PhotometricSystem ps;

    @org.junit.jupiter.api.BeforeEach
    void setUp() {
                   final Unit jansky = new Unit("Jy");
            final Unit degree = new Unit("degree");
            final Unit GHz= new Unit("GHz");
            final SkyCoordinateFrame frame = new SkyCoordinateFrame().withName("J2000").withEquinox("J2000.0").withDocumentURI("http://coord.net");
    
            final AlignedEllipse ellipseError = new AlignedEllipse(.2, .1);
            SDSSSource sdss = new SDSSSource().withPositionError(ellipseError);// UNUSED, but just checking position error subsetting.
            sdss.setPositionError(ellipseError);
            AlignedEllipse theError = sdss.getPositionError();
            
            final List<PhotometryFilter> filters = List.of(
                    createPhotometryFilter(fl -> {
                                    fl.bandName ="C-Band";
                                    fl.spectralLocation = new RealQuantity(5.0,GHz);
                                    fl.dataValidityFrom = new Date();
                                    fl.dataValidityTo = new Date();
                                    fl.description = "radio band";
                                    fl.name = fl.bandName;
                                }),
                    createPhotometryFilter(fl -> {
                                    fl.bandName ="L-Band";
                                    fl.spectralLocation = new RealQuantity(1.5,GHz);
                                    fl.dataValidityFrom = new Date();
                                    fl.dataValidityTo = new Date();
                                    fl.description = "radio band";
                                    fl.name = fl.bandName;
                                })
                    );
                    
    
            ps = new PhotometricSystem("test photometric system", 1, filters);
            sc = createSourceCatalogue(c -> {
                c.name = "testCat";
                c.entry = Arrays.asList(createSDSSSource(s -> {
                    s.name = "testSource";
                    s.classification = SourceClassification.AGN;
                    s.position = createSkyCoordinate(co -> {
                        co.frame = frame;
                        co.latitude = new RealQuantity(52.5, degree );
                        co.longitude = new RealQuantity(2.5, degree );
                    });
                    s.positionError = ellipseError;//note subsetting forces compile need AlignedEllipse
    
                    s.luminosity = Arrays.asList(
                            createLuminosityMeasurement(l ->{
                                l.description = "lummeas";
                                l.type = LuminosityType.FLUX;                         
                                l.value = new RealQuantity(2.5, jansky );
                                l.error = new RealQuantity(.25, jansky );
                                l.filter = filters.get(0);
                                
                            })
                            ,createLuminosityMeasurement(l ->{
                                l.description = "lummeas2";
                                l.filter = filters.get(1);
                                l.type = LuminosityType.FLUX;
                                l.value = new RealQuantity(3.5, jansky );
                                l.error = new RealQuantity(.25, jansky );//TODO should be allowed to be null
    
       })
    
                            );
                }));
            }
                    );
    
    
        }

    protected void checkModel(List<SourceCatalogue> lin) {
        assertEquals(1, lin.size());
        SourceCatalogue scin = lin.get(0);
        System.out.println(lin.get(0).getName());
        SDSSSource src = (SDSSSource) scin.getEntry().get(0);
        AlignedEllipse perr = src.getPositionError();
        assertEquals(0.2, perr.longError);
        assertTrue(!src.getLuminosity().get(0).getFilter().getBandName().equals(
        src.getLuminosity().get(1).getFilter().getBandName()),"failure to distinguish references");
        SkyCoordinateFrame fr = src.getPosition().getFrame();
        assertNotNull(fr);
        assertEquals("J2000", fr.getName());
    }

}


