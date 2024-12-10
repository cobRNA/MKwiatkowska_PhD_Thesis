#!/usr/bin/python2

__author__="BU"


"""This script contains only one fucntion calles get_sj, which selects all possible splice junctions from given GENCODE annotation file and corresponding ENSEMBL transcript ID"""

# Usage python get_sj.py -i input.gtf -o sjfile.txt

from optparse import OptionParser
import gzip
from os import sys
import getopt

# ===============
## OPTION PARSING
# ===============
parser = OptionParser()
parser.add_option("-i", 
	help="The input format is sorted gtf file. No stdin")
parser.add_option('-o', help='Output tab-sep two column file with tx and sj')
options, args = parser.parse_args()

# Store input and output file

infile=''
outfile=''

# Read command line args
myopts, args = getopt.getopt(sys.argv[1:],"i:o:")

# Loop over arguments and assign input to infile and output to outfile 
# o == option
# a == argument passed to the o

if myopts == []:
    print("Usage: %s -i input -o output" % sys.argv[0])

for o, a in myopts:
    if o == '-i':
        infile=a
    if o == '-o':
        outfile=a

print ("Input file : %s \nOutput file: %s" % (infile,outfile) )

# Body of GET_SJ function

def get_sj():
  
    exons_trans={}
    sj={}
    starts=[]
    stops=[]

    gtf=open(infile)
    for line in gtf:
        line_split = line.strip().split('\t')
        #print line_split
        record_type = line_split[2]
        if record_type.startswith('exon'):
            chrom=line_split[0]
            #print 'CHROM', chrom
            start=line_split[3]
            #print 'START', start
            stop=line_split[4]
            #print 'STOP', stop
            strand=line_split[6]
            #print 'STR', strand
            #print "element_set", line_split[9]
            element_set = line_split[8].strip().split(";")
            
            for element in element_set:
                if element.strip().split(" ")[0].startswith('transcript_id'):
                   trans_id=element.strip().split('"')[1]
                   #print 'TRANS ID', trans_id

                   if trans_id not in exons_trans:
                        exons_trans[trans_id]=[chrom+'_'+start+'_'+stop+'_'+strand]
                   else:
                       exons_trans[trans_id].append(chrom+'_'+start+'_'+stop+'_'+strand)
                   #print 'RESULTS',  trans_id, exons_trans[trans_id], '\n'
                   #print len(exons_trans.keys())
                   


    for key in exons_trans:
        #print key
        exon_list=exons_trans[key]
        if len(exon_list) >= 2:
            #print key
            #print 'LEN', len(exon_list)   
            for sth in exons_trans[key]:
                #print "STH", sth
                chr_tmp=sth.split("_")[0]
                start_tmp=int(sth.split("_")[1])
                stop_tmp=int(sth.split("_")[2])
                strand_tmp=sth.split("_")[3]
  
                starts.append(start_tmp)
                stops.append(stop_tmp)

                #print 'EXON LIST', exon_list, '\n'
            for i in range(0,(len(exon_list)-1)):
                #print "i", i   
                chr_nb=chr_tmp
                stop1=str(sorted(stops)[i])

                start2=str(sorted(starts)[i+1])
                sj_strand=strand_tmp                          
 
                if key not in sj:
                    sj[key]=[chr_nb+'_'+stop1+'_'+start2+'_'+sj_strand]
                else:
                    sj[key].append(chr_nb+'_'+stop1+'_'+start2+'_'+sj_strand)    
                #print 'FINAL', '\n', key, sj[key]
                #print len(sj.keys())
            starts=[]
            stops=[]

    f=open(outfile, 'w')
    for k in sj:
        for values in sj[k]:
            f.write('%s\t' % k)
            f.write('%s\n' % values)      
    f.close()

get_sj()


