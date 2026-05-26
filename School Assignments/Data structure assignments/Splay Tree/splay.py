from __future__ import annotations
import json
from typing import List

# DO NOT MODIFY!
class Node():
    def  __init__(self,
                  key       : int,
                  leftchild  = None,
                  rightchild = None,
                  parent     = None,):
        self.key        = key
        self.leftchild  = leftchild
        self.rightchild = rightchild
        self.parent     = parent

class SplayForest():
    def  __init__(self,
                  roots : None):
        self.roots = roots

    def newtree(self,treename):
        self.roots[treename] = None

    # For the tree rooted at root:
    # Return the json.dumps of the object with indent=2.
    # DO NOT MODIFY!!!
    def dump(self):
        def _to_dict(node) -> dict:
            pk = None
            if node.parent is not None:
                pk = node.parent.key
            return {
                "key": node.key,
                "left": (_to_dict(node.leftchild) if node.leftchild is not None else None),
                "right": (_to_dict(node.rightchild) if node.rightchild is not None else None),
                "parentkey": pk
            }
        if self.roots == None:
            dict_repr = {}
        else:
            dict_repr = {}
            for t in self.roots:
                if self.roots[t] is not None:
                    dict_repr[t] = _to_dict(self.roots[t])
        print(json.dumps(dict_repr,indent = 2))

    # Search:
    # Search for the key or the last node before we fall out of the tree.
    # Splay that node.
    def splay(self, n : Node, treename):
            def rotate_l(n : Node):
                right = n.rightchild
                n.rightchild = right.leftchild     
                if right.leftchild : right.leftchild.parent = n
                right.leftchild = n
                if n.parent != None :
                    mom = n.parent
                    if mom.leftchild == n:
                        mom.leftchild = right
                    else:
                        mom.rightchild = right
                else:
                    self.roots[treename] = right
                right.parent = n.parent
                n.parent = right
                
            def rotate_r(n : Node):
                left = n.leftchild
                n.leftchild = left.rightchild
                if left.rightchild : left.rightchild.parent = n
                left.rightchild = n
                if n.parent != None :
                    mom = n.parent
                    if mom.leftchild == n:
                        mom.leftchild = left
                    else:
                        mom.rightchild = left
                else:
                    self.roots[treename] = left
                left.parent = n.parent
                n.parent = left

            if n.parent == None: return
            mom = n.parent
            path = [None,None]
            path[0] = 0 if mom.leftchild == n else 1
            if mom.parent == None:
                if path[0]:
                    rotate_l(mom)
                else : rotate_r(mom)
                return
            else:
                gradma = mom.parent
                path[1] = 0 if gradma.leftchild == mom else 1
                if path[0] == 0 and path[1] == 0:
                    rotate_r(gradma)
                    rotate_r(mom)
                elif path[0] == 1 and path[1] == 1:
                    rotate_l(gradma)
                    rotate_l(mom)
                elif path[0] == 0 and path[1] == 1:
                    rotate_r(mom)
                    rotate_l(gradma)
                else:
                    rotate_l(mom)
                    rotate_r(gradma)
                self.splay(n, treename)
        
    def search(self,treename: str,key:int):
        
        n = self.roots[treename]
        if n == None : return
        while True:
            if n.key > key:
                if n.leftchild == None : 
                    self.splay(n, treename)
                    return
                n = n.leftchild
            elif n.key < key:
                if n.rightchild == None :
                    self.splay(n, treename)
                    return
                n = n.rightchild
            else:
                self.splay(n, treename)
                return
                

    # Insert Type 1:
    def insert1(self,treename:str,key:int):
        n = Node(key = key)
        self.search(treename, key)
        t = self.roots[treename]
        self.roots[treename] = n
        if t == None : return
        t.parent = n
        if t.key < key:
            n.leftchild = t
            n.rightchild = t.rightchild
            t.rightchild = None
            if n.rightchild : n.rightchild.parent = n
        else:
            n.rightchild = t
            n.leftchild = t.leftchild
            t.leftchild = None
            if n.leftchild : n.leftchild.parent = n
            

    # Insert Type 2:
    def insert2(self,treename:str,key:int):
        def insert(n: Node, new : Node):
            if n.key < new.key:
                if n.rightchild == None : 
                    n.rightchild = new
                    new.parent = n
                else:
                    insert(n.rightchild, new)
            else:
                if n.leftchild == None : 
                    n.leftchild = new
                    new.parent = n
                else:
                    insert(n.leftchild, new)
        
        n = Node(key = key)
        t = self.roots[treename]
        self.roots[treename] = n
        if t == None : return
        insert(t, n)
        self.search(treename, key)


    # Delete Type 1:
    def delete1(self,treename:str,key:int):
        self.search(treename, key)
        t = self.roots[treename]
        if (not t.leftchild) and t.rightchild:
            t.rightchild.parent = None
            self.roots[treename] = t.rightchild
        elif  t.leftchild and (not t.rightchild):
            t.leftchild.parent = None
            self.roots[treename] = t.leftchild
        elif t.leftchild and t.rightchild:
            t.rightchild.parent = None
            self.roots[treename] = t.rightchild
            self.search(treename, key)
            n = self.roots[treename]
            n.leftchild = t.leftchild
            n.leftchild.parent = n
        else:
            self.roots[treename] = None

    # Delete Type 2:
    def delete2(self,treename:str,key:int):
        def ios(n: Node):
            if n.leftchild == None:
                return n.key
            else: return ios(n.leftchild)

        def deletes(n : Node, key : int ,og : bool = False):
            if n.key != key:
                if n.key > key:
                    deletes(n.leftchild, key, og)
                    
                else:
                    deletes(n.rightchild, key, og)

                    
            elif (not n.leftchild) and n.rightchild:
                if n.parent:
                    mom = n.parent
                    if mom.leftchild == n:
                        mom.leftchild = n.rightchild
                        mom.leftchild.parent = mom
                    else:
                        mom.rightchild = n.rightchild
                        mom.rightchild.parent = mom
                    if og:
                        self.search(treename, mom.key)
                else:
                    self.roots[treename] = n.rightchild
                    n.rightchild.parent = None
            elif  n.leftchild and  (not n.rightchild):
                    if n.parent:
                        mom = n.parent
                        if mom.leftchild == n:
                            mom.leftchild = n.leftchild
                            mom.leftchild.parent = mom
                        else:
                            mom.rightchild = n.leftchild
                            mom.rightchild.parent = mom
                        if og:
                            self.search(treename, mom.key)
                    else:
                        self.roots[treename] = n.leftchild
                        n.leftchild.parent = None
            elif n.leftchild and n.rightchild:
                k = ios(n.rightchild)
                n.key = k
                deletes(n.rightchild,k ,False)
                if n.parent:
                    self.search(treename, n.parent.key)
            else:
                if n.parent:
                    mom = n.parent
                    if mom.leftchild == n: mom.leftchild = None
                    else: mom.rightchild = None
                    if og: self.search(treename, mom.key)
                else: self.roots[treename] = None
        
        deletes(self.roots[treename], key ,True)
