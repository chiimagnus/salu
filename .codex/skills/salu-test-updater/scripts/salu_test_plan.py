#!/usr/bin/env python3
from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable


@dataclass(frozen=True)
class FilePlan:
    source_path: str
    module: str  # GameCore | GameCLI | Other
    symbols: list[str]
    candidate_tests: list[tuple[str, int]]
    suggested_action: str


def _run(cmd: list[str], cwd: str) -> str:
    return subprocess.check_output(cmd, cwd=cwd, text=True, stderr=subprocess.STDOUT).strip()


def _has_cmd(cmd: str) -> bool:
    return any(os.access(os.path.join(p, cmd), os.X_OK) for p in os.getenv("PATH", "").split(os.pathsep))


def _git_root(repo: str) -> str:
    return _run(["git", "rev-parse", "--show-toplevel"], cwd=repo)


def _changed_files_last_commits(repo: str, last: int) -> list[str]:
    if last <= 0:
        return []

    # Use a range diff so we get the union of changes across the commits.
    # If HEAD~N does not exist, fall back to the initial commit range.
    try:
        base = _run(["git", "rev-parse", f"HEAD~{last}"], cwd=repo)
        rng = f"{base}..HEAD"
    except subprocess.CalledProcessError:
        rng = "HEAD"

    out = _run(["git", "diff", "--name-only", rng], cwd=repo)
    files = [line.strip() for line in out.splitlines() if line.strip()]
    return files


def _normalize_repo_relative_paths(repo_root: str, paths: Iterable[str]) -> list[str]:
    repo_root_path = Path(repo_root)
    normalized: list[str] = []
    for raw in paths:
        p = Path(raw)
        if p.is_absolute():
            try:
                rel = p.resolve().relative_to(repo_root_path.resolve())
                normalized.append(str(rel))
            except Exception:
                # If it isn't inside repo root, keep as-is (will likely be filtered out later).
                normalized.append(str(p))
        else:
            normalized.append(str(p))
    return normalized


def _is_source_swift(path: str) -> bool:
    return path.endswith(".swift") and path.startswith("Sources/")


def _module_for_source(path: str) -> str:
    if path.startswith("Sources/GameCore/"):
        return "GameCore"
    if path.startswith("Sources/GameCLI/"):
        return "GameCLI"
    return "Other"


def _extract_symbols(repo_root: str, source_path: str) -> list[str]:
    abs_path = Path(repo_root) / source_path
    try:
        text = abs_path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        text = abs_path.read_text(errors="replace")

    # Heuristic only: enough to help find related tests via ripgrep.
    type_re = re.compile(r"\b(?:public\s+)?(?:final\s+)?(?:class|struct|enum|protocol|actor)\s+([A-Za-z_]\w*)")
    func_re = re.compile(r"\b(?:public\s+)?func\s+([A-Za-z_]\w*)\s*\(")

    symbols: list[str] = []
    symbols.extend(type_re.findall(text))
    symbols.extend(func_re.findall(text))

    # Prefer unique, stable ordering.
    seen: set[str] = set()
    out: list[str] = []
    for s in symbols:
        if s in seen:
            continue
        seen.add(s)
        out.append(s)
    return out[:30]


def _candidate_test_dir(module: str) -> str | None:
    if module == "GameCore":
        return "Tests/GameCoreTests"
    if module == "GameCLI":
        return "Tests/GameCLITests"
    return None


def _find_candidate_tests(repo_root: str, test_dir: str, symbols: list[str]) -> list[tuple[str, int]]:
    abs_test_dir = str(Path(repo_root) / test_dir)
    if not Path(abs_test_dir).exists():
        return []

    scores: dict[str, int] = {}
    use_rg = _has_cmd("rg")

    for sym in symbols:
        try:
            if use_rg:
                out = _run(["rg", "-l", "-F", sym, abs_test_dir], cwd=repo_root)
            else:
                out = _run(["grep", "-Rsl", sym, abs_test_dir], cwd=repo_root)
        except subprocess.CalledProcessError:
            continue

        for line in out.splitlines():
            rel = str(Path(line).resolve().relative_to(Path(repo_root).resolve()))
            scores[rel] = scores.get(rel, 0) + 1

    ranked = sorted(scores.items(), key=lambda kv: (-kv[1], kv[0]))
    return ranked[:8]


