from __future__ import annotations

import html
import re
from pathlib import Path
from typing import Iterable

from reportlab.lib import colors
from reportlab.lib.colors import HexColor
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    BaseDocTemplate,
    Frame,
    HRFlowable,
    KeepTogether,
    ListFlowable,
    ListItem,
    PageBreak,
    PageTemplate,
    Paragraph,
    Spacer,
    Table,
    TableStyle,
)
from reportlab.platypus.tableofcontents import TableOfContents


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "docs" / "manuals"
OUTPUT_DIR = ROOT / "output" / "pdf"
FONT_PATH = ROOT / "fn" / "safevege" / "assets" / "fonts" / "NotoSansThai-Variable.ttf"
FONT_NAME = "SafeVegeThai"
PAGE_WIDTH, PAGE_HEIGHT = A4
MARGIN_LEFT = 19 * mm
MARGIN_RIGHT = 19 * mm
MARGIN_TOP = 19 * mm
MARGIN_BOTTOM = 18 * mm
CONTENT_WIDTH = PAGE_WIDTH - MARGIN_LEFT - MARGIN_RIGHT

GREEN = HexColor("#145A43")
GREEN_DARK = HexColor("#0C3D30")
GREEN_SOFT = HexColor("#E8F4EE")
MINT = HexColor("#F3F8F5")
GOLD = HexColor("#C89B3C")
INK = HexColor("#20322C")
MUTED = HexColor("#587068")
GRID = HexColor("#C9DCD3")


def register_font() -> None:
    if not FONT_PATH.is_file():
        raise FileNotFoundError(f"Thai font not found: {FONT_PATH}")
    pdfmetrics.registerFont(TTFont(FONT_NAME, str(FONT_PATH)))


