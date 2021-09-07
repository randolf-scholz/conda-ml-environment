import sys
print("  ".join(f'"{s}"' for s in sys.argv[1].split("\n")))