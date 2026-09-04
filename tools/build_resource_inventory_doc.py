from __future__ import annotations

import os
import wave
import zipfile
from collections import Counter
from datetime import date
from pathlib import Path

from docx import Document
from docx.enum.section import WD_SECTION
from docx.enum.table import WD_CELL_VERTICAL_ALIGNMENT, WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_BREAK, WD_LINE_SPACING
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Inches, Pt, RGBColor


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "docs" / "TD_Survival_Resource_Inventory_2026-07-29.docx"
WIREFRAME = ROOT / "docs" / "wireframes" / "td-survival-wireframe-v2.png"

NAVY = "18324A"
BLUE = "2E74B5"
DARK_BLUE = "1F4D78"
INK = "20252B"
MUTED = "66717E"
LIGHT_BLUE = "E8EEF5"
LIGHT_GRAY = "F2F4F7"
PALE = "F7F9FB"
WHITE = "FFFFFF"
GREEN = "2D6A4F"
GOLD = "8A6500"

CONTENT_DXA = 9360
TABLE_INDENT_DXA = 120
CELL_TOP_BOTTOM_DXA = 80
CELL_SIDE_DXA = 120


def set_run_font(run, size=None, color=None, bold=None, italic=None, name="Calibri"):
    run.font.name = name
    run._element.get_or_add_rPr().get_or_add_rFonts().set(qn("w:ascii"), name)
    run._element.get_or_add_rPr().get_or_add_rFonts().set(qn("w:hAnsi"), name)
    run._element.get_or_add_rPr().get_or_add_rFonts().set(qn("w:eastAsia"), "Malgun Gothic")
    if size is not None:
        run.font.size = Pt(size)
    if color is not None:
        run.font.color.rgb = RGBColor.from_string(color)
    if bold is not None:
        run.bold = bold
    if italic is not None:
        run.italic = italic


def set_cell_shading(cell, fill):
    tc_pr = cell._tc.get_or_add_tcPr()
    shd = tc_pr.find(qn("w:shd"))
    if shd is None:
        shd = OxmlElement("w:shd")
        tc_pr.append(shd)
    shd.set(qn("w:fill"), fill)


def set_cell_margins(cell):
    tc_pr = cell._tc.get_or_add_tcPr()
    tc_mar = tc_pr.find(qn("w:tcMar"))
    if tc_mar is None:
        tc_mar = OxmlElement("w:tcMar")
        tc_pr.append(tc_mar)
    for edge, value in (
        ("top", CELL_TOP_BOTTOM_DXA),
        ("bottom", CELL_TOP_BOTTOM_DXA),
        ("start", CELL_SIDE_DXA),
        ("end", CELL_SIDE_DXA),
    ):
        node = tc_mar.find(qn(f"w:{edge}"))
        if node is None:
            node = OxmlElement(f"w:{edge}")
            tc_mar.append(node)
        node.set(qn("w:w"), str(value))
        node.set(qn("w:type"), "dxa")


def set_table_geometry(table, widths_dxa, indent_dxa=TABLE_INDENT_DXA):
    assert sum(widths_dxa) == CONTENT_DXA, widths_dxa
    table.autofit = False
    table.alignment = WD_TABLE_ALIGNMENT.LEFT
    tbl_pr = table._tbl.tblPr

    tbl_w = tbl_pr.find(qn("w:tblW"))
    if tbl_w is None:
        tbl_w = OxmlElement("w:tblW")
        tbl_pr.append(tbl_w)
    tbl_w.set(qn("w:w"), str(CONTENT_DXA))
    tbl_w.set(qn("w:type"), "dxa")

    tbl_ind = tbl_pr.find(qn("w:tblInd"))
    if tbl_ind is None:
        tbl_ind = OxmlElement("w:tblInd")
        tbl_pr.append(tbl_ind)
    tbl_ind.set(qn("w:w"), str(indent_dxa))
    tbl_ind.set(qn("w:type"), "dxa")

    layout = tbl_pr.find(qn("w:tblLayout"))
    if layout is None:
        layout = OxmlElement("w:tblLayout")
        tbl_pr.append(layout)
    layout.set(qn("w:type"), "fixed")

    grid = table._tbl.tblGrid
    for child in list(grid):
        grid.remove(child)
    for width in widths_dxa:
        col = OxmlElement("w:gridCol")
        col.set(qn("w:w"), str(width))
        grid.append(col)

    for row in table.rows:
        for idx, cell in enumerate(row.cells):
            tc_pr = cell._tc.get_or_add_tcPr()
            tc_w = tc_pr.find(qn("w:tcW"))
            if tc_w is None:
                tc_w = OxmlElement("w:tcW")
                tc_pr.append(tc_w)
            tc_w.set(qn("w:w"), str(widths_dxa[idx]))
            tc_w.set(qn("w:type"), "dxa")
            cell.width = Inches(widths_dxa[idx] / 1440)
            cell.vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.CENTER
            set_cell_margins(cell)


def set_repeat_table_header(row):
    tr_pr = row._tr.get_or_add_trPr()
    tbl_header = OxmlElement("w:tblHeader")
    tbl_header.set(qn("w:val"), "true")
    tr_pr.append(tbl_header)


