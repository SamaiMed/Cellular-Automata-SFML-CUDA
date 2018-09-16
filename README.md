# Cellular Automata SFML CUDA


using 1 049 088 cells the application of Conway Game of Life using SFML and CUDA 9.0 run at 5 FPS.And that has to 
do mostly with the heavy cost of communication between the Host (CPU) and Device (GPU), CUDA Kernels cannot launch 
Host functions, so at each time the new cells stat matrix is calculated on the GPU it need to be transferred back 
to the host so it can call some OpenGl libs that would call the GPU so it  can be rendered, we can calculate
multiple stat matrices then send them in chunks to the host but that has been proven to be too memory inefficient 
due to the large size of the matrices.
   