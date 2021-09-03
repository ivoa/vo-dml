package org.ivoa.dm.sample.catalog;

import static org.junit.jupiter.api.Assertions.*;

import java.io.File;
import java.io.IOException;
import java.io.StringReader;
import java.io.StringWriter;
import java.util.Arrays;
import java.util.List;

import javax.xml.bind.JAXBContext;
import javax.xml.bind.JAXBElement;
import javax.xml.bind.JAXBException;
import javax.xml.bind.Marshaller;
import javax.xml.bind.SchemaOutputResolver;
import javax.xml.bind.Unmarshaller;
import javax.xml.bind.ValidationEvent;
import javax.xml.bind.util.ValidationEventCollector;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.transform.OutputKeys;
import javax.xml.transform.Result;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;
import javax.xml.transform.stream.StreamSource;

import org.ivoa.dm.filter.PhotometryFilter;
import org.ivoa.dm.ivoa.RealQuantity;
import org.ivoa.dm.ivoa.Unit;
import org.ivoa.dm.sample.SampleModel;
import org.ivoa.dm.sample.catalog.inner.SourceCatalogue;
import org.javastro.ivoa.entities.jaxb.DescriptionValidator;
import org.javastro.ivoa.entities.jaxb.JaxbAnnotationMeta;
import org.w3c.dom.Document;

/*
 * Created on 20/08/2021 by Paul Harrison (paul.harrison@manchester.ac.uk).
 */
class SourceCatalogueTest {

    /** logger for this class */
    private static final org.slf4j.Logger logger = org.slf4j.LoggerFactory
            .getLogger(SourceCatalogueTest.class);


    @org.junit.jupiter.api.BeforeEach
    void setUp() {
    }

    private static class MySchemaOutputResolver extends SchemaOutputResolver {
        public Result createOutput(String uri, String suggestedFileName)
                throws IOException {
            String[] parts = uri.split("/");


            File file = new File(suggestedFileName);//new File(parts[parts.length -2]+".xsd");
            StreamResult result = new StreamResult(file);
            System.out.println("uri=" + uri + " " + file.getName());
            result.setSystemId(file.toURI().toURL().toString());
            return result;
        }
    };


    @org.junit.jupiter.api.Test
    void sourceCatJaxBTest() throws JAXBException, ParserConfigurationException, TransformerException, IOException {

        logger.debug("starting test");
        final Unit jansky = new Unit("Jy");
        final Unit degree = new Unit("degree");
        final Unit GHz= new Unit("GHz");
        final SkyCoordinateFrame frame = new SkyCoordinateFrame().withName("J2000").withEquinox("J2000.0");

        final AlignedEllipse ellipseError = new AlignedEllipse(.2, .1);
        SDSSSource sdss = new SDSSSource().withPositionError(ellipseError);// UNUSED, but just checking position error subsetting.
        sdss.setPositionError(ellipseError);
        AlignedEllipse theError = sdss.getPositionError();

        SourceCatalogue sc = SourceCatalogue.builder(c -> {
            c.name = "testCat";
            c.entry = Arrays.asList(SDSSSource.builder(s -> {
                s.name = "testSource";
                s.position = SkyCoordinate.builder(co -> {
                    co.frame = frame;
                    co.latitude = new RealQuantity(52.5, degree );
                    co.longitude = new RealQuantity(2.5, degree );
                });
                s.positionError = ellipseError;//note subsetting forces compile need AlignedEllipse

                s.luminosity = Arrays.asList(
                        LuminosityMeasurement.builder(l ->{
                            l.description = "lummeas";
                            l.type = LuminosityType.FLUX;                         
                            l.value = new RealQuantity(2.5, jansky );
                            l.filter = PhotometryFilter.builder(fl -> {
                                fl.bandName ="C-Band";
                                fl.spectralLocation = new RealQuantity(5.0,GHz);
                            });
                        })
                        ,LuminosityMeasurement.builder(l ->{
                            l.description = "lummeas2";
                            l.filter = PhotometryFilter.builder(fl -> {
                                fl.bandName ="L-Band";
                                fl.spectralLocation = new RealQuantity(1.5,GHz);
                            });
                            l.type = LuminosityType.FLUX;
                            l.value = new RealQuantity(3.5, jansky );
                        })

                        );
            }));
        }
                );


        JAXBContext jc = SampleModel.contextFactory();
        JaxbAnnotationMeta<SourceCatalogue> meta = JaxbAnnotationMeta.of(SourceCatalogue.class);
        DescriptionValidator<SourceCatalogue> validator = new DescriptionValidator<>(jc, meta);
        DescriptionValidator.Validation validation = validator.validate(sc);
        if(!validation.valid) {
            System.err.println(validation.message);
        }
        assertTrue(validation.valid);

        SampleModel model = new SampleModel();
        model.addContent(sc);
        model.makeRefIDsUnique();
        JaxbAnnotationMeta<SampleModel> mmeta = JaxbAnnotationMeta.of(SampleModel.class);
        DescriptionValidator<SampleModel> mvalidator = new DescriptionValidator<>(jc, mmeta);
        DescriptionValidator.Validation mvalidation = mvalidator.validate(model);
        assertTrue(mvalidation.valid, "errors on whole model");





        DocumentBuilderFactory dbf = DocumentBuilderFactory
                .newInstance();
        dbf.setNamespaceAware(true);
        Document doc = dbf.newDocumentBuilder().newDocument();
        Marshaller m = jc.createMarshaller();
        m.setProperty(Marshaller.JAXB_FORMATTED_OUTPUT, Boolean.TRUE);
        JAXBElement<SampleModel> element = mmeta.element(model);
        m.marshal(element, doc);
        // Set up the output transformer
        TransformerFactory transfac = TransformerFactory.newInstance();
        Transformer trans = transfac.newTransformer();
        trans.setOutputProperty(OutputKeys.OMIT_XML_DECLARATION, "no");
        trans.setOutputProperty(OutputKeys.INDENT, "yes");

        // Print the DOM node
        StringWriter sw = new StringWriter();
        StreamResult result = new StreamResult(sw);
        DOMSource source = new DOMSource(doc);
        trans.transform(source, result);
        System.out.println(sw.toString());

        //try to read in again
        Unmarshaller um = jc.createUnmarshaller();
        ValidationEventCollector vc = new javax.xml.bind.util.ValidationEventCollector();
        um.setEventHandler(vc);
        JAXBElement<SampleModel> el = um.unmarshal(new StreamSource(new StringReader(sw.toString())),SampleModel.class);
        if (vc.hasEvents()) {
            for (ValidationEvent err : vc.getEvents()) {
                System.err.println(err.getMessage());
            }
        }
        assertTrue(!vc.hasEvents(), "reading xml back had errors");
        SampleModel modelin = el.getValue();
        assertNotNull(modelin);
        List<SourceCatalogue> lin = modelin.getContent(SourceCatalogue.class);
        assertEquals(1, lin.size());
        SourceCatalogue scin = lin.get(0);
        System.out.println(lin.get(0).getName());
        SDSSSource src = (SDSSSource) scin.getEntry().get(0);
        AlignedEllipse perr = src.getPositionError();
        assertEquals(0.2, perr.longError);
        assertTrue(!src.getLuminosity().get(0).getFilter().getBandName().equals(
       src.getLuminosity().get(1).getFilter().getBandName()),"failure to distiguish references");
        

        SchemaOutputResolver sor = new MySchemaOutputResolver();
        System.out.println("generating schema");
        jc.generateSchema(sor);
    }
}
