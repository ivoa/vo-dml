
package org.ivoa.vodml.stdtypes;

import javax.persistence.Embeddable;

import org.ivoa.vodml.annotation.VoDml;
import org.ivoa.vodml.annotation.VodmlType;

/**
 * UML DataType rational : A rational number from Q, represented by two
 * integers, a numerator and a denominator. A native mapping to a serialisation
 * context does in general not exists.
 *
 * @author generated by VO-URP tools VO-URP Home
 * @author Laurent Bourges (voparis) / Gerard Lemson (mpe)
 */
@VoDml(ref = "ivoa:rational", type=VodmlType.primitiveType)
@Embeddable
public class Rational {

    private int numerator;
    private int denominator;

    /**
     * Creates a new rational DataType instance, wrapping a base type.
     *
     * @param v
     */
    public Rational(final int _n, final int _d) {
        this.numerator = _n;
        this.denominator = _d;
    }

    /**
     * TODO Implement better parser.<br/>
     * 
     * @param sv
     */
    public Rational(String sv) {
        String[] words = sv.trim().split("[(/)]");
        if (words.length != 2)
            throw new IllegalArgumentException(
                    "String value in constructor must be of form '(%f/%f)'");
        this.numerator = Integer.parseInt(words[0]);
        this.denominator = Integer.parseInt(words[1]);
    }

    public Rational() {
        this(0, 1);
    }

    /**
     * Return the string representation of this Rational.<br/>
     */
    @Override
    public final String toString() {
        return String.format("(%d/%d)", numerator, denominator);
    }

    public int getNumerator() {
        return numerator;
    }

    public void setNumerator(int numerator) {
        this.numerator = numerator;
    }

    public int getDenominator() {
        return denominator;
    }

    public void setDenominator(int denominator) {
        this.denominator = denominator;
    }
}
