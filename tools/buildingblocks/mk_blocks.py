# -*- coding: UTF-8 -*-
from __future__ import unicode_literals
from collections import OrderedDict
import json
import sys
from os import path as P
from jinja2 import Environment, PackageLoader


TYPE, ID = '@type', '@id'

LABELS = {
    'termGroup': 'termgrupp',
    'equivalentClass': 'ekvivalent typ',
    'subClassOf': 'undertyp av',
}

def get_label(o):
    return o.get('uniformTitle') or o.get('title') or \
            o.get('legalName') or o.get('name') or \
            o.get('prefLabel') or (o.get('prefLabelByLang') and o['prefLabelByLang']['sv']) or \
            o.get('label') or (o.get('labelByLang') and o['labelByLang']['sv']) or \
            o.get('notation') or \
            o[ID].replace('http://', '')

def aslist(o):
    return o if isinstance(o, list) else [o]


args = sys.argv[1:]

model_file = args.pop(0)
examples_file = args.pop(0)
example_id = args.pop(0)

usework = True


def load(src):
    with open(src) as f:
        return json.load(f, object_pairs_hook=OrderedDict)

examples = load(examples_file)
model = load(model_file)


examples = {item[ID]: item for item in examples}
model = {term[ID]: term for term in model['@graph']
        if not term[ID].startswith('_:')}

terms = []
_termids = set()

def add_term(term_id):
    if term_id not in _termids:
        _termids.add(term_id)
        term = model[term_id] # if term_id in model else examples[term_id]
        if 'range' not in term:
            superterm = term.get('subPropertyOf')
            if isinstance(superterm, list):
                superterm = superterm[0] # TODO: use all...
            if superterm and superterm[ID] in model:
                superterm = model[superterm[ID]]
                superrange = superterm.get('range')
                if superrange:
                    term['range'] = superrange
        terms.append(term)
        return term

def get_type_label(o):
    rtype = o.get(TYPE)
    if not rtype:
        return
    if rtype == 'ObjectProperty':
        if o.get('structprops'):
            return 'Strukturerat värde'
        return 'Relation'
    elif rtype == 'DatatypeProperty':
        return 'Text'
    elif rtype == 'Class':
        return 'Typ'
    else:
        term = model.get(rtype)
        return get_label(term) if term else rtype

definitions = []
_defids = set()

def add_dfn(item, items=examples):
    if not isinstance(item, dict):
        return
    item_id = item.get(ID)
    item = items.get(item_id)
    if not item:
        return
    #focus = item.get('focus')
    #if focus:
    #    item = items[focus[ID]]
    #    item_id = item[ID]
    if item_id not in _defids:
        _defids.add(item_id)
        definitions.append(item)
    for vs in item.values():
        for v in aslist(vs):
            add_dfn(v)

def use_example(obj):
    if TYPE in obj:
        add_term(obj[TYPE])
        add_dfn(model[obj[TYPE]], model)
    for key, val in obj.items():
        if key.startswith('@'):
            continue
        term = add_term(key)
        term_range = term.get('range')
        #if term_range:
        #    add_term(term_range[ID])
        islist = isinstance(val, list)
        vals = aslist(val)
        for val in vals:
            add_dfn(val)
            if isinstance(val, dict):
                props = term.setdefault('structprops', [])
                vtype = val.get(TYPE)
                if vtype:
                    #add_term(vtype)
                    #if not term_range:
                    #    term['range'] = {ID: vtype}
                    term.setdefault('example_types', []).append(vtype)
                keys = set(p[ID] for p in props)
                for k, vs in val.items():
                    if k in model and k not in keys:
                        props.append(model[k])
                    for v in aslist(vs):
                        add_dfn(v)


example = examples[example_id]
del example['describedBy']
work = examples[example['exampleOfWork'][ID]]
if not usework:
    del example['exampleOfWork']
use_example(example)
use_example(work)


env = Environment(loader=PackageLoader(__name__, '.'))
tplt = env.get_template('blocks-tplt.html')
html = tplt.render(dict(vars(__builtins__), **vars())).encode('utf-8')
sys.stdout.write(html)
