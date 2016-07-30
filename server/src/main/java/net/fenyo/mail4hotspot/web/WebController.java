// (c) Alexandre Fenyo 2012, 2013, 2014, 2015, 2016 - alex@fenyo.net - http://fenyo.net - GPLv3 licensed

package net.fenyo.mail4hotspot.web;

import java.io.IOException;
import java.net.URLEncoder;
import java.net.UnknownHostException;
import java.util.Map;

import net.fenyo.mail4hotspot.domain.*;
import net.fenyo.mail4hotspot.domain.Account.Provider;
import net.fenyo.mail4hotspot.service.AdvancedServices;
import net.fenyo.mail4hotspot.service.Browser;
import net.fenyo.mail4hotspot.service.GeneralServices;
import net.fenyo.mail4hotspot.tools.GeneralException;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.ModelMap;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.ModelAndView;
import org.springframework.dao.*;
import org.springframework.transaction.*;
import javax.persistence.*;
import javax.servlet.http.HttpServletRequest;

// excellente doc sur les controller : "16.3 Implementing Controllers" de spring-framework-reference.pdf
@Controller("webController")
public class WebController {
	protected final Log log = LogFactory.getLog(getClass());

	// @qualifier: http://static.springsource.org/spring/docs/3.0.x/spring-framework-reference/html/beans.html#beans-autowired-annotation
	@Autowired
	private GeneralServices generalServices;

	@Autowired
	private AdvancedServices advancedServices;

	/* requests for users */

	@RequestMapping("/intro")
	public ModelAndView intro() {
		log.info("TRACE: intro;done;");
		ModelAndView mav = new ModelAndView();
		mav.setViewName("say-hello");
		return mav;
	}

	@RequestMapping("/admin")
	public ModelAndView admin() {
		log.info("TRACE: admin;done;");
		ModelAndView mav = new ModelAndView();
		mav.addObject("userList", generalServices.getUserList());
		mav.setViewName("say-admin");
		return mav;
	}

	@RequestMapping(value = "/getvaluepack", method = RequestMethod.GET)
	public ModelAndView getValuePack() {
		log.info("TRACE: getvaluepack;get;");
		ModelAndView mav = new ModelAndView();
		mav.setViewName("form-getvaluepack");
		return mav;
	}

	// si on voulait directement envoyer le contenu du fichier quand le login/password est OK : http://stackoverflow.com/questions/6604509/spring-mvc-image-controller-to-display-image-bytes-in-jsp
	@RequestMapping(value = "/getvaluepack", method = RequestMethod.POST)
	public ModelAndView getValuePackPost(
			@RequestParam(value = "username", required = false) final String username,
			@RequestParam(value = "password", required = false) final String password,
			final ModelMap model) {
		log.info("TRACE: getvaluepack;post;" + username + ";" + password + ";");
		ModelAndView mav = new ModelAndView();

		try {
			final User user = generalServices.getUser(username);
			if (user.getPassword().equals(password) == false) {
				log.info("TRACE: getvaluepack;invalid password;" + username + ";" + password + ";");
				mav.setViewName("getvaluepack-badauth");
			} else {
				log.info("TRACE: getvaluepack;done;" + username + ";" + password + ";");
				mav.setViewName("getvaluepack-goodauth");
			}
		} catch (final Exception ex) {
			log.info("TRACE: getvaluepack;bad username;" + username + ";" + password + ";");
			mav.setViewName("getvaluepack-badauth");
		}

		return mav;
	}

	@RequestMapping(value = "/getuuid", method = RequestMethod.GET)
	public ModelAndView getUuid() {
		log.info("TRACE: getuuid;get;");
		ModelAndView mav = new ModelAndView();
		mav.setViewName("form-getuuid");
		return mav;
	}

	@RequestMapping(value = "/getuuid", method = RequestMethod.POST)
	public ModelAndView getUuidPost(
			@RequestParam(value = "username", required = false) final String username,
			@RequestParam(value = "password", required = false) final String password,
			final ModelMap model) {
		log.info("TRACE: getuuid;post;" + username + ";" + password + ";");
		ModelAndView mav = new ModelAndView();

		try {
			final User user = generalServices.getUser(username);
			if (user.getPassword().equals(password) == false) {
				log.info("TRACE: getuuid;invalid password;" + username + ";" + password + ";");
				mav.setViewName("getuuid-badauth");
			} else {
				log.info("TRACE: getuuid;done;" + username + ";" + password + ";");
				mav.addObject("user", user);
				mav.setViewName("getuuid-goodauth");
			}
		} catch (final Exception ex) {
			log.info("TRACE: getuuid;bad username;" + username + ";" + password + ";");
			mav.setViewName("getuuid-badauth");
		}

		return mav;
	}

