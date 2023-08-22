//
//  AlphaFrameFilter.metal
//  swiftMessanger
//
//  Created by Furkan Alioglu on 22.08.2023.
//

#include <metal_stdlib>
using namespace metal;



#include <metal_stdlib>
#include <CoreImage/CoreImage.h> // includes CIKernelMetalLib.h

extern "C" {
    namespace coreimage {
        float4 alphaFrame(sampler source, sampler mask) {
            float4 color = source.sample(source.coord());
            float opacity = mask.sample(mask.coord()).r;
            return float4(color.rgb, opacity);
        }
    }
}
