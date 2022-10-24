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

/**
 * Obtains VODML type information from vodml annotations.
 * @author Paul Harrison (paul.harrison@manchester.ac.uk) 
 * @since 31 Aug 2021
 */
public class ReflectIveVodmlTypeGetter implements VodmlTypeGetter {

    
    
    private final VoDml a;
    private final String id;

    /**
     * @param c the class to query
     */
    public ReflectIveVodmlTypeGetter(Class<?> c) {
       a = c.getAnnotation(VoDml.class);
       id = c.getCanonicalName();
       
    }
        
     public ReflectIveVodmlTypeGetter(Field f) {
       a = f.getAnnotation(VoDml.class);
       id = f.getName();
       
    }
    
 /**
 * {@inheritDoc}
 * overrides @see org.ivoa.vodml.nav.VodmlTypeGetter#vodmlInfo()
 */
@Override
      public VodmlTypeInfo vodmlInfo() {
       if (a != null )
        {
            return new VodmlTypeInfo(a.ref(), a.type());
        }
        else {
            throw new IllegalArgumentException("no VODML meta information for "+id);
        }

    }

   /**
    * factory method for creating typegetter.
    * @param o the object to create the typegetter for.
    * @return a TypeGetter that uses reflection on the VO-DML annotations. 
    */
  public static ReflectIveVodmlTypeGetter factory(Object o) {
       if(o instanceof Class) {
           return new ReflectIveVodmlTypeGetter((Class)o);
       }
       else if (o instanceof Field){
           return new ReflectIveVodmlTypeGetter((Field)o);
       }
       else
       {
           throw new IllegalArgumentException("unknown metatype " + o.getClass().getCanonicalName());
       }

   }

}


