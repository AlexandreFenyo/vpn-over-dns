// (c) Alexandre Fenyo 2012, 2013, 2014, 2015, 2016 - alex@fenyo.net - http://fenyo.net - GPLv3 licensed

package net.fenyo.mail4hotspot.dns;

import java.util.Arrays;
import java.util.zip.*;

import net.fenyo.mail4hotspot.service.AdvancedServices;
import net.fenyo.mail4hotspot.tools.GeneralException;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import java.nio.*;
import java.nio.charset.*;
import java.net.*;

public class Msg {
	protected final Log log = LogFactory.getLog(getClass());

	// s'il est trop petit, on plantera la compression...
	// c'est pour cela qu'on a mis 1 Mo, donc pour économiser de la place on le met static
	final static byte [] compressed = new byte [1024 * 1024];

	private final int input_size;
	private int output_size = 0;
	private int bytes_written = 0;
	private final byte input_buffer[];
	private final boolean input_buffer_state[];
	private byte output_buffer[] = null;
	private Boolean is_processed = false;

	private long last_use = System.currentTimeMillis();

	public static class BinaryMessageReply {
		public String reply_string;
		public byte [] reply_data;
	}

	public long getLastUse() {
		return last_use;
	}

	private static byte hex2Byte(final String hex) throws GeneralException {
		if (hex.length() != 2) throw new GeneralException("invalid hex size");
		char c0 = hex.toUpperCase().charAt(0);
		char c1 = hex.toUpperCase().charAt(1);
		if (c0 >= 'A') c0 = (char) (c0 - 'A' + 10);
		else c0 = (char) (c0 - '0');
		if (c1 >= 'A') c1 = (char) (c1 - 'A' + 10);
		else c1 = (char) (c1 - '0');
		return (byte) (c0 * 16 + c1);
	}

	// dump message content for purpose of debugging
	public String debugContent() {
		String retval = "";

		if (input_buffer.length == 0) return "invalid null size";

		if (input_buffer[0] == 0) {
			// UTF-8 message type
			retval += "type=text;";

			final ByteBuffer bb = ByteBuffer.allocate(input_buffer.length - 1);
			bb.put(input_buffer, 1, input_buffer.length - 1);
			bb.position(0);
			final String query = Charset.forName("UTF-8").decode(bb).toString();
			retval += "query=" + query + ";";

		} else {
			// binary message type
			retval += "type=binary;";

			final ByteBuffer bb = ByteBuffer.allocate(input_buffer[0]);
			bb.put(input_buffer, 1, input_buffer[0]);
			bb.position(0);
			final String query = Charset.forName("UTF-8").decode(bb).toString();
			retval += "query=" + query + ";";
		}

		return retval;
	}

