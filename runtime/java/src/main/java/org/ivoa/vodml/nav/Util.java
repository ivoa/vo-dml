/*
 * Created on 30 Aug 2021 
 * Copyright 2021 Paul Harrison (paul.harrison@manchester.ac.uk)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License in file LICENSE
 */ 

package org.ivoa.vodml.nav;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.atomic.AtomicLong;
import java.util.stream.Collectors;

import org.ivoa.vodml.annotation.VodmlType;
import org.ivoa.vodml.jaxb.XmlIdManagement;
import org.ivoa.vodml.nav.ModelInstanceTraverser.Visitor;



/**
 * Utility functions for navigating VODML models.
 * @author Paul Harrison (paul.harrison@manchester.ac.uk) 
 * @since 30 Aug 2021
 */
public class Util {
    
    static final AtomicLong NEXT_ID = new AtomicLong(1000);

    /** logger for this class */
    private static final org.slf4j.Logger logger = org.slf4j.LoggerFactory
            .getLogger(Util.class);

    private Util() {
        //lots of static functions so no instantiation.
    }


    /**
     * Will find all the references referred to by the vodml-ref in the key of the map and 
     * add them to the corresponding set that is the value of the map
     *
     * @param modelInstance the vodml model instance to be searched. 
     * @param l the map of Class -&gt; Set correspondences;
     */
    @SuppressWarnings("rawtypes")
    public static void findReferences(final Object modelInstance, final Map<Class, Set> l)
    {
        final Set<Class> classes = l.keySet();
        logger.info("finding references to {}",classes);
        ModelInstanceTraverser.traverse(modelInstance,new Visitor() {

            @SuppressWarnings("unchecked")
            @Override
            public void startInstance(final Object o, final VodmlTypeInfo v,  boolean firstVisit) {
                if(v.kind == VodmlType.reference) {

                    if(classes.contains(o.getClass()))

                    {
                        Set s = l.get(o.getClass());
                        s.add(o);
                    } else if (o.getClass().getSuperclass() != Object.class) //deal with superclasses
                    {
                        for ( Class c : classes)
                        {
                            if(c.isAssignableFrom(o.getClass())){
                                Set s = l.get(c);
                                s.add(o);
                                break; // IMPL only do the first encountered - this might not be the best - would need vodml level processing logic to do better.
                            }
                        }
                    }
                }

            }
        });

    }
    public static List<XmlIdManagement> findXmlIDs(final List<Object> modelInstance)
    {
        List<XmlIdManagement> retval = new ArrayList<>();
        ModelInstanceTraverser.traverse(modelInstance, new Visitor() {
            
            @Override
            public void startInstance(Object o, VodmlTypeInfo v, boolean firstVisit) {
                if (firstVisit)
                {                  
                    if(o instanceof XmlIdManagement) 
                    {
                        XmlIdManagement i = (XmlIdManagement) o;
                        retval.add(i);
                    }
                }
                
            }
        });
        return retval;
    }
    
    public static void makeUniqueIDs(List<? extends XmlIdManagement> els ) {
        
      Set<String> currentValues = els.stream().map(p->p.getXmlId()).collect(Collectors.toSet());
      for (XmlIdManagement el : els) {
        final String id = el.getXmlId();
        if(id == null || id.isEmpty()|| id.trim().equals("0"))
        {
            Long l;
            do {
             l =  NEXT_ID.getAndIncrement();
            }
            while(currentValues.contains( l.toString()));
            currentValues.add(l.toString());
            el.setXmlId(l.toString());
        }
    }
    }


}


