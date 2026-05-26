from __future__ import annotations
import json
import math
import statistics as stat
from typing import List

# DO NOT MODIFY!
class Datum():
    def __init__(self,
                 coords : tuple[int],
                 code   : str):
        self.coords = coords
        self.code   = code
    def to_json(self) -> dict:
        dict_repr = {'coords':self.coords,'code':self.code}
        return(dict_repr)

# DO NOT MODIFY!
class NodeInternal():
    def  __init__(self,
                  splitindex : int,
                  splitvalue : float,
                  leftchild,
                  rightchild):
        self.splitindex = splitindex
        self.splitvalue = splitvalue
        self.leftchild  = leftchild
        self.rightchild = rightchild

# DO NOT MODIFY!
class NodeLeaf():
    def  __init__(self,
                  data : List[Datum]):
        self.data = data

class EKDtree():
    # DO NOT MODIFY.
    def  __init__(self,
                  splitmethod : str,
                  k           : int,
                  m           : int,
                  root        : NodeLeaf = None):
        self.k    = k
        self.m    = m
        self.splitmethod = splitmethod
        self.root = root
    
    #bounding box func
    def bbox(self, n)  -> list[list[int]]:
        if isinstance(n, NodeLeaf):
            t = [None] * self.k
            for d in n.data:
                c = d.coords
                for i in range(self.k):
                    if t[i] == None:
                        t[i] = [c[i],c[i]]
                    else:
                        t[i][0] = min(c[i],t[i][0])
                        t[i][1] = max(c[i],t[i][1])
            return t
        else:
            t = self.bbox(n.leftchild)
            b = self.bbox(n.rightchild)
            for i in range(self.k):
                t[i][0] = min(b[i][0],t[i][0])
                t[i][1] = max(b[i][1],t[i][1])
            return t


    # For the tree rooted at root, dump the tree to stringified JSON object and return.
    # DO NOT MODIFY.
    def dump(self) -> str:
        def _to_dict(node) -> dict:
            if isinstance(node,NodeLeaf):
                # Sort the data by code so you there's no ambiguity.
                sd = sorted(node.data, key = lambda x:x.code)
                return {
                    "points": [str({'coords': datum.coords,'code': datum.code}) for datum in sd]
                }
            else:
                return {
                    "splitindex" : node.splitindex,
                    "splitvalue" : node.splitvalue,
                    "l"          : (_to_dict(node.leftchild)  if node.leftchild  is not None else None),
                    "r"          : (_to_dict(node.rightchild) if node.rightchild is not None else None)
                }
        if self.root is None:
            dict_repr = {}
        else:
            dict_repr = _to_dict(self.root)
        return json.dumps(dict_repr,indent=2)

    # Insert the Datum with the given code and coords into the tree.
    # The Datum with the given coords is guaranteed to not be in the tree.
    def insert(self,point:tuple[int],code:str):
        def spreadest( data : list[Datum]):
            largest = 0
            spread = None
            for i in range(self.k):
                def index(t : Datum): return t.coords[i]
                data.sort(key=index)
                h = data[-1].coords[i] - data[0].coords[i]
                if spread == None : spread = h
                elif h > spread :
                    spread = h
                    largest = i
            return largest
        def split(leaf : NodeLeaf, splitdex : int):
            left_size = (self.m + 1) // 2
            data = leaf.data
            def comp(t : Datum):
                coords = t.coords
                return (coords[splitdex],) + coords[splitdex+1 :self.k] + coords[0 : splitdex]
            data.sort(key = comp)
            if len(data) % 2 == 0:
                v = (data[left_size-1].coords[splitdex] + data[left_size].coords[splitdex]) / 2
            else: v = data[left_size].coords[splitdex] / 1
            
            left = data[0: left_size]
            right = data[left_size : (self.m + 1)]
            left = NodeLeaf(data = left)
            right = NodeLeaf(data = right)

            return NodeInternal(splitindex= splitdex, splitvalue= v, 
                                leftchild= left, rightchild= right)
        def inserter(node, splitdex: int):
            if isinstance(node, NodeLeaf):
                d = Datum(coords= point, code= code)
                data = node.data
                data.append(d)
                if len(data) == self.m+1:
                    if self.splitmethod == "spread":
                        splitdex = spreadest(data)
                    return split(node, splitdex)
                return None
            else:
                i = node.splitindex
                v = node.splitvalue
                if(point[i] < v):
                    if node.leftchild == None:
                        node.leftchild = NodeLeaf(data = [Datum(coords= point, code=code)])
                    else:
                        if i+1 == self.k : i = 0 
                        else : i = i+1 
                        n = inserter(node.leftchild, i)
                        if n : node.leftchild = n
                        return None
                else:
                    if node.rightchild == None:
                        node.rightchild = NodeLeaf(data = [Datum(coords= point, code=code)])
                    else:
                        if i+1 == self.k : i = 0 
                        else : i = i+1 
                        n = inserter(node.rightchild, i)
                        if n : node.rightchild = n
                        return None
        
        if self.root == None:
            self.root =  NodeLeaf(data = [Datum(coords= point, code=code)])
        else: 
            n = inserter(self.root, 0)
            if n: self.root = n


    # Delete the Datum with the given point from the tree.
    # The Datum with the given point is guaranteed to be in the tree.
    def delete(self,point:tuple[int]):
        def deletes(node):
            if isinstance(node, NodeLeaf):
                for i in node.data:
                    if i.coords == point:
                        node.data.remove(i)
                        break
                if len(node.data) == 0:
                    return None
                return node
            else:
                c = node.splitindex
                v = node.splitvalue
                if point[c] < v:
                    node.leftchild = deletes(node.leftchild)
                elif point[c] > v:
                    node.rightchild = deletes(node.rightchild)
                else:
                    node.leftchild = deletes(node.leftchild)
                    node.rightchild = deletes(node.rightchild)
                if node.leftchild == None:
                    return node.rightchild
                if node.rightchild == None:
                    return node.leftchild
                return node
        self.root = deletes(self.root)

    # Find the k nearest neighbors to the line.
    def knnquery(self,k:int,point:tuple[int]) -> str:
        def dist_from_p(d : Datum):
            c = d.coords
            dist = 0
            for i in range(self.k):
                dist += (c[i] - point[i]) ** 2
            return dist
        def dist_from_p2(d : Datum):
            c = d.coords
            dist = 0
            for i in range(self.k):
                dist += (c[i] - point[i]) ** 2
            return (dist, d.code)
        def b_from_p(b : list[list[int]]):
            dist = 0
            for i in range(self.k):
                dist += max(0,b[i][0] - point[i] ,point[i] - b[i][1]) ** 2
            return dist
        leaveschecked = [0]
        knnlist = [[]]
        def queryer(n, knnlist = knnlist, leaveschecked = leaveschecked):
            if isinstance(n, NodeLeaf):
                leaveschecked[0] += 1
                l = n.data
                l = knnlist[0] + l
                l.sort(key = dist_from_p2)
                if len(l) < k: knnlist[0] = l
                else: knnlist[0] = l[:k]
            else:
                lbox = self.bbox(n.leftchild)
                rbox = self.bbox(n.rightchild)
                dleft = b_from_p(lbox)
                dright = b_from_p(rbox)
                order = [(lbox, dleft), (rbox, dright)]
                order.sort(key = lambda x: x[1])
                if len(knnlist[0]) < k or order[0][1] <= dist_from_p(knnlist[0][-1]):
                    queryer(n.leftchild if order[0][0] is lbox else n.rightchild)
                    if len(knnlist[0]) < k or order[1][1] <= dist_from_p(knnlist[0][-1]):
                        queryer(n.leftchild if order[1][0] is lbox else n.rightchild)
        queryer(self.root)
        
        knnlist = knnlist[0]           
        # Do not modify the return
        return(json.dumps({"leaveschecked":leaveschecked[0],"points":[str({'coords': datum.coords,'code': datum.code}) for datum in knnlist]},indent=2))

    # Find all points in the querybox.
    def rangequery(self,querybox:List) -> str:
        def get_list_list():
            l = [None] * self.k
            for i in range(self.k):
                l[i] = [querybox[i*2], querybox[(i*2) + 1]]
            return l
        box = get_list_list()
        def b_in_p(p :tuple[int]):
            dist = 0
            for i in range(self.k):
                dist += max(0,box[i][0] - p[i] ,p[i] - box[i][1]) ** 2
            return dist == 0
        def b_in_b(b: list[list[int]]):
            for i in range(self.k):
                if b[i][0] > box[i][1] or b[i][1] < box[i][0]:
                    return False
            return True

        leaveschecked = [0]
        rangelist = []
        def queryer(n):
            if isinstance(n, NodeLeaf):
                leaveschecked[0] += 1
                data = n.data
                for d in data:
                    if b_in_p(d.coords):
                        rangelist.append(d)
            else:
                lbox = self.bbox(n.leftchild)
                rbox = self.bbox(n.rightchild)
                if b_in_b(lbox): queryer(n.leftchild)
                if b_in_b(rbox): queryer(n.rightchild)
        queryer(self.root)
        rangelist.sort(key = lambda x: x.code)    
        # Do not modify the return
        
        return(json.dumps({"leaveschecked":leaveschecked[0],"points":[str({'coords': datum.coords,'code': datum.code}) for datum in rangelist]},indent=2))