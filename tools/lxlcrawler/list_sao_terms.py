#!/usr/bin/env python3
import lxlcrawler

start_url = "https://id.kb.se/find?q=*&limit=200&inScheme.@id=https://id.kb.se/term/sao"

for i, item in enumerate(lxlcrawler.crawl(start_url)):
    print("[{}] {}, {}".format(i + 1, item['@id'], item.get('prefLabel')))
