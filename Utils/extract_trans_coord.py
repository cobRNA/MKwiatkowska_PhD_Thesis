#!/usr/bin/env python2

__author__ = "BU"

from optparse import OptionParser
import gzip
from os import sys
import getopt

# ===============
## OPTION PARSING
# ===============

parser = OptionParser()
parser.add_option("-i", help="GTF/GTF. No stdin")
parser.add_option("-o", help="Output GFF file with trans coord")

options, args = parser.parse_args()


# Store input and output file

infile = ""
outfile = ""

# Read command line args
myopts, args = getopt.getopt(sys.argv[1:], "i:o:")

# Loop over arguments and assign input to infile and output to outfile
# o == option
# a == argument passed to the o

if myopts == []:
    print("Usage: %s -i input -o output -g outgtf" % sys.argv[0])

for o, a in myopts:
    if o == "-i":
        infile = a
    if o == "-o":
        outfile = a

print("Input file : %s \nOutput file: %s" % (infile, outfile))


def extract_trans_coord():

    tx_start = {}
    tx_stop = {}
    tx_line = {}
    tx_gff = {}

    gtf_file = open(infile, "r")
    for line in gtf_file:
        line_split = line.split("\n")[0].split("\t")
        chrom = line_split[0]
        item = line_split[1]
        typ = line_split[2]

        if typ == "exon":

            start = int(line_split[3])
            stop = int(line_split[4])
            strand = line_split[6]
            txID = line_split[8].split(";")[1].split("transcript_id")[1]
            geneID = line_split[8].split(";")[0].split("gene_id")[1]
            # print 'TX', txID
            # print 'GENE', geneID
            record = chrom + "@" + item + "@" + strand + "@" + geneID
            # print record

            # hash with start

            if txID not in tx_start:
                tx_start[txID] = [start]
            else:
                tx_start[txID].append(start)

            # hash with stop

            if txID not in tx_stop:
                tx_stop[txID] = [stop]
            else:
                tx_stop[txID].append(stop)

            # txID and the line

            tx_line[txID] = record
            # print 'TX_LINE',txID, tx_line[txID]

    for key in tx_start:
        # print 'TX_START',tx_start[key]

        tx_start[key].sort()
        tx_stop[key].sort()

        new_start = tx_start[key][0]
        # print 'NEW_START', new_start
        # print 'STOP', stop
        # print 'tx_stop[key]', tx_stop[key]
        new_stop = tx_stop[key][len(tx_stop[key]) - 1]
        # print 'NEW_STOP', new_stop
        tx_items = tx_line[key].split("@")
        tx_chrom = tx_items[0]
        tx_add = tx_items[1]
        tx_str = tx_items[2]
        tx_geneID = tx_items[3]
        merged = (
            tx_chrom
            + "\t"
            + tx_add
            + "\t"
            + "exon"
            + "\t"
            + str(new_start)
            + "\t"
            + str(new_stop)
            + "\t"
            + "."
            + "\t"
            + tx_str
            + "\t"
            + "."
            + "\t"
            + "gene_id"
            + tx_geneID
            + ";"
            + " "
            + "transcript_id"
            + key
            + ";"
        )

        tx_gff[key] = merged

    f = open(outfile, "w")
    for kyz in tx_gff:
        f.write("%s\n" % tx_gff[kyz])
    f.close()


extract_trans_coord()
