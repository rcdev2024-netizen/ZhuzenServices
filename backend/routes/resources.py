from datetime import datetime, timezone
from typing import Annotated, Any

from fastapi import APIRouter, Depends, HTTPException, Query, status

from backend.db import RepositoryError, SupabaseRepository
from backend.dependencies import current_claims, get_repository
from backend.schemas import ActionPayload, ResourcePayload

router = APIRouter(tags=["Operations"])

# These resources are exposed as first-class API collections. Every business
# resource maps to its own Supabase table; resource_records remains available
# for ad hoc timeline and activity entries.
RESOURCE_TABLES: dict[str, str] = {
    "users": "users",
    "roles": "roles",
    "customers": "customers",
    "assets": "assets",
    "resource-records": "resource_records",
    "service-requests": "service_requests",
    "job-orders": "job_orders",
    "warranties": "warranties",
    "diagnostics": "diagnostics",
    "quotations": "quotations",
    "parts": "parts",
    "purchase-orders": "purchase_orders",
    "suppliers": "suppliers",
    "repairs": "repairs",
    "qc-checklists": "qc_checklists",
    "qc": "qc_checklists",
    "customer-signatures": "customer_signatures",
    "projects": "projects",
    "site-surveys": "site_surveys",
    "material-preparations": "material_preparations",
    "technicians": "technicians",
    "assignments": "assignments",
    "installations": "installations",
    "commissioning": "commissioning",
    "punch-lists": "punch_lists",
    "service-partners": "service_partners",
    "partner-requests": "partner_requests",
    "schedules": "schedules",
    "calendar": "calendar_events",
    "service-reports": "service_reports",
    "uploads": "uploads",
    "attachments": "attachments",
    "invoices": "invoices",
    "payments": "payments",
    "service-income": "service_income",
    "incentives": "incentives",
    "customer-feedback": "customer_feedback",
    "performance": "performance_metrics",
    "dashboard": "dashboard_snapshots",
    "reports": "report_runs",
}

RESOURCES = {
    *RESOURCE_TABLES.keys(),
}

ACTION_STATUS: dict[str, str] = {
    "assign": "assigned",
    "cancel": "cancelled",
    "close": "closed",
    "start": "in_progress",
    "complete": "completed",
    "submit": "submitted",
    "approve": "approved",
    "reject": "rejected",
    "pause": "paused",
    "receive": "received",
    "void": "voided",
    "resolve": "resolved",
    "fail": "failed",
    "pass": "passed",
    "customer-signoff": "signed",
    "photos": "attached",
    "attachments": "attached",
}


def table_for(resource: str) -> str:
    if resource in RESOURCE_TABLES:
        return RESOURCE_TABLES[resource]
    if resource not in RESOURCES:
        raise HTTPException(status_code=404, detail=f"Unknown resource: {resource}")
    return "resource_records"


def _generic_payload(resource: str, payload: dict[str, Any], user_id: str | None) -> dict[str, Any]:
    if resource in {"users", "roles", "customers", "assets", "resource-records"}:
        return payload
    return {
        "data": payload,
        "created_by": user_id,
        "status": payload.get("status", "draft"),
    }


def _safe_row(resource: str, row: dict[str, Any]) -> dict[str, Any]:
    if resource == "users":
        return {key: value for key, value in row.items() if key != "password_hash"}
    return row


SPECIAL_COLLECTIONS = {
    ("technicians", "availability"),
    ("technicians", "workload"),
    ("service-income", "summary"),
    ("service-income", "monthly"),
    ("service-income", "by-type"),
    ("performance", "dashboard"),
    ("performance", "technicians"),
    ("performance", "customer-ratings"),
    ("performance", "on-time-completion"),
    ("performance", "repeat-callbacks"),
    ("performance", "warranty-returns"),
    ("performance", "income-generated"),
    ("dashboard", "overview"),
    ("dashboard", "jobs"),
    ("dashboard", "projects"),
    ("dashboard", "revenue"),
    ("dashboard", "incentives"),
    ("dashboard", "performance"),
    ("reports", "service-income"),
    ("reports", "job-orders"),
    ("reports", "projects"),
    ("reports", "inventory"),
    ("reports", "technician-performance"),
    ("reports", "incentives"),
    ("reports", "customer-feedback"),
    ("reports", "export"),
}


@router.get("/{resource}")
async def list_resource(
    resource: str,
    claims: Annotated[dict[str, Any], Depends(current_claims)],
    repo: Annotated[SupabaseRepository, Depends(get_repository)],
    limit: int = Query(default=50, ge=1, le=200),
    status_filter: str | None = Query(default=None, alias="status"),
):
    table = table_for(resource)
    filters: dict[str, Any] = {}
    if resource == "resource-records":
        filters["resource_type"] = resource
    if status_filter:
        filters["status"] = status_filter
    try:
        rows = await repo.select(table, filters=filters, limit=limit)
    except RepositoryError as exc:
        raise HTTPException(status_code=502, detail=str(exc)) from exc
    safe_rows = [_safe_row(resource, row) for row in rows]
    return {"items": safe_rows, "count": len(safe_rows), "resource": resource}


@router.post("/{resource}", status_code=status.HTTP_201_CREATED)
async def create_resource(
    resource: str,
    payload: ResourcePayload,
    claims: Annotated[dict[str, Any], Depends(current_claims)],
    repo: Annotated[SupabaseRepository, Depends(get_repository)],
):
    table = table_for(resource)
    record = _generic_payload(resource, payload.data, str(claims["sub"]))
    if resource == "users":
        password = record.pop("password", None)
        if not password:
            raise HTTPException(status_code=400, detail="A password is required when creating a user.")
        from backend.security import hash_password

        record["password_hash"] = hash_password(password)
    try:
        return _safe_row(resource, await repo.insert(table, record))
    except RepositoryError as exc:
        raise HTTPException(status_code=502, detail=str(exc)) from exc


