// RUN: hcl-opt %s | hcl-opt | FileCheck %s

module {

memref.global "private" @gv0 : memref<4x4xf32> = dense<[[1.0, 2.0, 3.0, 4.0], [1.0, 2.0, 3.0, 4.0], [1.0, 2.0, 3.0, 4.0], [1.0, 2.0, 3.0, 4.0]]>
memref.global "private" @gv1 : memref<4x4xf32> = dense<[[1.0, 2.0, 3.0, 4.0], [1.0, 2.0, 3.0, 4.0], [1.0, 2.0, 3.0, 4.0], [1.0, 2.0, 3.0, 4.0]]>
memref.global "private" @gv2 : memref<4x4xf32> = dense<[[1.0, 2.0, 3.0, 4.0], [1.0, 2.0, 3.0, 4.0], [1.0, 2.0, 3.0, 4.0], [1.0, 2.0, 3.0, 4.0]]>

func @matrix_multiply( 
  %A: memref<4x4xf32>, %B: memref<4x4xf32>, 
  %C: memref<4x4xf32>)
{ 
    %li = hcl.create_loop_handle "i" : !hcl.LoopHandle
    %lj = hcl.create_loop_handle "j" : !hcl.LoopHandle
    %lk = hcl.create_loop_handle "k" : !hcl.LoopHandle
    %s = hcl.create_stage_handle "s" : !hcl.StageHandle
	affine.for %i = 0 to 4 {          
	  affine.for %j = 0 to 4 {      
		affine.for %k = 0 to 4 {
		  %a = affine.load %A[%i, %k] : memref<4x4xf32> 
		  %b = affine.load %B[%k, %j] : memref<4x4xf32> 
		  %c = affine.load %C[%i, %j] : memref<4x4xf32> 
		  %prod = mulf %a, %b : f32
		  %sum  = addf %prod, %c: f32
		  affine.store %sum, %C[%i, %j] : memref<4x4xf32> 
		} {loop_name = "k"}
 	  } {loop_name = "j"}
	} {loop_name = "i", stage_name="s"}
    
    %li0, %li1 = hcl.split (%s, %li, 2)
    %lj0, %lj1 = hcl.split (%s, %lj, 2)
    hcl.reorder(%s, %li0, %lj0, %li1,%lj1)
    hcl.unroll(%s, %lj1)
    hcl.pipeline(%s, %lj1, 1)
    return
    }

  func @main() -> () {
  %0 = memref.get_global @gv0 : memref<4x4xf32>
  %1 = memref.get_global @gv0 : memref<4x4xf32>
  %2 = memref.get_global @gv0 : memref<4x4xf32>

  call @matrix_multiply(%0, %1, %2) : (memref<4x4xf32>, memref<4x4xf32>, memref<4x4xf32>) -> () 
  return
}
}

