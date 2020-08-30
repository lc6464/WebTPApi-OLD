<%@ WebHandler Language="C#" Class="BiliVideoInfo" %>
using System.Web;
using System.Net;
using System.Text.RegularExpressions;

public class BiliVideoInfo : IHttpHandler {
public bool IsReusable { get { return false; } }
public void ProcessRequest (HttpContext context) {
HttpResponse Response = context.Response; HttpRequest Request = context.Request; Response.ContentType = "application/json";

string vid = Request.Unvalidated.QueryString["vid"]; Regex p = new Regex(@"^(av(\d+)|BV[A-Za-z0-9]+)$");
if (p.IsMatch(vid)) {
	string m = p.Match(vid).ToString(), q = (m.Substring(0, 2) == "av")?("aid=" + m.Substring(2)):("bvid=" + m); q = "https://api.bilibili.com/x/web-interface/archive/stat?" + q;
	WebClient wc = new WebClient();
	try {
		Response.BinaryWrite(wc.DownloadData(q));
	} catch {
		Response.Write("{\"code\": 1, \"message\": \"无法连接哔哩哔哩服务器\"}");
	} finally {
		wc.Dispose();
	}
} else {
	Response.Write("{\"code\": 2, \"message\": \"请求错误\"}");
}

}
}