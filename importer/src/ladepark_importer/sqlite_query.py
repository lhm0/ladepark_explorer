"""Compatibility facade for charging SQLite reference queries.

New code should import from :mod:`ladepark_importer.charging_sqlite`.
"""

from ladepark_importer.charging_sqlite.query import (
    GroupQuery,
    GroupQueryResult,
    get_group_detail,
    query_groups,
)

__all__ = ["GroupQuery", "GroupQueryResult", "get_group_detail", "query_groups"]
