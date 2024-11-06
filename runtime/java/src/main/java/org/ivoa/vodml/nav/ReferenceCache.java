package org.ivoa.vodml.nav;
/*
 * Created on 12/02/2024 by Paul Harrison (paul.harrison@manchester.ac.uk).
 */

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;


/**
 * A reference cache implementation to help with processing of contained references.
 * The type parameter is the type of the references contained within the cache instance.
 * @author Paul Harrison (paul.harrison@manchester.ac.uk) 
 * @since 15 Feb 2024
 */
public class ReferenceCache <T> {
    
   private Map<T, T> valmap = new HashMap<>(); 
   
  /**
   * Store values in the cache.
 * @param initial - the original reference.
 * @param cloned - the cloned value of the same reference.
 */
public  void setValues(List<T> initial, List<T> cloned)
   {
       for (int i = 0; i < initial.size(); i++) {
       valmap.put(initial.get(i), cloned.get(i)) ;
    }
   }

/**
 * Get the new instance of the reference. Note that if the initial value is not in the cache then the value itself is returned.
 * @param initial the original value of the reference.
 * @return the new instance of the reference. 
 */
   public T get(T initial) {
   return valmap.getOrDefault(initial,initial);
}

   /**
    * Get the new instance of the reference. Note that if the initial value is not in the cache then the value itself is returned.
    * @param initial the original value of the reference.
    * @return the new List of the reference.
    */
   public List<T> get(List<T> initial) {
      return initial.stream().map(s -> valmap.getOrDefault(s,s)).collect(Collectors.toList());
   }



}
