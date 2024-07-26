package org.ivoa.vodml.jaxb;
/*
 * Created on 26/07/2024 by Paul Harrison (paul.harrison@manchester.ac.uk).
 */

import jakarta.xml.bind.annotation.adapters.XmlAdapter;

import java.time.LocalDateTime;
import java.time.LocalDateTime;

public class DateTimeConverter  extends XmlAdapter<String, LocalDateTime> {


   @Override
   public LocalDateTime unmarshal(String v) throws Exception {
      if (v == null) {
         return null;
      }
      return LocalDateTime.parse(v);
   }

   @Override
   public String marshal(LocalDateTime v) throws Exception {
      if (v == null) {
         return null;
      }
      return v.toString();
   }
}
