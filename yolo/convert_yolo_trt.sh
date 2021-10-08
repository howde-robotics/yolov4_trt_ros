echo "What is your model name (Should have XXX.weights and XXX.cfg in this folder)?"
read model_prefix


echo "What is the input shape? Input 288 or 416 or 608 (probably 416)"
read input_shape

echo "Creating ${model_prefix}-${input_shape}.cfg and ${model_prefix}-${input_shape}.weights"

cat $model_prefix.cfg | sed -e 's/batch=[0-9]*$/batch=1/g' | sed -e "s/width=[0-9]*$/width=${input_shape}/g" | sed -e "s/height=[0-9]*$/height=${input_shape}/g" > $model_prefix-${input_shape}.cfg

ln -sf $model_prefix.weights $model_prefix-${input_shape}.weights


echo "How many categories are there? (Probably 1)"
read category_num

model_name="${model_prefix}-${input_shape}"

# convert from yolo to onnx
python3 yolo_to_onnx.py -m $model_name -c $category_num

echo "Done converting to .onnx"
echo "..."
echo "Now converting to .trt"

# convert from onnx to trt
python3 onnx_to_tensorrt.py -m $model_name -c $category_num --verbose

echo "Conversion from yolo to trt done!"
