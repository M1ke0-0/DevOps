from typing import List
import platform

import psutil

from schemas.system import System, CPU, Memory, Disk, Core, Swap, Partition


def get_size(bytes, suffix="B") -> str:
    factor = 1024
    for unit in ["", "K", "M", "G", "T", "P"]:
        if bytes < factor:
            return f"{bytes:.2f}{unit}{suffix}"
        bytes /= factor


def get_system_info() -> System:
    uname = platform.uname()
    return System(
        system=uname.system,
        node=uname.node,
        release=uname.release,
        version=uname.version,
        machine=uname.machine,
        processor=uname.processor
    )


def get_cpu_info() -> CPU:
    cpu_usage_per_core: List[Core] = []
    for i, percentage in enumerate(psutil.cpu_percent(percpu=True, interval=1)):
        cpu_usage_per_core.append(Core(core=i, percentage=f"{percentage}%"))
    cpufreq = psutil.cpu_freq()
    return CPU(
        physical_cores=psutil.cpu_count(logical=False),
        total_cores=psutil.cpu_count(logical=True),
        max_freq=f"{cpufreq.max:.2f}Mhz",
        min_freq=f"{cpufreq.min:.2f}Mhz",
        current_freq=f"{cpufreq.current:.2f}Mhz",
        cpu_usage_per_core=cpu_usage_per_core,
        total_cpu_usage=f"{psutil.cpu_percent()}%"
    )


def get_memory_info() -> Memory:
    svmem = psutil.virtual_memory()
    swap = psutil.swap_memory()
    return Memory(
        total=get_size(svmem.total),
        available=get_size(svmem.available),
        used=get_size(svmem.used),
        percentage=f"{svmem.percent}%",
        swap=Swap(
            total=get_size(swap.total),
            free=get_size(swap.free),
            used=get_size(swap.used),
            percentage=f"{swap.percent}%"
        )
    )


def get_disk_usage() -> Disk:
    partitions: List[Partition] = []
    parts = psutil.disk_partitions()
    for part in parts:
        device = part.device
        mountpoint = part.mountpoint
        fstype = part.fstype
        total = None
        used = None
        free = None
        percentage = None

        try:
            partition_usage = psutil.disk_usage(part.mountpoint)
            total = get_size(partition_usage.total)
            used = get_size(partition_usage.used)
            free = get_size(partition_usage.free)
            percentage = f"{partition_usage.percent}%"
        except PermissionError:
            pass

        partitions.append(Partition(
            device=device,
            mountpoint=mountpoint,
            fstype=fstype,
            total=total,
            used=used,
            free=free,
            percentage=percentage
        ))
    
    disk_io = psutil.disk_io_counters()
    return Disk(
        partitions=partitions,
        total_read=get_size(disk_io.read_bytes),
        total_write=get_size(disk_io.write_bytes)
    )