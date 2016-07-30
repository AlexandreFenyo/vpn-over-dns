// (c) Alexandre Fenyo 2012, 2013, 2014, 2015, 2016 - alex@fenyo.net - http://fenyo.net - GPLv3 licensed

package net.fenyo.mail4hotspot.dns;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import net.fenyo.mail4hotspot.tools.GeneralException;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

public class MsgFactory {
	protected final static Log log = LogFactory.getLog(MsgFactory.class);

	private static Map<Integer, Msg> messages = new HashMap<Integer, Msg>();
	private static int current_msg_id = new Double((Math.random() * (0x1000000 - 256)) + 256).intValue();
	private static Object current_msg_id_lock = new Object();

	public static void sweep() {
		synchronized (messages) {
			// ne pas effacer un élément d'une map quand on itère dessus (cf doc de keySet)
			final List<Integer> to_delete = new ArrayList<Integer>();
			for (int id : messages.keySet())
				// délai max : 5 min + délai entre les tests (rechercher @Scheduled dans AdvancedServicesImpl)
				if (System.currentTimeMillis() - messages.get(id).getLastUse() > 5 * 60 * 1000)
					to_delete.add(id);
			for (int id : to_delete) {
				log.info("sweeping one old message: id=" + id + " content=[" + messages.get(id).debugContent() + "]");
				messages.remove(id);
			}
		}
	}

	private static int getMsgId() throws GeneralException {
		synchronized (current_msg_id_lock) {
			int tmp_id = current_msg_id;

			current_msg_id++;
			if (current_msg_id == 0x1000000) current_msg_id = 256;

			synchronized (messages) {
				while (messages.containsKey(current_msg_id)) {
					current_msg_id++;
					if (current_msg_id == 0x1000000) current_msg_id = 256;
					if (current_msg_id == tmp_id) throw new GeneralException("no more message id");
				}
			}

			return current_msg_id;
		}
	}

	public static Msg getMsg(final int msg_id) {
		synchronized (messages) {
			return messages.get(msg_id);
		}
	}

	public static boolean msgExists(final int msg_id) {
		synchronized (messages) {
			return messages.containsKey(msg_id);
		}
	}

	public static void removeMsg(final int msg_id) {
		synchronized (messages) {
			// log.debug("drop message id=" + msg_id);
			messages.remove(msg_id);
		}
	}

	public static int createMsg(final int size) throws GeneralException {
		final int msg_id = getMsgId();
		final Msg msg = new Msg(size);
		synchronized (messages) {
			// log.debug("create message id=" + msg_id);
			messages.put(msg_id, msg);
		}

		return msg_id;
	}
}
