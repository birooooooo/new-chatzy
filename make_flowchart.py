import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch

fig, ax = plt.subplots(figsize=(20, 28))
ax.set_xlim(0, 20)
ax.set_ylim(0, 28)
ax.axis('off')
fig.patch.set_facecolor('#0A0F1E')

# ── Color palette ──────────────────────────────────────────────────────────────
C_BLUE    = '#2997FF'
C_DARK    = '#1A3A5C'
C_GREEN   = '#30D158'
C_RED     = '#FF375F'
C_ORANGE  = '#FF9F0A'
C_PURPLE  = '#BF5AF2'
C_TEAL    = '#5AC8FA'
C_WHITE   = '#FFFFFF'
C_BG      = '#0A0F1E'
C_CARD    = '#111827'

def box(ax, x, y, w, h, label, sublabel='', color=C_BLUE, text_color=C_WHITE,
        shape='round,pad=0.1', fontsize=10):
    rect = FancyBboxPatch((x - w/2, y - h/2), w, h,
                          boxstyle=shape,
                          linewidth=1.5, edgecolor=color,
                          facecolor=C_CARD, zorder=3)
    ax.add_patch(rect)
    # colored top bar
    bar = FancyBboxPatch((x - w/2, y + h/2 - 0.18), w, 0.18,
                         boxstyle='square,pad=0',
                         linewidth=0, edgecolor=color,
                         facecolor=color, zorder=4)
    ax.add_patch(bar)
    ax.text(x, y + 0.06, label, ha='center', va='center',
            color=C_WHITE, fontsize=fontsize, fontweight='bold',
            zorder=5, wrap=True)
    if sublabel:
        ax.text(x, y - 0.22, sublabel, ha='center', va='center',
                color='#AAAAAA', fontsize=7.5, zorder=5)

def diamond(ax, x, y, w, h, label, color=C_ORANGE):
    dx, dy = w/2, h/2
    xs = [x,     x+dx, x,     x-dx, x]
    ys = [y+dy,  y,    y-dy,  y,    y+dy]
    ax.fill(xs, ys, color=C_CARD, zorder=3)
    ax.plot(xs, ys, color=color, linewidth=1.5, zorder=4)
    ax.text(x, y, label, ha='center', va='center',
            color=C_WHITE, fontsize=9, fontweight='bold', zorder=5)

def oval(ax, x, y, w, h, label, color=C_GREEN):
    ellipse = mpatches.Ellipse((x, y), w, h,
                               facecolor=color, edgecolor=color,
                               linewidth=2, zorder=3)
    ax.add_patch(ellipse)
    ax.text(x, y, label, ha='center', va='center',
            color=C_WHITE, fontsize=10, fontweight='bold', zorder=5)

def arrow(ax, x1, y1, x2, y2, label='', color='#555577'):
    ax.annotate('', xy=(x2, y2), xytext=(x1, y1),
                arrowprops=dict(arrowstyle='->', color=color,
                                lw=1.6, connectionstyle='arc3,rad=0.0'),
                zorder=2)
    if label:
        mx, my = (x1+x2)/2, (y1+y2)/2
        ax.text(mx+0.12, my, label, color='#AAAAAA', fontsize=8, zorder=5)

def curved_arrow(ax, x1, y1, x2, y2, rad=0.3, color='#555577', label=''):
    ax.annotate('', xy=(x2, y2), xytext=(x1, y1),
                arrowprops=dict(arrowstyle='->', color=color,
                                lw=1.4, connectionstyle=f'arc3,rad={rad}'),
                zorder=2)
    if label:
        mx, my = (x1+x2)/2, (y1+y2)/2
        ax.text(mx, my, label, color='#AAAAAA', fontsize=7.5, zorder=5)

# ══════════════════════════════════════════════════════════════════════════════
# Title
# ══════════════════════════════════════════════════════════════════════════════
ax.text(10, 27.4, 'CHATZY — Application Flowchart',
        ha='center', va='center', color=C_BLUE,
        fontsize=18, fontweight='bold')
ax.text(10, 27.0, 'Cihan University — Erbil  |  Informatics and Software Engineering',
        ha='center', va='center', color='#777799', fontsize=10)

