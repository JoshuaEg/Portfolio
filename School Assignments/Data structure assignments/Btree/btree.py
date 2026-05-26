from __future__ import annotations
import json
from typing import List
import math

# Node Class.
# You may make minor modifications.
class Node():
    def  __init__(self,
                  keys     : List[int]  = None,
                  children : List[Node] = None,
                  parent   : Node = None):
        self.keys     = keys
        self.children = children
        self.parent   = parent

# DO NOT MODIFY THIS CLASS DEFINITION.
class Btree():
    def  __init__(self,
                  m    : int  = None,
                  root : Node = None):
        self.m    = m
        self.root = None

    # DO NOT MODIFY THIS CLASS METHOD.
    def dump(self) -> str:
        def _to_dict(node) -> dict:
            return {
                "k": node.keys,
                "c": [(_to_dict(child) if child is not None else None) for child in node.children]
            }
        if self.root == None:
            dict_repr = {}
        else:
            dict_repr = _to_dict(self.root)
        return json.dumps(dict_repr,indent=2)


    # Insert.
    def insert(self, key: int):
        def check_left(root: Node, i : int):
            if root == None : return False
            i -= 1
            while i >= 0:
                if len(root.children[i].keys) != self.m -1:
                    return True
                i -= 1
            return False       
        def check_right(root: Node, i : int):
            if root == None : return False
            i += 1
            while i < len(root.children):
                if len(root.children[i].keys) != self.m -1 :
                    return True
                i += 1
            return False
        def sap(curr : Node, ancestors : list):
            def rotatesLeft(curr : Node, i : int):
                mom = curr.parent
                left = mom.children[i - 1]
                left.keys.append(mom.keys[i-1])
                left.children.append(curr.children[0])
                left.children[-1].parent = left

                mom.keys[i-1] = curr.keys[0]
                curr.keys = curr.keys[1:]
                curr.children = curr.children[1:]

                if (len(left.keys) == self.m):
                    rotatesLeft(left, i-1)
            def rotatesRight(curr : Node, i : int):
                mom = curr.parent
                right = mom.children[i + 1]
                right.keys.insert(0, mom.keys[i])
                right.children.insert(0, curr.children.pop())
                right.children[0].parent = right

                mom.keys[i] = curr.keys.pop()
                    
                if (len(right.keys) == self.m):
                    rotatesRight(right, i+1)
            j = math.ceil(len(curr.keys) / 2) - 1 
            mid = curr.keys[j]
            left = curr.keys[:j]
            right = curr.keys[j+1:]
            left = Node( keys = left, children = curr.children[:j+1], parent = curr.parent )
            right = Node( keys = right, children = curr.children[j+1:], parent = curr.parent )
            if curr.children[0] == None:
                left.children = [None] * (len(left.keys) + 1)
                right.children = [None] * (len(right.keys) + 1)
            if curr.parent == None:
                p = Node(keys = [mid],children = [left, right], parent = None )
                left.parent = p
                right.parent = p
                self.root = p
                return
            i = ancestors.pop()
            mom = curr.parent
            mom.keys.insert(i, mid)
            mom.children[i] = left
            mom.children.insert(i+1, right)
            if len(mom.keys) == self.m:
               
                if len(ancestors) == 0:
                    sap(mom, ancestors)
                    mommy_issues()
                    return
                if check_left(mom.parent, ancestors[-1]):
                    rotatesLeft(mom, ancestors.pop())
                elif check_right(mom.parent, ancestors[-1]):
                    rotatesRight(mom, ancestors.pop())
                else:
                    sap(mom, ancestors)
                mommy_issues()
            return       
        def mommy_issues(curr : Node = self.root):
            for kid in curr.children:
                if kid == None : return
                mommy_issues(kid)
                kid.parent = curr
        if self.root == None:
            self.root = Node(keys = [key], children = [None,None]) 
            return
        
        curr = self.root
        if  curr.children[0] == None:
                i = 0
                while i < len(curr.keys):
                    if key < curr.keys[i]:
                        curr.keys = curr.keys[:i] + [key] + curr.keys[i:]
                        break
                    i += 1
                if i == len(curr.keys):
                    curr.keys.append(key)
                curr.children.append(None)
                if len(curr.keys) == self.m:
                  sap(curr, []) 
                  mommy_issues(curr)
                return
        i = 0
        while i < len(curr.keys):
            if key < curr.keys[i]:
                break
            i += 1
        child = curr.children[i]
        ancestors = []
        while True:
            if child.children[0] == None:
                j = 0
                while j < len(child.keys):
                    if key < child.keys[j]:
                        child.keys = child.keys[:j] + [key] + child.keys[j:]
                        break
                    j += 1
                if j == len(child.keys):
                    child.keys.append(key)
                if len(child.keys) == self.m:
                    #left rotation
                    if check_left(curr, i):
                        while(len(child.keys) == self.m):
                            left = curr.children[i-1]
                            left.keys.append(curr.keys[i-1])
                            curr.keys[i-1] = child.keys[0]
                            child.keys = child.keys[1:]
                            child = left
                            i -= 1
                        child.children.append(None)
                        
                    elif check_right(curr, i):
                    #right rotation
                        while(len(child.keys) == self.m):
                            right = curr.children[i+1]
                            right.keys.insert(0, curr.keys[i])
                            curr.keys[i] = child.keys.pop()
                            child = right
                            i += 1
                        child.children.append(None)               
                    #SaP
                    else: 
                        ancestors.append(i)
                        sap(child, ancestors ) 
                        mommy_issues(self.root)
                else:
                    child.children.append(None)
                return   
            ancestors.append(i)
            i = 0
            curr = child
            while i < len(curr.keys):
                if key < curr.keys[i]:
                    break
                i += 1
            child = curr.children[i]
            

    # Delete.
    def delete(self, key: int):
        def mommy_issues(curr : Node = self.root):
            
            for kid in curr.children:
                if kid == None : return
                mommy_issues(kid)
                kid.parent = curr       
        def ios(curr : Node) -> int:
            if curr.children[0] != None:
                return ios(curr.children[0])
            return curr.keys[0]       
        def checkLeft(curr : Node, i : int ):
            mom = curr.parent
            if mom == None : return False
            i -= 1
            while i >= 0:
                if len(mom.children[i].keys) > (math.ceil(self.m/2) - 1):
                    return True
                i -= 1
            return False      
        def checkRight(curr : Node, i : int ):
            mom = curr.parent
            if mom == None : return False
            i += 1
            while i < len(mom.children):
                if len(mom.children[i].keys) > (math.ceil(self.m/2) - 1):
                    return True
                i += 1
            return False
        def getsLeft(curr : Node, i : int):
            mom = curr.parent
            l = i - 1
            left = mom.children[l]
            if len(left.keys) == (math.ceil(self.m/2) - 1):
                getsLeft(left, l)
    
            abandon = left.children.pop()
            curr.children.insert(0, abandon)
            if (curr.children[0] != None):
                curr.children[0].parent = curr
          
            
            curr.keys.insert(0, mom.keys[l])
            mom.keys[l] = left.keys.pop()
        def getsRight(curr : Node, i : int):
            mom = curr.parent
            r = i + 1
            right = mom.children[r]
            if len(right.keys) == (math.ceil(self.m/2) - 1):
                getsRight(right, r)

            curr.children.append( right.children[0])
            right.children = right.children[1:]
            if (curr.children[-1] != None):
                curr.children[-1].parent = curr

            curr.keys.append(mom.keys[i])
            mom.keys[i] = right.keys[0]
            right.keys = right.keys[1:]       
        def dam(curr : Node , pred : list[int]):
            i = pred.pop()
            mom = curr.parent
            if i == None: return

            if i == 0:
                right = mom.children[i+1]
                mid = mom.keys[i]
                mom.keys.pop(i)
                mom.children.pop(i)
                merge = curr.keys + [mid] + right.keys
                kids = curr.children + right.children
                momref = i
            else:
                left = mom.children[i-1]
                mid = mom.keys[i-1]
                mom.keys.pop(i-1)
                mom.children.pop(i-1)
                merge = left.keys + [mid] + curr.keys
                kids = left.children + curr.children
                momref = i-1

            n = Node(keys = merge, children=kids, parent = mom)
            mom.children[momref] = n

            if n.children[0] == None:
                n.children = [None] * (len(n.keys) + 1)
            if len(self.root.keys) == 0:
                n.parent = None
                self.root = n
                return
            if len(mom.keys) == (math.ceil(self.m/2) - 2) and mom != self.root:
                if checkLeft(mom, pred[-1]):
                    getsLeft(mom, pred.pop())
                elif checkRight(mom, pred[-1]):
                    getsRight(mom, pred.pop())
                else:
                    dam(mom, pred)
                    mommy_issues()
        def deletes(curr : Node, key: int, sauce : int = None, pred : list = []):
            if curr == None : return
            i = 0
            while(i < len(curr.keys)):
                if curr.keys[i] == key:
                    if curr.children[0] == None:
                        for j in range(0, len(curr.keys)):
                            if curr.keys[j] == key:
                                curr.keys.remove(key)
                                break 
                        curr.children.pop()
                        if len(curr.keys) == (math.ceil(self.m/2) - 2) and curr != self.root:
                            if checkLeft(curr, sauce):
                                getsLeft(curr, sauce)
                                
                            elif checkRight(curr, sauce):
                                getsRight(curr, sauce)
                                
                            else:
                                pred.append(sauce)
                                dam(curr, pred)
                                mommy_issues(self.root)
                            return  
                        return
                    else:
                        k = ios(curr.children[i+1])
                        curr.keys[i] = k
                        pred.append(sauce)
                        deletes(curr.children[i+1], k, i+1, pred)
                        return
                elif key < curr.keys[i]:
                    pred.append(sauce)
                    deletes(curr.children[i], key, i, pred)
                    return
                i += 1
            pred.append(sauce)
            deletes(curr.children[i], key, i, pred)
        if self.root == None:
            return
        
        deletes(self.root, key)
        

    # Search
    def search(self,key) -> str:
        def traverser(curr : Node, key : int):
            for i in range(0, len(curr.keys)):
                if key < curr.keys[i]:
                    return [i] + traverser(curr.children[i], key)
                if key == curr.keys[i] : return []
            i = len(curr.keys)
            return [i] +  traverser(curr.children[i], key)
        root = self.root
        return str(traverser(root, key))
        