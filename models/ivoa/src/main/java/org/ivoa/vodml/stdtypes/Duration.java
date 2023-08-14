
package org.ivoa.vodml.stdtypes;

import java.util.Date;

import org.ivoa.vodml.annotation.VoDml;
import org.ivoa.vodml.annotation.VodmlRole;
import org.ivoa.vodml.jpa.JPAManipulations;

import jakarta.persistence.*;

/**
 * UML PrimitiveType duration : Represents an interval of time from beginning to
 * end. Is not equivalent to a simple real value indicating the number of
 * seconds (for example). In general a custom mapping to a particular
 * serialisation context must be provided.
 *
 * @author generated by VO-URP tools VO-URP Home
 * @author Laurent Bourges (voparis) / Gerard Lemson (mpe)
 *
 */
@Embeddable
@VoDml(id = "ivoa:duration", role=VodmlRole.primitiveType, type = "ivoa:duration" )
public class Duration implements JPAManipulations {
//TODO not sure that this is the best representation - PAH - better to use java internal type esp. JDK8+
    /** string representation */
    private Date from;
    private Date to;

    /**
     * Creates a new duration Primitive Type instance, wrapping a base type.
     *
     * @param from the start of the duration
     * @param to the end of the duration
     */
    public Duration(Date from, Date to) {
        this.from = from;
        this.to = to;
    }

    public Duration() {
        this.from = new Date();
        this.to = from;
    }


    public Date getFrom() {
        return from;
    }

    public void setFrom(Date from) {
        this.from = from;
    }

    public Date getTo() {
        return to;
    }

    public void setTo(Date to) {
        this.to = to;
    }

    @Override
    public void forceLoad() {
        // nothing to do
    }

    @Override
    public void jpaClone(EntityManager em) {
        // nothing to do
    }

    @Override
    public void persistRefs(EntityManager em) {
        // nothing to do.
    }
}
