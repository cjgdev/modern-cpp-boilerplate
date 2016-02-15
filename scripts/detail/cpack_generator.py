import os
import platform

available_generators = [
    'TBZ2',
    'TGZ',
]

if platform.system() == 'Linux':
  available_generators += [
      'DEB',
      'RPM',
  ]

def default():
  if platform.system() == 'Linux':
    return 'RPM'
  return 'TGZ'
