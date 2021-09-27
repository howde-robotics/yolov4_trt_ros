echo "YOLOv3 or YOLOv4. Input 3 or 4"
read model_type

echo "Large or Tiny. Input L or T"
read model_size

if [[ $model_size == 'L' ]]
then
    model_prefix="yolov${model_type}"
else
    model_prefix="yolov${model_type}-tiny"
fi

echo "Do you want to download the model? [Y/N]"
read download

if [[ $download == 'Y' ]]
then
    if [[ $model_type == 3 ]]
    then
	wget https://raw.githubusercontent.com/pjreddie/darknet/master/cfg/yolov3.cfg -q --show-progress --no-clobber
	wget https://pjreddie.com/media/files/yolov3.weights -q --show-progress --no-clobber
    else
	wget https://raw.githubusercontent.com/AlexeyAB/darknet/master/cfg/yolov4.cfg -q --show-progress --no-clobber
	wget https://github.com/AlexeyAB/darknet/releases/download/darknet_yolo_v3_optimal/yolov4.weights -q --show-progress --no-clobber
    fi
fi

echo "What is the input shape? Input 288 or 416 or 608"
read input_shape

if [[ $model_type == 3 ]]
then
    if [[ $input_shape == 288 ]]
    then
        echo "Creating ${model_prefix}-288.cfg and ${model_prefix}-288.weights"
        cat $model_prefix.cfg | sed -e '2s/batch=64/batch=1/' | sed -e '7s/width=608/width=288/' | sed -e '8s/height=608/height=288/' > $model_prefix-288.cfg
        ln -sf $model_prefix.weights $model_prefix-288.weights
    fi
    if [[ $input_shape == 416 ]]
    then
        echo "Creating ${model_prefix}-416.cfg and ${model_prefix}-416.weights"
        cat $model_prefix.cfg | sed -e '2s/batch=64/batch=1/' | sed -e '7s/width=608/width=416/' | sed -e '8s/height=608/height=416/' > $model_prefix-416.cfg
        ln -sf $model_prefix.weights $model_prefix-416.weights
    fi
    if [[ $input_shape == 608 ]]
    then
        echo "Creating ${model_prefix}-608.cfg and ${model_prefix}-608.weights"
        cat $model_prefix.cfg | sed -e '2s/batch=64/batch=1/' > $model_prefix-608.cfg
        ln -sf $model_prefix.weights $model_prefix-608.weights
    fi
else
    if [[ $input_shape == 288 ]]
    then
        echo "Creating ${model_prefix}-288.cfg and ${model_prefix}-288.weights"
        cat $model_prefix.cfg | sed -e '2s/batch=64/batch=1/' | sed -e '7s/width=608/width=288/' | sed -e '8s/height=608/height=288/' > $model_prefix-288.cfg
        ln -sf $model_prefix.weights $model_prefix-288.weights
    fi
    if [[ $input_shape == 416 ]]
    then
        echo "Creating ${model_prefix}-416.cfg and ${model_prefix}-416.weights"
        cat $model_prefix.cfg | sed -e '2s/batch=64/batch=1/' | sed -e '7s/width=608/width=416/' | sed -e '8s/height=608/height=416/' > $model_prefix-416.cfg
        ln -sf $model_prefix.weights $model_prefix-416.weights
    fi
    if [[ $input_shape == 608 ]]
    then
        echo "Creating ${model_prefix}-608.cfg and ${model_prefix}-608.weights"
        cat $model_prefix.cfg | sed -e '2s/batch=64/batch=1/' > $model_prefix-608.cfg
        ln -sf $model_prefix.weights $model_prefix-608.weights
    fi
fi

echo "How many categories are there?"
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
