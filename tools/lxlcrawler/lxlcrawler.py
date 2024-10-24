#!/usr/bin/env python3
from urllib.parse import urljoin
from urllib.request import urlopen, Request
import json
import codecs

reader = codecs.getreader("utf-8")


def load_json(url):
    req = Request(url, headers={'accept': 'application/json'})
    with urlopen(req) as f:
        return json.load(reader(f))


def crawl(collection_url):
    while True:
        data = load_json(collection_url)
        for item in data.get('orderedItems')or data.get('items') or []:
            yield item
        next_page = data.get('next') or data.get('nextPage')
        if next_page:
            if isinstance(next_page, dict):
                next_page = next_page['@id']
            collection_url = urljoin(collection_url, next_page)
        else:
            break

if __name__ == '__main__':
    import argparse
    ap = argparse.ArgumentParser()
    ap.add_argument('url')
    args = ap.parse_args()

    for item in crawl(args.url):
        print(item)
