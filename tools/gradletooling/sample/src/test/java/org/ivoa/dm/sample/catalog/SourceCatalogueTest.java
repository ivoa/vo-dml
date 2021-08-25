package org.ivoa.dm.sample.catalog;

import org.ivoa.dm.ivoa.RealQuantity;
import org.ivoa.dm.ivoa.Unit;
import org.ivoa.dm.sample.catalog.inner.SourceCatalogue;
import org.javastro.ivoa.entities.jaxb.DescriptionValidator;
import org.javastro.ivoa.entities.jaxb.JaxbAnnotationMeta;
import org.w3c.dom.Document;

import javax.xml.bind.JAXBContext;
import javax.xml.bind.JAXBElement;
import javax.xml.bind.JAXBException;
import javax.xml.bind.Marshaller;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.transform.OutputKeys;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;

import static org.junit.jupiter.api.Assertions.*;

import java.io.OutputStream;
import java.io.PrintWriter;
import java.io.StringWriter;
import java.util.Arrays;

/*
 * Created on 20/08/2021 by Paul Harrison (paul.harrison@manchester.ac.uk).
 */

class SourceCatalogueTest {

   @org.junit.jupiter.api.BeforeEach
   void setUp() {
   }

   @org.junit.jupiter.api.Test
   void sourceCatJaxBTest() throws JAXBException, ParserConfigurationException, TransformerException {
       
      final Unit jansky = new Unit("Jy");
      SourceCatalogue sc = SourceCatalogue.builder(c -> {
          c.name = "testCat";
          c.entry = Arrays.asList(SDSSSource.builder(s -> {
              s.name = "testSource";
              s.luminosity = Arrays.asList(
                        LuminosityMeasurement.builder(l ->{
                          l.description = "lummeas";
                          l.type = LuminosityType.FLUX;                         
                          l.value = new RealQuantity(2.5, jansky );
                      })
                        ,LuminosityMeasurement.builder(l ->{
                          l.description = "lummeas2";
                          l.type = LuminosityType.FLUX;
                          l.value = new RealQuantity(3.5, jansky );
                      })
                        
                      );
          }));
      }
      );
              

      JAXBContext jc = JAXBContext.newInstance("org.ivoa.dm.sample.catalog.inner");
      JaxbAnnotationMeta<SourceCatalogue> meta = JaxbAnnotationMeta.of(SourceCatalogue.class);
      DescriptionValidator<SourceCatalogue> validator = new DescriptionValidator<>(jc, meta);
      DescriptionValidator.Validation validation = validator.validate(sc);
      assertTrue(validation.valid);
      DocumentBuilderFactory dbf = DocumentBuilderFactory
            .newInstance();
      dbf.setNamespaceAware(true);
      Document doc = dbf.newDocumentBuilder().newDocument();
      Marshaller m = jc.createMarshaller();
      m.setProperty(Marshaller.JAXB_FORMATTED_OUTPUT, Boolean.TRUE);
      JAXBElement<SourceCatalogue> element = meta.element(sc);
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

   
      fail("no proper test yet");
   }
}