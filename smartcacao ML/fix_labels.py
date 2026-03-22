#!/usr/bin/env python3
"""
Fix label files with incorrect class IDs.
Ensures class IDs match the folder: 0=under_fermented, 1=properly_fermented, 2=over_fermented
"""

import os
from pathlib import Path

def fix_labels():
    """Fix all label files with correct class IDs based on folder."""
    
    base_path = Path("dataset")
    labels_path = base_path / "labels"
    
    class_map = {
        "under_fermented": "0",
        "properly_fermented": "1",
        "over_fermented": "2",
    }
    
    categories = ["under_fermented", "properly_fermented", "over_fermented"]
    splits = ["train", "val"]
    
    print("=" * 70)
    print("Fix Label Files - Correct Class IDs")
    print("=" * 70)
    
    total_fixed = 0
    
    for split in splits:
        print(f"\n[{split.upper()}]")
        
        for category in categories:
            labels_dir = labels_path / split / category
            correct_class = class_map[category]
            
            if not labels_dir.exists():
                print(f"  ⚠ {category} - folder not found")
                continue
            
            label_files = sorted([f for f in labels_dir.glob("*.txt")])
            
            if not label_files:
                print(f"  {category} - no labels found")
                continue
            
            print(f"  {category}:")
            print(f"    Labels: {len(label_files)}")
            
            fixed_count = 0
            for label_file in label_files:
                try:
                    content = label_file.read_text().strip()
                    if not content:
                        # Empty file, add default bbox
                        label_file.write_text(f"{correct_class} 0.50 0.50 0.85 0.85\n")
                        fixed_count += 1
                    else:
                        lines = content.split('\n')
                        fixed_lines = []
                        for line in lines:
                            if line.strip():
                                parts = line.split()
                                if len(parts) >= 5:
                                    # Replace class ID with correct one
                                    fixed_line = f"{correct_class} " + " ".join(parts[1:5])
                                    fixed_lines.append(fixed_line)
                        
                        if fixed_lines:
                            label_file.write_text("\n".join(fixed_lines) + "\n")
                            fixed_count += 1
                except Exception as e:
                    print(f"      ⚠ Error fixing {label_file.name}: {e}")
            
            print(f"    Fixed: {fixed_count}")
            total_fixed += fixed_count
    
    print(f"\n{'=' * 70}")
    print(f"✓ Total labels fixed: {total_fixed}")
    print(f"{'=' * 70}")
    print(f"\nAll class IDs now match their folders:")
    print(f"  0 = under_fermented")
    print(f"  1 = properly_fermented")
    print(f"  2 = over_fermented")
    print(f"\nReady to train! Run: python train.py")

if __name__ == "__main__":
    fix_labels()
