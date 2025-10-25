package com.example.webapp;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.Properties;

/**
 * Sample servlet for CI/CD pipeline demonstration
 * Displays application version and environment information
 */
@WebServlet("/")
public class HelloServlet extends HttpServlet {
    
    private String appVersion;
    private String environment;
    
    @Override
    public void init() throws ServletException {
        super.init();
        // Load version from properties file
        try {
            Properties props = new Properties();
            props.load(getClass().getClassLoader().getResourceAsStream("version.properties"));
            appVersion = props.getProperty("VERSION", "unknown");
            environment = props.getProperty("ENVIRONMENT", "unknown");
        } catch (Exception e) {
            appVersion = "1.0.0-SNAPSHOT";
            environment = "development";
        }
    }
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        response.setContentType("text/html;charset=UTF-8");
        
        try (PrintWriter out = response.getWriter()) {
            out.println("<!DOCTYPE html>");
            out.println("<html>");
            out.println("<head>");
            out.println("<title>Sample Web Application</title>");
            out.println("<style>");
            out.println("body { font-family: Arial, sans-serif; margin: 50px; background-color: #f0f0f0; }");
            out.println(".container { background-color: white; padding: 30px; border-radius: 10px; box-shadow: 0 0 10px rgba(0,0,0,0.1); }");
            out.println("h1 { color: #333; }");
            out.println(".info { background-color: #e7f3ff; padding: 15px; border-left: 4px solid #2196F3; margin: 10px 0; }");
            out.println(".success { background-color: #d4edda; padding: 15px; border-left: 4px solid #28a745; margin: 10px 0; }");
            out.println("</style>");
            out.println("</head>");
            out.println("<body>");
            out.println("<div class='container'>");
            out.println("<h1>🚀 Sample Web Application</h1>");
            out.println("<div class='success'>");
            out.println("<h2>✅ Application is running successfully!</h2>");
            out.println("</div>");
            out.println("<div class='info'>");
            out.println("<h3>Application Information:</h3>");
            out.println("<p><strong>Version:</strong> " + appVersion + "</p>");
            out.println("<p><strong>Environment:</strong> " + environment + "</p>");
            out.println("<p><strong>Server:</strong> " + getServletContext().getServerInfo() + "</p>");
            out.println("<p><strong>Build Time:</strong> " + new java.util.Date() + "</p>");
            out.println("</div>");
            out.println("<div class='info'>");
            out.println("<h3>CI/CD Pipeline Features:</h3>");
            out.println("<ul>");
            out.println("<li>✅ Automated build with Maven</li>");
            out.println("<li>✅ Unit tests execution</li>");
            out.println("<li>✅ SonarQube code quality analysis</li>");
            out.println("<li>✅ Security scanning (password detection)</li>");
            out.println("<li>✅ Artifact versioning and storage in Nexus</li>");
            out.println("<li>✅ Environment-specific configuration</li>");
            out.println("<li>✅ Automated deployment to WildFly/JBoss</li>");
            out.println("</ul>");
            out.println("</div>");
            out.println("</div>");
            out.println("</body>");
            out.println("</html>");
        }
    }
}
