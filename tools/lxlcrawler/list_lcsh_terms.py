import sys

import lxlcrawler

# The JSON documents per object contain expanded JSON-LD:
MADSLABEL = "http://www.loc.gov/mads/rdf/v1#authoritativeLabel"

# Adhering to the EMM ActivityStreams based protocol: <https://emm-spec.org/1.0/>
start_url = "https://id.loc.gov/authorities/subjects/activitystreams/feed/1"

args = sys.argv[1:]
fetch_data = '-l' in args

for i, item in enumerate(lxlcrawler.crawl(start_url)):
    obj = item['object']

    mod = item.get('published') or item.get('endTime')

    label = None
    if fetch_data:
        for url in obj.get('url'):
            if url.get('mediaType') == "application/json":
                for thing in lxlcrawler.load_json(url['href']):
                    if thing['@id'] == obj['id']:
                        for label in thing.get(MADSLABEL, []):
                            if isinstance(label, dict):
                                label = label['@value']
                            break
                break

    print(f"[{i + 1}] {item['type']} {mod}, {obj['id']}, {obj['type']}, {label}")
