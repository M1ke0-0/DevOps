package tech.pndsdn.java.model;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class SystemInfo {
    private String nameOS;
    private String versionOS;
    private String arhitectureOS; 
}
