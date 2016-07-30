// (c) Alexandre Fenyo 2012, 2013, 2014, 2015, 2016 - alex@fenyo.net - http://fenyo.net - GPLv3 licensed

package net.fenyo.mail4hotspot.tools;

/**
 * An exception for errors specific to this software.
 * @author Alexandre Fenyo
 * @version $Id: GeneralException.java,v 1.5 2008/04/15 23:58:18 fenyo Exp $
 */

public class GeneralException extends Exception {
  public static final long serialVersionUID = 1L;

  /**
   * Constructor.
   * Creates a GeneralException instance.
   * @param none.
   */
  public GeneralException() {
   super(); 
  }

  /**
   * Constructor.
   * Creates a GeneralException instance.
   * @param message message associated with this exception.
   * @param none.
   */
  public GeneralException(final String message) {
    super(message); 
   }

  /**
   * Constructor.
   * Creates a GeneralException instance.
   * @param message message associated with this exception.
   * @param exception exception associated with this exception.
   */
  public GeneralException(final String message, final Throwable cause) {
    super(message, cause); 
   }

  /**
   * Constructor.
   * Creates a GeneralException instance.
   * @param exception exception associated with this exception.
   */
  public GeneralException(final Throwable cause) {
    super(cause); 
   }
}
