class Tree:
    label = 0

    def __init__(self, elements, need_label=False):
        """
		Build binary tree from sorted collection.
		"""
        if need_label:
            self.label = '_' + str(Tree.label)
            Tree.label += 1
        else:
            self.label = None

        if len(elements) <= 1:
            self.right = None
            self.left = None
            self.value = elements[0] if elements else None
        else:
            self.right = Tree(elements[len(elements) // 2:])
            self.left = Tree(elements[0:len(elements) // 2], True)
            self.value = elements[len(elements) // 2]

    def __iter__(self):
        yield self
        if self.right:
            for right in self.right.__iter__():
                yield right
        if self.left:
            for left in self.left.__iter__():
                yield left