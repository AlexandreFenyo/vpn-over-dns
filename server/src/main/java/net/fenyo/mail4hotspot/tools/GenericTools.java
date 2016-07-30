// (c) Alexandre Fenyo 2012, 2013, 2014, 2015, 2016 - alex@fenyo.net - http://fenyo.net - GPLv3 licensed

package net.fenyo.mail4hotspot.tools;

import java.io.IOException;
import java.io.StringReader;
import java.nio.ByteBuffer;

import javax.swing.text.html.*;
import javax.swing.text.html.parser.*;
import javax.swing.text.*;

public class GenericTools {
	protected final static org.apache.commons.logging.Log log = org.apache.commons.logging.LogFactory.getLog(GenericTools.class);

	public static String truncate(final String str, final int len) {
		if (str == null) return null;
		if (str.length() <= len) return str;
		return str.substring(0, len);
	}

	public static String escapeDelimiter(final String str) {
		if (str == null) return "";
		return str.replaceAll("§", "[PARAGRAPH]");
	}
	
	public static String html2Text(final String html) {
		try {
			final StringBuilder sb = new StringBuilder();
			HTMLEditorKit.ParserCallback parserCallback = new HTMLEditorKit.ParserCallback() {
			    private boolean readyForNewline = false;
			    private boolean headParsed = false; // éviter l'entête (notamment titre et styles éventuels)
			 
			    @Override
			    public void handleText(final char [] data, final int pos) {
			        if (headParsed) {
			        	sb.append(new String(data).trim());
				        readyForNewline = true;
			        }
			    }

			    @Override
			    public void handleStartTag(final HTML.Tag t, final MutableAttributeSet a, final int pos) {
			        if (readyForNewline && (t == HTML.Tag.DIV || t == HTML.Tag.BR || t == HTML.Tag.P)) {
			            sb.append("\n");
			            readyForNewline = false;
			        }
			    }

			    @Override
			    public void handleEndTag(final HTML.Tag t, final int pos) {
			        if (t== HTML.Tag.HEAD) headParsed = true;
			    }

			    @Override
			    public void handleSimpleTag(final HTML.Tag t, final MutableAttributeSet a, final int pos) {
			        handleStartTag(t, a, pos);
			    }
			};

			// dernier paramètre true, pour éviter une exception ChangedCharSetException dans le cas où le charset est redéfini au début du HTML par un élément du style <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
			new ParserDelegator().parse(new StringReader(html), parserCallback, true);
			return sb.toString();
		} catch (final IOException ex) {
			log.error(ex);
			return null;
		}
	}
}
