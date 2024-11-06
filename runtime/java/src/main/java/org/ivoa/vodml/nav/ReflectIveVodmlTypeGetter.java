/*
 * Created on 31 Aug 2021 
 * Copyright 2021 Paul Harrison (paul.harrison@manchester.ac.uk)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License in file LICENSE
 */ 

package org.ivoa.vodml.nav;

import java.lang.reflect.Field;

import org.ivoa.vodml.annotation.VoDml;
import org.ivoa.vodml.annotation.VodmlRole;

/**
 * Obtains VODML type information from vodml annotations.
 * @author Paul Harrison (paul.harrison@manchester.ac.uk) 
 * @since 31 Aug 2021
 */
public class ReflectIveVodmlTypeGetter implements VodmlTypeGetter {

    /** logger for this class */
    private static final org.slf4j.Logger logger = org.slf4j.LoggerFactory
            .getLogger(ReflectIveVodmlTypeGetter.class);


    private final VoDml vodmlann;
    private final String id;
    private final VodmlTypeInfo info;

    /**
     * Creates a typegetter for a class.
     * @param c the class to query
     */
    public ReflectIveVodmlTypeGetter(Class<?> c) {
        vodmlann = c.getAnnotation(VoDml.class);
        id = c.getCanonicalName();
        if (vodmlann != null)
        {
            info = new VodmlTypeInfo(vodmlann.id(), vodmlann.role());
        }
        else {
            logger.trace("no VODML meta information for {}  - this should be expected  ",id); 
            info = VodmlTypeInfo.UNKNOWN;
        }

    }

    /**
     * Creates a typegetter for a field.
     * @param f the field to query.
     */
    public ReflectIveVodmlTypeGetter(Field f) {
        vodmlann = f.getAnnotation(VoDml.class);
        id = f.getName();

        if (vodmlann != null )
        {
            switch (vodmlann.role()) {
            case attribute:
            {          
                info = new VodmlTypeInfo(vodmlann.id(), vodmlann.role(), vodmlann.type(), vodmlann.typeRole());
                break;
            }
            default:
            {
                info = new VodmlTypeInfo(vodmlann.id(), vodmlann.role(), vodmlann.type());
                break;
            }
            }

        }
        else {
            logger.trace("no VODML meta information for {} - this should be expected ",id); 
            info = VodmlTypeInfo.UNKNOWN;
        }


    }

    /**
     * {@inheritDoc}
     * overrides @see org.ivoa.vodml.nav.VodmlTypeGetter#vodmlInfo()
     */
    @Override
    public VodmlTypeInfo vodmlInfo() {
        return info;
    }


}


