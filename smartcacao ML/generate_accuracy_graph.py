import os
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
from pathlib import Path

# Directory containing training runs
runs_dir = Path("runs/detect")

# Collect all training runs with results.csv
training_runs = []
for run_dir in sorted(runs_dir.glob("train*")):
    results_file = run_dir / "results.csv"
    if results_file.exists():
        training_runs.append((run_dir.name, results_file))

if not training_runs:
    print("No training runs with results.csv found!")
    exit(1)

print(f"Found {len(training_runs)} training runs with results.csv")

# Create figure
fig, axes = plt.subplots(2, 2, figsize=(14, 10))
fig.suptitle("Model Accuracy Over Training Epochs", fontsize=16, fontweight='bold')

colors = plt.cm.tab10(np.linspace(0, 1, len(training_runs)))

# Plot 1: Precision
ax = axes[0, 0]
for (run_name, results_file), color in zip(training_runs, colors):
    df = pd.read_csv(results_file)
    df.columns = df.columns.str.strip()  # Remove leading/trailing spaces
    epochs = df.index + 1
    
    if "metrics/precision(B)" in df.columns:
        ax.plot(epochs, df["metrics/precision(B)"], marker='o', label=run_name, color=color, linewidth=2)

ax.set_xlabel("Epoch", fontsize=10)
ax.set_ylabel("Precision", fontsize=10)
ax.set_title("Precision (% of predictions were correct)", fontsize=11, fontweight='bold')
ax.grid(True, alpha=0.3)
ax.legend(fontsize=8)
ax.set_ylim([0, 1])

# Plot 2: Recall
ax = axes[0, 1]
for (run_name, results_file), color in zip(training_runs, colors):
    df = pd.read_csv(results_file)
    df.columns = df.columns.str.strip()
    epochs = df.index + 1
    
    if "metrics/recall(B)" in df.columns:
        ax.plot(epochs, df["metrics/recall(B)"], marker='o', label=run_name, color=color, linewidth=2)

ax.set_xlabel("Epoch", fontsize=10)
ax.set_ylabel("Recall", fontsize=10)
ax.set_title("Recall (% of actual beans were found)", fontsize=11, fontweight='bold')
ax.grid(True, alpha=0.3)
ax.legend(fontsize=8)
ax.set_ylim([0, 1])

# Plot 3: mAP50
ax = axes[1, 0]
for (run_name, results_file), color in zip(training_runs, colors):
    df = pd.read_csv(results_file)
    df.columns = df.columns.str.strip()
    epochs = df.index + 1
    
    if "metrics/mAP50(B)" in df.columns:
        ax.plot(epochs, df["metrics/mAP50(B)"], marker='s', label=run_name, color=color, linewidth=2)

ax.set_xlabel("Epoch", fontsize=10)
ax.set_ylabel("mAP50", fontsize=10)
ax.set_title("mAP50 (Average detection quality at 50% threshold)", fontsize=11, fontweight='bold')
ax.grid(True, alpha=0.3)
ax.legend(fontsize=8)
ax.set_ylim([0, 1])

# Plot 4: mAP50-95 (overall quality)
ax = axes[1, 1]
for (run_name, results_file), color in zip(training_runs, colors):
    df = pd.read_csv(results_file)
    df.columns = df.columns.str.strip()
    epochs = df.index + 1
    
    if "metrics/mAP50-95(B)" in df.columns:
        ax.plot(epochs, df["metrics/mAP50-95(B)"], marker='^', label=run_name, color=color, linewidth=2)

ax.set_xlabel("Epoch", fontsize=10)
ax.set_ylabel("mAP50-95", fontsize=10)
ax.set_title("mAP50-95 (Overall accuracy across all thresholds)", fontsize=11, fontweight='bold')
ax.grid(True, alpha=0.3)
ax.legend(fontsize=8)
ax.set_ylim([0, 1])

plt.tight_layout()
plt.savefig("accuracy_graph.png", dpi=300, bbox_inches='tight')
print("\n✓ Accuracy graph saved: accuracy_graph.png")

# Print summary statistics
print("\nAccuracy Summary (Final Epoch):")
print("-" * 80)
for run_name, results_file in training_runs:
    df = pd.read_csv(results_file)
    df.columns = df.columns.str.strip()
    
    last_epoch = df.iloc[-1]
    print(f"\n{run_name}:")
    if "metrics/precision(B)" in df.columns:
        print(f"  Precision: {last_epoch['metrics/precision(B)']:.3f}")
    if "metrics/recall(B)" in df.columns:
        print(f"  Recall:    {last_epoch['metrics/recall(B)']:.3f}")
    if "metrics/mAP50(B)" in df.columns:
        print(f"  mAP50:     {last_epoch['metrics/mAP50(B)']:.3f}")
    if "metrics/mAP50-95(B)" in df.columns:
        print(f"  mAP50-95:  {last_epoch['metrics/mAP50-95(B)']:.3f}")