# ══════════════════════════════════════════════════════════════════════════════
# ROW 1: Start → Splash
# ══════════════════════════════════════════════════════════════════════════════
oval(ax,  10, 26.2, 2.0, 0.55, 'APP LAUNCH', color=C_DARK)
arrow(ax, 10, 25.93, 10, 25.4)
box(ax,   10, 25.0, 2.8, 0.70, 'Splash Screen', '3.5s animation + logo check', color=C_TEAL)
arrow(ax, 10, 24.65, 10, 24.1)

# ── Auth check ────────────────────────────────────────────────────────────────
diamond(ax, 10, 23.7, 3.2, 0.75, 'User Logged In?', color=C_ORANGE)

# ── NO path → Login ───────────────────────────────────────────────────────────
arrow(ax, 8.4, 23.7, 6.5, 23.7, 'NO')
box(ax,   5.2, 23.7, 2.4, 0.70, 'Login Screen', 'email / username', color=C_RED)

diamond(ax, 5.2, 22.7, 3.0, 0.70, 'New User?', color=C_ORANGE)
arrow(ax, 5.2, 23.35, 5.2, 23.05)

# Register path
arrow(ax, 3.7, 22.7, 2.5, 22.7, 'YES')
box(ax,   1.4, 22.7, 2.2, 0.70, 'Register\nScreen', 'email+username+avatar', color=C_PURPLE, fontsize=9)
arrow(ax, 2.5, 22.7, 3.7, 22.7)   # back implied by auth flow

# Forgot password
arrow(ax, 5.2, 22.35, 5.2, 21.7)
diamond(ax, 5.2, 21.35, 3.0, 0.70, 'Forgot Password?', color=C_ORANGE)
arrow(ax, 3.7, 21.35, 2.5, 21.35, 'YES')
box(ax,   1.4, 21.35, 2.2, 0.60, 'Reset Email\nSent', 'Firebase Auth', color=C_TEAL, fontsize=9)
arrow(ax, 5.2, 21.0, 5.2, 20.4, label='NO / Login OK')

# ── YES path → Home ───────────────────────────────────────────────────────────
arrow(ax, 11.6, 23.7, 13.5, 23.7, 'YES')
# connect login success to home
arrow(ax, 5.2, 20.4, 10, 20.4)
ax.plot([13.5, 13.5, 10], [23.7, 20.4, 20.4], color='#555577', lw=1.6, zorder=2)

# ══════════════════════════════════════════════════════════════════════════════
# ROW 2: Home Screen (Bottom Nav hub)
# ══════════════════════════════════════════════════════════════════════════════
box(ax, 10, 19.85, 4.0, 0.80, 'HOME SCREEN', 'Bottom Navigation Bar — 4 Tabs', color=C_GREEN, fontsize=11)

# 4 arrows fanning out
arrow(ax, 8.0, 19.85, 3.5, 18.9)   # Tab 0 Chats
arrow(ax, 9.2, 19.45, 7.5, 18.9)   # Tab 1 Contacts
arrow(ax, 10.8, 19.45, 12.5, 18.9) # Tab 2 Stories
arrow(ax, 12.0, 19.85, 16.5, 18.9) # Tab 3 Settings

# ══════════════════════════════════════════════════════════════════════════════
# TAB 0 — CHATS
# ══════════════════════════════════════════════════════════════════════════════
box(ax, 3.0, 18.5, 3.0, 0.70, 'Chats List', 'Tab 0 — real-time list', color=C_BLUE)

diamond(ax, 3.0, 17.5, 3.0, 0.70, 'Chat Type?', color=C_ORANGE)
arrow(ax, 3.0, 18.15, 3.0, 17.85)

# Private chat
arrow(ax, 1.5, 17.5, 0.8, 17.5, 'Private')
box(ax,  0.5, 16.8, 1.8, 0.65, 'Private\nChat Screen', 'text/media/audio', color=C_BLUE, fontsize=8)
ax.plot([0.5, 0.5], [17.5, 16.8], color='#555577', lw=1.4)

# Group chat
arrow(ax, 3.0, 17.15, 3.0, 16.5, label='Group')
box(ax,  3.0, 16.1, 2.2, 0.65, 'Group Chat\nScreen', 'admin controls', color=C_DARK, fontsize=8)

