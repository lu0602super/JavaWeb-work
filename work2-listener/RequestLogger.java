package gzu.com.work2demo;

import jakarta.servlet.ServletRequestEvent;
import jakarta.servlet.ServletRequestListener;
import jakarta.servlet.annotation.WebListener;
import jakarta.servlet.http.HttpServletRequest;
import java.text.SimpleDateFormat;
import java.util.Date;

@WebListener
public class RequestLogger implements ServletRequestListener {

    private static final SimpleDateFormat DATE_FORMAT = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");

    @Override
    public void requestDestroyed(ServletRequestEvent sre) {
        long endTime = System.currentTimeMillis();
        long processingTime = endTime - (Long) sre.getServletRequest().getAttribute("startTime");
        logRequestDetails(sre, endTime, processingTime);
    }

    @Override
    public void requestInitialized(ServletRequestEvent sre) {
        sre.getServletRequest().setAttribute("startTime", System.currentTimeMillis());
    }

    private void logRequestDetails(ServletRequestEvent sre, long endTime, long processingTime) {
        var request = sre.getServletRequest();
        HttpServletRequest httpRequest = (HttpServletRequest) request;

        // 只记录对 /test 路径的请求
        if (!httpRequest.getRequestURI().endsWith("/test")) {
            return;
        }

        String timestamp = DATE_FORMAT.format(new Date(endTime));
        String remoteAddr = httpRequest.getRemoteAddr();
        String method = httpRequest.getMethod();
        String uri = httpRequest.getRequestURI();
        String query = httpRequest.getQueryString() != null ? httpRequest.getQueryString() : "";
        String userAgent = httpRequest.getHeader("User-Agent");
        String processingTimeMs = String.valueOf(processingTime);

        // 使用 System.out.println 打印日志
        System.out.println("时间戳: " + timestamp);
        System.out.println("客户端IP: " + remoteAddr);
        System.out.println("请求方法: " + method);
        System.out.println("请求URI: " + uri);
        System.out.println("查询字符串: " + query);
        System.out.println("User-Agent: " + userAgent);
        System.out.println("处理时间(ms): " + processingTimeMs);
    }
}