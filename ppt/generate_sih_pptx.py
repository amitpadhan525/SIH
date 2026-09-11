import os
import sys
from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN, MSO_ANCHOR
from pptx.enum.shapes import MSO_SHAPE
from pptx.oxml import parse_xml
from pptx.oxml.ns import nsdecls

INPUT_PPTX = '/home/amit/github/SIH/ppt/SIH2026-IDEA-Presentation-Format (1).pptx'
OUTPUT_PPTX_6SLIDES = '/home/amit/github/SIH/ppt/SIH2026_ArtisanAI_Presentation.pptx'
OUTPUT_PPTX_TEMPLATE_OVERWRITE = '/home/amit/github/SIH/ppt/SIH2026-IDEA-Presentation-Format (1).pptx'

prs = Presentation(INPUT_PPTX)

# Palette Definitions
COLOR_PRIMARY_DARK  = RGBColor(20, 32, 48)     # Deep Navy
COLOR_ACCENT_ORANGE = RGBColor(211, 84, 0)     # Terracotta / Artisan Orange
COLOR_TEXT_MAIN     = RGBColor(40, 50, 60)     # Charcoal Slate Body Text
COLOR_TEXT_MUTED    = RGBColor(100, 110, 120)  # Muted Grey
COLOR_BLUE_HEADING  = RGBColor(18, 78, 140)    # Deep Cobalt Blue Header
COLOR_CARD_BG       = RGBColor(248, 250, 252)  # Soft Canvas White/Slate
COLOR_CARD_BORDER   = RGBColor(220, 226, 235)  # Light Border

def setup_header(slide, title_text, team_text="[Your Team Name]"):
    """
    Guarantees zero overlap with:
    - Team Oval on left (left=0.4", width=1.45")
    - SIH Logo on right (left=10.7", width=2.46")
    Title sits cleanly in middle (left=2.0", width=8.5")
    """
    for shape in slide.shapes:
        if shape.name.startswith("Oval") and shape.has_text_frame:
            shape.left = Inches(0.4)
            shape.top = Inches(0.18)
            shape.width = Inches(1.45)
            shape.height = Inches(0.85)
            shape.text_frame.clear()
            p = shape.text_frame.paragraphs[0]
            p.text = team_text
            p.font.name = 'Calibri'
            p.font.size = Pt(10)
            p.font.bold = True
            p.alignment = PP_ALIGN.CENTER
            shape.text_frame.vertical_anchor = MSO_ANCHOR.MIDDLE
        elif shape.name.startswith("Title") and shape.has_text_frame:
            shape.left = Inches(1.95)
            shape.top = Inches(0.12)
            shape.width = Inches(8.65)
            shape.height = Inches(0.95)
            shape.text_frame.clear()
            shape.text_frame.margin_left = shape.text_frame.margin_right = Inches(0.05)
            shape.text_frame.margin_top = shape.text_frame.margin_bottom = Inches(0.05)
            shape.text_frame.vertical_anchor = MSO_ANCHOR.MIDDLE
            p = shape.text_frame.paragraphs[0]
            p.text = title_text
            p.font.name = 'Calibri'
            p.font.size = Pt(21)
            p.font.bold = True
            p.font.color.rgb = COLOR_PRIMARY_DARK
            p.alignment = PP_ALIGN.CENTER

def create_card(slide, left, top, width, height):
    """Creates a structured rounded rectangle card container"""
    shape = slide.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, left, top, width, height)
    shape.fill.solid()
    shape.fill.fore_color.rgb = COLOR_CARD_BG
    shape.line.color.rgb = COLOR_CARD_BORDER
    shape.line.width = Pt(1)
    
    tf = shape.text_frame
    tf.word_wrap = True
    tf.margin_left = Inches(0.18)
    tf.margin_right = Inches(0.18)
    tf.margin_top = Inches(0.16)
    tf.margin_bottom = Inches(0.14)
    tf.clear()
    return tf

def disable_bullet(p):
    """Explicitly removes any inherited layout bullet marker"""
    pPr = p._p.get_or_add_pPr()
    for child in list(pPr):
        if child.tag.endswith('buChar') or child.tag.endswith('buAutoNum') or child.tag.endswith('buNone') or child.tag.endswith('buFont'):
            pPr.remove(child)
    bu_none = parse_xml(f'<a:buNone {nsdecls("a")}/>')
    pPr.append(bu_none)