def keep_row_together(row):
    tr_pr = row._tr.get_or_add_trPr()
    cant_split = OxmlElement("w:cantSplit")
    tr_pr.append(cant_split)


def format_table_text(table, header=True, body_size=8.9):
    for r_idx, row in enumerate(table.rows):
        keep_row_together(row)
        for c_idx, cell in enumerate(row.cells):
            for paragraph in cell.paragraphs:
                paragraph.paragraph_format.space_before = Pt(0)
                paragraph.paragraph_format.space_after = Pt(0)
                paragraph.paragraph_format.line_spacing = 1.12
                if c_idx == 0 and len(row.cells) <= 2:
                    paragraph.alignment = WD_ALIGN_PARAGRAPH.LEFT
                for run in paragraph.runs:
                    set_run_font(
                        run,
                        size=9 if r_idx == 0 and header else body_size,
                        color=WHITE if r_idx == 0 and header else INK,
                        bold=(r_idx == 0 and header),
                    )
            if r_idx == 0 and header:
                set_cell_shading(cell, NAVY)
    if header and table.rows:
        set_repeat_table_header(table.rows[0])


def add_table(doc, headers, rows, widths_dxa, body_size=8.9):
    table = doc.add_table(rows=1, cols=len(headers))
    table.style = "Table Grid"
    for idx, label in enumerate(headers):
        table.rows[0].cells[idx].text = label
    for row_data in rows:
        cells = table.add_row().cells
        for idx, value in enumerate(row_data):
            cells[idx].text = str(value)
    set_table_geometry(table, widths_dxa)
    format_table_text(table, header=True, body_size=body_size)
    for row_idx, row in enumerate(table.rows[1:], 1):
        if row_idx % 2 == 0:
            for cell in row.cells:
                set_cell_shading(cell, PALE)
    doc.add_paragraph().paragraph_format.space_after = Pt(1)
    return table


def add_kicker(doc, text):
    p = doc.add_paragraph()
    p.paragraph_format.space_after = Pt(5)
    r = p.add_run(text.upper())
    set_run_font(r, size=9.5, color=BLUE, bold=True)
    return p


def add_title(doc, text):
    p = doc.add_paragraph()
    p.paragraph_format.space_after = Pt(8)
    p.paragraph_format.keep_with_next = True
    r = p.add_run(text)
    set_run_font(r, size=28, color=NAVY, bold=True)
    return p


def add_subtitle(doc, text):
    p = doc.add_paragraph()
    p.paragraph_format.space_after = Pt(14)
    r = p.add_run(text)
    set_run_font(r, size=13, color=MUTED)
    return p


def add_heading(doc, text, level=1):
    p = doc.add_paragraph(style=f"Heading {level}")
    p.paragraph_format.keep_with_next = True
    r = p.add_run(text)
    return p


def add_body(doc, text, bold_lead=None):
    p = doc.add_paragraph()
    if bold_lead and text.startswith(bold_lead):
        a = p.add_run(bold_lead)
        set_run_font(a, size=11, color=INK, bold=True)
        b = p.add_run(text[len(bold_lead):])
        set_run_font(b, size=11, color=INK)
    else:
        r = p.add_run(text)
        set_run_font(r, size=11, color=INK)
    return p


def add_callout(doc, label, text, fill=LIGHT_BLUE, accent=BLUE):
    table = doc.add_table(rows=1, cols=1)
    table.style = "Table Grid"
    set_table_geometry(table, [CONTENT_DXA])
    cell = table.cell(0, 0)
    set_cell_shading(cell, fill)
    p = cell.paragraphs[0]
    p.paragraph_format.space_after = Pt(0)
    a = p.add_run(label + "  ")
    set_run_font(a, size=9.5, color=accent, bold=True)
    b = p.add_run(text)
    set_run_font(b, size=10.2, color=INK)
    doc.add_paragraph().paragraph_format.space_after = Pt(1)


def add_page_field(paragraph):
    run = paragraph.add_run()
    fld_char = OxmlElement("w:fldChar")
    fld_char.set(qn("w:fldCharType"), "begin")
    instr_text = OxmlElement("w:instrText")
    instr_text.set(qn("xml:space"), "preserve")
    instr_text.text = " PAGE "
    fld_end = OxmlElement("w:fldChar")
    fld_end.set(qn("w:fldCharType"), "end")
    run._r.append(fld_char)
    run._r.append(instr_text)
    run._r.append(fld_end)
    set_run_font(run, size=8.5, color=MUTED)


