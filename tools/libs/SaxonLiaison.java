
import java.io.BufferedReader;
import org.apache.tools.ant.types.Resource;
import org.apache.tools.ant.taskdefs.optional.TraXLiaison;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.Date;


/**
 * This class is a hack to work around Ant bug #41314: http://issues.apache.org/bugzilla/show_bug.cgi?id=41314
 * 
 * @author laurent bourges (voparis) / Gerard Lemson (mpe)
 */
public final class SaxonLiaison extends TraXLiaison {

  private final static String TRANSFORM_PROP = "javax.xml.transform.TransformerFactory";
  private final static String SAXON_FACTORY = "net.sf.saxon.TransformerFactoryImpl";
  // constants : 
  private final static String LAST_MODIFIED_TAG = "<lastModifiedDate>";
  private final static String LAST_MODIFIED_ATT = "lastModifiedDate=\"";
  private final int MAX_SCAN_LINES = 100;
  private final long EMPTY = -1l;
  /** data format : YYYYMMDDHHmmss */
  public static final SimpleDateFormat NDF = new SimpleDateFormat("yyyyMMddHHmmss");
  /** data format : YYYY-MM-DD HH24:mm:ss */
  public static final SimpleDateFormat SDF = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
  public static final SimpleDateFormat XSDDF = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss");

  // member :
  private long xslLastModified = EMPTY;

  public SaxonLiaison() throws Exception {
  }

  /**
   * XSLTLiaison3 signature (ant 1.7.0)
   * 
   * @param stylesheet
   * @throws java.lang.Exception
   */
  @Override
  public void setStylesheet(Resource stylesheet) throws Exception {
    this.xslLastModified = (stylesheet != null) ? stylesheet.getLastModified() : EMPTY;

    super.setStylesheet(stylesheet);
  }

  /**
   * XSLTLiaison2 signature 
   * 
   * @param stylesheet
   * @throws java.lang.Exception
   */
  @Override
  public void setStylesheet(final File stylesheet) throws Exception {
    this.xslLastModified = (stylesheet != null) ? stylesheet.lastModified() : EMPTY;

    super.setStylesheet(stylesheet);
  }

  @Override
  public void transform(final File infile, final File outfile) throws Exception {
    final String oldProperty = System.setProperty(TRANSFORM_PROP, SAXON_FACTORY);

    try {
        final long lastModified = computeLastModified(infile);

        addParam("lastModified", String.valueOf(lastModified));

        final Date lastDate = new Date(lastModified);
        System.out.println("lastModifiedDate : " + lastDate);

        addParam("lastModifiedID", NDF.format(lastDate));
        addParam("lastModifiedText", SDF.format(lastDate));
    addParam("lastModifiedXSDDatetime", XSDDF.format(lastDate));

        super.transform(infile, outfile);
    } finally {
        if (oldProperty == null) {
          System.clearProperty(TRANSFORM_PROP);
        } else {
          System.setProperty(TRANSFORM_PROP, oldProperty);
        }
    }
  }

  public long computeLastModified(final File infile) {
    long lastModified = EMPTY;

    long xmlDate = extractLastModified(infile);
    if (xmlDate == EMPTY) {
      xmlDate = infile.lastModified();
      System.out.println("xml file : lastModifiedDate : " + xmlDate);
    }

    System.out.println("xsl file : lastModifiedDate : " + xslLastModified);

    if (xmlDate > xslLastModified) {
      lastModified = xmlDate;
    } else {
      lastModified = xslLastModified;
    }

    System.out.println("lastModifiedDate : " + lastModified);
    return lastModified;
  }

  public long extractLastModified(final File infile) {
    long val = EMPTY;
    BufferedReader br = null;
    try {

      // 8K buffer :
      br = new BufferedReader(new FileReader(infile));

      int i = 0;
      for (String line = null; (line = br.readLine()) != null;) {
        val = extractLastModified(line);
        i++;
        // avoid to scan all file :
        if (val != EMPTY || i > MAX_SCAN_LINES) {
          break;
        }
      }

    } catch (IOException ioe) {
      System.out.println("io failure : ");
      ioe.printStackTrace(System.out);
    } finally {
      if (br != null) {
        try {
          br.close();
        } catch (IOException ioe) {
          System.out.println("io failure : ");
          ioe.printStackTrace(System.out);
        }
      }
    }
    System.out.println("xml body : lastModifiedDate : " + val);
    return val;
  }

  public long extractLastModified(final String line) {
    int pos = -1;
    int lastPos = -1;
    String val = null;

    pos = line.indexOf(LAST_MODIFIED_TAG);
    if (pos != -1) {
      pos += LAST_MODIFIED_TAG.length();
      lastPos = line.indexOf("</", pos);
      if (lastPos != -1) {
        val = line.substring(pos, lastPos);
      }
    }
    if (val == null) {
      pos = line.indexOf(LAST_MODIFIED_ATT);
      if (pos != -1) {
        pos += LAST_MODIFIED_ATT.length();
        lastPos = line.indexOf("\"");
        if (lastPos != -1) {
          val = line.substring(pos, lastPos);
        }
      }

    }
    return (val != null) ? Long.parseLong(val) : EMPTY;
  }
}
