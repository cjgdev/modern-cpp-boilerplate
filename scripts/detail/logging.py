import os

class Logging:
  def __init__(self, build_temp_dir, verbose):
    self.verbose = verbose
    self.log_path = os.path.join(build_temp_dir, 'log.txt')
    self.log_file = open(self.log_path, 'w')
