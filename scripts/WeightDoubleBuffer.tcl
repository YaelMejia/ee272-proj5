set blockname [file rootname [file tail [info script] ]]

source scripts/common.tcl

directive set -DESIGN_HIERARCHY "
    {WeightDoubleBuffer<8192, ${ARRAY_DIMENSION}, ${ARRAY_DIMENSION}>} 
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
directive set /WeightDoubleBuffer<8192,${ARRAY_DIMENSION},${ARRAY_DIMENSION}>/mem -WORD_WIDTH [expr ${ARRAY_DIMENSION} * 8]
directive set /WeightDoubleBuffer<8192,${ARRAY_DIMENSION},${ARRAY_DIMENSION}>/mem:cns -STAGE_REPLICATION 2

# Writer Configuration
# Input is 4 weights * 8 bits = 32 bits
directive set /WeightDoubleBuffer<8192,${ARRAY_DIMENSION},${ARRAY_DIMENSION}>/WeightDoubleBufferWriter<8192,${ARRAY_DIMENSION},${ARRAY_DIMENSION}>/din -WORD_WIDTH 32
# Output to memory is 128 bits
directive set /WeightDoubleBuffer<8192,${ARRAY_DIMENSION},${ARRAY_DIMENSION}>/WeightDoubleBufferWriter<8192,${ARRAY_DIMENSION},${ARRAY_DIMENSION}>/dout -WORD_WIDTH [expr ${ARRAY_DIMENSION} * 8]
# Internal variables
directive set /WeightDoubleBuffer<8192,${ARRAY_DIMENSION},${ARRAY_DIMENSION}>/WeightDoubleBufferWriter<8192,${ARRAY_DIMENSION},${ARRAY_DIMENSION}>/run/TILE:for:packet.value -WORD_WIDTH 32
# memRow is the full row width (128 bits)
directive set /WeightDoubleBuffer<8192,${ARRAY_DIMENSION},${ARRAY_DIMENSION}>/WeightDoubleBufferWriter<8192,${ARRAY_DIMENSION},${ARRAY_DIMENSION}>/run/TILE:memRow.value -WORD_WIDTH [expr ${ARRAY_DIMENSION} * 8]

# Reader Configuration
directive set /WeightDoubleBuffer<8192,${ARRAY_DIMENSION},${ARRAY_DIMENSION}>/WeightDoubleBufferReader<8192,${ARRAY_DIMENSION},${ARRAY_DIMENSION}>/din -WORD_WIDTH [expr ${ARRAY_DIMENSION} * 8]
directive set /WeightDoubleBuffer<8192,${ARRAY_DIMENSION},${ARRAY_DIMENSION}>/WeightDoubleBufferReader<8192,${ARRAY_DIMENSION},${ARRAY_DIMENSION}>/dout -WORD_WIDTH [expr ${ARRAY_DIMENSION} * 8]

# Temp variable width
directive set /WeightDoubleBuffer<8192,${ARRAY_DIMENSION},${ARRAY_DIMENSION}>/.../tmp.data.value -match glob -WORD_WIDTH [expr ${ARRAY_DIMENSION} * 8]
# -------------------------------

go architect

go allocate
go extract