def configure_document(doc):
    section = doc.sections[0]
    section.page_width = Inches(8.5)
    section.page_height = Inches(11)
    section.top_margin = Inches(1)
    section.right_margin = Inches(1)
    section.bottom_margin = Inches(1)
    section.left_margin = Inches(1)
    section.header_distance = Inches(0.492)
    section.footer_distance = Inches(0.492)
    section.different_first_page_header_footer = True

    normal = doc.styles["Normal"]
    normal.font.name = "Calibri"
    normal._element.rPr.rFonts.set(qn("w:ascii"), "Calibri")
    normal._element.rPr.rFonts.set(qn("w:hAnsi"), "Calibri")
    normal._element.rPr.rFonts.set(qn("w:eastAsia"), "Malgun Gothic")
    normal.font.size = Pt(11)
    normal.font.color.rgb = RGBColor.from_string(INK)
    normal.paragraph_format.space_before = Pt(0)
    normal.paragraph_format.space_after = Pt(6)
    normal.paragraph_format.line_spacing = 1.25
    normal.paragraph_format.widow_control = True

    heading_tokens = {
        "Heading 1": (16, BLUE, 18, 10),
        "Heading 2": (13, BLUE, 14, 7),
        "Heading 3": (12, DARK_BLUE, 10, 5),
    }
    for name, (size, color, before, after) in heading_tokens.items():
        style = doc.styles[name]
        style.font.name = "Calibri"
        style._element.rPr.rFonts.set(qn("w:ascii"), "Calibri")
        style._element.rPr.rFonts.set(qn("w:hAnsi"), "Calibri")
        style._element.rPr.rFonts.set(qn("w:eastAsia"), "Malgun Gothic")
        style.font.size = Pt(size)
        style.font.color.rgb = RGBColor.from_string(color)
        style.font.bold = True
        style.paragraph_format.space_before = Pt(before)
        style.paragraph_format.space_after = Pt(after)
        style.paragraph_format.keep_with_next = True
        style.paragraph_format.keep_together = True

    header = section.header
    p = header.paragraphs[0]
    p.alignment = WD_ALIGN_PARAGRAPH.LEFT
    p.paragraph_format.space_after = Pt(0)
    r = p.add_run("TD SURVIVAL  /  RESOURCE INVENTORY")
    set_run_font(r, size=8.5, color=MUTED, bold=True)

    footer = section.footer
    p = footer.paragraphs[0]
    p.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    p.paragraph_format.space_after = Pt(0)
    r = p.add_run("2026-07-29   ·   ")
    set_run_font(r, size=8.5, color=MUTED)
    add_page_field(p)

    first_footer = section.first_page_footer
    fp = first_footer.paragraphs[0]
    fp.alignment = WD_ALIGN_PARAGRAPH.CENTER
    fr = fp.add_run("TD Survival · 내부 개발 리소스 기준선 · 2026-07-29")
    set_run_font(fr, size=8.5, color=MUTED)


def rel(path: Path):
    return path.relative_to(ROOT).as_posix()


def meaningful_files():
    excluded_dirs = {".godot", "tmp", "_render_resource_inventory", "__pycache__"}
    result = []
    for path in ROOT.rglob("*"):
        if not path.is_file():
            continue
        relative = path.relative_to(ROOT)
        if any(part in excluded_dirs for part in relative.parts):
            continue
        if path.suffix.lower() in {".uid", ".import"}:
            continue
        if path.resolve() == OUTPUT.resolve():
            continue
        result.append(path)
    return sorted(result, key=lambda p: rel(p).lower())


def duration_seconds(path: Path):
    with wave.open(str(path), "rb") as handle:
        return handle.getnframes() / float(handle.getframerate())


def names(paths):
    return ", ".join(path.name for path in paths)


def add_cover(doc, total_files, counts):
    for _ in range(4):
        p = doc.add_paragraph()
        p.paragraph_format.space_after = Pt(12)
    add_kicker(doc, "PROJECT REFERENCE / GODOT 4.7")
    add_title(doc, "TD Survival 리소스 목록서")
    add_subtitle(doc, "게임 구조, 콘텐츠 자산, UI 기준 이미지와 검증 진입점을 한 문서에서 추적하는 개발 기준선")

    rows = [
        ("기준일", "2026-07-29 (Asia/Seoul)"),
        ("프로젝트", "TD_survival · Godot 4.7 · Mobile renderer"),
        ("기준 화면", "1280 × 720 · 가로 · canvas_items / expand"),
        ("조사 범위", f"의미 있는 파일 {total_files}개 · .godot / .uid / .import / tmp 제외"),
        ("주요 구성", f"GDScript {counts['.gd']} · Scene {counts['.tscn']} · PNG {counts['.png']} · WAV {counts['.wav']}"),
        ("동반 산출물", "docs/wireframes/td-survival-wireframe-v2.png"),
    ]
    table = add_table(doc, ["항목", "내용"], rows, [2700, 6660], body_size=9.5)
    for row in table.rows[1:]:
        for run in row.cells[0].paragraphs[0].runs:
            set_run_font(run, size=9.3, color=DARK_BLUE, bold=True)

    add_callout(
        doc,
        "문서 사용법",
        "경로와 수량은 현재 저장소를 기준으로 작성했습니다. 기능 의도는 실제 씬·스크립트 연결을 우선했고, 설계 문서와 구현이 다른 항목은 ‘관리 포인트’로 분리했습니다.",
    )
    doc.add_page_break()


