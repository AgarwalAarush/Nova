#!/usr/bin/env python3
import onnx
import coremltools as ct

models = ["jarvis", "embedding_model", "melspectrogram"]

for name in models:
    onnx_path = f"{name}.onnx"
    mlmodel_path = f"{name}.mlmodel"
    print(f"Converting {name} ({onnx_path} → {mlmodel_path})")

    try:
        onnx_model = onnx.load(onnx_path)
        mlmodel = ct.convert(
            onnx_model,
            source="onnx",
            minimum_deployment_target=ct.target.iOS13,
            compute_units=ct.ComputeUnit.ALL,
            # inputs=[ct.TensorType(name="input", shape=(1, 1, 64, 80))]
        )
        mlmodel.save(mlmodel_path)
        print(f"✅ {name} saved to {mlmodel_path}\n")

    except Exception as e:
        print(f"❌ Error converting {name}: {e}\n")
