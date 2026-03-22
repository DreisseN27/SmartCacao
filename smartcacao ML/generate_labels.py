#!/usr/bin/env python3
"""
Generate label files with estimated bounding boxes for single-bean images.
This script estimates that each bean fills ~70-90% of the image.
You can adjust the estimation parameters if needed.
"""

import os
from pathlib import Path
from PIL import Image

def get_class_id(category_name):
    """Map category name to class ID."""
    class_map = {
        "under_fermented": 0,
        "properly_fermented": 1,
        "over_fermented": 2,
    }
    return class_map.get(category_name, 0)

def estimate_bbox(image_path, bean_width_percent=0.85, bean_height_percent=0.85):
    """
    Estimate bounding box for single bean (assumes centered bean taking up most of image).
    
    Args:
        image_path: Path to image
        bean_width_percent: Estimated % of image width occupied by bean (0.0-1.0)
        bean_height_percent: Estimated % of image height occupied by bean (0.0-1.0)
    
    Returns:
        Tuple: (x_center, y_center, width, height) in normalized format
    """
    try:
        img = Image.open(image_path)
        # For centered bean assumption:
        x_center = 0.50
        y_center = 0.50
        width = bean_width_percent
        height = bean_height_percent
        return (x_center, y_center, width, height)
    except Exception as e:
        print(f"  ⚠ Error reading {image_path.name}: {e}")
        # Fallback to default
        return (0.50, 0.50, 0.85, 0.85)

def generate_labels():
    """Generate label files for all images with estimated bounding boxes."""
    
    base_path = Path("dataset")
    images_path = base_path / "images"
    labels_path = base_path / "labels"
    
    categories = ["under_fermented", "properly_fermented", "over_fermented"]
    splits = ["train", "val"]
    
    print("=" * 70)
    print("Generate Label Files with Estimated Bounding Boxes")
    print("=" * 70)
    print("Assuming: Single centered bean, ~85% of image width/height")
    print("Edit .txt files manually if estimates need adjustment")
    print("=" * 70)
    
    total_created = 0
    
    for split in splits:
        print(f"\n[{split.upper()}]")
        
        for category in categories:
            images_dir = images_path / split / category
            labels_dir = labels_path / split / category
            
            if not images_dir.exists():
                print(f"  ⚠ Skipping {category} - folder not found")
                continue
            
            # Get all image files
            image_files = sorted([
                f for f in images_dir.iterdir() 
                if f.suffix.lower() in ['.jpg', '.jpeg', '.png']
            ])
            
            if not image_files:
                print(f"  ⚠ {category} - no images found")
                continue
            
            print(f"  {category}:")
            print(f"    Images: {len(image_files)}")
            
            created_count = 0
            for image_file in image_files:
                label_file = labels_dir / f"{image_file.stem}.txt"
                
                # Estimate bbox
                x_center, y_center, width, height = estimate_bbox(image_file)
                class_id = get_class_id(category)
                
                # Write label file
                label_content = f"{class_id} {x_center:.2f} {y_center:.2f} {width:.2f} {height:.2f}\n"
                label_file.write_text(label_content)
                created_count += 1
            
            print(f"    Labels created: {created_count}")
            total_created += created_count
    
    print(f"\n{'=' * 70}")
    print(f"✓ Total label files created: {total_created}")
    print(f"{'=' * 70}")
    print(f"\nLabel format (YOLO):")
    print(f"  <class_id> <x_center> <y_center> <width> <height>")
    print(f"\nClass mapping:")
    print(f"  0 = under_fermented")
    print(f"  1 = properly_fermented")
    print(f"  2 = over_fermented")
    print(f"\nNote:")
    print(f"  - All values are normalized (0.0-1.0)")
    print(f"  - (0.50, 0.50) = image center")
    print(f"  - If estimates are wrong, edit .txt files manually")
    print(f"\nTo refine:")
    print(f"  - Edit individual .txt files to adjust coordinates")
    print(f"  - Use LabelImg or Roboflow to visualize and verify")
    print(f"\nNext: python train.py")

if __name__ == "__main__":
    generate_labels()