def add_card_header(tf, title, space_before=0, space_after=3):
    p = tf.paragraphs[0] if len(tf.paragraphs) == 1 and tf.paragraphs[0].text == '' else tf.add_paragraph()
    disable_bullet(p)
    p.text = title
    p.font.name = 'Calibri'
    p.font.size = Pt(12.5)
    p.font.bold = True
    p.font.color.rgb = COLOR_BLUE_HEADING
    p.space_before = Pt(space_before)
    p.space_after = Pt(space_after)
    p.alignment = PP_ALIGN.LEFT
    return p

def add_card_bullet(tf, bold_prefix, text_body, font_size=10, space_after=3.5):
    p = tf.add_paragraph()
    disable_bullet(p)
    p.space_before = Pt(0)
    p.space_after = Pt(space_after)
    p.line_spacing = 1.12
    p.alignment = PP_ALIGN.LEFT
    
    # Bullet icon + bold label
    r0 = p.add_run()
    r0.text = "▪  " + bold_prefix + " "
    r0.font.name = 'Calibri'
    r0.font.size = Pt(font_size)
    r0.font.bold = True
    r0.font.color.rgb = COLOR_PRIMARY_DARK
    
    # Normal description
    r1 = p.add_run()
    r1.text = text_body
    r1.font.name = 'Calibri'
    r1.font.size = Pt(font_size)
    r1.font.bold = False
    r1.font.color.rgb = COLOR_TEXT_MAIN

# -------------------------------------------------------------
# SLIDE 1: TITLE PAGE
# -------------------------------------------------------------
slide1 = prs.slides[0]
for shape in slide1.shapes:
    if shape.name == 'TextBox 9' or (shape.has_text_frame and 'Problem Statement ID' in shape.text_frame.text):
        shape.left = Inches(0.55)
        shape.top = Inches(2.15)
        shape.width = Inches(5.8)
        shape.height = Inches(4.8)
        tf = shape.text_frame
        tf.clear()
        tf.margin_left = tf.margin_right = tf.margin_top = tf.margin_bottom = Inches(0.05)
        
        fields = [
            ("Problem Statement ID:", "SIH26090 (PS-90)", True),
            ("Problem Statement Title:", "AI-Driven Digital Commerce & Catalog Management Platform for Grassroots Artisans", False),
            ("Theme:", "Smart Automation / Heritage & Culture / AI for Bharat", False),
            ("PS Category:", "Software", False),
            ("Team ID:", "[Your Team ID / e.g. SIH-2026-XXXXX]", False),
            ("Team Name:", "[Your Team Name]", False)
        ]
        
        for idx, (label, val, is_highlight) in enumerate(fields):
            p = tf.paragraphs[0] if idx == 0 else tf.add_paragraph()
            disable_bullet(p)
            p.space_after = Pt(6.5)
            p.line_spacing = 1.15
            
            r_label = p.add_run()
            r_label.text = f"{label} "
            r_label.font.name = 'Calibri'
            r_label.font.size = Pt(13)
            r_label.font.bold = True
            r_label.font.color.rgb = COLOR_PRIMARY_DARK
            
            r_val = p.add_run()
            r_val.text = val
            r_val.font.name = 'Calibri'
            r_val.font.size = Pt(13)
            r_val.font.bold = is_highlight
            r_val.font.color.rgb = COLOR_ACCENT_ORANGE if is_highlight else COLOR_TEXT_MAIN

def remove_legacy_textbox(slide):
    for shape in list(slide.shapes):
        if shape.name.startswith("TextBox") or (shape.has_text_frame and ('Proposed Solution' in shape.text_frame.text or 'Technologies to be used' in shape.text_frame.text or 'Analysis of the feasibility' in shape.text_frame.text or 'Potential impact' in shape.text_frame.text or 'Details / Links' in shape.text_frame.text)):
            sp = shape._element
            sp.getparent().remove(sp)

# -------------------------------------------------------------
# SLIDE 2: IDEA TITLE & PROPOSED SOLUTION
# -------------------------------------------------------------
slide2 = prs.slides[1]
setup_header(slide2, "IDEA TITLE: ArtisanAI (Voice Commerce Platform)")
remove_legacy_textbox(slide2)