def add_summary(doc, total_files, counts):
    add_heading(doc, "1. 리소스 기준선", 1)
    add_body(
        doc,
        "현재 프로젝트는 메인 메뉴에서 코어와 타깃을 선택한 뒤 10분 전투에 진입하고, 전투 중 레벨업 3택과 편대 설치를 반복한 후 승리/패배 결과로 종료되는 러프 프로토타입입니다. 자원은 전역 서비스, 데이터 타입, 콘텐츠 인스턴스, 런타임 씬, 기능 스크립트, 미디어 자산, 자동 검증 자료로 분리되어 있습니다.",
    )
    add_callout(doc, "현재 상태", "핵심 기능은 연결되어 있으나 밸런스, 실제 모바일 UX, 성능·발열, 최종 아트와 애니메이션은 추가 검증 대상입니다.", fill=LIGHT_BLUE, accent=GREEN)

    overview_rows = [
        ("전역 서비스", "6", "autoload/*.gd", "데이터, 세션, 저장, 신호, 오디오, RNG"),
        ("데이터 타입", "11", "resources/*.gd", "코어·타깃·적·타워·성장·스테이지 스키마"),
        ("콘텐츠 인스턴스", "2", "data/**/*.tres", "기본 적, 10분 표준 스테이지"),
        ("런타임 씬", "11", "scenes/**/*.tscn", "메뉴, 게임, 전장, 액터, 픽업, UI"),
        ("런타임 스크립트", "28", "scripts/**/*.gd", "전투, 성장, 입력, 결과, UI 로직"),
        ("게임 미디어", "51", "assets/**/*.(png|wav)", "그래픽 41, 오디오 10"),
        ("QA 리소스", "22", "tests/**/*", "테스트 씬/러너 4, UI 스냅샷 18"),
        ("문서·설정·도구", str(total_files - 131), "루트, docs, tools", "GDD, 상태 문서, 설정, 아이콘, 생성 도구, 와이어프레임"),
    ]
    add_table(doc, ["분류", "수량", "기준 경로", "역할"], overview_rows, [1700, 900, 2800, 3960], body_size=8.6)

    add_heading(doc, "1.1 런타임 시작점과 조작", 2)
    input_rows = [
        ("시작 씬", "scenes/main/main_menu.tscn", "메인 메뉴 및 게임 설정"),
        ("R / restart_game", "게임오버·진행 중 정책에 따라", "현재 런 재시작"),
        ("Space / core_skill", "전투", "코어 스킬 발동"),
        ("F / cycle_game_speed", "전투", "게임 속도 순환"),
        ("G / toggle_attack_ranges", "전투", "공격 범위 표시 전환"),
        ("Esc / ui_cancel", "메뉴·전투·오버레이", "뒤로가기 또는 일시정지"),
    ]
    add_table(doc, ["입력/진입점", "적용 위치", "기능"], input_rows, [2200, 3000, 4160], body_size=9)

    add_heading(doc, "1.2 파일 형식별 집계", 2)
    ext_rows = []
    descriptions = {
        ".png": "게임 그래픽, UI 스냅샷, 와이어프레임",
        ".gd": "Autoload, 데이터 타입, 런타임, 테스트",
        ".tscn": "런타임 씬과 테스트 진입 씬",
        ".md": "GDD, 상태, 컨텍스트, 운영 지침",
        ".wav": "효과음과 결과 피드백",
        ".tres": "스테이지와 적 데이터 인스턴스",
        ".py": "리소스 생성·문서 자동화 도구",
        ".godot": "Godot 프로젝트 설정",
        ".svg": "프로젝트 아이콘",
    }
    for extension, count in counts.most_common():
        ext_rows.append((extension or "(없음)", count, descriptions.get(extension, "지원 파일")))
    add_table(doc, ["확장자", "수량", "용도"], ext_rows, [1800, 1000, 6560], body_size=9.2)


def add_architecture(doc):
    add_heading(doc, "2. 전역 서비스와 데이터 모델", 1)
    autoload_rows = [
        ("DataRegistry", "autoload/data_registry.gd", "코어·커서·적·타워 등 정적 게임 데이터 등록 및 조회"),
        ("GameSession", "autoload/game_session.gd", "런 설정과 현재 세션 상태 유지"),
        ("SaveManager", "autoload/save_manager.gd", "옵션·기록·영속 데이터 저장/로드"),
        ("SignalBus", "autoload/signal_bus.gd", "모듈 간 전역 이벤트 전달"),
        ("AudioManager", "autoload/audio_manager.gd", "효과음 로드·재생과 오디오 옵션 적용"),
        ("RunRng", "autoload/run_rng.gd", "런 단위 시드와 재현 가능한 난수 제공"),
    ]
    add_table(doc, ["Autoload", "파일", "책임"], autoload_rows, [1700, 3100, 4560], body_size=8.9)

    add_heading(doc, "2.1 Resource 타입", 2)
    resource_rows = [
        ("CoreData", "resources/core_data.gd", "코어 속성·스킬·표시 데이터"),
        ("CursorData", "resources/cursor_data.gd", "타깃 커서/전선 위치 데이터"),
        ("EnemyData", "resources/enemy_data.gd", "적 기본 능력치와 행동 속성"),
        ("StageData", "resources/stage_data.gd", "스테이지 시간과 스폰 구성"),
        ("TowerData", "resources/tower_data.gd", "타워 전투 능력과 공격 정의"),
        ("TowerBranchData", "resources/tower_branch_data.gd", "타워 성장 분기"),
        ("TowerFormationData", "resources/tower_formation_data.gd", "편대 레시피와 배치 형태"),
        ("UpgradeData", "resources/upgrade_data.gd", "레벨업 선택지와 효과"),
        ("SpecializationBranchData", "resources/specialization_branch_data.gd", "특성 분기 데이터"),
        ("GameTypes", "resources/game_types.gd", "공용 enum과 타입 상수"),
    ]
    add_table(doc, ["타입", "파일", "주요 용도"], resource_rows, [2200, 3300, 3860], body_size=8.4)

    add_heading(doc, "2.2 콘텐츠 인스턴스", 2)
    data_rows = [
        ("기본 적", "data/enemies/basic_enemy.tres", "id=basic", "EnemyData 기반 기본 적"),
        ("10분 표준 스테이지", "data/stages/standard_20m.tres", "id=standard_20m / 600초", "StageData 기반 표준 런"),
    ]
    add_table(doc, ["표시명", "파일", "식별/설정", "역할"], data_rows, [1800, 3100, 2200, 2260], body_size=8.6)


