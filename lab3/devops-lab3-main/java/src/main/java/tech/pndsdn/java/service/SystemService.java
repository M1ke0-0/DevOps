package tech.pndsdn.java.service;

import org.springframework.stereotype.Service;

import tech.pndsdn.java.model.SystemInfo;;

@Service
public class SystemService {
    private final SystemInfo systemInfo = SystemInfo.builder()
        .nameOS(System.getProperty("os.name"))
        .versionOS(System.getProperty("os.version"))
        .arhitectureOS(System.getProperty("os.arch"))
        .build();

    public SystemInfo getSystemInfo() {
        return systemInfo;
    }
}
