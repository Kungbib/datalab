#!/usr/bin/env python3
from urllib.parse import urljoin
from urllib.request import urlopen, Request
import json
import codecs

reader = codecs.getreader("utf-8")

def crawl(collection_url):
    while True:
        req = Request(collection_url, headers={'accept': 'application/json'})
        data = json.load(reader(urlopen(req)))
        for item in data['items']:
            yield item
        next_page = data.get('nextPage')
        if next_page:
            collection_url = urljoin(collection_url, next_page['@id'])
        else:
            break

if __name__ == '__main__':
    import argparse
    ap = argparse.ArgumentParser()
    ap.add_argument('url')
    args = ap.parse_args()

    for item in crawl(args.url):
        print(item)
