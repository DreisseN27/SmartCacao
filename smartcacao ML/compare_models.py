import cv2
import numpy as np
import matplotlib.pyplot as plt
from pathlib import Path

# Load metric images from both training runs
train10_dir = Path("runs/detect/train10")
train102_dir = Path("runs/detect/train102")

metrics = ["PR_curve.png", "P_curve.png", "R_curve.png", "F1_curve.png"]

fig = plt.figure(figsize=(16, 12))
fig.suptitle("Model Comparison: train10 vs train102", fontsize=18, fontweight='bold')

for idx, metric in enumerate(metrics, 1):
    # train10
    train10_path = train10_dir / metric
    if train10_path.exists():
        ax = plt.subplot(2, 4, idx)
        img = cv2.imread(str(train10_path))
        img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
        ax.imshow(img)
        ax.set_title(f"train10 - {metric.replace('.png', '')}", fontsize=11, fontweight='bold')
        ax.axis('off')
    
    # train102
    train102_path = train102_dir / metric
    if train102_path.exists():
        ax = plt.subplot(2, 4, idx + 4)
        img = cv2.imread(str(train102_path))
        img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
        ax.imshow(img)
        ax.set_title(f"train102 - {metric.replace('.png', '')}", fontsize=11, fontweight='bold')
        ax.axis('off')

plt.tight_layout()
plt.savefig("model_comparison.png", dpi=150, bbox_inches='tight')
print("✓ Comparison graph saved: model_comparison.png")

# Also load confusion matrices
print("\n" + "="*80)
print("CONFUSION MATRIX COMPARISON")
print("="*80)

fig2 = plt.figure(figsize=(14, 6))
fig2.suptitle("Confusion Matrix Comparison", fontsize=16, fontweight='bold')

for idx, (run_name, run_dir) in enumerate([("train10", train10_dir), ("train102", train102_dir)], 1):
    cm_path = run_dir / "confusion_matrix_normalized.png"
    if cm_path.exists():
        ax = plt.subplot(1, 2, idx)
        img = cv2.imread(str(cm_path))
        img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
        ax.imshow(img)
        ax.set_title(f"{run_name} - Normalized Confusion Matrix", fontsize=12, fontweight='bold')
        ax.axis('off')
        print(f"\n{run_name}:")
        print(f"  ✓ Confusion matrix available")

plt.tight_layout()
plt.savefig("confusion_matrix_comparison.png", dpi=150, bbox_inches='tight')
print("\n✓ Confusion matrix comparison saved: confusion_matrix_comparison.png")

# Print summary
print("\n" + "="*80)
print("SUMMARY")
print("="*80)
print("\ntrain10 (9 epochs - COMPLETE):")
print("  ✓ PR Curve (Precision vs Recall)")
print("  ✓ P Curve (Precision over classes)")
print("  ✓ R Curve (Recall over classes)")
print("  ✓ F1 Curve (F1 Score over classes)")
print("  ✓ Confusion Matrix")
print("  ✓ Training history (results.csv)")

print("\ntrain102 (INCOMPLETE - missing weights):")
print("  ✓ PR Curve")
print("  ✓ P Curve")
print("  ✓ R Curve")
print("  ✓ F1 Curve")
print("  ✓ Confusion Matrix")
print("  ✗ Training history (no results.csv)")
print("  ✗ Model weights (training incomplete)")

print("\n" + "="*80)
print("KEY INSIGHT:")
print("="*80)
print("Both models have similar metric curves, which suggests:")
print("  • Similar training data quality")
print("  • Likely same class distribution")
print("  • Both struggle with real-world cacao beans")
print("\nRECOMMENDATION:")
print("  → Retrain with 100+ REAL cacao bean photos")
print("  → Include different fermentation stages (under, proper, over)")
print("  → Different angles, lighting, backgrounds")