def add_scene_catalog(doc):
    add_heading(doc, "3. 씬 카탈로그", 1)
    add_body(doc, "런타임 씬은 조립 책임을 갖고, 실제 규칙과 상태 전이는 대응 GDScript에 위임합니다. 테스트 씬 2개는 별도 진입점으로 관리됩니다.")
    scene_rows = [
        ("MainMenu", "scenes/main/main_menu.tscn", "Control", "타이틀, 설정, 업적, 도감 페이지"),
        ("Game", "scenes/game/game.tscn", "Node2D", "전장·액터·성장·UI 통합 조립"),
        ("Battlefield", "scenes/battlefield/battlefield.tscn", "Node2D", "전장 좌표와 시각 기반"),
        ("Core", "scenes/actors/core.tscn", "Node2D", "방어 코어"),
        ("Enemy", "scenes/actors/enemy.tscn", "Node2D", "적 액터"),
        ("TargetCursor", "scenes/actors/target_cursor.tscn", "Node2D", "타깃 위치 표시"),
        ("ExperienceOrb", "scenes/pickups/experience_orb.tscn", "Node2D", "경험치 픽업"),
        ("HUD", "scenes/ui/hud.tscn", "Control", "전투 HUD와 결과 오버레이"),
        ("LevelUpPanel", "scenes/ui/level_up_panel.tscn", "Control", "3택과 편대 설치"),
        ("PauseMenu", "scenes/ui/pause_menu.tscn", "Control", "일시정지와 옵션"),
        ("SmokeTest", "tests/smoke_test.tscn", "Node", "헤드리스 스모크 테스트"),
        ("UISnapshotRunner", "tests/ui_snapshot.tscn", "Node", "UI 기준 이미지 생성"),
    ]
    add_table(doc, ["루트", "파일", "타입", "책임"], scene_rows, [1700, 3300, 1200, 3160], body_size=8.2)

    add_heading(doc, "3.1 Game 씬 조립 구조", 2)
    assembly_rows = [
        ("월드", "Battlefield, Enemies, TowerColumns, Pickups", "전투 공간과 동적 액터 컨테이너"),
        ("핵심 액터", "Core, TargetCursor, EnemySpawner", "방어 목표, 타깃, 적 생성"),
        ("진행", "LoadoutManager, ExperienceManager, ExperienceRewards", "빌드 상태, 경험치, 보상"),
        ("측정/효과", "RunMetrics, ScreenEffects, RangeOverlay", "통계, 화면 피드백, 공격 범위"),
        ("UI", "HUD, LevelUpPanel, PauseMenu", "전투 정보, 선택, 중단/복귀"),
    ]
    add_table(doc, ["영역", "노드/컴포넌트", "역할"], assembly_rows, [1700, 4100, 3560], body_size=8.8)


def add_script_modules(doc):
    add_heading(doc, "4. 기능 스크립트 모듈", 1)
    module_rows = [
        ("actors · 3", "core.gd, enemy.gd, target_cursor.gd", "핵심 액터 상태·표현·행동"),
        ("battlefield · 3", "battlefield.gd, enemy_spawner.gd, tower_column.gd", "전장 좌표, 스폰, 편대 열"),
        ("combat · 6", "combat_effect.gd, combat_range_overlay.gd, density_query_service.gd, projectile.gd, spatial_index.gd, targeting_service.gd", "발사체·효과·타깃 탐색·공간 질의"),
        ("effects · 1", "screen_effects.gd", "피격 플래시·화면 흔들림"),
        ("game · 4", "game_controller.gd, game_input_policy.gd, run_metrics.gd, run_result_service.gd", "상태 전이, 입력 허용, 런 통계·결과"),
        ("pickups · 1", "experience_orb.gd", "경험치 오브 이동·획득"),
        ("progression · 5", "experience_manager.gd, experience_reward_service.gd, growth_track_state.gd, loadout_manager.gd, specialization_offer_policy.gd", "레벨·보상·성장·빌드·특성 제안"),
        ("ui · 5", "flat_effect_icon.gd, hud.gd, level_up_panel.gd, main_menu.gd, pause_menu.gd", "HUD, 선택 패널, 메뉴, 공용 아이콘"),
    ]
    add_table(doc, ["모듈", "파일", "책임"], module_rows, [1700, 4900, 2760], body_size=8.15)

    add_heading(doc, "4.1 경계와 의존 방향", 2)
    boundary_rows = [
        ("UI → 게임", "버튼·키 입력을 의도 이벤트로 변환", "HUD가 전투 규칙을 직접 계산하지 않음"),
        ("GameController → 서비스", "게임 단계와 모듈 협력 조정", "결과 계산은 RunResultService에 위임"),
        ("전투 액터 → 질의 서비스", "타깃 선택·밀도·공간 인덱스 사용", "액터 내부 탐색 중복을 줄임"),
        ("성장 → 데이터/정책", "보상·특성 제안을 별도 정책으로 결정", "UI 선택 표시와 후보 생성 분리"),
        ("전역 → 런타임", "Autoload는 공용 상태·서비스만 제공", "씬 인스턴스의 지역 상태를 최소 침범"),
    ]
    add_table(doc, ["경계", "상호작용", "검토 기준"], boundary_rows, [2100, 3400, 3860], body_size=8.7)


