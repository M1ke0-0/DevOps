from typing import List

from fastapi import APIRouter

from schemas.system import SystemInfo, Filter
from utils.system import (get_system_info,
                          get_cpu_info,
                          get_memory_info,
                          get_disk_usage)

router = APIRouter()


@router.post("/info", response_model=SystemInfo)
async def system_info(filters: List[Filter]):
    if filters == []:
        return SystemInfo(
            system=get_system_info(),
            cpu=get_cpu_info(),
            memory=get_memory_info(),
            disk=get_disk_usage()
        )
    filters = set(filters)
    return SystemInfo(
        system=None if Filter.system not in filters else get_system_info(),
        cpu=None if Filter.cpu not in filters else get_cpu_info(),
        memory=None if Filter.memory not in filters else get_memory_info(),
        disk=None if Filter.disk not in filters else get_disk_usage()
    )