	@RequestMapping(value = "/create-account", method = RequestMethod.GET)
	public ModelAndView createAccount() {
		log.info("TRACE: createaccount;get;");
		ModelAndView mav = new ModelAndView();
		mav.setViewName("form-createaccount");
		return mav;
	}

	@RequestMapping(value = "/create-account", method = RequestMethod.POST)
	public ModelAndView createAccountPost (
			@RequestParam(value = "user_username", required = false) final String user_username,
			@RequestParam(value = "username", required = false) final String username,
			@RequestParam(value = "email", required = false) final String email,
			@RequestParam(value = "password", required = false) final String password,
			@RequestParam(value = "provider", required = false) final String provider_string,
			final ModelMap model) throws GeneralException {
		log.info("TRACE: createaccount;post;" + user_username + ";" + provider_string + ";" + username + ";" + email + ";" + password + ";");
		Account.Provider provider = null;
		if (provider_string.equals("GMAIL")) provider = Provider.GMAIL;
		if (provider_string.equals("HOTMAIL")) provider = Provider.HOTMAIL;
		if (provider_string.equals("OPERAMAIL")) provider = Provider.OPERAMAIL;
		if (provider_string.equals("YAHOO")) provider = Provider.YAHOO;
		if (provider_string.equals("TESTIMAPLOCALHOST")) provider = Provider.TESTIMAPLOCALHOST;
		if (provider_string.equals("TESTIMAPRSI")) provider = Provider.TESTIMAPRSI;
		if (provider_string.equals("TESTPOPLOCALHOST")) provider = Provider.TESTPOPLOCALHOST;
		if (provider_string.equals("TESTPOPRSI")) provider = Provider.TESTPOPRSI;

		generalServices.createAccount(user_username, username, email, password, provider);
		log.info("TRACE: createaccount;done;" + user_username + ";" + provider_string + ";" + username + ";" + email + ";" + password + ";");

		ModelAndView mav = new ModelAndView("redirect:admin", model);
		return mav;
	}

	@RequestMapping(value = "/create-user", method = RequestMethod.GET)
	public ModelAndView createUser() {
		log.info("TRACE: createuser;get;");
		ModelAndView mav = new ModelAndView();
		mav.setViewName("form-createuser");
		return mav;
	}

	@RequestMapping(value = "/create-user", method = RequestMethod.POST)
	public ModelAndView createUserPost(
			@RequestParam(value = "username", required = false) final String username,
			@RequestParam(value = "password", required = false) final String password,
			final ModelMap model) throws GeneralException {
		log.info("TRACE: createuser;post;" + username + ";" + password + ";");
		generalServices.createUser(username, password);
		log.info("TRACE: createuser;done;" + username + ";" + password + ";");

		ModelAndView mav = new ModelAndView("redirect:admin", model);
		//mav.setViewName("forward:admin"); // est traité en interne, l'URL côté browser ne change pas => pour que l'URL change, il faut utiliser redirect
		return mav;
	}

	@RequestMapping(value = "/drop-account", method = RequestMethod.GET)
	public ModelAndView dropAccount() {
		log.info("TRACE: drop-account;get;");
		ModelAndView mav = new ModelAndView();
		mav.setViewName("form-dropaccount");
		return mav;
	}

	@RequestMapping(value = "/drop-account", method = RequestMethod.POST)
	public ModelAndView dropAccountPost(
			@RequestParam(value = "username", required = false) final String username,
			@RequestParam(value = "id", required = false) final long id,
			final ModelMap model) throws GeneralException {
		log.info("TRACE: drop-account;post;" + username + ";" + id + ";");
		generalServices.dropAccount(username, id);
		log.info("TRACE: drop-account;done;" + username + ";" + id + ";");

		ModelAndView mav = new ModelAndView("redirect:admin", model);
		return mav;
	}

