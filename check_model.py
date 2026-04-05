import onnx
m = onnx.load('smartcacao/assets/models/best.onnx')
print('Output info:')
for o in m.graph.output:
    print(f'  Name: {o.name}')
    if hasattr(o.type, 'tensor_type'):
        shape = o.type.tensor_type.shape.dim
        dims = [d.dim_value for d in shape]
        print(f'  Shape: {dims}')
        if len(dims) == 3:
            print(f'  Total elements: {dims[0] * dims[1] * dims[2]}')