# AI chat
arrow(ax, 4.5, 17.5, 5.2, 17.5, 'AI Bot')
box(ax,  5.5, 16.8, 2.0, 0.65, 'AI Chatbot\nScreen', 'Gemini 2.0 Flash', color=C_PURPLE, fontsize=8)
ax.plot([5.5, 5.5], [17.5, 16.8], color='#555577', lw=1.4)

# Message flow inside chat
arrow(ax, 3.0, 15.77, 3.0, 15.2)
box(ax,  3.0, 14.85, 2.2, 0.65, 'Send Message', 'optimistic update', color=C_BLUE, fontsize=8)
arrow(ax, 3.0, 14.52, 3.0, 13.95)
diamond(ax, 3.0, 13.6, 2.6, 0.65, 'Media\nAttached?', color=C_ORANGE)
arrow(ax, 1.7, 13.6, 0.7, 13.6, 'YES')
box(ax,  0.4, 13.1, 1.4, 0.65, 'Upload to\nStorage', 'get URL', color=C_TEAL, fontsize=7.5)
ax.plot([0.4, 0.4], [13.6, 13.1], color='#555577', lw=1.4)
arrow(ax, 3.0, 13.27, 3.0, 12.7, label='NO/after upload')
box(ax,  3.0, 12.35, 2.2, 0.65, 'Save to\nFirestore', 'status: sent→read', color=C_GREEN, fontsize=8)

# ══════════════════════════════════════════════════════════════════════════════
# TAB 1 — CONTACTS
# ══════════════════════════════════════════════════════════════════════════════
box(ax, 7.5, 18.5, 2.8, 0.70, 'Contacts Screen', 'Tab 1 — search users', color=C_BLUE)
arrow(ax, 7.5, 18.15, 7.5, 17.45)
box(ax,  7.5, 17.1, 2.4, 0.65, 'Search Users', 'searchKeywords query', color=C_DARK, fontsize=8)
arrow(ax, 7.5, 16.77, 7.5, 16.2)
box(ax,  7.5, 15.85, 2.4, 0.65, 'User Details\nScreen', 'profile / block / chat', color=C_TEAL, fontsize=8)
arrow(ax, 7.5, 15.52, 7.5, 14.95)
diamond(ax, 7.5, 14.6, 2.4, 0.65, 'Action?', color=C_ORANGE)
arrow(ax, 6.3, 14.6, 5.6, 14.6, 'Start Chat')
ax.plot([5.6, 5.6, 3.0], [14.6, 14.85, 14.85], color='#555577', lw=1.4, linestyle='dashed')
arrow(ax, 8.7, 14.6, 9.2, 14.6, 'Block')
box(ax,  9.8, 14.6, 1.6, 0.55, 'Block List\nUpdated', color=C_RED, fontsize=7.5)

# ══════════════════════════════════════════════════════════════════════════════
# TAB 2 — STORIES
# ══════════════════════════════════════════════════════════════════════════════
box(ax, 12.5, 18.5, 2.8, 0.70, 'Stories Feed', 'Tab 2 — active stories', color=C_BLUE)
arrow(ax, 12.5, 18.15, 12.5, 17.45)
diamond(ax, 12.5, 17.1, 2.6, 0.65, 'View or\nCreate?', color=C_ORANGE)
arrow(ax, 11.2, 17.1, 10.3, 17.1, 'View')
box(ax,   9.7, 17.1, 1.6, 0.60, 'Story\nViewer', 'react / view count', color=C_TEAL, fontsize=7.5)
arrow(ax, 13.8, 17.1, 14.6, 17.1, 'Create')
box(ax,   15.2, 17.1, 1.6, 0.60, 'Create\nStory', 'image/video/text', color=C_PURPLE, fontsize=7.5)
arrow(ax, 15.2, 16.8, 15.2, 16.2)
box(ax,   15.2, 15.85, 2.0, 0.60, 'Upload Media\n→ Firestore', 'expiresAt +24h', color=C_GREEN, fontsize=7.5)

