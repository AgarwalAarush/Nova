#!/usr/bin/env python3
"""
conversion.py — ONNX → Core ML conversion script for macOS/iOS.
⚠️ Requires coremltools and onnx:
   pip install coremltools onnx
"""
import onnx
import coremltools as ct

# List your ONNX model basenames here (without ".onnx")
models = ["jarvis", "embedding_model", "melspectrogram"]

for name in models:
    onnx_path = f"{name}.onnx"
    mlmodel_path = f"{name}.mlmodel"
    print(f"Converting {name} ({onnx_path} → {mlmodel_path})")

    try:
        # 1. Load the ONNX model
        onnx_model = onnx.load(onnx_path)

        # 2. Convert—no 'source' arg needed, it auto-detects ONNX.
        #    Optionally specify minimum iOS deployment target:
        mlmodel = ct.convert(
            onnx_model,
            minimum_deployment_target=ct.target.iOS13
        )

        # 3. Save out the Core ML model
        mlmodel.save(mlmodel_path)
        print(f"✅ {name} saved to {mlmodel_path}\n")

    except Exception as e:
        print(f"❌ Error converting {name}: {e}\n")
        # continue with the next model