# Left Card: Solution & Workflow
tf_s2_left = create_card(slide2, Inches(0.50), Inches(1.25), Inches(5.95), Inches(5.40))
add_card_header(tf_s2_left, "1. Proposed Solution & Core Workflow")
add_card_bullet(tf_s2_left, "5-Step Intuitive Flow:", "PHOTO ➔ SPEAK ➔ PROCESS ➔ REVIEW ➔ PUBLISH. Turns raw craft photos and native speech into studio-grade e-commerce listings in <30 seconds.")
add_card_bullet(tf_s2_left, "Voice-First Cataloging:", "Artisans speak naturally in their native tongue/dialect (Hindi, Odia, regional dialects); Whisper STT extracts structured specs (material, dimensions, care).")
add_card_bullet(tf_s2_left, "1-Tap Auto-Fill Review:", "Pre-fills multi-language product listings for immediate preview and editing before final publishing.")

add_card_header(tf_s2_left, "2. Addressing Core Pain Points", space_before=6)
add_card_bullet(tf_s2_left, "Eliminates Literacy Barriers:", "Bypasses complex multi-field English forms with simple voice description and 1-tap automated attribute extraction.")
add_card_bullet(tf_s2_left, "Studio Photography (Zero Cost):", "Removes workshop clutter, corrects lighting/orientation, and renders 1024x1024 marketplace-compliant white/grey studio backdrops.")

# Right Card: Innovation & Economic Model
tf_s2_right = create_card(slide2, Inches(6.70), Inches(1.25), Inches(6.12), Inches(5.40))
add_card_header(tf_s2_right, "3. Innovation & Uniqueness")
add_card_bullet(tf_s2_right, "Offline-First Resilience:", "Local persistent JSON queue buffers audio and image drafts during network blackouts and auto-syncs when reconnected.")
add_card_bullet(tf_s2_right, "Anti-Hallucination Extraction:", "Restricts catalog specs strictly to spoken verified facts, ensuring 100% genuine product attributes.")
add_card_bullet(tf_s2_right, "Multi-Protocol Export Ready:", "1-click export to ONDC Beckn protocol JSON and Government e-Marketplace (GeM) listing formats.")

add_card_header(tf_s2_right, "4. Fair Wage Economic Model", space_before=6)
add_card_bullet(tf_s2_right, "Living Wage Protection:", "Calculates living wages (₹90+/hr) + raw materials to suggest transparent Fair Base, E-Commerce, & Export retail pricing.")
add_card_bullet(tf_s2_right, "Direct Buyer Connection:", "Includes direct buyer inquiry inbox to help artisans negotiate bulk orders directly, bypassing predatory middlemen.")

# -------------------------------------------------------------
# SLIDE 3: TECHNICAL APPROACH
# -------------------------------------------------------------
slide3 = prs.slides[2]
setup_header(slide3, "TECHNICAL APPROACH & SYSTEM ARCHITECTURE")
remove_legacy_textbox(slide3)

# Left Card: Technology Stack
tf_s3_left = create_card(slide3, Inches(0.50), Inches(1.25), Inches(5.95), Inches(5.40))
add_card_header(tf_s3_left, "1. Production Technology Stack")
add_card_bullet(tf_s3_left, "Mobile Frontend:", "Flutter 3.x (Dart), Local JSON Sync Queue, Flutter Secure Storage (Android KeyStore), Cross-Platform (Android/iOS).")
add_card_bullet(tf_s3_left, "Backend Core:", "FastAPI (Python 3.14/3.11), SQLAlchemy 2.0 ORM, PostgreSQL 16 / SQLite, Alembic Database Migrations.")
add_card_bullet(tf_s3_left, "AI & Speech Pipeline:", "Local Whisper STT (Indian regional dialects), OpenCV/PIL Image Studio (1024x1024 Chroma removal, contrast & soft contact shadows).")
add_card_bullet(tf_s3_left, "Pricing & Export Engine:", "Dynamic Cost-Plus Fair Wage Algorithm, ONDC Beckn Schema Builder, GeM CSV/JSON Exporter.")
add_card_bullet(tf_s3_left, "DevOps & Infrastructure:", "Dockerized microservices, NGINX reverse proxy with SSL, rate limiting, and zero vendor lock-in.")

