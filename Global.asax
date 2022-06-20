<%@ Application Language="C#" %>
<script runat="server">
	//void Application_Start(object sender, EventArgs e) { // 在应用程序启动时运行的代码

	//}

	//void Application_End(object sender, EventArgs e) { //  在应用程序关闭时运行的代码

	//}

	//void Application_Error(object sender, EventArgs e) { // 在出现未处理的错误时运行的代码

	//}

	void Application_PreSendRequestHeaders() {
		Response.Charset = "utf-8";
		var origin = Request.Headers["Origin"];
		if (!string.IsNullOrWhiteSpace(origin) && new Regex(@"^https://([A-Za-z\d\-.]*\.)?lcwebsite.cn(\:\d{1,5})?/?$").IsMatch(origin)) {
			Response.AppendHeader("Access-Control-Allow-Origin", origin);
		}
	}

	//void Session_Start(object sender, EventArgs e) { // 在新会话启动时运行的代码

	//}

	//void Session_End(object sender, EventArgs e) { // 在会话结束时运行的代码。 只有 sessionstate 设置为 InProc 时，才会引发 Session_End 事件。

	//}
</script>