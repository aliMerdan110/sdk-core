# Changelog

## 1.1.0
- Aligned notification inbox pagination with the backend `offset` / `limit` contract.
- Removed the unsupported archive operation.
- Aligned preferences DTOs with the backend category list (`category`, `pushEnabled`, `mutedUntilUtc`, `isCustomized`).
- Parses notification `data` and the backend `createdAt` / `readAt` fields.
