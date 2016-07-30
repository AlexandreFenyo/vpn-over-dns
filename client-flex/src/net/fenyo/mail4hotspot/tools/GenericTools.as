// (c) Alexandre Fenyo 2012, 2013, 2014, 2015, 2016 - alex@fenyo.net - http://fenyo.net - GPLv3 licensed

package net.fenyo.mail4hotspot.tools
{
	public class GenericTools
	{
		private static var last_prof_time : Number = new Date().time;

		public function GenericTools() {
		}

		public static function getXMLField(content : String, field : String) : String {
			var pattern : RegExp = new RegExp("<" + field + ">(?P<field>.*)</" + field + ">");
			var result : Array = pattern.exec(content);
			if (result == null) return "";
			else return result.field;
		}

		public static function profiler(str : String, displ : Boolean = true) : void {
			const now : Number = new Date().time;
			const delay : Number = now - last_prof_time;
			last_prof_time = now;
			trace("PROFILER: " + str + (displ ? (" - " + delay) : ""));
		}

		public static function padNumber(number : uint, length : uint = 8) : String {
			// amélioration : pour éviter la limitation à length = 32 (car il y a 32 0 dans la chaîne qui suit), construire la chaîne zeros automatiquement en fonction de length
			const zeros : String = "00000000000000000000000000000000";
			if (length > zeros.length) {
				trace("padNumber: invalid length parameter");
				return null;
			}
			var part1 : String = new String(number);
			var part2 : String = "";
			if (length > part1.length) part2 = zeros.substr(0, length - part1.length);
			return part2 + part1;
		}

		public static function simulateIPLoss(rr : String) : String {
			// 20% d'erreurs
			// return (Math.random() * 10 < 2) ? "zefzefzezefx.org" : rr;

			// 95% d'erreurs
			// return (Math.random() * 100 < 95) ? (rr + ".zefzefzezefx.org") : rr;

			// 0% d'erreurs
			return rr;
}

		public static function hex2dec(hex : String) : String {
			var bytes : Array = [];
			while(hex.length > 2) {
				var byte : String = hex.substr(-2);
				hex = hex.substr(0, hex.length - 2);
				bytes.splice(0, 0, int("0x" + byte));
			}
			return bytes.join(" ");
		}
		
		public static function d2h(d : int) : String {
			var c : Array = [ '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F' ];
			var l : int = d / 16;
			var r : int = d % 16;
			return c[l] + c[r];
		}
		
		public static function dec2hex(dec : String) : String {
			var hex : String = "0x";
			var bytes : Array = dec.split(" ");
			for(var i : int = 0; i < bytes.length; i++)
				hex += d2h(int(bytes[i]));
			return hex;
		}
	}
}
