# Flight Report Design Notes

## Goal
Create an OOP ABAP report that queries flight data and displays it in ALV using `REUSE_ALV_GRID_DISPLAY_LVC`.

## Requirements Used
- Selection parameters: `carrid`, `connid`, `fldate` (single values)
- Data source: `SFLIGHT`
- Output: `REUSE_ALV_GRID_DISPLAY_LVC`
- Field catalog: built dynamically from the result table via RTTI

## Design Summary
- **Single local class** `lcl_report` with small, focused methods:
  - `run` orchestrates the flow
  - `read_data` executes the query
  - `build_fieldcat` creates LVC field catalog via RTTI
  - `display_alv` renders output with layout settings
- **Separation of concerns** keeps query logic, metadata building, and UI rendering independent.
- **Optional filters** handled via boolean conditions so empty parameters do not restrict the query.

## Implementation Highlights
- Selected fields are explicit to avoid `SELECT *`.
- RTTI uses the table line type to derive component names and builds `lvc_t_fcat`.
- `ref_table` and `ref_field` are set to enable DDIC text lookup in ALV.
- `layout-zebra` is enabled for readability.

## How to Run
- Execute report `Z260403_REPORT_1`.
- Fill any of the parameters (optional), then run.

## Validation Checklist
- No syntax errors after activation.
- ALV shows expected columns and data.
- Filters work when parameters are supplied.

## Notes
- This implementation uses local class OOP for clarity and testability.
- For production hardening, consider explicit authorization checks and row count guards.