def make_styles() -> dict[str, ParagraphStyle]:
    base = getSampleStyleSheet()
    return {
        "body": ParagraphStyle(
            "ManualBody",
            parent=base["BodyText"],
            fontName=FONT_NAME,
            fontSize=9.6,
            leading=14.2,
            textColor=INK,
            spaceAfter=6,
            wordWrap="CJK",
            splitLongWords=True,
        ),
        "cover_brand": ParagraphStyle(
            "CoverBrand",
            fontName=FONT_NAME,
            fontSize=11,
            leading=14,
            textColor=GOLD,
            alignment=TA_CENTER,
            spaceAfter=10,
        ),
        "cover_title": ParagraphStyle(
            "CoverTitle",
            fontName=FONT_NAME,
            fontSize=24,
            leading=32,
            textColor=GREEN_DARK,
            alignment=TA_CENTER,
            spaceAfter=10,
            wordWrap="CJK",
        ),
        "cover_subtitle": ParagraphStyle(
            "CoverSubtitle",
            fontName=FONT_NAME,
            fontSize=11.5,
            leading=18,
            textColor=MUTED,
            alignment=TA_CENTER,
            wordWrap="CJK",
        ),
        "cover_note": ParagraphStyle(
            "CoverNote",
            fontName=FONT_NAME,
            fontSize=8.5,
            leading=12,
            textColor=MUTED,
            alignment=TA_CENTER,
            wordWrap="CJK",
        ),
        "h1": ParagraphStyle(
            "ManualHeading1",
            parent=base["Heading1"],
            fontName=FONT_NAME,
            fontSize=16,
            leading=22,
            textColor=GREEN_DARK,
            spaceBefore=12,
            spaceAfter=8,
            keepWithNext=True,
            wordWrap="CJK",
        ),
        "h2": ParagraphStyle(
            "ManualHeading2",
            parent=base["Heading2"],
            fontName=FONT_NAME,
            fontSize=12.2,
            leading=17,
            textColor=GREEN,
            spaceBefore=9,
            spaceAfter=5,
            keepWithNext=True,
            wordWrap="CJK",
        ),
        "h3": ParagraphStyle(
            "ManualHeading3",
            parent=base["Heading3"],
            fontName=FONT_NAME,
            fontSize=10.6,
            leading=15,
            textColor=GREEN,
            spaceBefore=7,
            spaceAfter=4,
            keepWithNext=True,
            wordWrap="CJK",
        ),
        "bullet": ParagraphStyle(
            "ManualBullet",
            parent=base["BodyText"],
            fontName=FONT_NAME,
            fontSize=9.4,
            leading=13.4,
            textColor=INK,
            wordWrap="CJK",
            splitLongWords=True,
        ),
        "table": ParagraphStyle(
            "ManualTable",
            parent=base["BodyText"],
            fontName=FONT_NAME,
            fontSize=8.2,
            leading=11.3,
            textColor=INK,
            wordWrap="CJK",
            splitLongWords=True,
        ),
        "table_header": ParagraphStyle(
            "ManualTableHeader",
            parent=base["BodyText"],
            fontName=FONT_NAME,
            fontSize=8.3,
            leading=11.5,
            textColor=colors.white,
            wordWrap="CJK",
            splitLongWords=True,
        ),
        "code": ParagraphStyle(
            "ManualCode",
            parent=base["Code"],
            fontName=FONT_NAME,
            fontSize=7.4,
            leading=10.2,
            textColor=GREEN_DARK,
            wordWrap="CJK",
            splitLongWords=True,
        ),
        "quote": ParagraphStyle(
            "ManualQuote",
            parent=base["BodyText"],
            fontName=FONT_NAME,
            fontSize=9.2,
            leading=13.4,
            textColor=GREEN_DARK,
            leftIndent=2,
            wordWrap="CJK",
            splitLongWords=True,
        ),
        "contents_title": ParagraphStyle(
            "ManualContentsTitle",
            parent=base["Heading1"],
            fontName=FONT_NAME,
            fontSize=18,
            leading=24,
            textColor=GREEN_DARK,
            spaceAfter=10,
        ),
        "toc1": ParagraphStyle(
            "ManualTOC1",
            fontName=FONT_NAME,
            fontSize=10.2,
            leading=16,
            textColor=GREEN_DARK,
            leftIndent=0,
            firstLineIndent=0,
        ),
        "toc2": ParagraphStyle(
            "ManualTOC2",
            fontName=FONT_NAME,
            fontSize=9.3,
            leading=13,
            textColor=MUTED,
            leftIndent=12,
            firstLineIndent=0,
        ),
        "toc3": ParagraphStyle(
            "ManualTOC3",
            fontName=FONT_NAME,
            fontSize=8.8,
            leading=12,
            textColor=MUTED,
            leftIndent=24,
            firstLineIndent=0,
        ),
        "small": ParagraphStyle(
            "ManualSmall",
            fontName=FONT_NAME,
            fontSize=8,
            leading=11,
            textColor=MUTED,
            wordWrap="CJK",
            splitLongWords=True,
        ),
    }


def inline_markup(text: str) -> str:
    escaped = html.escape(text, quote=False)
    escaped = re.sub(r"`([^`]+)`", r'<font color="#145A43"><b>\1</b></font>', escaped)
    escaped = re.sub(r"\*\*([^*]+)\*\*", r"<b>\1</b>", escaped)
    return escaped


def parse_table_row(line: str) -> list[str]:
    row = line.strip()
    if row.startswith("|"):
        row = row[1:]
    if row.endswith("|"):
        row = row[:-1]
    return [cell.strip() for cell in row.split("|")]


def is_table_separator(line: str) -> bool:
    cells = parse_table_row(line)
    return bool(cells) and all(re.fullmatch(r":?-{3,}:?", cell.replace(" ", "")) for cell in cells)


