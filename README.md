# Getting Weights from Drive to Dragoon

Sup nerd, heres a quick how-to: get a new set of weights into the dragoon system (as of Nov 1)

1. Sign into google drive, go to MRSD project > 9_Colab_Notebooks > saved_weights adn find the folder of the approriate run you want to downlaod
2. Download the `.cfg` and the appropriate `.weights` file. `_last.weights` and `_final.weights` should the be equivalent and are the final weights during training. `_best.weights` are the weights that performed the best on the validation set during training. If you didn't overtrain, there should be too much of a difference here. If you have a reasonable validation set, `_best.weights` is probably the right choice.
3. Place the `.cfg` and `.weights` file in `dragoon_system/src/perception/yolov4_trt_ros/yolo`
4. Rename both to `yolov4-tiny-{thermal/rgb}.{cfg/weights}`. Use your noggin to figure out the correct permutation here.
5. Go to this folder in terminal and run `convert_yolo_trt.sh` 
6. Enter the name `yolov4-tiny-{thermal/rgb}` when prompted
7. Enter `416` for size when prompted
8. Enter `1` for number of categories when prompted
9. Wait
10. Check for errors in the final few lines of the output. If there isn't anything bad there, check the folder: you should find 4 NEW files named `yolov4-tiny-{thermal/rgb}-416.[weights, cfg, onnx, trt]`
11. Make a new folder in `yolov4_trt_ros/yolo` with the same name as the folder in google drive that you got the weights from. This will help keep track of which networks we are using
12. Move all 6 (yes 6) files into this new folder
13. To run with these new weights, change the `training_name` parameter of the launch file in `dragoon_bringup/launch/include/yolov4_trt_{thermal/rgb}.launch`. NOTE: Not the launch file in yolov4_trt_ros/launch, which is not used during our primary bootup 




# YOLOv4 with TensorRT engine

This package contains the yolov4_trt_node that performs the inference using NVIDIA's TensorRT engine

This package works for both YOLOv3 and YOLOv4. Do change the commands accordingly, corresponding to the YOLO model used.


![Video_Result2](docs/results.gif)

---
## Setting up the environment

### Install dependencies

### Current Environment:

- Jetson Xavier AGX
- ROS Melodic
- Ubuntu 18.04
- Jetpack 4.4
- TensorRT 7+

#### Dependencies:

- OpenCV 3.x
- numpy 1.15.1
- Protobuf 3.8.0
- Pycuda 2019.1.2
- onnx 1.4.1 (depends on Protobuf)

### Install all dependencies with below commands

```
Install pycuda (takes awhile)
$ cd ${HOME}/catkin_ws/src/yolov4_trt_ros/dependencies
$ ./install_pycuda.sh

Install Protobuf (takes awhile)
$ cd ${HOME}/catkin_ws/src/yolov4_trt_ros/dependencies
$ ./install_protobuf-3.8.0.sh

Install onnx (depends on Protobuf above)
$ sudo pip3 install onnx==1.4.1
```

