#!/usr/bin/env python
# Script to take a bunch of patches, and query their subject lines on lkml.org
# Requirements: google python API and a registered Search Engine ID and API
# key

import sys
import argparse
import json

import pprint
from googleapiclient.discovery import build

verbose = 0
debug = 0
searchEngine_ID = 'FILL-ME-IN'
API_key = 'FILL-ME-IN'

def read_opt(argv):
    global verbose, debug

    parser = argparse.ArgumentParser()
    parser.add_argument('-s', '--string', nargs='*', required=True)
    parser.add_argument('-v', '--verbose', action='store_true')
    parser.add_argument('-d', '--debug', action='store_true')
    args = parser.parse_args(argv)
    if args.verbose:
        verbose = 1
    if args.debug:
        debug = 1
    if debug:
        print('read_opt: {}'.format(args.string))
    return ' '.join(args.string)

count = 0
upcount = 0
noupcount = 0
unknown = 0
if __name__ == "__main__":
    str = read_opt(sys.argv[1:])
    if debug:
        print('string: {}'.format(str))
    # We expect the follow string format: "<SHA>^ <patch subject line>"
    # So remove the SHA for the search
    search_str = str.split('^')[0]
    if debug:
        print('search_str: {}'.format(search_str))

    count += 1
    query_str = ' '.join([search_str])
    #query = urllib.urlencode({ 'q' : query_str })

    # Build a service object for interacting with the API. Visit
    # the Google APIs Console <http://code.google.com/apis/console>
    # to get an API key for your own application.
    service = build("customsearch", "v1", developerKey=API_key)

    #response = service.cse().list(q=query_str, siteSearch='lkml.org',
    response = service.cse().list(q=query_str,
                cx=searchEngine_ID).execute()
#            cx=searchEngine_ID, num=2).execute()

    if debug:
        pprint.pprint(response)
    if not response['items']:
        unknown += 1
        print '\tNo response... possibly throttled by Google. Aborting.'
        sys.exit(2)
    results = response['responseData']['results']
    if debug:
        print results
    if not results:
        noupcount += 1
        print '\tNo results'
        sys.exit(2)
    for result in results:
            if verbose:
                title = result['title']
                url = result['url']   # was URL in the original and that threw a name error exception
                print ('\t' + title + '; ' + url )
    upcount += 1

    print ('Total: {}, noup: {}, upcount: {},  unknown: {}'.format(count, noupcount, upcount, unknown))
