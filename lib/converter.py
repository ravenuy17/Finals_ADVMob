# Convert the model to TFLite format
import tensorflow as tf

converter = tf.lite.TFLiteConverter.from_keras_model(model)
tflite_model = converter.convert()

# Save the TFLite model
with open('fsl_model.tflite', 'wb') as f:
    f.write(tflite_model)