def make_table(lines: list[str], styles: dict[str, ParagraphStyle]) -> Table:
    raw_rows = [parse_table_row(line) for line in lines if not is_table_separator(line)]
    column_count = max(len(row) for row in raw_rows)
    normalized = [row + [""] * (column_count - len(row)) for row in raw_rows]
    cells: list[list[Paragraph]] = []
    for row_index, row in enumerate(normalized):
        style = styles["table_header"] if row_index == 0 else styles["table"]
        cells.append([Paragraph(inline_markup(cell), style) for cell in row])

    if column_count == 2:
        widths = [CONTENT_WIDTH * 0.34, CONTENT_WIDTH * 0.66]
    elif column_count == 3:
        widths = [CONTENT_WIDTH * 0.24, CONTENT_WIDTH * 0.42, CONTENT_WIDTH * 0.34]
    else:
        widths = [CONTENT_WIDTH / column_count] * column_count

    table = Table(cells, colWidths=widths, repeatRows=1, hAlign="LEFT", splitByRow=1)
    table.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), GREEN),
                ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                ("GRID", (0, 0), (-1, -1), 0.35, GRID),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("LEFTPADDING", (0, 0), (-1, -1), 6),
                ("RIGHTPADDING", (0, 0), (-1, -1), 6),
                ("TOPPADDING", (0, 0), (-1, -1), 5),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
                ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, MINT]),
            ]
        )
    )
    return table


def make_code_block(lines: list[str], styles: dict[str, ParagraphStyle]) -> Table:
    rows = [[Paragraph(inline_markup(line) if line else "&nbsp;", styles["code"])] for line in lines]
    table = Table(rows, colWidths=[CONTENT_WIDTH], hAlign="LEFT", splitByRow=1)
    table.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, -1), HexColor("#F0F6F3")),
                ("BOX", (0, 0), (-1, -1), 0.5, GRID),
                ("LEFTPADDING", (0, 0), (-1, -1), 8),
                ("RIGHTPADDING", (0, 0), (-1, -1), 8),
                ("TOPPADDING", (0, 0), (-1, -1), 3),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
            ]
        )
    )
    return table


def make_quote(lines: list[str], styles: dict[str, ParagraphStyle]) -> Table:
    text = "<br/>".join(inline_markup(line[2:].strip()) for line in lines)
    table = Table([[Paragraph(text, styles["quote"])]], colWidths=[CONTENT_WIDTH], hAlign="LEFT")
    table.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, -1), GREEN_SOFT),
                ("LINEBEFORE", (0, 0), (0, -1), 3, GOLD),
                ("BOX", (0, 0), (-1, -1), 0.35, GRID),
                ("LEFTPADDING", (0, 0), (-1, -1), 9),
                ("RIGHTPADDING", (0, 0), (-1, -1), 9),
                ("TOPPADDING", (0, 0), (-1, -1), 7),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 7),
            ]
        )
    )
    return table


def make_list(items: list[str], styles: dict[str, ParagraphStyle], ordered: bool) -> ListFlowable:
    list_items = [ListItem(Paragraph(inline_markup(item), styles["bullet"]), leftIndent=4) for item in items]
    options = {
        "bulletType": "1" if ordered else "bullet",
        "bulletFontName": FONT_NAME,
        "bulletFontSize": 8,
        "leftIndent": 16,
        "bulletOffsetY": 2,
        "spaceAfter": 6,
    }
    if ordered:
        options["start"] = "1"
    return ListFlowable(list_items, **options)


def is_special_line(lines: list[str], index: int) -> bool:
    line = lines[index]
    if line.startswith("```") or re.match(r"^#{2,6}\s+", line):
        return True
    if re.match(r"^\s*[-*]\s+", line) or re.match(r"^\s*\d+\.\s+", line):
        return True
    if line.startswith("> ") or line.strip() == "---":
        return True
    return line.startswith("|") and index + 1 < len(lines) and is_table_separator(lines[index + 1])


