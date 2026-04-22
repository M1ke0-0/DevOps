from fastapi import APIRouter

from routers.system import router as system

router = APIRouter(prefix="/api/v1")
router.include_router(system, prefix="/system", tags=["System"])
