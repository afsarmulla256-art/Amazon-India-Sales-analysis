"""
================================================
  AMAZON INDIA SALES PERFORMANCE ANALYSIS
  Visualisations — All 4 Charts in One File
  Author : Afsar Ahamed
  Run    : python visualisations.py
  Output : charts/ folder
================================================
"""
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import seaborn as sns
import os

df = pd.read_csv("amazon_sales_powerbi.csv")
df['Date'] = pd.to_datetime(df['Date'])
os.makedirs("charts", exist_ok=True)

NAVY="#0F1C3F"; TEAL="#00B4D8"; CORAL="#EF476F"
GOLD="#FFB703"; GREEN="#06D6A0"; AMBER="#F4A261"
GRAY="#64748B"; WHITE="#FFFFFF"; DGRAY="#E2E8F0"

plt.rcParams.update({
    "font.family":"DejaVu Sans","axes.spines.top":False,
    "axes.spines.right":False,"axes.facecolor":WHITE,
    "figure.facecolor":WHITE,"axes.grid":True,
    "grid.color":DGRAY,"grid.linewidth":0.5
})

# CHART 1 — Monthly Revenue Trend
fig, ax = plt.subplots(figsize=(10,5))
monthly = df.groupby('Month')['Amount'].sum() / 1e6
months = ['2022-04','2022-05','2022-06']
vals = [monthly.get(m,0) for m in months]
labels = ['Apr 2022','May 2022','Jun 2022']
bars = ax.bar(labels, vals, color=[TEAL,GOLD,CORAL], width=0.5, edgecolor=WHITE, linewidth=2, zorder=3)
ax.plot(labels, vals, color=NAVY, linewidth=2, marker='o', markersize=8,
        markerfacecolor=WHITE, markeredgecolor=NAVY, markeredgewidth=2, zorder=4)
for bar,v in zip(bars,vals):
    ax.text(bar.get_x()+bar.get_width()/2, v+0.3, f'₹{v:.1f}M',
            ha='center', va='bottom', fontweight='bold', fontsize=13, color=NAVY)
ax.set_ylabel('Revenue (INR Million)', color=GRAY); ax.set_ylim(0,35)
ax.set_title('Monthly Revenue Trend — Apr to Jun 2022', fontsize=14, fontweight='bold', color=NAVY)
ax.tick_params(colors=GRAY)
plt.tight_layout()
plt.savefig("charts/01_monthly_revenue.png", dpi=150, bbox_inches='tight')
plt.close()
print("✅ Chart 1 — Monthly Revenue Trend")

# CHART 2 — Category Revenue
fig, ax = plt.subplots(figsize=(10,5))
cat = df.groupby('Category')['Amount'].sum().sort_values() / 1e6
colors = [TEAL if v<10 else GOLD if v<25 else CORAL for v in cat.values]
bars = ax.barh(cat.index, cat.values, color=colors, height=0.6, edgecolor=WHITE, linewidth=1.5)
for bar,v in zip(bars,cat.values):
    if v > 0.5:
        ax.text(v+0.3, bar.get_y()+bar.get_height()/2, f'₹{v:.1f}M',
                va='center', fontweight='bold', fontsize=11, color=NAVY)
ax.set_xlabel('Revenue (INR Million)', color=GRAY)
ax.set_title('Revenue by Product Category', fontsize=14, fontweight='bold', color=NAVY)
ax.tick_params(axis='y', colors=NAVY, labelsize=11); ax.set_xlim(0,48)
plt.tight_layout()
plt.savefig("charts/02_category_revenue.png", dpi=150, bbox_inches='tight')
plt.close()
print("✅ Chart 2 — Category Revenue")

# CHART 3 — Order Status Donut
fig, ax = plt.subplots(figsize=(7,6))
status = df['OrderStatus'].value_counts()
colors_s = [TEAL, GREEN, CORAL, AMBER, GRAY]
ax.pie(status.values, colors=colors_s[:len(status)], startangle=90,
       wedgeprops={'width':0.55,'edgecolor':WHITE,'linewidth':3})
ax.text(0,0.08,f'{status.sum():,}',ha='center',va='center',fontsize=18,fontweight='bold',color=NAVY)
ax.text(0,-0.22,'Total Orders',ha='center',va='center',fontsize=11,color=GRAY)
handles=[mpatches.Patch(color=c,label=f'{l}  {v:,}')
         for c,l,v in zip(colors_s,status.index,status.values)]
ax.legend(handles=handles,loc='lower center',ncol=1,frameon=False,fontsize=10,bbox_to_anchor=(0.5,-0.15))
ax.set_title('Order Status Distribution',fontsize=14,fontweight='bold',color=NAVY,pad=15)
plt.tight_layout()
plt.savefig("charts/03_order_status.png", dpi=150, bbox_inches='tight')
plt.close()
print("✅ Chart 3 — Order Status")

# CHART 4 — Top 8 States
fig, ax = plt.subplots(figsize=(11,5))
states = df.groupby('ship-state')['Amount'].sum().sort_values(ascending=False).head(8) / 1e6
bar_colors = [CORAL if i==0 else GOLD if i==1 else TEAL for i in range(len(states))]
bars = ax.bar(range(len(states)), states.values, color=bar_colors, width=0.6, edgecolor=WHITE, linewidth=2, zorder=3)
ax.set_xticks(range(len(states)))
ax.set_xticklabels([s.title() for s in states.index], rotation=15, ha='right', color=NAVY, fontsize=10)
for bar,v in zip(bars,states.values):
    ax.text(bar.get_x()+bar.get_width()/2, v+0.1, f'₹{v:.1f}M',
            ha='center', va='bottom', fontweight='bold', fontsize=11, color=NAVY)
ax.set_ylabel('Revenue (INR Million)', color=GRAY); ax.set_ylim(0,17)
ax.set_title('Top 8 States by Revenue', fontsize=14, fontweight='bold', color=NAVY)
ax.tick_params(axis='y', colors=GRAY)
plt.tight_layout()
plt.savefig("charts/04_top_states.png", dpi=150, bbox_inches='tight')
plt.close()
print("✅ Chart 4 — Top States")

print("\n🎉 All 4 charts saved to charts/ folder!")