# Right Card: Methodology & Data Flow
tf_s3_right = create_card(slide3, Inches(6.70), Inches(1.25), Inches(6.12), Inches(5.40))
add_card_header(tf_s3_right, "2. End-to-End Implementation Methodology")
add_card_bullet(tf_s3_right, "Step 1 (Capture & Local Buffer):", "Artisan records 10s voice + camera photo on mobile. Buffered atomically in persistent local queue if offline.")
add_card_bullet(tf_s3_right, "Step 2 (FastAPI AI Processing):", "Backend receives payload -> Whisper transcribes voice -> extracts dimensions & craft type -> PIL normalizes lighting & renders shadow.")
add_card_bullet(tf_s3_right, "Step 3 (Cost Benchmarking):", "Algorithm computes base labor + material costs + margin multiplier -> recommends 3-tier prices (Fair Base, E-Comm, Export).")
add_card_bullet(tf_s3_right, "Step 4 (Publish & Distribute):", "Catalog stored in PostgreSQL, indexed for buyer discovery, and formatted for ONDC Beckn / GeM marketplace integration.")

# -------------------------------------------------------------
# SLIDE 4: FEASIBILITY AND VIABILITY
# -------------------------------------------------------------
slide4 = prs.slides[3]
setup_header(slide4, "FEASIBILITY AND VIABILITY")
remove_legacy_textbox(slide4)

# Left Card: Feasibility Analysis
tf_s4_left = create_card(slide4, Inches(0.50), Inches(1.25), Inches(5.95), Inches(5.40))
add_card_header(tf_s4_left, "1. Feasibility & Scalability Analysis")
add_card_bullet(tf_s4_left, "Technical Feasibility:", "Production-hardened prototype tested end-to-end; lightweight mobile APK (<25MB), runs smoothly on budget Android phones (>=2GB RAM).")
add_card_bullet(tf_s4_left, "Zero Cloud Lock-In & Low Cost:", "Built using open-source models with local CPU fallback; near-zero server infrastructure cost per listing generated.")
add_card_bullet(tf_s4_left, "Modular Microservices:", "Stateless FastAPI worker nodes scale horizontally behind NGINX to handle millions of catalog sync requests.")
add_card_bullet(tf_s4_left, "Security & Compliance:", "Magic-byte MIME upload validation, IDOR mitigation, bcrypt token hashing, and strict role-based admin controls.")

# Right Card: Risks & Mitigation Strategies
tf_s4_right = create_card(slide4, Inches(6.70), Inches(1.25), Inches(6.12), Inches(5.40))
add_card_header(tf_s4_right, "2. Potential Challenges & Mitigation Strategies")
add_card_bullet(tf_s4_right, "Rural Network Blackouts:", "Challenge: Erratic connectivity causes cloud sync failures.\nMitigation: Offline-first JSON queue stores drafts locally and auto-syncs when connection returns.")
add_card_bullet(tf_s4_right, "Noisy Workshop Audio:", "Challenge: Loom clatter and ambient workshop noise.\nMitigation: Pre-filtered audio with Whisper STT and strict anti-hallucination fact verification boundaries.")
add_card_bullet(tf_s4_right, "Poor Camera Lighting:", "Challenge: Harsh shadows and dim indoor photography.\nMitigation: CLAHE contrast balance, unsharp masking, and synthetic studio contact shadow rendering.")

# -------------------------------------------------------------
# SLIDE 5: IMPACT AND BENEFITS
# -------------------------------------------------------------
slide5 = prs.slides[4]
setup_header(slide5, "IMPACT AND BENEFITS")
remove_legacy_textbox(slide5)

