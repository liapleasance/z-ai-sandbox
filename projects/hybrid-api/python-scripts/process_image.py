#!/usr/bin/env python3
"""
🖼️ Processamento de Imagens - Operações Básicas

Operações suportadas (sem PIL como fallback, com PIL se disponível):
- resize: Redimensionar
- rotate: Rotacionar
- grayscale: Converter para escala de cinza
- flip: Espelhar (horizontal/vertical)
- info: Obter informações da imagem
"""

import sys
import json
import time
import base64
import io

def try_import_pil():
    """Tenta importar PIL/Pillow"""
    try:
        from PIL import Image, ImageOps, ImageFilter
        return True, {"Image": Image, "ImageOps": ImageOps, "ImageFilter": ImageFilter}
    except ImportError:
        return False, {}

def process_image_info(image_path=None):
    """Obter informações sobre uma imagem"""
    has_pil, pil_modules = try_import_pil()
    
    if not has_pil:
        return {
            "status": "error",
            "message": "PIL/Pillow não instalado"
        }
    
    Image = pil_modules["Image"]
    
    try:
        if image_path:
            img = Image.open(image_path)
            info = {
                "filename": image_path,
                "format": img.format,
                "mode": img.mode,
                "size": img.size,
                "width": img.width,
                "height": img.height,
            }
            img.close()
            return {"status": "success", "info": info}
        else:
            return {
                "status": "info",
                "message": "Forneça 'imagePath' para analisar uma imagem",
                "pilAvailable": True
            }
    except Exception as e:
        return {"status": "error", "message": str(e)}

def create_sample_image(width=100, height=100, color=(255, 0, 0)):
    """Criar imagem de exemplo"""
    has_pil, pil_modules = try_import_pil()
    
    if not has_pil:
        return None
    
    Image = pil_modules["Image"]
    
    # Criar imagem colorida sólida
    img = Image.new('RGB', (width, height), color)
    
    # Adicionar padrão simples
    pixels = img.load()
    for y in range(height):
        for x in range(width):
            if (x + y) % 20 < 10:
                pixels[x, y] = tuple(255 - c for c in color)
    
    return img

def image_to_base64(img):
    """Converter imagem para base64"""
    buffered = io.BytesIO()
    img.save(buffered, format="PNG")
    return base64.b64encode(buffered.getvalue()).decode('utf-8')

def main():
    start_time = time.time()
    
    # Ler input do stdin
    try:
        input_data = json.load(sys.stdin)
    except Exception as e:
        output = {"error": f"Erro ao ler input: {str(e)}"}
        print(json.dumps(output))
        return
    
    operation = input_data.get("operation", "info").lower()
    
    has_pil, pil_modules = try_import_pil()
    
    try:
        if operation == "info":
            image_path = input_data.get("imagePath")
            result = process_image_info(image_path)
            
        elif operation == "create":
            width = input_data.get("width", 100)
            height = input_data.get("height", 100)
            color = tuple(input_data.get("color", [255, 0, 0]))
            
            if not has_pil:
                raise ValueError("PIL/Pillow necessário para criar imagens")
            
            img = create_sample_image(width, height, color)
            if img is None:
                raise ValueError("Falha ao criar imagem")
            
            base64_data = image_to_base64(img)
            result = {
                "status": "success",
                "operation": "create",
                "width": width,
                "height": height,
                "color": color,
                "format": "png",
                "base64": base64_data[:100] + "...truncated" if len(base64_data) > 100 else base64_data,
                "sizeBytes": len(base64_data)
            }
            img.close()
            
        elif operation == "resize":
            if not has_pil:
                raise ValueError("PIL/Pillow necessário para redimensionar")
            
            Image = pil_modules["Image"]
            image_path = input_data.get("imagePath")
            new_width = input_data.get("width", 100)
            new_height = input_data.get("height", 100)
            
            if not image_path:
                # Criar e redimensionar imagem de exemplo
                img = create_sample_image(200, 200)
            else:
                img = Image.open(image_path)
            
            img_resized = img.resize((new_width, new_height), Image.Resampling.LANCZOS)
            base64_data = image_to_base64(img_resized)
            
            result = {
                "status": "success",
                "operation": "resize",
                "originalSize": img.size,
                "newSize": (new_width, new_height),
                "base64": base64_data[:100] + "...truncated" if len(base64_data) > 100 else base64_data
            }
            img.close()
            img_resized.close()
            
        elif operation == "grayscale":
            if not has_pil:
                raise ValueError("PIL/Pillow necessário para converter")
            
            Image = pil_modules["Image"]
            image_path = input_data.get("imagePath")
            
            if not image_path:
                img = create_sample_image(100, 100, (100, 150, 200))
            else:
                img = Image.open(image_path)
            
            img_gray = img.convert('L')
            base64_data = image_to_base64(img_gray)
            
            result = {
                "status": "success",
                "operation": "grayscale",
                "originalMode": img.mode,
                "newMode": img_gray.mode,
                "base64": base64_data[:100] + "...truncated" if len(base64_data) > 100 else base64_data
            }
            img.close()
            img_gray.close()
            
        elif operation == "rotate":
            if not has_pil:
                raise ValueError("PIL/Pillow necessário para rotacionar")
            
            Image = pil_modules["Image"]
            angle = input_data.get("angle", 90)
            image_path = input_data.get("imagePath")
            
            if not image_path:
                img = create_sample_image(100, 100)
            else:
                img = Image.open(image_path)
            
            img_rotated = img.rotate(angle, expand=True)
            base64_data = image_to_base64(img_rotated)
            
            result = {
                "status": "success",
                "operation": "rotate",
                "angle": angle,
                "originalSize": img.size,
                "newSize": img_rotated.size,
                "base64": base64_data[:100] + "...truncated" if len(base64_data) > 100 else base64_data
            }
            img.close()
            img_rotated.close()
            
        else:
            operations = ["info", "create", "resize", "grayscale", "rotate"]
            raise ValueError(
                f"Operação desconhecida: {operation}. Disponíveis: {operations}"
            )
        
        elapsed_ms = (time.time() - start_time) * 1000
        
        if isinstance(result, dict):
            result["processingTimeMs"] = round(elapsed_ms, 4)
            result["pilAvailable"] = has_pil
        
        output = result
        
    except Exception as e:
        elapsed_ms = (time.time() - start_time) * 1000
        output = {
            "status": "error",
            "error": str(e),
            "operation": operation,
            "pilAvailable": has_pil,
            "processingTimeMs": round(elapsed_ms, 4)
        }
    
    print(json.dumps(output))

if __name__ == "__main__":
    main()
