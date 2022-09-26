
/*
 * Created on 26/09/2022 by Paul Harrison (paul.harrison@manchester.ac.uk).
 */

import org.ivoa.dm.sample.SampleModel;

import javax.xml.bind.JAXBException;
import java.io.IOException;

public class WriteSampleSchema {
   public static void main(String[] args) {
      try {
         SampleModel.writeXMLSchema();
      } catch (JAXBException|IOException e) {
         throw new RuntimeException(e);
      }
   }
}