	@RequestMapping(value = "/drop-user", method = RequestMethod.GET)
	public ModelAndView dropUser() {
		log.info("TRACE: drop-user;get;");
		ModelAndView mav = new ModelAndView();
		mav.setViewName("form-dropuser");
		return mav;
	}

	@RequestMapping(value = "/drop-user", method = RequestMethod.POST)
	public ModelAndView dropUserPost(
			@RequestParam(value = "username", required = false) final String username,
			final ModelMap model) throws GeneralException {
		log.info("TRACE: drop-user;post;" + username + ";");
		generalServices.dropUser(username);
		log.info("TRACE: drop-user;done;" + username + ";");

		ModelAndView mav = new ModelAndView("redirect:admin", model);
		return mav;
	}

	@RequestMapping(value = "/create-default", method = RequestMethod.GET)
	public ModelAndView createDefault(final ModelMap model) {
		log.info("TRACE: create-default;get;");
		generalServices.createDefault();
		log.info("TRACE: create-default;done;");
		ModelAndView mav = new ModelAndView("redirect:admin", model);
		return mav;
	}

	@RequestMapping(value = "/create-initial-users", method = RequestMethod.GET)
	public ModelAndView createInitialUsers(final ModelMap model) {
		log.info("TRACE: create-initial-users;get;");
		generalServices.createInitialUsers();
		log.info("TRACE: create-initial-users;done;");
		ModelAndView mav = new ModelAndView("redirect:admin", model);
		return mav;
	}

	@RequestMapping(value = "/create-initial-ips", method = RequestMethod.GET)
	public ModelAndView createInitialIps(final ModelMap model) throws UnknownHostException {
		log.info("TRACE: create-initial-ips;get;");
		generalServices.createInitialIps();
		log.info("TRACE: create-initial-ips;done;");
		ModelAndView mav = new ModelAndView("redirect:admin", model);
		return mav;
	}

//	@RequestMapping(value = "/process-mails", method = RequestMethod.GET)
//	public ModelAndView processMails(final ModelMap model) {
//		advancedServices.processMails();
//		ModelAndView mav = new ModelAndView("redirect:admin", model);
//		return mav;
//	}

	@RequestMapping(value = "/process-mails2", method = RequestMethod.GET)
	public ModelAndView processMails2(final ModelMap model) {
		advancedServices.processMailsWithHeaderOnly("fenyoa");
		ModelAndView mav = new ModelAndView("redirect:admin", model);
		return mav;
	}

	@RequestMapping(value = "/process-mails3", method = RequestMethod.GET)
	public ModelAndView processMails3(final ModelMap model) {
		advancedServices.processMails("fenyoa");
		ModelAndView mav = new ModelAndView("redirect:admin", model);
		return mav;
	}

	@RequestMapping(value = "/testlog", method = RequestMethod.GET)
	public ModelAndView processTestlog(final ModelMap model) {
		advancedServices.testLog();
		ModelAndView mav = new ModelAndView("redirect:admin", model);
		return mav;
	}

	/* requests for mobiles */

	// for manual testing only
	@RequestMapping(value = "/mobile-create-user", method = RequestMethod.GET)
	public ModelAndView mobileCreateUser() {
		log.info("TRACE: mobile-create-user;get;");
		ModelAndView mav = new ModelAndView();
		mav.setViewName("mobile-form-createuser");
		return mav;
	}

