// (c) Alexandre Fenyo 2012, 2013, 2014, 2015, 2016 - alex@fenyo.net - http://fenyo.net - GPLv3 licensed

package net.fenyo.mail4hotspot.service
{
	public class PortItem
	{
		// on déclare les propriétés Bindable afin que l'ItemRenderer contenant par ex <s:Label text="{ data.from }, { data.subject }"/> puisse les binder.
		// si on ne le faisait pas, on aurait un warning "warning: unable to bind to property 'subject' on class 'net.fenyo.mail4hotspot.service::MailItem'"
		// et les modifs après récupération et affichage ne seraient pas réaffichées
		[Bindable]
		public var local_port : Number;
		
		[Bindable]
		public var remote_port : Number;
		
		[Bindable]
		public var remote_host : String;
		
		[Bindable]
		public var description : String;

		[Bindable]
		public var selected : Boolean;

		[Bindable]
		public var internal_use : Boolean;

		public function PortItem(local_port : Number, remote_port : Number, remote_host : String, description : String, internal_use : Boolean = false) {
			this.local_port = local_port;
			this.remote_port = remote_port;
			this.remote_host = remote_host;
			this.description = description;
			this.selected = false;
			this.internal_use = internal_use;
		}
	}
}
