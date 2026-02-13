set blockname [file rootname [file tail [info script] ]]

source scripts/common.tcl

directive set -DESIGN_HIERARCHY "
    {SystolicArrayCore<IDTYPE, WDTYPE, ODTYPE, ${ARRAY_DIMENSION}, ${ARRAY_DIMENSION}>}
"

go compile

source scripts/set_libraries.tcl

solution library add {[CCORE] ProcessingElement<IDTYPE,WDTYPE,ODTYPE>.v1}

go libraries
directive set -CLOCKS $clocks
directive set /SystolicArrayCore<IDTYPE,WDTYPE,ODTYPE,${ARRAY_DIMENSION},${ARRAY_DIMENSION}>/ProcessingElement<IDTYPE,WDTYPE,ODTYPE> -MAP_TO_MODULE {[CCORE] ProcessingElement<IDTYPE,WDTYPE,ODTYPE>.v1}

go assembly

directive set /SystolicArrayCore<IDTYPE,WDTYPE,ODTYPE,${ARRAY_DIMENSION},${ARRAY_DIMENSION}>/run -DESIGN_GOAL Latency
directive set /SystolicArrayCore<IDTYPE,WDTYPE,ODTYPE,${ARRAY_DIMENSION},${ARRAY_DIMENSION}>/run -CLOCK_OVERHEAD 0.000000

# -------------------------------
# Accumulation Buffer Interleaving
# -------------------------------
directive set /SystolicArrayCore<IDTYPE,WDTYPE,ODTYPE,${ARRAY_DIMENSION},${ARRAY_DIMENSION}>/run/accumulation_buffer:rsc -INTERLEAVE ${ARRAY_DIMENSION}
# Block size = Total Depth / Interleave = 256 / 16 = 16
directive set /SystolicArrayCore<IDTYPE,WDTYPE,ODTYPE,${ARRAY_DIMENSION},${ARRAY_DIMENSION}>/run/accumulation_buffer:rsc -BLOCK_SIZE [expr 256 / ${ARRAY_DIMENSION}]

# -------------------------------
# Register Mapping
# -------------------------------
directive set /SystolicArrayCore<IDTYPE,WDTYPE,ODTYPE,${ARRAY_DIMENSION},${ARRAY_DIMENSION}> -REGISTER_THRESHOLD 4096
directive set /SystolicArrayCore<IDTYPE,WDTYPE,ODTYPE,${ARRAY_DIMENSION},${ARRAY_DIMENSION}>/run/input_reg:rsc -MAP_TO_MODULE {[Register]}
directive set /SystolicArrayCore<IDTYPE,WDTYPE,ODTYPE,${ARRAY_DIMENSION},${ARRAY_DIMENSION}>/run/psum_reg:rsc -MAP_TO_MODULE {[Register]}
directive set /SystolicArrayCore<IDTYPE,WDTYPE,ODTYPE,${ARRAY_DIMENSION},${ARRAY_DIMENSION}>/run/weight_reg:rsc -MAP_TO_MODULE {[Register]}
directive set /SystolicArrayCore<IDTYPE,WDTYPE,ODTYPE,${ARRAY_DIMENSION},${ARRAY_DIMENSION}>/run/input_reg2:rsc -MAP_TO_MODULE {[Register]}
directive set /SystolicArrayCore<IDTYPE,WDTYPE,ODTYPE,${ARRAY_DIMENSION},${ARRAY_DIMENSION}>/run/psum_reg2:rsc -MAP_TO_MODULE {[Register]}

go architect

# IGNORE MEMORY DEPENDENCIES
for {set i 0} {$i < ${ARRAY_DIMENSION}} {incr i} {
    catch {
        ignore_memory_precedences \
            -from /SystolicArrayCore<IDTYPE,WDTYPE,ODTYPE,${ARRAY_DIMENSION},${ARRAY_DIMENSION}>/run/INNER_LOOP:if#2:else:for:read_mem(accumulation_buffer:rsc($i)(0).@) \
            -to /SystolicArrayCore<IDTYPE,WDTYPE,ODTYPE,${ARRAY_DIMENSION},${ARRAY_DIMENSION}>/run/INNER_LOOP:if#3:for:write_mem(accumulation_buffer:rsc($i)(0).@)
    }
}

go allocate
go extract