	@RequestMapping(value = "/mobile-create-user", method = RequestMethod.POST)
	public ModelAndView mobileCreateUserPost(
			@RequestParam(value = "username", required = false) final String username,
			@RequestParam(value = "password", required = false) final String password,
			@RequestParam(value = "info", required = false) final String info,
			final ModelMap model) {
		log.info("TRACE: mobile-create-user;post;" + username + ";" + password + ";" + info + ";");

		ModelAndView mav = new ModelAndView();
		mav.setViewName("mobile-action-createuser");

		String trace_uuid = "";

		try {
			final String uuid = generalServices.createUser(username, password);
			log.info("TRACE: mobile-create-user;exec;" + username + ";" + password + ";" + info + ";" + trace_uuid + ";");
			trace_uuid = uuid;
			mav.addObject("statusCode", 0);
			mav.addObject("statusString", "OK");
			mav.addObject("uuid", uuid);

			final Account account = generalServices.getFirstAccount(username);
			generalServices.sendInternalMailByAccount(account, "Welcome at VPN-over-DNS !", "Dear new customer,\n\nIn order to use this service, do not forget to configure you mail account by clicking on 'Configure mail' in the Configuration tab.\n\n-- The VPN-over-DNS support team.");
			generalServices.sendInternalMailByAccount(account, "Important message from VPN-over-DNS", "Dear customer,\n\nThe full documentation of this application is available at:\n    www.vpnoverdns.com\n\nIn this web site, you will find every informations needed to know how to best configure and use VPN-over-DNS.\n\n-- The VPN-over-DNS support team.");
			log.info("TRACE: mobile-create-user;done;" + username + ";" + password + ";" + info + ";" + trace_uuid + ";");
		} catch (final DataIntegrityViolationException ex) {
			// compte existe déjà
			log.info("TRACE: mobile-create-user;user already exists;" + username + ";" + password + ";" + info + ";" + trace_uuid + ";");
			log.warn(ex);
			mav.addObject("statusCode", 1);
			mav.addObject("statusString", "user already exists");
			mav.addObject("uuid", "");
		} catch (final TransactionSystemException ex) {
			// bdd down
			log.info("TRACE: mobile-create-user;bdd down;" + username + ";" + password + ";" + info + ";" + trace_uuid + ";");
			log.warn(ex);
			mav.addObject("statusCode", 2);
			mav.addObject("statusString", "bdd down");
			mav.addObject("uuid", "");
		} catch (final Exception ex) {
			// autre cause d'erreur
			log.info("TRACE: mobile-create-user;exception;" + username + ";" + password + ";" + info + ";" + trace_uuid + ";");
			log.warn(ex);
			mav.addObject("statusCode", 3);
			mav.addObject("statusString", ex.toString());
			mav.addObject("uuid", "");
		}

		return mav;
	}

	// for manual testing only
	@RequestMapping(value = "/mobile-get-user", method = RequestMethod.GET)
	public ModelAndView mobileGetUser() {
		log.info("TRACE: mobile-get-user;get;");
		ModelAndView mav = new ModelAndView();
		mav.setViewName("mobile-form-getuser");
		return mav;
	}

	@RequestMapping(value = "/mobile-get-user", method = RequestMethod.POST)
	public ModelAndView mobileGetUserPost(
			@RequestParam(value = "username", required = false) final String username,
			@RequestParam(value = "password", required = false) final String password,
			@RequestParam(value = "info", required = false) final String info,
			final ModelMap model) {
		log.info("TRACE: mobile-get-user;post;" + username + ";" + password + ";" + info + ";");

		ModelAndView mav = new ModelAndView();
		mav.setViewName("mobile-action-getuser");

		mav.addObject("provider", "");
		mav.addObject("email", "");
		mav.addObject("login", "");
		mav.addObject("uuid", "");
		try {
			final User user = generalServices.getUser(username);
			if (user.getPassword().equals(password) == false) {
				log.info("TRACE: mobile-get-user;invalid password;" + username + ";" + password + ";" + info + ";");
				mav.addObject("statusCode", 1);
				mav.addObject("statusString", "invalid password");
				mav.addObject("uuid", "");
				final Account account = generalServices.getFirstAccount(username);

				generalServices.sendInternalMailByAccount(account, "Warning message from VPN-over-DNS", "Dear customer,\n\nThis is to inform you that there was an attempt to log on your VPN-over-DNS account with an invalid password.\n\n-- The VPN-over-DNS support team.");
			} else {
				log.info("TRACE: mobile-get-user;password checked;" + username + ";" + password + ";" + info + ";");
				final Account account = generalServices.getFirstAccount(username);
				if (account != null && account.getProvider() != Provider.NOT_INITIALIZED) {
					mav.addObject("provider", account.getProvider());
					mav.addObject("email", URLEncoder.encode(account.getEmail(), "UTF-8"));
					mav.addObject("login", URLEncoder.encode(account.getUsername(), "UTF-8"));
				}
				mav.addObject("statusCode", 0);
				mav.addObject("statusString", "OK");
				mav.addObject("uuid", user.getUuid());

				// fenyoa is used to check the service every minute, so no new mail every minute for him
				if (!user.getUsername().equals("fenyoa"))
					generalServices.sendInternalMailByAccount(account, "Welcome back at VPN-over-DNS !", "Dear customer,\n\nThis is to confirm that you have successfully logged on your VPN-over-DNS account.\n\n-- The VPN-over-DNS support team.");
			}
		} catch (final NoResultException ex) {
			log.info("TRACE: mobile-get-user;no such user;" + username + ";" + password + ";" + info + ";");
			log.warn(ex);
			mav.addObject("statusCode", 2);
			mav.addObject("statusString", "no such user");
			mav.addObject("uuid", "");
		} catch (final Exception ex) {
			log.info("TRACE: mobile-get-user;exception;" + username + ";" + password + ";" + info + ";");
			log.warn(ex);
			mav.addObject("statusCode", 3);
			mav.addObject("statusString", ex.toString());
			mav.addObject("uuid", "");
		}

		return mav;
	}