def parse_markdown(path: Path, styles: dict[str, ParagraphStyle]) -> tuple[str, list]:
    lines = path.read_text(encoding="utf-8-sig").splitlines()
    title = path.stem
    story: list = []
    i = 0
    while i < len(lines):
        line = lines[i].rstrip()
        if not line.strip():
            i += 1
            continue

        h1 = re.match(r"^#\s+(.+)$", line)
        if h1:
            title = h1.group(1).strip()
            i += 1
            continue

        if line.startswith("```"):
            code_lines: list[str] = []
            i += 1
            while i < len(lines) and not lines[i].startswith("```"):
                code_lines.append(lines[i].rstrip())
                i += 1
            if i < len(lines):
                i += 1
            story.extend([make_code_block(code_lines, styles), Spacer(1, 5)])
            continue

        heading = re.match(r"^(#{2,6})\s+(.+)$", line)
        if heading:
            level = min(len(heading.group(1)) - 1, 3)
            story.append(Paragraph(inline_markup(heading.group(2).strip()), styles[f"h{level}"]))
            i += 1
            continue

        if line.startswith("|") and i + 1 < len(lines) and is_table_separator(lines[i + 1]):
            table_lines = [line]
            i += 1
            while i < len(lines) and lines[i].startswith("|"):
                table_lines.append(lines[i].rstrip())
                i += 1
            story.extend([make_table(table_lines, styles), Spacer(1, 7)])
            continue

        if re.match(r"^\s*[-*]\s+", line):
            items: list[str] = []
            while i < len(lines):
                match = re.match(r"^\s*[-*]\s+(.+)$", lines[i].rstrip())
                if not match:
                    break
                items.append(match.group(1).strip())
                i += 1
            story.append(make_list(items, styles, ordered=False))
            continue

        if re.match(r"^\s*\d+\.\s+", line):
            items = []
            while i < len(lines):
                match = re.match(r"^\s*\d+\.\s+(.+)$", lines[i].rstrip())
                if not match:
                    break
                items.append(match.group(1).strip())
                i += 1
            story.append(make_list(items, styles, ordered=True))
            continue

        if line.startswith("> "):
            quote_lines = []
            while i < len(lines) and lines[i].startswith("> "):
                quote_lines.append(lines[i].rstrip())
                i += 1
            story.extend([make_quote(quote_lines, styles), Spacer(1, 7)])
            continue

        if line.strip() == "---":
            story.extend([HRFlowable(width="100%", thickness=0.5, color=GRID, spaceBefore=4, spaceAfter=8)])
            i += 1
            continue

        paragraph_lines = [line.strip()]
        i += 1
        while i < len(lines) and lines[i].strip() and not is_special_line(lines, i):
            paragraph_lines.append(lines[i].strip())
            i += 1
        story.append(Paragraph(inline_markup(" ".join(paragraph_lines)), styles["body"]))

    return title, story


class ManualDocTemplate(BaseDocTemplate):
    def __init__(self, filename: str, title: str, author: str, **kwargs) -> None:
        self.manual_title = title
        self._heading_count = 0
        super().__init__(
            filename,
            pagesize=A4,
            leftMargin=MARGIN_LEFT,
            rightMargin=MARGIN_RIGHT,
            topMargin=MARGIN_TOP,
            bottomMargin=MARGIN_BOTTOM,
            title=title,
            author=author,
            subject="คู่มือ SafeVege ภาษาไทย",
            **kwargs,
        )
        frame = Frame(self.leftMargin, self.bottomMargin, self.width, self.height, id="manual")
        self.addPageTemplates([PageTemplate(id="manual", frames=[frame], onPage=draw_page)])

    def afterFlowable(self, flowable) -> None:
        if not isinstance(flowable, Paragraph):
            return
        style_name = flowable.style.name
        level_map = {"ManualHeading1": 0, "ManualHeading2": 1, "ManualHeading3": 2}
        if style_name not in level_map:
            return
        level = level_map[style_name]
        text = flowable.getPlainText()
        self._heading_count += 1
        key = f"heading-{self._heading_count}"
        self.canv.bookmarkPage(key)
        self.canv.addOutlineEntry(text, key, level=level, closed=False)
        self.notify("TOCEntry", (level, text, self.page))


