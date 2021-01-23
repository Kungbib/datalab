#!/usr/bin/env python3
from collections import OrderedDict
try:
    from lxml import etree
except:
    from xml.etree import ElementTree as etree


class Node(object):
    def __init__(self, name=None, depth=0):
        self.name = name
        self.depth = depth
        self.sources = set()
        self.children = OrderedDict()

    def process(self, elem, source):
        self.sources.add(source)
        for attr in elem.attrib:
            self.add('@' + attr, source)
        if not list(elem) and elem.text and elem.text.strip():
            self.add('#text', source)
        for child in elem:
            name = child.tag if child.tag != etree.Comment else '#comment'
            node = self.add(name, source)
            node.process(child, source)

    def add(self, name, source):
        node = self.children.setdefault(name, Node(name, self.depth + 1))
        node.sources.add(source)
        return node


def visualize(node, indent=2, source_count=0, parent_ratio=None):
    source_count = source_count or len(node.sources)
    ratio = len(node.sources) / source_count
    if node.name:
        note = ""
        if ratio < 1.0 and ratio != parent_ratio:
            note = " # in %.3f%%" % (ratio*100)
        print((' ' * indent) * node.depth + node.name + note)
    for child in node.children.values():
        visualize(child, indent, source_count, ratio)


if __name__ == '__main__':
    import glob, os, sys

    args = sys.argv[1:]

    tree = Node()

    for pth in args:
        sources = glob.glob(pth) if not os.path.isdir(pth) else (
                os.path.join(dirpath, fname)
                for dirpath, dirnames, filenames in os.walk(pth)
                for fname in filenames if not fname.startswith('.'))

        for source in sources:
            try:
                print("Processing", source, file=sys.stderr)
                root = etree.parse(source).getroot()
            except etree.XMLSyntaxError:
                print("XML syntax error in:", source, file=sys.stderr)
            else:
                tree.name = root.tag
                tree.process(root, source)

    visualize(tree)
