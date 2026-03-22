import os
import json
import matplotlib.pyplot as plt
import cv2
from pathlib import Path
import numpy as np

# Paths
RUNS_DIR = Path("runs/detect")
OUTPUT_DIR = Path("accuracy_reports")
OUTPUT_DIR.mkdir(exist_ok=True)

def load_and_display_metrics(train_dir):
    """Load and display YOLOv8 training metrics"""
    
    print(f"\n=== Analyzing {train_dir.name} ===")
    
    # Check for existing graphs
    graphs = {
        'confusion_matrix': train_dir / 'confusion_matrix.png',
        'pr_curve': train_dir / 'PR_curve.png',
        'f1_curve': train_dir / 'F1_curve.png',
        'precision_curve': train_dir / 'P_curve.png',
        'recall_curve': train_dir / 'R_curve.png',
    }
    
    # Display available graphs
    fig, axes = plt.subplots(2, 3, figsize=(15, 10))
    fig.suptitle(f'Model Training Metrics - {train_dir.name}', fontsize=16, fontweight='bold')
    
    for idx, (name, path) in enumerate(graphs.items()):
        row = idx // 3
        col = idx % 3
        ax = axes[row, col]
        
        if path.exists():
            img = cv2.imread(str(path))
            img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
            ax.imshow(img)
            ax.set_title(name.replace('_', ' ').title(), fontweight='bold')
            ax.axis('off')
            print(f"✓ Loaded {name}")
        else:
            ax.text(0.5, 0.5, f'{name}\n(not found)', 
                   ha='center', va='center', transform=ax.transAxes)
            ax.axis('off')
            print(f"✗ Missing {name}")
    
    plt.tight_layout()
    output_path = OUTPUT_DIR / f"{train_dir.name}_metrics.png"
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    print(f"\n✓ Saved: {output_path}\n")
    plt.close()

def create_summary_report():
    """Create a summary of all training runs"""
    
    print("\n" + "="*50)
    print("SMARTCACAO MODEL TRAINING SUMMARY")
    print("="*50 + "\n")
    
    train_dirs = sorted([d for d in RUNS_DIR.iterdir() if d.is_dir()], 
                       key=lambda x: int(x.name.replace('train', '') or 0), 
                       reverse=True)
    
    print(f"Found {len(train_dirs)} training runs:\n")
    
    for i, train_dir in enumerate(train_dirs[:5], 1):  # Show last 5
        print(f"{i}. {train_dir.name}")
        
        # Count generated files
        files = list(train_dir.glob('*.png')) + list(train_dir.glob('*.jpg')) + list(train_dir.glob('*.csv'))
        print(f"   Files: {len(files)}")
        
        # Check for key metrics
        has_confusion = (train_dir / 'confusion_matrix.png').exists()
        has_pr_curve = (train_dir / 'PR_curve.png').exists()
        has_results = list(train_dir.glob('results.csv'))
        
        print(f"   ✓ Confusion Matrix: {has_confusion}")
        print(f"   ✓ PR Curve: {has_pr_curve}")
        print(f"   ✓ Results CSV: {len(has_results) > 0}\n")

def main():
    print("\n🔍 Scanning previous training runs...\n")
    
    # Create summary
    create_summary_report()
    
    # Analyze each training run
    train_dirs = sorted([d for d in RUNS_DIR.iterdir() if d.is_dir()], 
                       key=lambda x: int(x.name.replace('train', '') or 0), 
                       reverse=True)
    
    for train_dir in train_dirs[:3]:  # Process last 3 runs
        load_and_display_metrics(train_dir)
    
    print("\n" + "="*50)
    print(f"✓ All reports saved to: {OUTPUT_DIR}")
    print("="*50 + "\n")

if __name__ == "__main__":
    main()
