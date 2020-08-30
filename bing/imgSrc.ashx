<%@ WebHandler Language="C#" Class="BingImage" %>
using System.Web;
using System.Net;
using System.Text;
using System.Text.RegularExpressions;

public class BingImage : IHttpHandler {
public bool IsReusable { get { return false; } }
public void ProcessRequest (HttpContext context) {
HttpResponse Response = context.Response; HttpRequest Request = context.Request; Response.ContentType = "application/xml";

string idx = Request.Unvalidated.QueryString["idx"], n = Request.Unvalidated.QueryString["n"], err = "<result><msg>参数 idx 仅能为0-7之间的整数，n 仅能为1-8之间的整数</msg><err>1</err></result>";
Regex idxR = new Regex(@"^[0-7]$"); Regex nR = new Regex(@"^[1-8]$");
if (idx == null) { idx = "0"; }
if (n == null) { n = "1"; }
if (idx == "") {
	Response.Write(err);
} else if (!idxR.IsMatch(idx)) {
	Response.Write(err);
} else if (n == "") {
	Response.Write(err);
} else if (!nR.IsMatch(n)) {
	Response.Write(err);
} else {
	WebClient wc = new WebClient() { Encoding = Encoding.UTF8 };
	try {
		string result = wc.DownloadString("https://cn.bing.com/HPImageArchive.aspx?n=" + n + "&idx=" + idx);
		result = result.Replace("<tooltips><loadMessage><message>正在加载...</message></loadMessage><previousImage><text>上一个图像</text></previousImage><nextImage><text>下一个图像</text></nextImage><play><text>播放视频</text></play><pause><text>暂停视频</text></pause></tooltips>","").Replace("<headline></headline><drk>1</drk><top>1</top><bot>1</bot><hotspots></hotspots>","");
		result = Regex.Replace(Regex.Replace(Regex.Replace(result,@"<fullstartdate>\d{12}</fullstartdate>",""),@"<urlBase>/th\?id=OHR\.[%A-Za-z0-9\-_\+\.]+?</urlBase>",""),@"<url>(/th\?id=OHR\.[%A-Za-z0-9\-_\+\.]+?\.jpg&amp;rf=LaDigue_1920x1080.jpg&amp;pid=hp)</url>","<url>https://www.bing.com${1}</url>");
		Response.Write(Regex.Replace(result,@"<copyrightlink>https://www\.bing\.com/search\?q=[%A-Za-z0-9\+\-_\.]+?&amp;form=hpcapt&amp;mkt=zh-cn</copyrightlink>",""));
	} catch {
		Response.Write("<result><msg>连接必应服务器发生错误！</msg><err>2</err></result>");
	} finally {
		wc.Dispose();
	}
}

}
}