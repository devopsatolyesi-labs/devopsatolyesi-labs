package com.devopsatolyesi;

import com.sun.net.httpserver.HttpServer;
import com.sun.net.httpserver.HttpHandler;
import com.sun.net.httpserver.HttpExchange;
import java.io.IOException;
import java.io.OutputStream;
import java.net.InetSocketAddress;

public class Application {
    public static void main(String[] args) throws IOException {
        int port = 8080;
        HttpServer server = HttpServer.create(new InetSocketAddress(port), 0);
        server.createContext("/", new HttpHandler() {
            @Override
            public void handle(HttpExchange exchange) throws IOException {
                long maxMemoryMb = Runtime.getRuntime().maxMemory() / (1024 * 1024);
                long totalMemoryMb = Runtime.getRuntime().totalMemory() / (1024 * 1024);
                String response = "{\n" +
                    "  \"status\": \"UP\",\n" +
                    "  \"service\": \"spring-boot-demo\",\n" +
                    "  \"runtime\": \"Java 17 JRE Hardened\",\n" +
                    "  \"jvm_max_heap_mb\": " + maxMemoryMb + ",\n" +
                    "  \"jvm_total_heap_mb\": " + totalMemoryMb + "\n" +
                    "}\n";
                exchange.getResponseHeaders().set("Content-Type", "application/json");
                exchange.sendResponseHeaders(200, response.getBytes().length);
                OutputStream os = exchange.getResponseBody();
                os.write(response.getBytes());
                os.close();
            }
        });
        System.out.println("Spring Boot Microservice started on port " + port);
        server.start();
    }
}
