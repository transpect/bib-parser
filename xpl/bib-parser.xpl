<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc"
  xmlns:c="http://www.w3.org/ns/xproc-step"
  xmlns:cx="http://xmlcalabash.com/ns/extensions"
  xmlns:pxf="http://exproc.org/proposed/steps/file"
  xmlns:tr="http://transpect.io"
  xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
  xmlns:s="http://purl.oclc.org/dsdl/schematron"
  version="1.0"
  name="bib-parser" 
  type="tr:bib-parser">
  
  <p:documentation>
    This is an XProc wrapper to run bibliographic 
    reference parsers.
  </p:documentation>
  
  <p:output port="result" primary="true"/>
  <p:output port="report" primary="false" sequence="true">
    <p:pipe port="report" step="try"/>
  </p:output>
  
  <p:option name="href" select="'C:/cygwin64/home/kraetke/bib-extension/refs.txt'">
    <p:documentation>
      Path to plain text file containing one reference per line, e.g.
      
      Winters, Michael Sean, “Rome Consistory Showing Pope Francis’ Vision Taking Root,” National Catholic Reporter August 29, 2022.
      Wright, George, “South Sudan: Journalists Held Over Film of President Appearing to Wet Himself,” BBC  News, January 7, 2023.
    </p:documentation>
  </p:option>
  
  <p:option name="parser-path" select="'/usr/local/bin/anystyle'"/>
  
  <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
  <p:import href="http://transpect.io/xproc-util/file-uri/xpl/file-uri.xpl"/>
  <p:import href="http://transpect.io/xproc-util/store-debug/xpl/store-debug.xpl"/>
  
  <p:try name="try">
    <p:group>
      <p:output port="result" primary="true"/>
      <p:output port="report" primary="false" sequence="true">
        <p:empty/>
      </p:output>
  
      <tr:file-uri name="get-parser-path">
        <p:with-option name="filename" select="$parser-path"/>
        <p:input port="catalog">
          <p:document href="http://this.transpect.io/xmlcatalog/catalog.xml"/>
        </p:input>
        <p:input port="resolver">
          <p:document href="http://transpect.io/xslt-util/xslt-based-catalog-resolver/xsl/resolve-uri-by-catalog.xsl"/>
        </p:input>
      </tr:file-uri>
      
      <cx:message cx:depends-on="get-parser-path" name="msg1">
        <p:with-option name="message" select="concat('[info] bib parser executable: ', /c:result/@os-path)"/>
      </cx:message>
      
      <pxf:info name="parser-info" fail-on-error="false" cx:depends-on="get-parser-path">
        <p:with-option name="href" select="/*/@local-href">
          <p:pipe port="result" step="get-parser-path"/>
        </p:with-option>
      </pxf:info>
      
      <cx:message name="msg2" cx:depends-on="parser-info">
        <p:with-option name="message" select="if(exists(/c:error)) 
                                              then '[ERROR] bib parser executable does not exist or is not readable' 
                                              else concat('[info] bib parser executable readable: ', c:file/@readable)"/>
      </cx:message>
      
      <p:sink/>
      
      <tr:file-uri name="get-file-path">
        <p:with-option name="filename" select="$href"/>
        <p:input port="catalog">
          <p:document href="http://this.transpect.io/xmlcatalog/catalog.xml"/>
        </p:input>
        <p:input port="resolver">
          <p:document href="http://transpect.io/xslt-util/xslt-based-catalog-resolver/xsl/resolve-uri-by-catalog.xsl"/>
        </p:input>
      </tr:file-uri>
      
      <cx:message name="msg3" cx:depends-on="file-info">
        <p:with-option name="message" select="'[info] bibliography file: ', /c:result/@os-path"/>
      </cx:message>
      
      <pxf:info name="file-info" fail-on-error="false" cx:depends-on="get-file-path">
        <p:with-option name="href" select="/*/@local-href">
          <p:pipe port="result" step="get-file-path"/>
        </p:with-option>
      </pxf:info>
      
      <cx:message name="msg4" cx:depends-on="file-info">
        <p:with-option name="message" select="if(exists(/c:error)) 
                                              then '[ERROR] bibliography file does not exist or is not readable' 
                                              else concat('[info] bibliography file readable: ', c:file/@readable)"/>
      </cx:message>
      
      <p:choose name="choose" cx:depends-on="file-info">
        <p:variable name="executable-readable" select="c:file/@readable">
          <p:pipe port="result" step="parser-info"/>
        </p:variable>
        <p:variable name="file-readable" select="c:file/@readable">
          <p:pipe port="result" step="file-info"/>
        </p:variable>
        <p:variable name="parser-path" select="/c:result/@os-path">
          <p:pipe port="result" step="get-parser-path"/>
        </p:variable>
        <p:variable name="file-path" select="/c:result/@os-path">
          <p:pipe port="result" step="get-file-path"/>
        </p:variable>
        <p:variable name="parser-args" select="'-f xml parse'"/>
        <p:variable name="run" select="string-join(($parser-path, $parser-args, $file-path), ' ')"/>    
        <p:when test="$executable-readable eq 'true' and $file-readable eq 'true'">
          
          <p:exec name="run-parser" result-is-xml="true">
            <p:input port="source">
              <p:empty/>
            </p:input>
            <p:with-option name="command" select="'ruby'"/>
            <p:with-option name="args" 
                           select="$run"/>
          </p:exec>
        
        </p:when>
        <p:otherwise>
          
          <p:error code="exectutable-not-found">
            <p:input port="source">
              <p:inline>
                <c:error>
                  <c:error>exectutable not found</c:error>
                </c:error>
              </p:inline>
            </p:input>
          </p:error>
          
        </p:otherwise>
      </p:choose>
      
    </p:group>
    <p:catch name="catch">
      <p:output port="result" primary="true"/>
      <p:output port="report" primary="false" sequence="true">
        <p:pipe port="result" step="forward-error"/>
      </p:output>
      
      <p:identity name="forward-error">
        <p:input port="source">
          <p:pipe port="error" step="catch"/>
        </p:input>
      </p:identity>
      
    </p:catch>
  </p:try>
  
</p:declare-step>