* Please also install [jetson-inference](https://github.com/dusty-nv/ros_deep_learning#jetson-inference)
* Note: This package uses similar nodes to ros_deep_learning package. Please place a CATKIN_IGNORE in that package to avoid similar node name catkin_make error
* If these scripts do not work for you, do refer to this amazing repository by [jefflgaol](https://github.com/jefflgaol/Install-Packages-Jetson-ARM-Family) on installing the above packages and more on Jetson ARM devices.
---
## Setting up the package

### 1. Clone project into catkin_ws and build it

``` 
$ cd ~/catkin_ws && catkin_make
$ source devel/setup.bash
```

### 2. Make libyolo_layer.so

```
$ cd ${HOME}/catkin_ws/src/yolov4_trt_ros/plugins
$ make
```

This will generate a libyolo_layer.so file

### 3. Place your yolo.weights and yolo.cfg file in the yolo folder

```
$ cd ${HOME}/catkin_ws/src/yolov4_trt_ros/yolo
```
** Please name the yolov4.weights and yolov4.cfg file as follows:
- yolov4.weights
- yolov4.cfg

Run the conversion script to convert to TensorRT engine file

```
$ ./convert_yolo_trt
```

- Input the appropriate arguments
- This conversion might take awhile
- The optimised TensorRT engine would now be saved as yolov3-416.trt / yolov4-416.trt

### 4. Change the class labels

```
$ cd ${HOME}/catkin_ws/src/yolov4_trt_ros/utils
$ vim yolo_classes.py
```

- Change the class labels to suit your model

### 5. Change the video_input and topic_name

```
$ cd ${HOME}/catkin_ws/src/yolov4_trt_ros/launch
```

- `yolov3_trt.launch` : change the topic_name

- `yolov4_trt.launch` : change the topic_name

- `video_source.launch` : change the input format (refer to this [Link](https://github.com/dusty-nv/jetson-inference/blob/master/docs/aux-streaming.md)

   * video_source.launch requires jetson-inference to be installed
   * Default input is CSI camera

---
## Using the package

### Running the package

Note: Run the launch files separately in different terminals

### 1. Run the video_source 

```
# For csi input
$ roslaunch yolov4_trt_ros video_source.launch input:=csi://0

# For video input
$ roslaunch yolov4_trt_ros video_source.launch input:=/path_to_video/video.mp4

# For USB camera
$ roslaunch yolov4_trt_ros video_source.launch input:=v4l2://0
```

### 2. Run the yolo detector

```
# For YOLOv3 (single input)
$ roslaunch yolov4_trt_ros yolov3_trt.launch

# For YOLOv4 (single input)
$ roslaunch yolov4_trt_ros yolov4_trt.launch

# For YOLOv4 (multiple input)
$ roslaunch yolov4_trt_ros yolov4_trt_batch.launch
```

### 3. For maximum performance

```
$ cd /usr/bin/
$ sudo ./nvpmodel -m 0	# Enable 2 Denver CPU
$ sudo ./jetson_clock	# Maximise CPU/GPU performance
```

* These commands are found/referred in this [forum post](https://forums.developer.nvidia.com/t/nvpmodel-and-jetson-clocks/58659/2)
* Please ensure the jetson device is cooled appropriately to prevent overheating

### Parameters

- str model = "yolov3" or "yolov4" 
- str model_path = "/abs_path_to_model/"
- int input_shape = 288/416/608
- int category_num = 80
- double conf_th = 0.5
- bool show_img = True

- Default Input FPS from CSI camera = 30.0
* To change this, go to jetson-inference/utils/camera/gstCamera.cpp 

``` 
# In line 359, change this line
mOptions.frameRate = 15

# To desired frame_rate
mOptions.frameRate = desired_frame_rate
``` 
---
## Results obtained

### Inference Results
#### Single Camera Input

   | Model    | Hardware |    FPS    |  Inference Time (ms)  | 
   |:---------|:--:|:---------:|:----------------:|
   | Yolov4-416| Xavier AGX | 40.0 | 0.025 |
   | Yolov4-416| Jetson Tx2 | 16.0 | 0.0625 |

   
* Will be adding inference tests for YOLOv3/4 and YOLOv3-tiny/YOLOv4-tiny for different Jetson devices and multiple camera inputs inference tests in the future

### 1. Screenshots 

### Video_in: .mp4 video (640x360)
### Tests Done on Xavier AGX
### Avg FPS : ~38 FPS

![Video_Result1](docs/yolov4_custom_1.png)

![Video_Result2](docs/yolov4_custom_2.png)

![Video_Result3](docs/yolov4_custom_3.png)

---
## Licenses and References

### 1. TensorRT samples from [jkjung-avt](https://github.com/jkjung-avt/) 

Many thanks for his project with tensorrt samples. I have referenced his source code and adapted it to ROS for robotics applications.

I also used the pycuda and protobuf installation script from his project

Those code are under [MIT License](https://github.com/jkjung-avt/tensorrt_demos/blob/master/LICENSE)

### 2. Jetson-inference from [dusty-nv](https://github.com/dusty-nv/ros_deep_learning#jetson-inference)

Many thanks for his work on the Jetson Inference with ROS. I have used his video_source input from his project for capturing video inputs. 

Those code are under [NVIDIA License](https://github.com/dusty-nv/jetson-inference/blob/master/LICENSE.md) 