	private byte [] process(final AdvancedServices advancedServices, final Inet4Address address) throws GeneralException {
		// log.debug("processing message of type " + input_buffer[0]);
		// for (byte b : input_buffer) log.debug("received byte: [" + b + "]");

		if (input_buffer.length == 0) throw new GeneralException("invalid size");
		if (input_buffer[0] == 0) {
			// UTF-8 message type

			final ByteBuffer bb = ByteBuffer.allocate(input_buffer.length - 1);
			bb.put(input_buffer, 1, input_buffer.length - 1);
			bb.position(0);
			final String query = Charset.forName("UTF-8").decode(bb).toString();
			// log.debug("RECEIVED query: [" + query + "]");

			final String reply = advancedServices.processQueryFromClient(query, address);

			// this buffer may not be backed by an accessible byte array, so we do not use Charset.forName("UTF-8").encode(reply).array() to fill output_buffer
			final ByteBuffer ob = Charset.forName("UTF-8").encode(reply);
			ob.get(output_buffer = new byte [ob.limit()]);

			output_size = output_buffer.length;

		} else {
			// binary message type
			// log.debug("processing binary message");

			final ByteBuffer bb = ByteBuffer.allocate(input_buffer[0]);
			bb.put(input_buffer, 1, input_buffer[0]);
			bb.position(0);
			final String query = Charset.forName("UTF-8").decode(bb).toString();
			//		log.debug("RECEIVED query: [" + query + "]");

			final BinaryMessageReply reply = advancedServices.processBinaryQueryFromClient(query, Arrays.copyOfRange(input_buffer, input_buffer[0] + 1, input_buffer.length), address);

			// this buffer may not be backed by an accessible byte array, so we do not use Charset.forName("UTF-8").encode(reply).array() to fill string_part
			final ByteBuffer ob = Charset.forName("UTF-8").encode(reply.reply_string);
			final byte [] string_part = new byte[ob.limit()];
			ob.get(string_part);

			if (string_part.length > 255) throw new GeneralException("string_part too long");
			output_buffer = new byte [string_part.length + reply.reply_data.length + 1];
			output_buffer[0] = (byte) string_part.length;
			for (int i = 0; i < string_part.length; i++) output_buffer[i + 1] = string_part[i];
			for (int i = 0; i < reply.reply_data.length; i++) output_buffer[string_part.length + i + 1] = reply.reply_data[i];
			output_size = output_buffer.length;
		}
		
		synchronized (compressed) {
			// http://docs.oracle.com/javase/7/docs/api/java/util/zip/Deflater.html#deflate(byte[])
			// log.debug("processing binary message: length before compressing: " + output_buffer.length);
			final Deflater compresser = new Deflater();
			compresser.setInput(output_buffer);
			compresser.finish();
			final int nbytes = compresser.deflate(compressed);
//			log.debug("RET: " + nbytes);
//			log.debug("COMPRESSED: " + compressed.length);
			// log.debug("processing binary message: length after compressing: " + nbytes);
			if (compressed.length == nbytes) {
				log.error("compressed buffer too small...");
				throw new GeneralException("compressed buffer too small...");
			}
			output_buffer = Arrays.copyOf(compressed, nbytes);
			output_size = output_buffer.length;
		}

		synchronized (is_processed) {
			is_processed = true;
		}

		return new byte [] { 'E', 0 }; // 'E'rror 0 == OK
	}

	public boolean isProcessed() {
		last_use = System.currentTimeMillis();

		synchronized (is_processed) {
			return is_processed;
		}
	}

	public int outputLength() {
		last_use = System.currentTimeMillis();

		return output_buffer.length;
	}

	public byte [] read(final int pos, final int size) throws GeneralException {
		synchronized (output_buffer) {
			last_use = System.currentTimeMillis();

			if (size == 0 || pos + size > this.output_size) throw new GeneralException("output buffer too short");
			return Arrays.copyOfRange(output_buffer, pos, pos + size);
		}
	}

	public byte [] write(final int pos, final String contentHexa, final AdvancedServices advancedServices, final Inet4Address address) throws GeneralException {
		synchronized (input_buffer) {
			last_use = System.currentTimeMillis();

			// log.debug("write at pos " + pos + ", length=" + contentHexa.length() / 2);

			if ((contentHexa.length() & 1) == 1) throw new GeneralException("invalid write length parity");
			final int contentLen = contentHexa.length() / 2;
			if (pos + contentLen > input_size) throw new GeneralException("invalid write length: pos=" + pos + " contentLen=" + contentLen + " input_size=" + input_size);
			for (int i = 0; i < contentLen; i++)
				if (input_buffer_state[pos + i] == false) {
					input_buffer[pos + i] = hex2Byte(contentHexa.substring(2 * i, 2 * (i + 1)));
					input_buffer_state[pos + i] = true;
					bytes_written++;
					if (bytes_written == input_size) return process(advancedServices, address);
				}
			return new byte [] { 'E', 0 }; // 'E'rror 0 == no error
		}
	}

	public Msg() {
		input_size = 0;
		input_buffer = null;
		input_buffer_state = null;
	}

	public Msg(final int size) {
		input_size = size;
		input_buffer = new byte [size];
		input_buffer_state = new boolean [size];
	}
}