def add_media(doc):
    add_heading(doc, "5. 그래픽 리소스", 1)
    groups = [
        ("배경", ROOT / "assets" / "graphics" / "backgrounds"),
        ("코어", ROOT / "assets" / "graphics" / "cores"),
        ("타깃 커서", ROOT / "assets" / "graphics" / "cursors"),
        ("적", ROOT / "assets" / "graphics" / "enemies"),
        ("발사체", ROOT / "assets" / "graphics" / "projectiles"),
        ("타워", ROOT / "assets" / "graphics" / "towers"),
    ]
    roles = {
        "배경": "전장과 메인 메뉴 배경",
        "코어": "방어 코어 공통 테스트 이미지",
        "타깃 커서": "iron/silver/gold/platinum 타깃 등급",
        "적": "일반형·특수형·중간 보스·최종 보스 외형",
        "발사체": "포탄·서리·키네틱·플라즈마",
        "타워": "공격 패턴별 타워 외형",
    }
    rows = []
    for label, path in groups:
        files = sorted(path.glob("*.png"))
        rows.append((label, len(files), rel(path), names(files), roles[label]))
    add_table(doc, ["분류", "수량", "경로", "파일", "용도"], rows, [1100, 600, 2100, 3550, 2010], body_size=7.55)

    add_heading(doc, "5.1 UI 기준 이미지", 2)
    snapshots = sorted((ROOT / "tests" / "ui_snapshots").glob("*.png"))
    snapshot_rows = [
        ("메뉴/설정", "main_menu.png, game_setup.png, achievements.png, codex.png"),
        ("전투", "gameplay_hud.png, attack_ranges.png, effects_showcase.png"),
        ("성장/배치", "level_up_choices.png, specialization_choices.png, final_trait_choices.png, formation_placement.png"),
        ("도감/로스터", "tower_roster.png, enemy_roster.png, boss_roster.png, tower_attack_patterns.png"),
        ("중단/결과", "pause_menu.png, pause_options.png, result_screen.png"),
    ]
    add_table(doc, ["화면군", "기준 이미지"], snapshot_rows, [1900, 7460], body_size=8.8)
    add_callout(doc, "수량 확인", f"tests/ui_snapshots에는 PNG {len(snapshots)}개가 있으며, tests/ui_snapshot.tscn과 ui_snapshot_runner.gd가 생성 진입점입니다.")

    add_heading(doc, "5.2 와이어프레임", 2)
    wireframe_rows = [
        ("기존", "docs/wireframes/td-survival-wireframe.png", "메뉴→설정→전투→성장→결과"),
        ("현재", "docs/wireframes/td-survival-wireframe-v2.png", "일시정지 분기와 Space/F/G/Esc/1·2·3 조작 힌트 보강"),
    ]
    add_table(doc, ["버전", "파일", "범위"], wireframe_rows, [1200, 4100, 4060], body_size=8.9)

    add_heading(doc, "6. 오디오 리소스", 1)
    purpose = {
        "boss_spawn.wav": "보스 등장",
        "boss_warning.wav": "보스 경고",
        "core_hit.wav": "코어 피격",
        "core_skill.wav": "코어 스킬",
        "defeat.wav": "패배 결과",
        "hit_heavy.wav": "강한 타격",
        "hit_light.wav": "약한 타격",
        "level_up.wav": "레벨업",
        "ui_click.wav": "UI 클릭",
        "victory.wav": "승리 결과",
    }
    audio_rows = []
    for path in sorted((ROOT / "assets" / "audio").rglob("*.wav")):
        audio_rows.append((path.parent.name, path.name, purpose[path.name], f"{duration_seconds(path):.2f}s", f"{path.stat().st_size / 1024:.1f} KB"))
    add_table(doc, ["분류", "파일", "이벤트", "길이", "크기"], audio_rows, [1350, 2600, 2500, 1100, 1810], body_size=8.6)


