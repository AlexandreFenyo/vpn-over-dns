<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<%@ page language="java" contentType="text/html; charset=ISO-8859-1" pageEncoding="ISO-8859-1" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1">
<title>Insert title here</title>
</head>
<body>

<a HREF="testlog">générer des logs</a><BR/>

<a HREF="create-account">création d'un Account</a><BR/>

<a HREF="drop-account">suppression d'un Account</a><BR/>
<a HREF="drop-user">suppression d'un User</a><BR/>
<a HREF="create-user">Création d'un User</a><BR/>

<a HREF="create-initial-users">Peuplement des utilisateurs initiaux</a><BR/>
<a HREF="create-initial-ips">Peuplement des IPs initiales</a><BR/>
<a HREF="create-default">Peuplement des comptes de test</a><BR/>

<!-- <a HREF="process-mails">Lancer le traitement des mails</a><BR/> -->
<a HREF="process-mails2">Lancer le traitement initial des mails pour fenyo (headers only)</a><BR/>
<a HREF="process-mails3">Lancer le traitement récurrent des mails pour fenyo (with headers)</a><BR/>

<HR>
Liste des 100 premiers utilisateurs :<BR/>
<c:forEach items="${userList}" var="user">
		username=[${user.username}] - uuid=[${user.uuid}]
		<br />
</c:forEach>

</body>
</html>