def _suggest_action(source_path: str, module: str, candidates: list[tuple[str, int]]) -> str:
    if module == "Other":
        return "跳过（非 GameCore/GameCLI）"

    if candidates:
        base = Path(source_path).stem
        base_lower = base.lower()

        # Prefer a candidate test file whose filename "looks like" it belongs to this source file.
        # This keeps suggestions closer to the repo's "functional grouping" style (e.g. BattleEngine.swift → BattleEngineFlowTests.swift).
        name_matched = [(p, s) for (p, s) in candidates if base_lower in Path(p).name.lower()]
        if name_matched:
            best = sorted(name_matched, key=lambda kv: (-kv[1], kv[0]))[0][0]
            return f"优先更新：{best}"

        return f"优先更新：{candidates[0][0]}"

    # Fallback: propose a new test file name, but keep it heuristic (the agent may choose a better grouping).
    base = Path(source_path).stem
    if module == "GameCore":
        return f"可能需要新建：Tests/GameCoreTests/{base}Tests.swift（或找更合适的聚合测试文件）"
    return f"可能需要新建：Tests/GameCLITests/{base}Tests.swift（或找更合适的聚合测试文件）"


def _render_markdown(repo_root: str, mode_label: str, plans: list[FilePlan]) -> str:
    lines: list[str] = []
    lines.append(f"# salu-test-updater: 测试更新清单")
    lines.append(f"- repo: `{repo_root}`")
    lines.append(f"- mode: `{mode_label}`")
    lines.append("")
    if not plans:
        lines.append("（未发现需要处理的 `Sources/**/*.swift` 变更）")
        return "\n".join(lines)

    for p in plans:
        lines.append(f"## {p.source_path}")
        lines.append(f"- module: `{p.module}`")
        if p.symbols:
            preview = ", ".join(p.symbols[:12]) + (" ..." if len(p.symbols) > 12 else "")
            lines.append(f"- symbols: `{preview}`")
        else:
            lines.append(f"- symbols: （未提取到，可能是扩展/常量/或纯实现文件）")
        if p.candidate_tests:
            lines.append("- candidate tests (hits):")
            for path, score in p.candidate_tests[:5]:
                lines.append(f"  - `{path}` ({score})")
        else:
            lines.append("- candidate tests: （无命中）")
        lines.append(f"- suggestion: {p.suggested_action}")
        lines.append("")

    return "\n".join(lines).rstrip() + "\n"


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="Generate a lightweight plan for updating Salu unit tests.")
    parser.add_argument("--repo", default=".", help="Path to the Salu git repo (default: .)")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--files", nargs="+", help="One or more Swift source files (absolute or repo-relative)")
    group.add_argument("--last", type=int, help="Use changed files from the last N commits (HEAD~N..HEAD)")
    args = parser.parse_args(argv)

    repo_root = _git_root(args.repo)

    if args.files is not None:
        input_paths = _normalize_repo_relative_paths(repo_root, args.files)
        mode_label = f"files ({len(input_paths)})"
    else:
        changed = _changed_files_last_commits(repo_root, args.last or 0)
        input_paths = _normalize_repo_relative_paths(repo_root, changed)
        mode_label = f"last {args.last} commits"

    source_swifts = [p for p in input_paths if _is_source_swift(p)]
    source_swifts = sorted(set(source_swifts))

    plans: list[FilePlan] = []
    for source in source_swifts:
        module = _module_for_source(source)
        symbols = _extract_symbols(repo_root, source) if module in ("GameCore", "GameCLI") else []
        test_dir = _candidate_test_dir(module)
        candidates = _find_candidate_tests(repo_root, test_dir, symbols) if test_dir else []
        suggested = _suggest_action(source, module, candidates)
        plans.append(
            FilePlan(
                source_path=source,
                module=module,
                symbols=symbols,
                candidate_tests=candidates,
                suggested_action=suggested,
            )
        )

    sys.stdout.write(_render_markdown(repo_root, mode_label, plans))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
