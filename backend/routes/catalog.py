from typing import Any

from fastapi import APIRouter, Body, Depends, HTTPException, Request

from backend.db import SupabaseRepository
from backend.dependencies import current_claims, get_repository
from backend.routes.resources import ACTION_STATUS, RESOURCE_TABLES
from backend.security import hash_password

router = APIRouter(tags=["API Catalog"])

CORE_RESOURCES = {"users", "roles", "customers", "assets", "resource-records"}
RELATION_TABLES = {
    "service-history": "service_requests",
    "job-orders": "job_orders",
    "invoices": "invoices",
    "timeline": "resource_records",
    "activities": "resource_records",
    "warranty": "warranties",
    "warranty-status": "warranties",
    "availability": "technicians",
    "workload": "assignments",
    "technician": "incentives",
}

RouteSpec = tuple[str, str, str, str, str | None]
ROUTES: list[RouteSpec] = []


def add(path: str, method: str, resource: str, operation: str, action: str | None = None) -> None:
    ROUTES.append((path, method, resource, operation, action))


def crud(resource: str, *, delete: bool = True) -> None:
    path = f"/api/{resource}"
    add(path, "GET", resource, "list")
    add(path, "POST", resource, "create")
    add(f"{path}/{{id}}", "GET", resource, "detail")
    add(f"{path}/{{id}}", "PUT", resource, "update")
    if delete:
        add(f"{path}/{{id}}", "DELETE", resource, "delete")


def actions(resource: str, action_names: list[str]) -> None:
    for action in action_names:
        add(f"/api/{resource}/{{id}}/{action}", "POST", resource, "action", action)


def relation(resource: str, suffix: str, *, parameter: str = "id") -> None:
    add(f"/api/{resource}/{{id}}/{suffix}", "GET", resource, "relation", suffix)


for resource in [
    "users",
    "roles",
    "customers",
    "assets",
    "service-requests",
    "job-orders",
    "warranties",
    "diagnostics",
    "quotations",
    "parts",
    "purchase-orders",
    "suppliers",
    "repairs",
    "projects",
    "site-surveys",
    "material-preparations",
    "technicians",
    "assignments",
    "installations",
    "commissioning",
    "punch-lists",
    "service-partners",
    "partner-requests",
    "schedules",
    "service-reports",
    "invoices",
    "payments",
    "service-income",
    "incentives",
    "customer-feedback",
]:
    crud(resource)

crud("qc-checklists", delete=False)
crud("calendar", delete=False)
crud("uploads", delete=False)
crud("attachments")
crud("customer-signatures", delete=False)

actions("service-requests", ["assign", "cancel", "close"])
actions("job-orders", ["start", "complete", "close", "customer-signoff", "photos"])
actions("diagnostics", ["approve", "reject"])
actions("quotations", ["submit", "approve", "reject"])
actions("purchase-orders", ["approve", "receive", "cancel"])
actions("repairs", ["start", "pause", "complete"])
actions("qc", ["pass", "fail"])
actions("projects", ["close", "photos"])
actions("site-surveys", ["submit"])
actions("installations", ["start", "complete"])
actions("commissioning", ["approve", "fail"])
actions("punch-lists", ["resolve"])
actions("partner-requests", ["approve", "assign"])
actions("service-reports", ["attachments"])
actions("invoices", ["send", "void"])
actions("payments", ["confirm"])
actions("customer-feedback", [])

for resource, action_names in {
    "warranties": ["check"],
    "parts": ["stock-in", "stock-out", "adjustment"],
    "incentives": ["compute", "generate"],
}.items():
    for action in action_names:
        add(f"/api/{resource}/{action}", "POST", resource, "collection-action", action)

for resource, suffixes in {
    "customers": ["service-history", "job-orders", "invoices"],
    "assets": ["service-history", "warranty-status"],
    "job-orders": ["timeline", "activities"],
    "quotations": ["pdf"],
    "service-reports": ["pdf"],
    "invoices": ["pdf"],
    "incentives": ["technician"],
}.items():
    for suffix in suffixes:
        relation(resource, suffix)

relation("assets", "warranty")

for resource, suffixes in {
    "parts": ["stock", "low-stock"],
    "technicians": ["availability", "workload"],
    "service-income": ["summary", "monthly", "by-type"],
    "performance": [
        "dashboard",
        "technicians",
        "customer-ratings",
        "on-time-completion",
        "repeat-callbacks",
        "warranty-returns",
        "income-generated",
    ],
    "dashboard": ["overview", "jobs", "projects", "revenue", "incentives", "performance"],
    "reports": [
        "service-income",
        "job-orders",
        "projects",
        "inventory",
        "technician-performance",
        "incentives",
        "customer-feedback",
    ],
}.items():
    for suffix in suffixes:
        add(f"/api/{resource}/{suffix}", "GET", resource, "view", suffix)

add("/api/performance/technicians/{id}", "GET", "performance", "relation", "technicians")
add("/api/incentives/technician/{id}", "GET", "incentives", "relation", "technician")

add("/api/reports/export/excel", "GET", "reports", "view", "export-excel")
add("/api/reports/export/pdf", "GET", "reports", "view", "export-pdf")


def _table_for(resource: str) -> str:
    try:
        return RESOURCE_TABLES[resource]
    except KeyError as exc:
        raise HTTPException(status_code=404, detail=f"Unknown resource: {resource}") from exc