# View adds viewer
arrow(ax, 9.7, 16.8, 9.7, 16.2)
box(ax,   9.7, 15.85, 2.0, 0.60, 'Add UID to\nviewedBy', 'arrayUnion', color=C_DARK, fontsize=7.5)

# ══════════════════════════════════════════════════════════════════════════════
# TAB 3 — SETTINGS
# ══════════════════════════════════════════════════════════════════════════════
box(ax, 16.5, 18.5, 3.0, 0.70, 'Settings', 'Tab 3', color=C_BLUE)
arrow(ax, 16.5, 18.15, 16.5, 17.5)

settings = [
    (14.5, 17.1, 'Profile\nEdit',    C_TEAL),
    (16.0, 17.1, 'Theme\nSettings',  C_DARK),
    (17.5, 17.1, 'Privacy\n& Block', C_RED),
    (19.0, 17.1, 'AI Account\nSettings', C_PURPLE),
]
for sx, sy, slabel, sc in settings:
    ax.plot([16.5, sx], [17.5, 17.3], color='#555577', lw=1.3)
    arrow(ax, sx, 17.3, sx, 17.0)
    box(ax, sx, 16.72, 1.6, 0.50, slabel, color=sc, fontsize=7.5)

# ══════════════════════════════════════════════════════════════════════════════
# AI Chatbot detailed flow
# ══════════════════════════════════════════════════════════════════════════════
arrow(ax, 5.5, 16.47, 5.5, 15.85)
box(ax,   5.5, 15.5, 2.0, 0.65, 'User Types\nMessage', 'AI input box', color=C_PURPLE, fontsize=8)
arrow(ax, 5.5, 15.17, 5.5, 14.55)
box(ax,   5.5, 14.2, 2.2, 0.65, 'Gemini 2.0\nFlash API', 'history context', color=C_DARK, fontsize=8)
arrow(ax, 5.5, 13.87, 5.5, 13.3)
box(ax,   5.5, 12.95, 2.2, 0.65, 'Sentiment\nAnalysis', '8 mood states', color=C_TEAL, fontsize=8)
arrow(ax, 5.5, 12.62, 5.5, 12.05)
box(ax,   5.5, 11.7, 2.2, 0.65, 'Character\nAnimation', 'mood → Huggy 3D', color=C_PURPLE, fontsize=8)

# ══════════════════════════════════════════════════════════════════════════════
# Legend
# ══════════════════════════════════════════════════════════════════════════════
legend_x, legend_y = 12.5, 12.8
ax.text(legend_x, legend_y + 0.4, 'LEGEND', color=C_BLUE,
        fontsize=10, fontweight='bold', ha='center')

legend_items = [
    (C_GREEN,  'Start / End (Oval)'),
    (C_BLUE,   'Process / Screen'),
    (C_ORANGE, 'Decision (Diamond)'),
    (C_TEAL,   'Data / Storage Operation'),
    (C_PURPLE, 'AI / External Service'),
    (C_RED,    'Error / Block / Delete'),
]
for idx, (lc, lt) in enumerate(legend_items):
    lx = legend_x - 2
    ly = legend_y - 0.02 - idx * 0.42
    rect = FancyBboxPatch((lx, ly), 0.55, 0.3,
                          boxstyle='round,pad=0.05',
                          facecolor=C_CARD, edgecolor=lc, lw=1.5)
    ax.add_patch(rect)
    bar2 = FancyBboxPatch((lx, ly + 0.22), 0.55, 0.08,
                          boxstyle='square,pad=0',
                          facecolor=lc, edgecolor=lc, lw=0)
    ax.add_patch(bar2)
    ax.text(lx + 0.7, ly + 0.15, lt, color=C_WHITE,
            fontsize=8.5, va='center')

# ══════════════════════════════════════════════════════════════════════════════
# Footer
# ══════════════════════════════════════════════════════════════════════════════
ax.text(10, 0.3, 'CHATZY Application Flowchart  |  Cihan University Erbil  |  2025–2026',
        ha='center', va='center', color='#555577', fontsize=8)

plt.tight_layout(pad=0.5)
plt.savefig('chatzy_flowchart.png', dpi=180,
            bbox_inches='tight', facecolor=C_BG)
print('Flowchart saved: chatzy_flowchart.png')