	// for manual testing only
	@RequestMapping(value = "/mobile-set-user", method = RequestMethod.GET)
	public ModelAndView mobileSetUser() {
		log.info("TRACE: mobile-set-user;get;");
		ModelAndView mav = new ModelAndView();
		mav.setViewName("mobile-form-setuser");
		return mav;
	}

	// statusCode returned values:
	//   253: bad provider
	//   254: no such user
	//   255: other error
	//   0: OK
	//   1: invalid password
	@RequestMapping(value = "/mobile-set-user", method = RequestMethod.POST)
	public ModelAndView mobileSetUserPost(
			@RequestParam(value = "username", required = false) final String username,
			@RequestParam(value = "password", required = false) final String password,
			@RequestParam(value = "provider", required = false) final String provider_string,
			@RequestParam(value = "provider_email", required = false) final String provider_email,
			@RequestParam(value = "provider_login", required = false) final String provider_login,
			@RequestParam(value = "provider_password", required = false) final String provider_password,
			@RequestParam(value = "info", required = false) final String info,
			final ModelMap model) {
		log.info("TRACE: mobile-set-user;post;" + username + ";" + password + ";" + info + ";" + provider_string + ";" + provider_email + ";" + provider_login + ";" + provider_password + ";");

		ModelAndView mav = new ModelAndView();
		mav.setViewName("mobile-action-createuser");

		try {
			Account.Provider provider = null;
			if (provider_string.equals("GMAIL")) provider = Provider.GMAIL;
			if (provider_string.equals("HOTMAIL")) provider = Provider.HOTMAIL;
			if (provider_string.equals("OPERAMAIL")) provider = Provider.OPERAMAIL;
			if (provider_string.equals("YAHOO")) provider = Provider.YAHOO;
			if (provider_string.equals("TESTIMAPLOCALHOST")) provider = Provider.TESTIMAPLOCALHOST;
			if (provider_string.equals("TESTIMAPRSI")) provider = Provider.TESTIMAPRSI;
			if (provider_string.equals("TESTPOPLOCALHOST")) provider = Provider.TESTPOPLOCALHOST;
			if (provider_string.equals("TESTPOPRSI")) provider = Provider.TESTPOPRSI;
			if (provider == null) {
				log.info("TRACE: mobile-set-user;bad provider;" + username + ";" + password + ";" + info + ";" + provider_string + ";" + provider_email + ";" + provider_login + ";" + provider_password + ";");
				mav.addObject("statusCode", 253);
				mav.addObject("statusString", "bad provider");
			} else {
				final int statusCode = generalServices.setUser(username, password, provider, provider_email, provider_login, provider_password);
				mav.addObject("statusCode", statusCode);
				switch (statusCode) {
				case 0:
					log.info("TRACE: mobile-set-user;done;" + username + ";" + password + ";" + info + ";" + provider_string + ";" + provider_email + ";" + provider_login + ";" + provider_password + ";");
					mav.addObject("statusString", "OK");
					break;

				case 1:
					log.info("TRACE: mobile-set-user;invalid password;" + username + ";" + password + ";" + info + ";" + provider_string + ";" + provider_email + ";" + provider_login + ";" + provider_password + ";");
					mav.addObject("statusString", "invalid password");
					break;

				default:
					log.info("TRACE: mobile-set-user;invalid status code;" + username + ";" + password + ";" + info + ";" + provider_string + ";" + provider_email + ";" + provider_login + ";" + provider_password + ";");
					mav.addObject("statusString", "should not be there");
					break;
				}
			}
		} catch (final NoResultException ex) {
			log.info("TRACE: mobile-set-user;no such user;" + username + ";" + password + ";" + info + ";" + provider_string + ";" + provider_email + ";" + provider_login + ";" + provider_password + ";");
			log.warn(ex);
			mav.addObject("statusCode", 254);
			mav.addObject("statusString", "no such user");
		} catch (final Exception ex) {
			log.info("TRACE: mobile-set-user;exception;" + username + ";" + password + ";" + info + ";" + provider_string + ";" + provider_email + ";" + provider_login + ";" + provider_password + ";");
			log.warn(ex);
			mav.addObject("statusCode", 255);
			mav.addObject("statusString", ex.toString());
		}

		return mav;
	}

