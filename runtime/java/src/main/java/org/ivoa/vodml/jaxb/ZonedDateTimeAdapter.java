/*
 * Copyright (c) 2026. Paul Harrison, University of Manchester
 */

package org.ivoa.vodml.jaxb;


import jakarta.xml.bind.annotation.adapters.XmlAdapter;

import java.time.ZoneOffset;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;

/**
 * Adapter for converting between ZonedDateTime and String in XML.
 */
public class ZonedDateTimeAdapter extends XmlAdapter<String, java.time.ZonedDateTime> {

    /**
     * Unmarshals a string to a ZonedDateTime.
     *
     * @param v the string to unmarshal
     * @return the unmarshaled ZonedDateTime
     * @throws Exception if an error occurs during unmarshaling
     */
    @Override
    public java.time.ZonedDateTime unmarshal(String v) throws Exception {
        if (v == null || v.isEmpty()) {
            return null;
        }
        return java.time.ZonedDateTime.parse(v, DateTimeFormatter.ISO_DATE_TIME);
    }

    @Override
    public String marshal(java.time.ZonedDateTime v) throws Exception {
        if(v==null){
            return null;
        }
        ZonedDateTime n = v.withZoneSameInstant(ZoneOffset.UTC); //normalize to UTC
        return n.format(DateTimeFormatter.ISO_DATE_TIME);
    }
}
