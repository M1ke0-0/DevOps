package tech.pndsdn.java.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import lombok.AllArgsConstructor;
import tech.pndsdn.java.model.SystemInfo;
import tech.pndsdn.java.service.SystemService;


@RestController
@RequestMapping("/api/v1/system")
@AllArgsConstructor
public class SystemController {

    private final SystemService service;
    
    @GetMapping
    public SystemInfo getSystemInfo() {
        return service.getSystemInfo();
    }
}