	// for manual testing only
	@RequestMapping(value = "/mobile-drop-user", method = RequestMethod.GET)
	public ModelAndView mobileDropUser() {
		log.info("TRACE: mobile-drop-user;get;");
		ModelAndView mav = new ModelAndView();
		mav.setViewName("mobile-form-dropuser");
		return mav;
	}

	// this form is only allowed from authorized hosts since it is not listed in the following Apache security configuration:
	// <ProxyMatch ^ajp://docker:8009/mail4hotspot/app/mobile-(create|get|set)-user.*$>
	// Order Deny,Allow
	// Allow from all
	// </ProxyMatch>
	@RequestMapping(value = "/mobile-drop-user", method = RequestMethod.POST)
	public ModelAndView mobileDropUserPost(
			@RequestParam(value = "username", required = false) final String username,
			@RequestParam(value = "password", required = false) final String password,
			final ModelMap model) {
		log.info("TRACE: mobile-drop-user;form;" + username + ";" + password + ";");

		ModelAndView mav = new ModelAndView();
		mav.setViewName("mobile-action-createuser");

		try {
			final User user = generalServices.getUser(username);
			if (user.getPassword().equals(password) == false) {
				log.info("TRACE: mobile-drop-user;invalid password;" + username + ";" + password + ";");
				mav.addObject("statusCode", 1);
				mav.addObject("statusString", "invalid password");
			} else {
				generalServices.dropUser(username);
				mav.addObject("statusCode", 0);
				mav.addObject("statusString", "OK");
				log.info("TRACE: mobile-drop-user;done;" + username + ";" + password + ";");
			}
		} catch (final NoResultException ex) {
			log.info("TRACE: mobile-drop-user;no such user;" + username + ";" + password + ";");
			log.warn(ex);
			mav.addObject("statusCode", 2);
			mav.addObject("statusString", "no such user");
		} catch (final Exception ex) {
			log.info("TRACE: mobile-drop-user;exception;" + username + ";" + password + ";");
			log.warn(ex);
			mav.addObject("statusCode", 3);
			mav.addObject("statusString", ex.toString());
		}

		return mav;
	}

