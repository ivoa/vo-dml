package org.ivoa.vodml.vocabularies;
/*
 * Created on 10/09/2024 by Paul Harrison (paul.harrison@manchester.ac.uk).
 */

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonProperty;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

/**
 * An IVOA vocabulary Term as described in https://www.ivoa.net/documents/Vocabularies.
 */
public class Term {



   /**
    * the actual string used in annotating the term.
    */
   private final String term;

   /**
    *  string that should be presented to humans instead of the slightly formalised terms.
    */
   private final String label;

   /**
    * A description of the term. should be sufficiently precise to allow someone with a certain amount of domain expertise to decide whether a certain "thing" is or is not covered by the term (or more precisely, the underlying concept).
    */
   private final String description;

   /**
    * Marks whether the term is preliminary and might disappear
    */
   private final boolean preliminary;

   /**
    * Marks whether the term is deprecated. If deprecated it should not be used in new applications.
    */
   private final boolean  deprecated;

   private List<Term> wider = new ArrayList<>();
   private List<Term> narrower = new ArrayList<>();
   private Term parent;


   @JsonCreator(mode = JsonCreator.Mode.PROPERTIES)
   public Term(@JsonProperty("term") String term,
               @JsonProperty("label") String label,
               @JsonProperty("description") String description,
               @JsonProperty("preliminary") String preliminary,
               @JsonProperty("deprecated") String deprecated) {
      this.term = term;
      this.label = label;
      this.description = description;
      this.preliminary = preliminary != null;
      this.deprecated = deprecated != null;
   }

   @JsonProperty
   public String getTerm() {
      return term;
   }
   @JsonProperty
   public String getLabel() {
      return label;
   }
   @JsonProperty
   public String getDescription() {
      return description;
   }
   @JsonProperty
   public boolean isPreliminary() {
      return preliminary;
   }
   @JsonProperty
   public boolean isDeprecated() {
      return deprecated;
   }


   // comparison is only made on term string
   @Override
   public boolean equals(Object o) {
      if (this == o) return true;
      if (o == null || getClass() != o.getClass()) return false;
      Term term1 = (Term) o;
      return Objects.equals(term, term1.term);
   }

   @Override
   public int hashCode() {
      return Objects.hashCode(term);
   }

   @Override
   public String toString() {
      return "Term{" +
            "term='" + term + '\'' +
            ", label='" + label + '\'' +
            ", description='" + description + '\'' +
            ", preliminary=" + preliminary +
            ", deprecated=" + deprecated +
            '}';
   }

   /**
    * is the given term wider than this.
    * @param t the term.
    * @return true if the given term is wider.
    */
   public boolean hasWiderTerm(Term t) {
      return wider.contains(t);
   }

   /**
    * add a wider term to the description.
    * @param wider the wider term.
    */
   public void addWider(Term wider) {
      this.wider.add(wider);
   }

   /**
    * add a narrower term to the description.
    * @param term the narrower term.
    */
   public void addNarrower(Term term) {
      this.narrower.add(term);
   }


   /**
    * is the given term narrower than this.
    * @param term the term
    * @return true if the given term is narrower.
    */
   public boolean hasNarrowerTerm(Term term) {
      return narrower.contains(term);
   }

   /**
    * add the parent term.
    * @param parent the term that is the parent.
    */
   public void addParent(Term parent) {
      this.parent= parent;
   }

   /**
    * Get the parent term to this.
    * @return The parent term;
    */
   public Term getParent() {
      return parent;
   }
}
