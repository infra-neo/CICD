package com.example.webapp;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

/**
 * Unit tests for HelloServlet
 */
public class HelloServletTest {
    
    @Test
    public void testServletExists() {
        HelloServlet servlet = new HelloServlet();
        assertNotNull(servlet, "Servlet should not be null");
    }
    
    @Test
    public void testApplicationLogic() {
        // Add your business logic tests here
        assertTrue(true, "Sample test should pass");
    }
    
    @Test
    public void testVersionFormat() {
        String version = "1.0.0-SNAPSHOT";
        assertTrue(version.contains("SNAPSHOT") || version.matches("\\d+\\.\\d+\\.\\d+"),
                "Version should be in valid format");
    }
}