@router.get("/{resource}/{record_id}")
async def get_resource(
    resource: str,
    record_id: str,
    claims: Annotated[dict[str, Any], Depends(current_claims)],
    repo: Annotated[SupabaseRepository, Depends(get_repository)],
):
    if (resource, record_id) in SPECIAL_COLLECTIONS:
        rows = await repo.select(
            table_for(resource),
            limit=200,
        )
        return {"items": rows, "count": len(rows), "resource": resource, "view": record_id}
    table_for(resource)
    rows = await repo.select(table_for(resource), filters={"id": record_id}, limit=1)
    if not rows:
        raise HTTPException(status_code=404, detail="Record not found.")
    return _safe_row(resource, rows[0])


@router.put("/{resource}/{record_id}")
async def update_resource(
    resource: str,
    record_id: str,
    payload: ResourcePayload,
    claims: Annotated[dict[str, Any], Depends(current_claims)],
    repo: Annotated[SupabaseRepository, Depends(get_repository)],
):
    table = table_for(resource)
    update = (
        payload.data
        if resource in {"users", "roles", "customers", "assets", "resource-records"}
        else {"data": payload.data}
    )
    if resource == "users":
        password = update.pop("password", None)
        update.pop("password_hash", None)
        if password:
            from backend.security import hash_password

            update["password_hash"] = hash_password(password)
    try:
        return _safe_row(resource, await repo.update(table, record_id, update))
    except RepositoryError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc


@router.delete("/{resource}/{record_id}")
async def delete_resource(
    resource: str,
    record_id: str,
    claims: Annotated[dict[str, Any], Depends(current_claims)],
    repo: Annotated[SupabaseRepository, Depends(get_repository)],
):
    table = table_for(resource)
    try:
        await repo.delete(table, record_id)
    except RepositoryError as exc:
        raise HTTPException(status_code=502, detail=str(exc)) from exc
    return {"message": "Record deleted successfully.", "id": record_id}


@router.post("/{resource}/{record_id}/{action}")
async def perform_action(
    resource: str,
    record_id: str,
    action: str,
    payload: ActionPayload,
    claims: Annotated[dict[str, Any], Depends(current_claims)],
    repo: Annotated[SupabaseRepository, Depends(get_repository)],
):
    table_for(resource)
    if action not in ACTION_STATUS:
        raise HTTPException(status_code=404, detail=f"Unsupported action: {action}")
    update: dict[str, Any] = {"status": ACTION_STATUS[action]}
    if resource in {"users", "roles", "customers", "assets", "resource-records"}:
        if payload.note:
            update["last_action_note"] = payload.note
        update["updated_at"] = datetime.now(timezone.utc).isoformat()
    else:
        update["data"] = {
            **payload.metadata,
            **({"note": payload.note} if payload.note else {}),
        }
        update["updated_at"] = datetime.now(timezone.utc).isoformat()
    try:
        record = await repo.update(table_for(resource), record_id, update)
    except RepositoryError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    return {"message": f"{resource} {action} successful.", "record": record}


@router.post("/{resource}/{action}")
async def perform_collection_action(
    resource: str,
    action: str,
    payload: ActionPayload,
    claims: Annotated[dict[str, Any], Depends(current_claims)],
    repo: Annotated[SupabaseRepository, Depends(get_repository)],
):
    table_for(resource)
    collection_actions = {
        "check",
        "compute",
        "generate",
        "stock-in",
        "stock-out",
        "adjustment",
        "confirm",
        "send",
        "export",
    }
    if action not in collection_actions:
        raise HTTPException(status_code=404, detail=f"Unsupported collection action: {action}")
    record = await repo.insert(
        table_for(resource),
        {
            "status": action.replace("-", "_"),
            "data": {
                **payload.metadata,
                **({"note": payload.note} if payload.note else {}),
                "action": action,
            },
            "created_by": claims["sub"],
        },
    )
    return {"message": f"{resource} {action} queued.", "record": record}


@router.get("/{resource}/{record_id}/{relation}")
async def related_records(
    resource: str,
    record_id: str,
    relation: str,
    claims: Annotated[dict[str, Any], Depends(current_claims)],
    repo: Annotated[SupabaseRepository, Depends(get_repository)],
):
    table_for(resource)
    allowed_relations = {
        "service-history",
        "job-orders",
        "invoices",
        "timeline",
        "activities",
        "warranty",
        "warranty-status",
        "availability",
        "workload",
        "summary",
        "monthly",
        "by-type",
        "pdf",
        "excel",
        "technician",
    }
    if relation not in allowed_relations and (resource, record_id) not in SPECIAL_COLLECTIONS:
        raise HTTPException(status_code=404, detail=f"Unsupported relation: {relation}")
    if relation == "pdf":
        return {"message": "PDF generation is queued.", "resource": resource, "id": record_id}
    relation_tables = {
        "service-history": "service_requests",
        "job-orders": "job_orders",
        "invoices": "invoices",
        "warranty": "warranties",
        "warranty-status": "warranties",
        "availability": "technicians",
        "workload": "assignments",
        "technician": "incentives",
        "summary": "service_income",
        "monthly": "service_income",
        "by-type": "service_income",
    }
    table = relation_tables.get(relation, "resource_records")
    rows = await repo.select(table, filters={"parent_id": record_id}, limit=200)
    return {"items": rows, "count": len(rows), "relation": relation}