def draw_page(canvas, document) -> None:
    page_number = canvas.getPageNumber()
    canvas.saveState()
    if page_number == 1:
        canvas.setFillColor(HexColor("#E8F4EE"))
        canvas.rect(0, 0, PAGE_WIDTH, PAGE_HEIGHT, fill=1, stroke=0)
        canvas.setFillColor(HexColor("#CFE8DA"))
        canvas.circle(PAGE_WIDTH + 4 * mm, PAGE_HEIGHT - 8 * mm, 43 * mm, fill=1, stroke=0)
        canvas.setFillColor(HexColor("#D9EFE2"))
        canvas.circle(-8 * mm, -3 * mm, 35 * mm, fill=1, stroke=0)
    else:
        canvas.setStrokeColor(GRID)
        canvas.setLineWidth(0.45)
        canvas.line(MARGIN_LEFT, PAGE_HEIGHT - 12 * mm, PAGE_WIDTH - MARGIN_RIGHT, PAGE_HEIGHT - 12 * mm)
        canvas.setFont(FONT_NAME, 7.4)
        canvas.setFillColor(MUTED)
        canvas.drawString(MARGIN_LEFT, PAGE_HEIGHT - 9 * mm, "SafeVege")
        canvas.drawRightString(PAGE_WIDTH - MARGIN_RIGHT, PAGE_HEIGHT - 9 * mm, "คู่มือการใช้งานระบบ")
        canvas.line(MARGIN_LEFT, 12 * mm, PAGE_WIDTH - MARGIN_RIGHT, 12 * mm)
        canvas.drawString(MARGIN_LEFT, 8 * mm, "เอกสารอ้างอิงจากโปรเจกต์ SafeVege")
        canvas.drawRightString(PAGE_WIDTH - MARGIN_RIGHT, 8 * mm, f"หน้า {page_number}")
    canvas.restoreState()


def cover_story(title: str, subtitle: str, styles: dict[str, ParagraphStyle]) -> list:
    card = Table(
        [[Paragraph("เอกสารภาษาไทย · อ้างอิงจากโค้ดและเอกสารในรีโป", styles["cover_note"])]],
        colWidths=[CONTENT_WIDTH * 0.82],
        hAlign="CENTER",
    )
    card.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, -1), colors.white),
                ("BOX", (0, 0), (-1, -1), 0.6, GRID),
                ("LEFTPADDING", (0, 0), (-1, -1), 10),
                ("RIGHTPADDING", (0, 0), (-1, -1), 10),
                ("TOPPADDING", (0, 0), (-1, -1), 8),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 8),
            ]
        )
    )
    return [
        Spacer(1, 33 * mm),
        Paragraph("SAFEVEGE", styles["cover_brand"]),
        Paragraph(inline_markup(title), styles["cover_title"]),
        Paragraph(inline_markup(subtitle), styles["cover_subtitle"]),
        Spacer(1, 16 * mm),
        card,
        Spacer(1, 23 * mm),
        Paragraph("วันที่จัดทำ: 25 ตุลาคม 2026", styles["cover_note"]),
        PageBreak(),
    ]


def build_pdf(source_name: str, output_name: str, subtitle: str) -> Path:
    styles = make_styles()
    source = SOURCE_DIR / source_name
    output = OUTPUT_DIR / output_name
    title, content = parse_markdown(source, styles)
    doc = ManualDocTemplate(str(output), title=title, author="SafeVege")
    toc = TableOfContents()
    toc.levelStyles = [styles["toc1"], styles["toc2"], styles["toc3"]]
    story = cover_story(title, subtitle, styles)
    story.extend(
        [
            Paragraph("สารบัญ", styles["contents_title"]),
            Spacer(1, 3),
            toc,
            PageBreak(),
        ]
    )
    story.extend(content)
    doc.multiBuild(story)
    return output


def main() -> None:
    register_font()
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    outputs = [
        build_pdf(
            "safevege-user-manual.md",
            "safevege-user-manual-th.pdf",
            "คู่มือสำหรับผู้เยี่ยมชม ร้านค้า และผู้ดูแลระบบ",
        ),
        build_pdf(
            "safevege-developer-manual.md",
            "safevege-developer-manual-th.pdf",
            "คู่มือโครงสร้างระบบ การตั้งค่า ฐานข้อมูล และการพัฒนาต่อ",
        ),
    ]
    for output in outputs:
        print(f"Wrote {output} ({output.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
