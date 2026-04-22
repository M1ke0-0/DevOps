from typing import List, Optional
import enum

from pydantic import BaseModel

class Filter(enum.StrEnum):
    system = "system"
    cpu = "cpu"
    memory = "memory"
    disk = "disk"


class System(BaseModel):
    system: str
    node: str
    release: str
    version: str
    machine: str
    processor: str


class Core(BaseModel):
    core: int
    percentage: str


class CPU(BaseModel):
    physical_cores: int
    total_cores: int
    max_freq: str
    min_freq: str
    current_freq: str
    cpu_usage_per_core: List[Core]
    total_cpu_usage: str


class Swap(BaseModel):
    total: str
    free: str
    used: str
    percentage: str


class Memory(BaseModel):
    total: str
    available: str
    used: str
    percentage: str
    swap: Swap


class Partition(BaseModel):
    device: str
    mountpoint: str
    fstype: str
    total: Optional[str]
    used: Optional[str]
    free: Optional[str]
    percentage: Optional[str]


class Disk(BaseModel):
    partitions: List[Partition]
    total_read: str
    total_write: str


class SystemInfo(BaseModel):
    system: Optional[System]
    cpu: Optional[CPU]
    memory: Optional[Memory]
    disk: Optional[Disk]