def add_qa_and_docs(doc):
    add_heading(doc, "7. 테스트·문서·지원 리소스", 1)
    qa_rows = [
        ("스모크 테스트", "tests/smoke_test.tscn + smoke_test_runner.gd", "헤드리스 기능 연결 검증"),
        ("UI 스냅샷", "tests/ui_snapshot.tscn + ui_snapshot_runner.gd", "18개 기준 화면 캡처"),
        ("SFX 생성기", "tools/generate_sfx.py", "테스트 WAV 생성"),
        ("목록서 생성기", "tools/build_resource_inventory_doc.py", "현재 DOCX 재생성"),
        ("프로젝트 설정", "project.godot", "시작 씬, Autoload, 입력, 표시/렌더링"),
        ("프로젝트 아이콘", "icon.svg", "애플리케이션 아이콘"),
    ]
    add_table(doc, ["구분", "파일", "역할"], qa_rows, [1900, 4300, 3160], body_size=8.7)

    add_heading(doc, "7.1 기획·상태 문서", 2)
    md_files = sorted(ROOT.glob("*.md")) + sorted((ROOT / "docs").glob("*.md"))
    doc_rows = []
    for path in md_files:
        name = path.name
        if name == "AGENTS.md":
            role = "작업 컨텍스트 운영 지침"
        elif name == "SHARED_CONTEXT.md":
            role = "현재 구현 기준 공유 컨텍스트"
        elif "gdd" in name.lower():
            role = "게임 디자인 문서"
        elif "status" in name.lower():
            role = "구현/프로젝트 상태"
        elif "plan" in name.lower():
            role = "구현 계획"
        elif "reference" in name.lower():
            role = "설계 참고"
        else:
            role = "프로젝트 설명"
        doc_rows.append((rel(path), role))
    add_table(doc, ["문서", "역할"], doc_rows, [6200, 3160], body_size=8.4)

    add_heading(doc, "7.2 검증 명령", 2)
    commands = [
        ("임포트/구문", "Godot_v4.7-stable_win64_console.exe --headless --editor --path . --quit"),
        ("스모크", "Godot_v4.7-stable_win64_console.exe --headless --path . res://tests/smoke_test.tscn"),
        ("UI 스냅샷", "Godot_v4.7-stable_win64_console.exe --headless --path . res://tests/ui_snapshot.tscn"),
    ]
    add_table(doc, ["범위", "명령"], commands, [1800, 7560], body_size=8.2)
    add_callout(doc, "이번 문서 작업", "리소스 조사와 문서 렌더 QA를 수행했으며, 게임 코드나 데이터는 변경하지 않았습니다. Godot 런타임 테스트는 별도 실행하지 않았습니다.", fill=LIGHT_GRAY, accent=GOLD)


def add_management(doc):
    add_heading(doc, "8. 관리 포인트", 1)
    rows = [
        ("ID/표시명 불일치", "data/stages/standard_20m.tres", "id는 standard_20m이지만 표시명과 duration은 10분/600초", "호환 의도 확인 전 임의 변경 금지"),
        ("GDD 기준선", "gdd v0.3 / v0.4", "README·상태 문서는 v0.3을 가리키지만 v0.4가 더 최근", "다음 기획 변경 전에 기준 버전 확정"),
        ("미완성 메뉴", "main_menu.tscn", "업적과 도감 페이지가 placeholder 상태", "콘텐츠 데이터와 해금 규칙 연결 필요"),
        ("생성형 테스트 아트", "assets/graphics", "프로토타입 품질의 PNG 중심", "최종 아트·애니메이션·규격표 필요"),
        ("모바일 검증", "1280×720 기준", "실기기 UX·성능·발열은 미검증", "터치 타깃, 안전 영역, 프레임/메모리 측정"),
        ("UI 회귀", "tests/ui_snapshots", "생성 성공과 승인 이미지는 다름", "변경 시 모든 화면 육안 비교"),
    ]
    add_table(doc, ["항목", "위치", "현재 상태", "권장 조치"], rows, [1700, 2400, 2700, 2560], body_size=8.25)

    add_heading(doc, "8.1 리소스 운영 규칙", 2)
    rules = [
        ("소스와 캐시 분리", ".uid와 .import는 엔진 메타데이터로 분리 집계하고, .godot 캐시는 목록 기준에서 제외합니다."),
        ("런타임 경로 안정성", "씬/스크립트/데이터 경로 변경 시 ext_resource와 preload 참조를 함께 검증합니다."),
        ("생성 자산 추적", "assets/graphics는 런타임 역할별 하위 폴더를 유지하고, 최종 자산 도입 시 출처/라이선스 정보를 추가합니다."),
        ("UI 승인 기준", "tests/ui_snapshots의 캡처를 화면별 기준선으로 사용하되, 자동 생성 이후 육안 승인을 별도로 기록합니다."),
        ("문서 갱신", "구조·입력·Autoload·핵심 경로가 바뀌면 docs/SHARED_CONTEXT.md와 이 목록서를 함께 갱신합니다."),
    ]
    add_table(doc, ["규칙", "적용 방법"], rules, [2200, 7160], body_size=8.8)


