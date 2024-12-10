#!/usr/bin/env python3
"""
Read targets from STDIN and converts it to tsv.
Crafted for the Hv3_CLS3_targetDesign.gtf.gz analysis in R.
"""

import sys

# Write header to stdout
HEADER = [
    "chr",
    "source",
    "feature",
    "start",
    "end",
    "score",
    "strand",
    "frame",
    "target_id",
    "target_set",
    "target_category",
]

sys.stdout.write("\t".join(HEADER) + "\n")

# Create tsv line
for input_line in sys.stdin:
    line = input_line.split("\t")
    target_ids = line[8].split(" ")[1].replace('"', "").replace(";", "")
    target_set = line[8].split(" ")[3].replace('"', "").replace(";", "")
    target_category = line[8].split(" ")[5].replace('"', "").replace(";", "")
    output_line = [
        line[0],
        line[1],
        line[2],
        line[3],
        line[4],
        line[5],
        line[6],
        line[7],
        target_ids,
        target_set,
        target_category,
    ]
    sys.stdout.write("\t".join(output_line) + "\n")
