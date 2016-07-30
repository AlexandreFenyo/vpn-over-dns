// (c) Alexandre Fenyo 2012, 2013, 2014, 2015, 2016 - alex@fenyo.net - http://fenyo.net - GPLv3 licensed

package net.fenyo.mail4hotspot.service
{
	public class MailItem
	{
		// on déclare les propriétés Bindable afin que l'ItemRenderer contenant par ex <s:Label text="{ data.from }, { data.subject }"/> puisse les binder.
		// si on ne le faisait pas, on aurait un warning "warning: unable to bind to property 'subject' on class 'net.fenyo.mail4hotspot.service::MailItem'"
		// et les modifs après récupération et affichage ne seraient pas réaffichées
		[Bindable]
		public var from : String;

		[Bindable]
		public var to : String;

		[Bindable]
		public var cc: String;

		[Bindable]
		public var message_id : String;

		[Bindable]
		public var subject : String;

		[Bindable]
		public var sent_date : String;

		[Bindable]
		public var received_date : String;

		[Bindable]
		public var content : String;

		[Bindable]
		public var unread: Boolean;

		public function MailItem(from : String, to : String, cc : String, message_id : String, subject : String, sent_date : String, received_date : String, content : String, unread : Boolean) {
			this.from = from;
			this.to = to;
			this.cc = cc;
			this.message_id = message_id;
			this.subject = subject;
			this.sent_date = sent_date;
			this.received_date = received_date;
			this.content = content;
			this.unread = unread;
		}
	}
}