def add_wireframe_page(doc):
    doc.add_page_break()
    add_heading(doc, "부록 A. 게임 진행/조작 와이어프레임", 1)
    add_body(doc, "메뉴, 게임 설정, 전투, 레벨업, 편대 설치, 일시정지, 결과 화면의 기본 흐름과 주요 키 조작을 한 장으로 정리한 동반 산출물입니다.")
    if WIREFRAME.exists():
        p = doc.add_paragraph()
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        run = p.add_run()
        inline = run.add_picture(str(WIREFRAME), width=Inches(6.25))
        doc_pr = inline._inline.docPr
        doc_pr.set("descr", "TD Survival 게임 진행 및 조작 흐름 와이어프레임")
        caption = doc.add_paragraph()
        caption.alignment = WD_ALIGN_PARAGRAPH.CENTER
        caption.paragraph_format.space_before = Pt(4)
        r = caption.add_run("그림 A-1. TD Survival 와이어프레임 v2")
        set_run_font(r, size=9, color=MUTED, italic=True)
    add_callout(doc, "원본 파일", "docs/wireframes/td-survival-wireframe-v2.png · 1672 × 941 PNG")


def add_appendix_manifest(doc, files):
    add_heading(doc, "부록 B. 경로별 전체 목록", 1)
    add_body(doc, "아래 목록은 조사 범위에 포함된 모든 파일을 상위 경로별로 압축 정리한 것입니다. Word 산출물 자체와 엔진 캐시/임포트 메타데이터는 제외합니다.")
    buckets = {}
    for path in files:
        relative = path.relative_to(ROOT)
        if len(relative.parts) == 1:
            key = "프로젝트 루트"
        elif relative.parts[0] in {"assets", "scripts", "scenes", "tests", "docs", "data"} and len(relative.parts) >= 2:
            key = "/".join(relative.parts[:2])
        else:
            key = relative.parts[0]
        buckets.setdefault(key, []).append(relative.as_posix())
    rows = []
    for key in sorted(buckets):
        values = buckets[key]
        rows.append((key, len(values), "\n".join(values)))
    add_table(doc, ["경로군", "수량", "파일"], rows, [1750, 700, 6910], body_size=7.25)


def set_core_properties(doc):
    props = doc.core_properties
    props.title = "TD Survival 리소스 목록서"
    props.subject = "Godot 4.7 TD Survival 프로젝트 리소스 인벤토리"
    props.author = "TD Survival Development"
    props.keywords = "Godot, TD Survival, Resource Inventory, Wireframe"
    props.comments = "Generated from the project workspace on 2026-07-29."


def audit_docx(path):
    with zipfile.ZipFile(path) as archive:
        bad_member = archive.testzip()
        assert bad_member is None, f"corrupt member: {bad_member}"
        required = {"word/document.xml", "word/styles.xml", "word/settings.xml"}
        assert required.issubset(set(archive.namelist()))

    checked = Document(path)
    assert len(checked.sections) == 1
    section = checked.sections[0]
    assert round(section.page_width.inches, 2) == 8.50
    assert round(section.page_height.inches, 2) == 11.00
    assert all(
        round(value.inches, 2) == 1.00
        for value in (section.top_margin, section.right_margin, section.bottom_margin, section.left_margin)
    )
    assert len(checked.inline_shapes) == 1

    combined_text = "\n".join(paragraph.text for paragraph in checked.paragraphs)
    forbidden = ("codex-file-citation", "lorem ipsum", "TODO", "확인 필요")
    assert not any(token.lower() in combined_text.lower() for token in forbidden)

    for index, table in enumerate(checked.tables, 1):
        tbl_pr = table._tbl.tblPr
        tbl_w = tbl_pr.find(qn("w:tblW"))
        tbl_ind = tbl_pr.find(qn("w:tblInd"))
        assert tbl_w is not None and int(tbl_w.get(qn("w:w"))) == CONTENT_DXA, index
        assert tbl_ind is not None and int(tbl_ind.get(qn("w:w"))) == TABLE_INDENT_DXA, index
        grid_widths = [int(node.get(qn("w:w"))) for node in table._tbl.tblGrid.findall(qn("w:gridCol"))]
        assert sum(grid_widths) == CONTENT_DXA, (index, grid_widths)
        for row in table.rows:
            cell_widths = []
            for cell in row.cells:
                tc_w = cell._tc.get_or_add_tcPr().find(qn("w:tcW"))
                assert tc_w is not None, index
                cell_widths.append(int(tc_w.get(qn("w:w"))))
            assert cell_widths == grid_widths, (index, cell_widths, grid_widths)

    print(
        f"audit=ok paragraphs:{len(checked.paragraphs)} tables:{len(checked.tables)} "
        f"images:{len(checked.inline_shapes)} size:{path.stat().st_size}"
    )


def main():
    files = meaningful_files()
    counts = Counter(path.suffix.lower() for path in files)
    doc = Document()
    configure_document(doc)
    set_core_properties(doc)

    add_cover(doc, len(files), counts)
    add_summary(doc, len(files), counts)
    add_architecture(doc)
    add_scene_catalog(doc)
    add_script_modules(doc)
    add_media(doc)
    add_qa_and_docs(doc)
    add_management(doc)
    add_wireframe_page(doc)
    add_appendix_manifest(doc, files)

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    doc.save(OUTPUT)
    audit_docx(OUTPUT)
    print(f"saved={OUTPUT}")
    print(f"files={len(files)}")
    print("extensions=" + ", ".join(f"{k}:{v}" for k, v in counts.most_common()))


if __name__ == "__main__":
    main()
