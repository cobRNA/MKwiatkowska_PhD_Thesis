#!/usr/bin/python2

__author__ = "BU"


"""How many splice juntion of a given gene/transcript have been supported by RNA-Seq"""

# Usage python get_sj.py -i input.gtf -o sjfile.txt

from os import sys
import getopt
from optparse import OptionParser

# ===============
## OPTION PARSING
# ===============

parser = OptionParser()
parser.add_option(
    "-i",
    help="Tab separated file, contatining all transcript ids and splice junctions for given gtf.No stdin",
)
parser.add_option("-r", help="File containing supported splice junctions")
parser.add_option(
    "-a",
    help="Annotation (gtf file). Preferebly containing only exon records. It is recommended to use the same file, as for geting inputfile",
)
parser.add_option("-t", help="Output file for support on transcript level")
parser.add_option("-g", help="Output file for support on gene level")
options, args = parser.parse_args()


# Store input and output file

infile = ""
outtrans = ""
outgenes = ""
reffile = ""
mode = ""
annot = ""


# Read command line args
myopts, args = getopt.getopt(sys.argv[1:], "i:t:g:a:m:r:")

# Loop over arguments and assign input to infile and output to outfile
# o == option
# a == argument passed to the o

if myopts == []:
    print("Usage: %s -i input -o output" % sys.argv[0])

for o, a in myopts:
    if o == "-i":
        infile = a
    if o == "-t":
        outtrans = a
    if o == "-g":
        outgenes = a
    if o == "-a":
        annot = a
    if o == "-r":
        reffile = a


print(
    "Input file : %s \nOutput file for trans: %s \nOutput file for genes: %s \nAnnotation: %s \nValidated sj file: %s"
    % (infile, outtrans, outgenes, annot, reffile)
)


def get_support():

    trans_sj = {}
    supported = []
    validated = {}
    checkout = {}
    gene_trans = {}
    gene_val = {}
    supgenes = {}

    # --------------------------------------------
    # Transcript level
    # --------------------------------------------

    input_file = open(infile, "r")
    for line in input_file:
        line_split = line.split("\t")
        # print line_split
        trans_id = line_split[0]
        sj = line_split[1].split("\n")[0]
        # print 'sj', sj

        if trans_id not in trans_sj:
            trans_sj[trans_id] = [sj]
        else:
            trans_sj[trans_id].append(sj)

        # print trans_id, trans_sj[trans_id]

    supp_sj = open(reffile, "r")
    for lines in supp_sj:
        # print "SUP", lines.split('\n')[0]
        supported.append(lines.split("\n")[0])

    for key in trans_sj:
        # print trans_sj[key]
        for value in trans_sj[key]:
            # print 'VALUE', value
            if value in supported:
                if key not in validated:
                    validated[key] = [value]
                else:
                    validated[key].append(value)

    for kyz in trans_sj:
        if kyz in validated:
            if len(validated[kyz]) == len(trans_sj[kyz]):
                checkout[kyz] = "VALIDATED"
            else:
                checkout[kyz] = "NOT_VALIDATED"
        else:
            checkout[kyz] = "NOT_VALIDATED"
        # print kyz, checkout[kyz]

    fil = open(outtrans, "w")
    for x in checkout:
        fil.write("%s\t" % x)
        fil.write("%s\n" % checkout[x])
    fil.close()

    # -----------------------------------------------
    # GENE LEVEL
    # -----------------------------------------------

    annotation = open(annot, "r")
    for record in annotation:
        record_split = record.split("\t")
        cigar = record_split[8].split(";")
        # print cigar

        for elem in cigar:
            if elem.startswith("gene_id"):
                gene_id = elem.split('"')[1].split(".")[0]
                # print gene_id
            if elem.startswith(" transcript_id"):
                trans_annot = elem.split('"')[1].split(".")[0]
                # print trans_id
                if gene_id not in gene_trans:
                    gene_trans[gene_id] = [trans_annot]
                else:
                    gene_trans[gene_id].append(trans_annot)

    for keys in gene_trans:
        # print set(gene_trans[keys])
        for item in set(gene_trans[keys]):
            # print item
            if item in checkout:
                if checkout[item] == "VALIDATED":
                    if keys not in gene_val:
                        gene_val[keys] = ["VALIDATED"]
                    else:
                        gene_val[keys].append("VALIDATED")

    for k in gene_trans:
        if k in gene_val:
            if len(set(gene_trans[k])) == len(gene_val[k]):
                supgenes[k] = "VALIDATED"
            else:
                supgenes[k] = "NOT_VALIDATED"
        else:
            supgenes[k] = "NOT_VALIDATED"
        # print k, supgenes[k]

    f = open(outgenes, "w")
    for z in supgenes:
        f.write("%s\t" % z)
        f.write("%s\n" % supgenes[z])
    f.close()


get_support()
