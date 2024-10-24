import lxlcrawler

# Adhering to the EMM ActivityStreams based protocol: <https://emm-spec.org/1.0/>
start_url = "https://id.loc.gov/authorities/subjects/activitystreams/feed/1"

# The JSON documents per object contain expanded JSON-LD:
MADSLABEL = "http://www.loc.gov/mads/rdf/v1#authoritativeLabel"

for i, item in enumerate(lxlcrawler.crawl(start_url)):
    obj = item['object']
    label = "?"
    for thing_type in obj['type']:
        break
    else:
        thing_type = "?"
    for url in obj.get('url'):
        if url.get('mediaType') == "application/json":
            for thing in lxlcrawler.load_json(url['href']):
                if thing['@id'] == obj['id']:
                    for label in thing[MADSLABEL]:
                        if isinstance(label, dict):
                            label = label['@value']
                        break
            break
    print(f"[{i + 1}]" + ", ".join([item['type'], obj['id'], thing_type, label]))
