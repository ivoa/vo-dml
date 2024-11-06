package org.ivoa.vodml.jaxb;
/*
 * Created on 27/08/2021 by Paul Harrison (paul.harrison@manchester.ac.uk).
 */

import java.util.IdentityHashMap;
import java.util.Map;
import java.util.concurrent.atomic.AtomicLong;

/**
 * Will generate a unique number for each class.
 */
public class IdentityRegistry {
    private static final Map<Object, Long> registry = new IdentityHashMap<>();
    static final AtomicLong NEXT_ID = new AtomicLong(1000);


    /**
     * get an identifier.
     * @param o the object for which an identifier is needed.
     * @return the identifier.
     */
    public static synchronized long idFor(Object o) {
        Long l = registry.get(o);
        if (l == null)
            registry.put(o, l = NEXT_ID.getAndIncrement());
        return l;
    }

    /**
     * remove and object from the identity registry.
     * @param o the object to remove.
     */
    public static synchronized void remove(Object o) {
        registry.remove(o);
    }

}
