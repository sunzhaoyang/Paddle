/* Copyright (c) 2016 PaddlePaddle Authors. All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. */

#include "paddle/fluid/operators/fake_dequantize_op.h"

namespace paddle {
namespace operators {

template <typename T>
__global__ void KeDequantize(const T* in, const T* scale, T max_range, int num,
                             T* out) {
  const int idx = threadIdx.x + blockIdx.x * blockDim.x;
  if (idx < num) {
    out[idx] = in[idx] * scale[0] / max_range;
  }
}

template <typename T>
struct DequantizeFunctor<platform::CUDADeviceContext, T> {
  void operator()(const platform::CUDADeviceContext& dev_ctx,
                  const framework::Tensor* in, const framework::Tensor* scale,
                  T max_range, framework::Tensor* out) {
    const T* in_data = in->data<T>();
    const T* scale_factor = scale->data<T>();
    T* out_data = out->mutable_data<T>(dev_ctx.GetPlace());

    int num = in->numel();
    int block = 512;
    int grid = (num + block - 1) / block;

    KeDequantize<T><<<grid, block, 0, dev_ctx.stream()>>>(
        in_data, scale_factor, max_range, num, out_data);
  }
};

template struct DequantizeFunctor<platform::CUDADeviceContext, float>;
template struct DequantizeFunctor<platform::CUDADeviceContext, double>;

}  // namespace operators
}  // namespace paddle

namespace ops = paddle::operators;
using CUDA = paddle::platform::CUDADeviceContext;
REGISTER_OP_CUDA_KERNEL(fake_dequantize_max_abs,
                        ops::FakeDequantizeMaxAbsKernel<CUDA, float>,
                        ops::FakeDequantizeMaxAbsKernel<CUDA, double>);
