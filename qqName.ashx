<%@ WebHandler Language="C#" Class="QqName" %>
using System.Web;
using System.Net;
using System.Text;
using System.Text.RegularExpressions;

public class QqName : IHttpHandler {
public bool IsReusable { get { return false; } }
public void ProcessRequest (HttpContext context) {
HttpResponse Response = context.Response; HttpRequest Request = context.Request; Response.ContentType = "application/json";

string qq = Request.Unvalidated.QueryString["qq"], err = "{\"code\": 1, \"msg\": \"QQ 号码应为5-13位数字！\"}", result;
Regex qqNum = new Regex(@"^\d{5,13}$");
if (qq == "" || qq == null) {
	result = err;
} else if (!qqNum.IsMatch(qq)) {
	result = err;
} else {
	WebClient wc = new WebClient() { Encoding = Encoding.UTF8, BaseAddress = "https://api.unipay.qq.com/v1/r/1450000186/wechat_query?cmd=1&pf=mds_storeopen_qb-__mds_qqclub_tab_-html5&pfkey=pfkey&from_h5=1&from_https=1&openid=openid&openkey=openkey&session_id=hy_gameid&session_type=st_dummy&offerId=1450000186&provide_uin=" + qq };
	try {
		result = wc.DownloadString(wc.BaseAddress); Regex p = new Regex(@"""nick"" ?: ?""([\d%A-Za-z\-_.]+?)""");
		string name = HttpUtility.UrlDecode(p.Match(result).Groups[1].ToString()).Replace(@"\",@"\\").Replace("\"",@"\""");
		result = (p.IsMatch(result))?("{\"code\": 0, \"name\": \"" + name + "\", \"qq\": " + qq + "}"):("{\"code\": 2, \"msg\": \"无此 QQ 账号！\"}");
	} catch { result = "{\"code\": 3, \"msg\": \"无法连接 QQ API 服务器！\"}"; } finally { wc.Dispose(); }
}
Response.Write(result);

}
}