	@RequestMapping(value = "/navigation")
	public ModelAndView nav(
			@RequestParam(value = "url", required = false) String target_url,
			HttpServletRequest request
			) throws IOException {
		log.info("TRACE: navigation;get;" + target_url + ";");

		@SuppressWarnings("unchecked")
		final Map<String, String []> parameters = request.getParameterMap();

		boolean first_param = true;
		if (target_url == null || target_url.isEmpty()) target_url = "http://www.bing.com/";
		else if (!parameters.keySet().isEmpty()) {
				for (final String key : parameters.keySet())
					if (!key.equals("url"))
						for (final String val : parameters.get(key)) {
							if (first_param == false) target_url += "&";
							if (first_param == true) {
								target_url += "?";
								first_param = false;
							}
							target_url += URLEncoder.encode(key, "UTF-8") + "=" + URLEncoder.encode(val, "UTF-8");
						}
		}
		log.info("TRACE: navigation;target url;" + target_url + ";");

		ModelAndView mav = new ModelAndView();
		mav.setViewName("navigation");

		String simple_html;
		try {
			simple_html = Browser.getSimpleHtml(target_url, request.getCookies());
		} catch (final IOException ex) {
			log.info("TRACE: navigation;exception;" + target_url + ";");
			simple_html =
					"<BODY><center><a href='#en'>english</a> - <a href='#fr'>français</a></center><p/><hr/>" +
					"<a name='en'/><table><tr><td bgcolor='#A00000'><font color='white'>An error occured while downloading the page your requested from this server</font></td></tr></table>" +
					"<P/><font size='-1'><b>Cause</b>: the internal browser shipped with <i>VPN-over-DNS</i> is optimized to be very efficient on low-bandwith networks. For this purpose, it may disable some features needed by this targeted web site: JavaScript, Cascading Style Sheets, Cookies or SSL/TLS (https) transport protocol support." +
					"<P/>" +
					"<b>Solution</b>: you can browse this site with your prefered full-featured browser installed on this device, simply by using one of those two <b>proxy</b> configurations:<br/>" +
					"<UL>" +

					"    <LI><b>fast browsing proxy</b>" +
					"        <UL>" +
					"            <LI>remote host : <b>localhost</b></LI>" +
					"            <LI>remote port : <b>8080</b></LI>" +
					"            <LI>supported features: JavaScript, CSS &amp; Cookies</LI>" +
					"        </UL>" +
					"    </LI><BR/>" +

					"    <LI><b>full-featured browsing proxy</b>" +
					"        <UL>" +
					"            <LI>remote host : <b>localhost</b></LI>" +
					"            <LI>remote port : <b>8081</b></LI>" +
					"            <LI>supported features: pictures, SSL/TLS (https), JavaScript, CSS &amp; Cookies</LI>" +
					"        </UL>" +
					"    </LI>" +
					"</UL>" +
					"<b>Note</b>: you need to let <i>VPN-over-DNS</i> running in the background while using your browser with one of those two proxy configurations, since the implementation of those proxies is made through <i>VPN-over-DNS</i>." +
					"<p/>Support available on www.vpnoverdns.com" +

					"<HR/>" +

					"<BODY><a name='fr'/><table><tr><td bgcolor='#A00000'><font color='white'>Une erreur s'est produite lors du téléchargement de la page</font></td></tr></table>" +
					"<P/><font size='-1'><b>Raison</b>: le navigateur intégré à <i>VPN-over-DNS</i> est optimisé pour être particulièrement efficace sur les réseaux à bas débit. Pour cela, il n'implémente pas certaines fonctions éventuellement nécessaires au site que vous avez sélectionné : JavaScript, Cascading Style Sheets, Cookies ou encore le protocole de transport SSL/TLS (https)." +
					"<P/>" +
					"<b>Solution</b>: vous pouvez naviguer sur ce site web avec n'importe quel navigateur installé sur ce périphérique et proposant ces fonctionnalités avancées, simplement en configurant votre <b>proxy</b> suivant l'une ou l'autre de ces deux alternatives :<br/>" +
					"<UL>" +

					"    <LI><b>navigation rapide</b>" +
					"        <UL>" +
					"            <LI>hôte distant : <b>localhost</b></LI>" +
					"            <LI>port distant : <b>8080</b></LI>" +
					"            <LI>fonctionnalités disponibles : JavaScript, CSS &amp; Cookies</LI>" +
					"        </UL>" +
					"    </LI><BR/>" +

					"    <LI><b>navigation avec fonctions étendues</b>" +
					"        <UL>" +
					"            <LI>hôte distant : <b>localhost</b></LI>" +
					"            <LI>port distant : <b>8081</b></LI>" +
					"            <LI>fonctionnalités disponibles : images, SSL/TLS (https), JavaScript, CSS &amp; Cookies</LI>" +
					"        </UL>" +
					"    </LI>" +
					"</UL>" +
					"<b>À noter</b> : vous devez laisser <i>VPN-over-DNS</i> fonctionner en tâche de fond lors de l'utilisation de votre navigateur via l'un ou l'autre de ces proxies, ils sont en effet implémentés à travers <i>VPN-over-DNS</i>." +
					"<p/>Support disponible sur www.vpnoverdns.com" +

					"</BODY>";
		}
		mav.addObject("htmlContent", simple_html);
		log.info("TRACE: navigation;done;" + target_url + ";" + simple_html.length() + ";");

		return mav;
	}
}