def _record_for_create(resource: str, payload: dict[str, Any], user_id: str) -> dict[str, Any]:
    if resource in CORE_RESOURCES:
        if resource == "users":
            password = payload.pop("password", None)
            if not password:
                raise HTTPException(status_code=400, detail="A password is required when creating a user.")
            payload.pop("password_hash", None)
            payload["password_hash"] = hash_password(password)
        return payload
    return {
        "status": payload.get("status", "draft"),
        "created_by": user_id,
        "data": payload,
    }


def _record_for_update(resource: str, payload: dict[str, Any]) -> dict[str, Any]:
    if resource in CORE_RESOURCES:
        if resource == "users":
            password = payload.pop("password", None)
            payload.pop("password_hash", None)
            if password:
                payload["password_hash"] = hash_password(password)
        return payload
    return {"data": payload}


def _safe(resource: str, row: dict[str, Any]) -> dict[str, Any]:
    if resource == "users":
        return {key: value for key, value in row.items() if key != "password_hash"}
    return row


async def _catalog_endpoint(
    request: Request,
    repo: SupabaseRepository,
    claims: dict[str, Any],
    spec: RouteSpec,
    payload: dict[str, Any] | None = None,
) -> Any:
    _, method, resource, operation, action = spec
    table = _table_for(resource)
    path_params = request.path_params
    record_id = path_params.get("id")

    if operation == "list":
        rows = await repo.select(table, limit=200)
        return {"items": [_safe(resource, row) for row in rows], "count": len(rows)}

    if operation == "detail":
        rows = await repo.select(table, filters={"id": record_id}, limit=1)
        if not rows:
            raise HTTPException(status_code=404, detail="Record not found.")
        return _safe(resource, rows[0])

    if operation == "create":
        record = _record_for_create(resource, dict(payload or {}), str(claims["sub"]))
        return _safe(resource, await repo.insert(table, record))

    if operation == "update":
        rows = await repo.update(table, str(record_id), _record_for_update(resource, dict(payload or {})))
        return _safe(resource, rows)

    if operation == "delete":
        await repo.delete(table, str(record_id))
        return {"message": "Record deleted successfully.", "id": record_id}

    if operation == "action":
        if action in {"photos", "attachments"}:
            attachment = {
                "status": "attached",
                "parent_id": record_id,
                "created_by": claims["sub"],
                "data": {**(payload or {}), "action": action},
            }
            return await repo.insert("attachments", attachment)
        if action == "customer-signoff":
            return await repo.insert(
                "customer_signatures",
                {"parent_id": record_id, "created_by": claims["sub"], "status": "signed", "data": payload or {}},
            )
        if action in {"pdf"}:
            return {"message": "PDF generation queued.", "id": record_id}
        if action not in ACTION_STATUS:
            raise HTTPException(status_code=404, detail=f"Unsupported action: {action}")
        if resource in CORE_RESOURCES:
            update = {"status": ACTION_STATUS[action]}
        else:
            update = {
                "status": ACTION_STATUS[action],
                "data": {**(payload or {}), "action": action},
            }
        return await repo.update(table, str(record_id), update)

    if operation == "collection-action":
        if action not in ACTION_STATUS and action not in {
            "check",
            "stock-in",
            "stock-out",
            "adjustment",
            "compute",
            "generate",
        }:
            raise HTTPException(status_code=404, detail=f"Unsupported collection action: {action}")
        record = {
            "status": ACTION_STATUS.get(action, action.replace("-", "_")),
            "created_by": claims["sub"],
            "data": {**(payload or {}), "action": action},
        }
        return await repo.insert(table, record)

    if operation in {"relation", "view"}:
        if action in {"pdf", "export-excel", "export-pdf"}:
            return {"message": "Export or PDF generation queued.", "resource": resource, "view": action}
        relation_table = RELATION_TABLES.get(action or "", table)
        rows = await repo.select(relation_table, filters={"parent_id": record_id}, limit=200)
        return {"items": rows, "count": len(rows), "resource": resource, "view": action}

    raise HTTPException(status_code=404, detail="Unsupported API operation.")


def _make_endpoint(spec: RouteSpec):
    _, method, _, _, _ = spec
    if method in {"GET", "DELETE"}:
        async def endpoint(
            request: Request,
            claims: dict[str, Any] = Depends(current_claims),
            repo: SupabaseRepository = Depends(get_repository),
        ) -> Any:
            return await _catalog_endpoint(request, repo, claims, spec)
    else:
        async def endpoint(
            request: Request,
            payload: dict[str, Any] | None = Body(default=None),
            claims: dict[str, Any] = Depends(current_claims),
            repo: SupabaseRepository = Depends(get_repository),
        ) -> Any:
            return await _catalog_endpoint(request, repo, claims, spec, payload)
    return endpoint


for index, spec in enumerate(ROUTES):
    path, method, resource, operation, action = spec
    router.add_api_route(
        path,
        _make_endpoint(spec),
        methods=[method],
        name=f"{method.lower()}_{resource}_{operation}_{action or index}",
        operation_id=f"{method.lower()}_{resource.replace('-', '_')}_{operation}_{index}_{action or 'default'}",
        status_code=201 if method == "POST" and operation == "create" else 200,
    )