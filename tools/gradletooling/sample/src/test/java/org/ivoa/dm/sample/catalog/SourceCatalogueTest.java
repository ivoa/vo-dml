package org.ivoa.dm.sample.catalog;

import org.ivoa.dm.ivoa.RealQuantity;
import org.ivoa.dm.ivoa.Unit;
import org.javastro.ivoa.entities.jaxb.DescriptionValidator;
import org.javastro.ivoa.entities.jaxb.JaxbAnnotationMeta;
import org.w3c.dom.Document;

import javax.xml.bind.JAXBContext;
import javax.xml.bind.JAXBElement;
import javax.xml.bind.JAXBException;
import javax.xml.bind.Marshaller;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;

import static org.junit.jupiter.api.Assertions.*;

/*
 * Created on 20/08/2021 by Paul Harrison (paul.harrison@manchester.ac.uk).
 */

class SourceCatalogueTest {

   @org.junit.jupiter.api.BeforeEach
   void setUp() {
   }

   @org.junit.jupiter.api.Test
   void sourceCatJaxBTest() throws JAXBException, ParserConfigurationException {
      SourceCatalogue sc = new SourceCatalogue();
      sc.setName("testCat");
      SDSSSource cat1 = new SDSSSource();
      LuminosityMeasurement lum = new LuminosityMeasurement();
      lum.setDescription("lummeas");
      lum.setType(LuminosityType.FLUX);
      RealQuantity pValue = new RealQuantity();
      pValue.setValue(2.5);
      Unit unit = new Unit("blah");
      pValue.setUnit(unit);
      lum.setValue(pValue);
      cat1.addLuminosity(lum);
      sc.addEntry(cat1);

      JAXBContext jc = JAXBContext.newInstance("org.ivoa.dm.sample.catalog");
      JaxbAnnotationMeta<SourceCatalogue> meta = JaxbAnnotationMeta.of(SourceCatalogue.class);
      DescriptionValidator<SourceCatalogue> validator = new DescriptionValidator<>(jc, meta);
      DescriptionValidator.Validation validation = validator.validate(sc);
      DocumentBuilderFactory dbf = DocumentBuilderFactory
            .newInstance();
      dbf.setNamespaceAware(true);
      Document doc = dbf.newDocumentBuilder().newDocument();
      Marshaller m = jc.createMarshaller();
      m.setProperty(Marshaller.JAXB_FORMATTED_OUTPUT, Boolean.TRUE);
      JAXBElement<SourceCatalogue> element = meta.element(sc);
      m.marshal(element, doc);
      fail("test not finished");
   }
}