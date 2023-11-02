# Tool for turning obj files into something Teardown likes.

import argparse

parser = argparse.ArgumentParser()

parser.add_argument('filepath')

args = parser.parse_args()


clean_name = args.filepath.replace(".obj","")
print(clean_name)

with open(args.filepath, 'r') as input:
    with open(args.filepath.replace(".obj","") + ".lua", 'w') as output:
        output.write(clean_name + " = {\n")

        for line in input.readlines():
            output.write("    \"")
            output.write(line.rstrip("\n"))
            output.write("\",\n")

        output.write("}")
