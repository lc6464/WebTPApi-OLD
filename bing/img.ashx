<%@ WebHandler Language="C#" Class="BingImage" %>
using System;
using System.IO;
using System.Web;
using System.Net.Http;
using System.Xml;

public class BingImage : IHttpHandler {
	public bool IsReusable { get { return false; } }
	public void ProcessRequest(HttpContext context) {
		HttpResponse Response = context.Response; HttpRequest Request = context.Request; HttpServerUtility Server = context.Server;
		Response.ContentType = "application/json"; // 准备工作

		string idxs = Request.Unvalidated.QueryString["idx"];
		uint idx = 0;
		if (string.IsNullOrWhiteSpace(idxs) || (uint.TryParse(idxs, out idx) && idx < 8)) { // idx 是否正确
			Response.Headers.Remove("Cache-Control"); // 缓存控制响应头
			var now = DateTime.Now; // 当前时间
			Response.AppendHeader("Cache-Control", "private,max-age=" + (int)(now.AddDays(1).Date - now).TotalSeconds); // 缓存时间
			string url, filePath = Server.MapPath("cache/" + now.AddDays(-idx).ToString("yyyyMMdd")); // 声明变量及获取服务器缓存文件名

			if (File.Exists(filePath)) { // 判断服务器缓存文件是否存在
				try { // 尝试读取缓存文件
					url = File.ReadAllText(filePath); // 赋值
					if (string.IsNullOrWhiteSpace(url)) { // 若缓存文件为空
						Response.AppendHeader("X-API-CacheFile-Empty", "True"); // X-API-缓存文件-空
						url = GetURLAndWriteFile(idx, filePath, Response); // 重新获取并写入
					}
				} catch { // 若读取失败
					Response.AppendHeader("X-API-Read-CacheFile-Error", "True"); // X-API-读取-缓存文件-出错
					url = GetURLAndWriteFile(idx, filePath, Response); // 重新获取并写入
				}
			} else { // 若不存在
				Response.AppendHeader("X-API-No-CacheFile", "True"); // X-API-无-缓存文件
				url = GetURLAndWriteFile(idx, filePath, Response); // 获取并写入
			}


			string type = Request.Unvalidated.QueryString["type"]; // 输出类型
			if (string.IsNullOrWhiteSpace(type)) { // 默认
				Response.Redirect(url); // 重定向
			} else if (type == "json") { // 返回 JSON
				Response.Write($"{{\"url\":\"{url}\",\"code\":0}}");
			} else if (type == "text") { // 返回纯文本
				Response.ContentType = "text/plain";
				Response.Write(url);
			} else if (type == "download") { // 下载并输出
				var hc = new HttpClient();
				try {
					var task = hc.GetByteArrayAsync(url); // 下载
					Response.ContentType = "image/jpeg";
					task.Wait(); // 等待下载完成
					Response.BinaryWrite(task.Result); // 输出
				} catch {
					Response.Headers.Remove("Cache-Control"); // 改缓存
					Response.AppendHeader("Cache-Control", "no-cache");
					Response.Write("{\"message\":\"下载图片失败！\",\"code\":3}");
				} finally {
					hc.Dispose();  // 释放资源
				}
			} else { // 默认
				Response.Redirect(url);
			}
		} else { // idx 有误
			Response.Write("{\"message\":\"参数 idx 仅能为 0~7 之间的整数！\",\"code\":1}");
		}
	}

	private static string GetURL(uint idx) { // 获取 URL
		try { // 下载 XML 并读取
			using XmlReader reader = XmlReader.Create("https://cn.bing.com/HPImageArchive.aspx?n=1&idx=" + idx);
			while (reader.Read()) {
				if(reader.NodeType == XmlNodeType.Element) {
					if(reader.Name == "url") {
						if (reader.Read()) {
							return "https://cn.bing.com"+reader.Value; // 返回 url
						}
					}
				}
			}
			return null; // 若读不到
		} catch { // 若下载失败或解析失败
			return "Error";
		}
	}

	private static string GetURLAndWriteFile(uint idx, string filePath, HttpResponse Response) { // 获取 URL 并写入缓存文件
		string url = GetURL(idx); // 获取
		if (string.IsNullOrWhiteSpace(url) || url == "Error") { // 空，null 或 Error？
			Response.Headers.Remove("Cache-Control"); // 改缓存
			Response.AppendHeader("Cache-Control", "no-cache");
			Response.ClearContent(); // 改内容
			Response.Write("{\"message\":\"连接必应服务器发生错误或 XML 解析错误！\",\"code\":2}");
			Response.End(); // 终止
		} else { // 正常
			try { // 试图写入缓存文件
				File.WriteAllText(filePath, url);
			} catch {
				Response.AppendHeader("X-API-Write-CacheFile-Error", "True"); // X-API-写入-缓存文件-出错
			}
		}
		return url; // 返回 url
	}
}