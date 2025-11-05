import fitz  # PyMuPDF
import json
from pathlib import Path


def extract_pdf_content(pdf_path, output_dir):
    """
    Extract text and images from PDF.

    Args:
        pdf_path: Path to the PDF file
        output_dir: Directory to save extracted content
    """
    pdf_path = Path(pdf_path)
    output_dir = Path(output_dir)

    # Create output directories
    images_dir = output_dir / "images"
    images_dir.mkdir(parents=True, exist_ok=True)

    # Open the PDF
    doc = fitz.open(pdf_path)

    # Store extracted data
    extracted_data = {"source": str(pdf_path), "pages": []}

    print(f"Processing {len(doc)} pages...")

    for page_num in range(len(doc)):
        page = doc[page_num]
        print(f"Processing page {page_num + 1}...")

        # Extract text
        text = page.get_text()

        # Extract images
        image_list = page.get_images()
        page_images = []

        for img_index, img in enumerate(image_list):
            xref = img[0]

            # Extract image
            base_image = doc.extract_image(xref)
            image_bytes = base_image["image"]
            image_ext = base_image["ext"]

            # Save image
            image_filename = f"page_{page_num + 1}_img_{img_index + 1}.{image_ext}"
            image_path = images_dir / image_filename

            with open(image_path, "wb") as img_file:
                img_file.write(image_bytes)

            page_images.append(
                {
                    "filename": image_filename,
                    "path": str(image_path),
                    "format": image_ext,
                }
            )

        # Store page data
        page_data = {
            "page_number": page_num + 1,
            "text": text.strip(),
            "images": page_images,
            "image_count": len(page_images),
        }

        extracted_data["pages"].append(page_data)

    # Save metadata as JSON
    metadata_path = output_dir / "extracted_metadata.json"
    with open(metadata_path, "w") as f:
        json.dump(extracted_data, f, indent=2)

    print(f"\nExtraction complete!")
    print(f"- Total pages: {len(doc)}")
    print(f"- Total images: {sum(len(p['images']) for p in extracted_data['pages'])}")
    print(f"- Metadata saved to: {metadata_path}")
    print(f"- Images saved to: {images_dir}")

    doc.close()

    return extracted_data


def main():
    # Define paths relative to project root
    project_root = Path(__file__).parent.parent
    pdf_path = project_root / "assets" / "how-to-not-fail-lemons-tech-inspection.pdf"
    output_dir = project_root / "data" / "extracted"

    # Extract content
    extract_pdf_content(pdf_path, output_dir)


if __name__ == "__main__":
    main()
