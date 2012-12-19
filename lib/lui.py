class LUI:
  def __init__(self):
    self.output = ""

  def text(self, content):
    self.output = self.output + content + "\000"

  def image(self, content):
    self.output = self.output +content + "\001\005"

  def result(self):
    return self.output

