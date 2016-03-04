#!/usr/bin/env python3
import lxlcrawler

i = 0
for item in lxlcrawler.crawl("https://id.kb.se/find?q=*&limit=200&inScheme.@id=https://id.kb.se/term/sao"):
    i += 1
    print("[%s]" % i, item['@id'], item.get('prefLabel'))
