<%@ WebHandler Language="C#" Class="BingImage" %>
using System.Web;
using System.Net;
using System.Xml;
using System.Text.RegularExpressions;

public class BingImage : IHttpHandler {
public bool IsReusable { get { return false; } }
public void ProcessRequest (HttpContext context) {
HttpResponse Response = context.Response; HttpRequest Request = context.Request; Response.ContentType = "application/json";

string idx = Request.Unvalidated.QueryString["idx"], err = "{\"msg\":\"参数 idx 仅能为0-7之间的整数\",\"err\":1}", type = Request.Unvalidated.QueryString["type"];
Regex idxR = new Regex(@"^[0-7]$");
if (idx == null) { idx = "0"; }
if (idx == "") {
	Response.Write(err);
} else if (!idxR.IsMatch(idx)) {
	Response.Write(err);
} else {
	try {
		using (XmlReader reader = XmlReader.Create("https://cn.bing.com/HPImageArchive.aspx?n=1&idx=" + idx)) {
			while (reader.Read()) {
				if(reader.NodeType == XmlNodeType.Element) {
					if(reader.Name == "url") {
						if (reader.Read()) {
							string result = "https://cn.bing.com"+reader.Value;
							if (type == "download") {
								WebClient wc = new WebClient();
								try {
									Response.BinaryWrite(wc.DownloadData(result)); Response.ContentType = "image/jpeg";
								} catch {
									Response.Write("{\"msg\":\"连接必应服务器发生错误！\",\"err\":2}");
								} finally {
									wc.Dispose();
								}
							} else if (type == "text") {
								Response.ContentType = "text/plain"; Response.Write(result);
							} else {
								Response.Redirect(result);
							}
							break;
						}
					}
				}
			}
		}
	} catch {
		Response.Write("{\"msg\":\"连接必应服务器发生错误！\",\"err\":2}");
	}
}

}
}