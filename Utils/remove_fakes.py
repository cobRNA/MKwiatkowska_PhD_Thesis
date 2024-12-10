#!/usr/bin/env python3

"""
 Use to remove fakeExons after tmerging anchored TM.
 Loads fakeExons info from fakeExons file into set by
 chr,start,end,strand features. Subsequently, reads 
 tmergeOutput line by line and comapres mentioned features
 with those present in fake exons set.
 If they match, line is consider as fake exon and discarded.
 Operates on sets, so all duplicated lines are removed!
 Does not require sorted input to work correctly.
"""

import sys
import argparse


def remove_fakes(tmerged, fakes) -> set:
    """
    Read chr|start|end|strand exon info from tmerge set.
    If exon does not exist in fakes set, add it
    to new without_fakes set.
    After completion, return resulitng set.

    Args:
    tmerged (set): exons from anchored merging procedure. Contains fake exons.
    fakes (set): fake exons extracted after anchoring.

    Returns:
    set: exons from tmerged that were not common with fakes.
    """
    without_fakes = set()
    removed_exons = set()

    for transcript in tmerged:
        features_list = transcript.split()
        exon = features_list[0] + features_list[3] + features_list[4] + features_list[6]
        if exon not in fakes:
            without_fakes.add(transcript)
        else:
            removed_exons.add(transcript)

    # Report progress
    sys.stderr.write(f"Exons from tmergeOutput file: {len(tmerged)} \n")
    sys.stderr.write(f"FakeExons to remove: {len(fakes)} \n")
    sys.stderr.write(f"Resulting number of exons: {len(without_fakes)} \n")
    return without_fakes, removed_exons


def main() -> None:
    """
    Handles arguments, loads data into tmerged and fakes data sets.
    Returns exons set not containing fake exons to STDOUT.
    """
    # Handle comandline arguments
    parser = argparse.ArgumentParser(
        description="Removes fakeExons from tmergedOutput file.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument(
        "-a",
        "--tmergedOutput",
        help="path to tmergedOutput file containing all exons",
        default=None,
    )

    parser.add_argument(
        "-f",
        "--fakeExons",
        help="path to fakeExons file containing only fake exons",
        default=None,
    )

    parser.add_argument(
        "-t",
        "--trueExons",
        help="path to trueExons file containing only true exons",
        default=None,
    )

    args = parser.parse_args()
    config = vars(args)

    # Open tmergedOutput file and load into memory
    # Set comprehension is used to:
    # - removed empty lines: "if x" part
    # - create fakes hash using only necessary features from input
    with open(config["tmergedOutput"], "r", encoding="utf-8") as file:
        tmerged = {x for x in file.read().split(sep="\n") if x}
    # Open fakeExons file and load into memory
    with open(config["fakeExons"], "r", encoding="utf-8") as file:
        fakes = {
            x.split()[0] + x.split()[3] + x.split()[4] + x.split()[6]
            for x in file.read().split(sep="\n")
            if x
        }
    # Open trueExons file and load into memory
    with open(config["trueExons"], "r", encoding="utf-8") as file:
        trues = {
            x
            for x in file.read().split(sep="\n")
            if (x) and (int(x.split()[4]) - int(x.split()[3]) <= 5)
        }

    # Remove fakeExons
    clean_set_of_exons, removed_exons = remove_fakes(tmerged=tmerged, fakes=fakes)

    # Filter out trues that are already present in clean_set_of_exons
    clean_set_of_exons_hashes = {
        x.split()[0] + x.split()[3] + x.split()[4] + x.split()[6]
        for x in clean_set_of_exons
    }
    trues_filtered = set()
    for e in trues:
        hash = e.split()[0] + e.split()[3] + e.split()[4] + e.split()[6]
        if hash not in clean_set_of_exons_hashes:
            trues_filtered.add(e)

    # From removed exons, filter out exons with tx_id not matching trueExons tx_ids
    true_tx_ids = {x.split()[11].strip('";') for x in trues_filtered}
    removed_exons_filtered = set()
    for exon in removed_exons:
        if exon.split()[13].strip('";') in true_tx_ids:
            removed_exons_filtered.add(exon)

    sys.stderr.write(f"Removed exons to scan: {len(removed_exons_filtered)}\n")
    sys.stderr.write(f"True exons to scan: {len(trues)}\n")

    # Retrieve mistakenly removed exons
    count = 0
    # retrieved_exons = set()
    for exon_t in trues_filtered:
        feature_list_t = exon_t.split()
        finger_print_t = (
            feature_list_t[0]
            + feature_list_t[3]
            + feature_list_t[4]
            + feature_list_t[6]
        )
        tx_id_t = feature_list_t[11].strip('";')

        for exon_r in removed_exons_filtered:
            feature_list_r = exon_r.split()
            finger_print_r = (
                feature_list_r[0]
                + feature_list_r[3]
                + feature_list_r[4]
                + feature_list_r[6]
            )
            tx_id_r = feature_list_r[13].strip('";')

            if finger_print_t == finger_print_r and tx_id_t in tx_id_r:
                clean_set_of_exons.add(exon_r)
                count += 1
                break

    sys.stderr.write(f"Retrieved {count} removed exons.\n")

    # Make sure, that not a sigle true exon was removed among fake ones
    ## Look for laking true exons in resulting clean_set
    ### Hash clean_set_of_exons
    # hashed_clean_set_of_exons = {
    #     x.split()[0] + x.split()[3] + x.split()[4] + x.split()[6]
    #     for x in clean_set_of_exons
    # }
    # ### From trues dictionary remove exons that are present in clean_set
    # for key in hashed_clean_set_of_exons:
    #     trues.pop(key, None)
    ### Hash removed exons
    # hashed_removed_exons = {
    #     x.split()[0] + x.split()[3] + x.split()[4] + x.split()[6]: x
    #     for x in clean_set_of_exons
    # }
    # for key in trues:
    #     hashed_removed_exons.pop(key, None)

    # ### Retrieve lacking trueExons from removed_exons set
    # sys.stderr.write(f"Exons to retrieve: {len(trues)}\n")
    # sys.stderr.write(f"Removed exons to scan: {len(hashed_removed_exons)}\n")
    # for exon in trues.values():
    #     feature_list_t = exon.split()
    #     finger_print_t = (
    #         feature_list_t[0]
    #         + feature_list_t[3]
    #         + feature_list_t[4]
    #         + feature_list_t[6]
    #         + feature_list_t[11].strip('";')
    #     )
    #     # id_t = feature_list_t[11].strip('";')

    #     for removed in hashed_removed_exons.values():
    #         feature_list_r = removed.split()
    #         finger_print_r = (
    #             feature_list_r[0]
    #             + feature_list_r[3]
    #             + feature_list_r[4]
    #             + feature_list_r[6]
    #             + feature_list_r[11].strip('";')
    #         )
    #         # id_r = feature_list_r[11].strip('";')

    #         if finger_print_t == finger_print_r:
    #             clean_set_of_exons.add(removed)
    #             sys.stderr.write(f"Exon retrieved!\n")
    #             break

    # Return exons without fakes
    sys.stdout.write("\n".join(clean_set_of_exons))
    sys.stdout.write("\n")


if __name__ == "__main__":
    main()
