set blockname [file rootname [file tail [info script] ]]

source scripts/common.tcl

directive set -DESIGN_HIERARCHY " 
    {InputDoubleBuffer<4096, ${ARRAY_DIMENSION}, ${ARRAY_DIMENSION}>} 
"

go compile

source scripts/set_libraries.tcl

go libraries
directive set -CLOCKS $clocks

go assembly

# -------------------------------
# Set the correct word widths and the stage replication
# -------------------------------
# Memory Configuration
directive set /InputDoubleBuffer<4096,${ARRAY_DIMENSION},${ARRAY_DIMENSION}>/mem -WORD_WIDTH [expr ${ARRAY_DIMENSION} * 8]
directive set /InputDoubleBuffer<4096,${ARRAY_DIMENSION},${ARRAY_DIMENSION}>/mem:cns -STAGE_REPLICATION 2

# Writer Configuration
# Input is 4 pixels * 8 bits = 32 bits
directive set /InputDoubleBuffer<4096,${ARRAY_DIMENSION},${ARRAY_DIMENSION}>/InputDoubleBufferWriter<4096,${ARRAY_DIMENSION},${ARRAY_DIMENSION}>/din -WORD_WIDTH 32
# Output to memory is 16 pixels * 8 bits = 128 bits
directive set /InputDoubleBuffer<4096,${ARRAY_DIMENSION},${ARRAY_DIMENSION}>/InputDoubleBufferWriter<4096,${ARRAY_DIMENSION},${ARRAY_DIMENSION}>/dout -WORD_WIDTH [expr ${ARRAY_DIMENSION} * 8]
# Ensure internal packet variables are 32 bits
directive set /InputDoubleBuffer<4096,${ARRAY_DIMENSION},${ARRAY_DIMENSION}>/InputDoubleBufferWriter<4096,${ARRAY_DIMENSION},${ARRAY_DIMENSION}>/run/TILE:for:packet.value -WORD_WIDTH 32

# Reader Configuration
# Read from memory is 128 bits
directive set /InputDoubleBuffer<4096,${ARRAY_DIMENSION},${ARRAY_DIMENSION}>/InputDoubleBufferReader<4096,${ARRAY_DIMENSION},${ARRAY_DIMENSION}>/din -WORD_WIDTH [expr ${ARRAY_DIMENSION} * 8]
# Output to Systolic Array is 128 bits
directive set /InputDoubleBuffer<4096,${ARRAY_DIMENSION},${ARRAY_DIMENSION}>/InputDoubleBufferReader<4096,${ARRAY_DIMENSION},${ARRAY_DIMENSION}>/dout -WORD_WIDTH [expr ${ARRAY_DIMENSION} * 8]

# Temp variable width (to match memory)
directive set /InputDoubleBuffer<4096,${ARRAY_DIMENSION},${ARRAY_DIMENSION}>/.../tmp.data.value -match glob -WORD_WIDTH [expr ${ARRAY_DIMENSION} * 8]
# -------------------------------

go architect

go allocate
go extract