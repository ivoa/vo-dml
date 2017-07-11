Laurent Bourges - Nov 27, 2012

---------------------------------------
   Distributed librairies
---------------------------------------

This folder and sub folders contains java libraries used by ant build file and java source code :


* Saxon B :
      - saxon9.jar
      - saxon9-s9api.jar
      (saxonb9-0-0-4j.zip)

    "The latest open-source implementation of XSLT 2.0 and XPath 2.0, and XQuery 1.0.
    This provides the "basic" conformance level of these languages: in effect, this provides all the features
    of the languages except schema-aware processing. This version reflects the syntax of the final XSLT 2.0,
    XQuery 1.0, and XPath 2.0 Recommendations of 23 January 2007.

    There are three files available: one containing executable code for the Java platform, one containing
    executable code for the .NET platform, and one containing documentation, source code, and sample applications
    applicable to both platforms. (Documentation is also available online)
    ..."

    Usage : this library is only used by <xslt2> custom tasks in ant script to provide an XSLT 2.0 reference implementation.

    http://saxon.sourceforge.net/
    http://freefr.dl.sourceforge.net/project/saxon/Saxon-B/9.0.0.8/saxonb9-0-0-8j.zip

    License terms: Mozilla Public License Version 1.0. see ./notices/LICENSE.txt


---------------------------------------
   SaxonLiaison Ant Hack
---------------------------------------

This folder contains the SaxonLiaison class (source & compiled code).


This small class extends ant TraXLiaison class to use Saxon XSLT2 processor.


Moreover, it computes the lastModificaton date with the following algorithm :
  - xml source document : xml-date
      this date is deducted from the file content (<lastModifiedDate> node or lastModifiedDate attribute) if present; file date otherwise.

  - xsl document : xsl-date

  => lastModfied = max (xml-date, xsl-date)


Then the XSLT is processed and SaxonLiaison published the following parameters :
  - lastModified = UTC format : number of milliseconds since 1/1/1970

  - lastModifiedDate = string format [yyyyMMddHHmmss]
  - lastModifiedText = string format [yyyy-MM-dd HH:mm:ss]
  - lastModifiedXSDDatetime = string format [yyyy-MM-ddTHH:mm:ss]

How to compile SaxonLiaison class:

javac -g -source 1.5 -target 1.5 -cp "./libs/ant.jar:./libs/ant-trax.jar" SaxonLiaison.java 


--- End of file ---