# Left Card: Target Audience Impact
tf_s5_left = create_card(slide5, Inches(0.50), Inches(1.25), Inches(5.95), Inches(5.40))
add_card_header(tf_s5_left, "1. Impact on Grassroots Artisans & SHGs")
add_card_bullet(tf_s5_left, "Empowering 200M+ Artisans:", "Directly bridges the digital divide for weavers, potters, metalcasters, and women's self-help groups across Bharat.")
add_card_bullet(tf_s5_left, "Time Efficiency:", "Reduces catalog creation time from 45+ minutes of manual form typing down to under 30 seconds of voice + photo.")
add_card_bullet(tf_s5_left, "Inclusive Multilingual UX:", "Enables non-English speaking artisans to generate professional national & global e-commerce listings effortlessly.")
add_card_bullet(tf_s5_left, "Fair Margin Recovery:", "Artisans reclaim 30%–40% lost margins previously captured by intermediaries through transparent cost-plus pricing.")

# Right Card: Cultural, Economic & National Value
tf_s5_right = create_card(slide5, Inches(6.70), Inches(1.25), Inches(6.12), Inches(5.40))
add_card_header(tf_s5_right, "2. Socio-Economic, Cultural & National Value")
add_card_bullet(tf_s5_right, "Cultural Heritage Preservation:", "Creates a permanent digital archive of endangered indigenous craft traditions (Dokra casting, Madhubani, Pattachitra).")
add_card_bullet(tf_s5_right, "Environmental Sustainability:", "Promotes eco-friendly, sustainable, zero-carbon handmade goods over mass factory plastic commodities.")
add_card_bullet(tf_s5_right, "Alignment with National Missions:", "Directly powers Digital India, Vocal for Local, ONDC protocol adoption, and Atmanirbhar Bharat.")
add_card_bullet(tf_s5_right, "Formal Economy Integration:", "Transforms unorganized grassroots micro-entrepreneurs into formal digital commerce participants with GeM & ONDC catalogs.")

# -------------------------------------------------------------
# SLIDE 6: RESEARCH AND REFERENCES
# -------------------------------------------------------------
slide6 = prs.slides[5]
setup_header(slide6, "RESEARCH AND REFERENCES")
remove_legacy_textbox(slide6)

# Left Card: Standards & Research
tf_s6_left = create_card(slide6, Inches(0.50), Inches(1.25), Inches(5.95), Inches(5.40))
add_card_header(tf_s6_left, "1. Government & Industry Standards")
add_card_bullet(tf_s6_left, "Ministry of Textiles, Govt. of India:", "4th All India Handloom Census & Handicrafts Socio-Economic Survey Reports.")
add_card_bullet(tf_s6_left, "Open Network for Digital Commerce (ONDC):", "Beckn Protocol Retail Specifications & Handicrafts Category Taxonomy (ondc.org).")
add_card_bullet(tf_s6_left, "Government e-Marketplace (GeM):", "Product catalog standardization & artisan onboarding guidelines (gem.gov.in).")
add_card_bullet(tf_s6_left, "Fair Trade Forum India & ILO:", "Living wage calculation standards for artisanal and unorganized craft labor.")

# Right Card: Academic Papers & Live Repository
tf_s6_right = create_card(slide6, Inches(6.70), Inches(1.25), Inches(6.12), Inches(5.40))
add_card_header(tf_s6_right, "2. Technical Research & Live Artifacts")
add_card_bullet(tf_s6_right, "OpenAI Whisper Research Paper:", "\"Robust Speech Recognition via Large-Scale Weak Supervision\" (Low-resource multilingual STT).")
add_card_bullet(tf_s6_right, "Offline-First Architecture Standards:", "Local storage persistence & sync reconciliation patterns in high-latency environments.")
add_card_bullet(tf_s6_right, "GitHub Repository:", "https://github.com/amitpadhan525/SIH (Full Stack: Flutter Mobile + FastAPI Backend + Docker)")
add_card_bullet(tf_s6_right, "Live Android APK Release:", "ArtisanAI v1.3 Production Hardened Release with demo evaluator mode.")

# Save populated master template
prs.save(OUTPUT_PPTX_TEMPLATE_OVERWRITE)
print(f"Saved master template: {OUTPUT_PPTX_TEMPLATE_OVERWRITE}")

# Create 6-slide submission PPTX
if len(prs.slides) > 6:
    rId = prs.slides._sldIdLst[6].rId
    prs.part.drop_rel(rId)
    del prs.slides._sldIdLst[6]
    prs.save(OUTPUT_PPTX_6SLIDES)
    print(f"Saved 6-slide submission PPTX: {OUTPUT_PPTX_6SLIDES}")

