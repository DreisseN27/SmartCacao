#!/usr/bin/env python3
"""
Auto-generate label files for object detection.
This script creates empty .txt label files for each image in your dataset.
You'll then fill in the bounding box coordinates.
"""

import os
from pathlib import Path

def create_label_files():
    """Create empty label files matching all images in dataset/images/."""
    
    base_path = Path("dataset")
    images_path = base_path / "images"
    labels_path = base_path / "labels"
    
    categories = ["under_fermented", "properly_fermented", "over_fermented"]
    splits = ["train", "val"]
    
    print("=" * 70)
    print("Auto-Generate Label Files")
    print("=" * 70)
    
    total_created = 0
    
    for split in splits:
        for category in categories:
            images_dir = images_path / split / category
            labels_dir = labels_path / split / category
            
            if not images_dir.exists():
                print(f"⚠ Skipping {split}/{category} - images folder not found")
                continue
            
            # Get all image files
            image_files = sorted([
                f for f in images_dir.iterdir() 
                if f.suffix.lower() in ['.jpg', '.jpeg', '.png']
            ])
            
            print(f"\n[{split.upper()}] {category.upper()}")
            print(f"  Images found: {len(image_files)}")
            
            created_count = 0
            for image_file in image_files:
                label_file = labels_dir / f"{image_file.stem}.txt"
                
                if not label_file.exists():
                    # Create empty label file or template
                    # For single bean per image, you'll fill in: class x_center y_center width height
                    label_file.write_text("")
                    created_count += 1
            
            print(f"  Label files created: {created_count}")
            total_created += created_count
    
    print(f"\n" + "=" * 70)
    print(f"✓ Total label files created: {total_created}")
    print(f"=" * 70)
    print(f"\nNext steps:")
    print(f"1. Open each label file corresponding to your image")
    print(f"2. Add the bounding box in YOLO format:")
    print(f"   <class_id> <x_center> <y_center> <width> <height>")
    print(f"\n   Example:")
    print(f"   0 0.50 0.50 0.80 0.90")
    print(f"   (class=under_fermented, centered bean, 80% width, 90% height)")
    print(f"\n3. After labeling all files, run: python train.py")

if __name__ == "__main__":
    create_label_files()
