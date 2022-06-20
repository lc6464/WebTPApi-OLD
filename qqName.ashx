<%@ WebHandler Language="C#" Class="QqName" %>
using System;
using System.Web;
using System.Net.Http;
using System.Text;
using System.Text.RegularExpressions;

public class QqName : IHttpHandler {
public bool IsReusable { get { return false; } }
public void ProcessRequest (HttpContext context) {
HttpResponse Response = context.Response; HttpRequest Request = context.Request; Response.ContentType = "application/json";

string qq = Request.QueryString["qq"], result;
Regex qqNum = new Regex(@"^\d{5,13}$");

if (qq == null || qq == "") {
	result = "{\"code\":4,\"msg\":\"未传入 QQ 号或 QQ 号为空！\"}";
} else if (!qqNum.IsMatch(qq)) {
	result = "{\"code\":1,\"msg\":\"QQ 号应为5-13位数字！\"}";
} else {
	var hc = new HttpClient() { Timeout = new TimeSpan(0, 0, 5), BaseAddress = new Uri("https://r.qzone.qq.com/fcg-bin/cgi_get_portrait.fcg") };
	try {
		var task = hc.GetByteArrayAsync("?uins=" + qq);
		task.Wait();
		result = Encoding.GetEncoding("GB18030").GetString(task.Result);
		Regex head = new Regex(@$"portraitCallBack\(\{{""{ qq }"":\[""http://qlogo\d\d?\.store\.qq\.com/qzone/{ qq }/{ qq }/100"",((\-)?\d{{1,8}},){{5}}""");
		if (head.IsMatch(result)) {
			result = Regex.Replace(Regex.Replace(result, head.ToString(), ""), @""",(\-)?\d{1,8}\]\}\)", "");
			result = HttpUtility.HtmlDecode(result).Replace(@"\",@"\\").Replace("\"",@"\""");
			result = $"{{\"code\":0,\"name\":\"{ result }\"}}";
		} else {
			result = "{\"code\":2,\"msg\":\"无此 QQ 账号！\"}";
		}
		if (Request.QueryString["debug"] == "true") Response.AppendHeader("X-API-Return", Encoding.GetEncoding("GB18030").GetString(task.Result));
	} catch { result = "{\"code\":3,\"msg\":\"无法连接 QQ API 服务器！\"}"; } finally { hc.Dispose(); }
}
Response.Write(result);

}
}