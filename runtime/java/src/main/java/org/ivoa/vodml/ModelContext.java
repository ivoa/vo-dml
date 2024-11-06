package org.ivoa.vodml;
/*
 * Created on 12/02/2024 by Paul Harrison (paul.harrison@manchester.ac.uk).
 */

import org.ivoa.vodml.nav.ReferenceCache;

import java.util.Map;
import java.util.Set;

/**
 * A context for storing ephemeral information about a model.
 * @author Paul Harrison (paul.harrison@manchester.ac.uk) 
 *  //TODO ensure thread safety.
 */
public class ModelContext {
   
    //force instances to be instantiated via create()
    private ModelContext() {
        
    };

    private static ModelContext instance;

    private ModelContext(Map<Class, ReferenceCache> mm) {
        this.mm = mm;
    }

    private Map<Class, ReferenceCache> mm;

    /**
     * get the current model context.
     * @return the context.
     */
    public static synchronized ModelContext current() {
        if (instance != null)
            return instance;
        else
            throw new IllegalStateException("the context has not been set");
    }

    /**
     * create a new model context with the associated reference cache.
     * @param m the reference cache.
     */
    public static  void create(Map<Class, ReferenceCache> m) {
        instance = new ModelContext(m);
    }

    /**
     * Return the cache for a particular reference type.
     * @param <T> the type of the reference.
     * @param clazz the type of the reference.
     * @return the cache.
     */
    @SuppressWarnings("unchecked")
    public <T> ReferenceCache<T> cache(Class<T> clazz) {
        return mm.get(clazz);
    }

    /**
     * List the reference types contained in the context.
     * @return the set of types.
     */
    @SuppressWarnings("rawtypes")
    public Set<Class> containedRefs() {
       return mm.keySet();
        
    }
   

}
