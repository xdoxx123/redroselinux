with open("src/installer/installer.h", "r+") as f:
    lines = [l if not l.startswith("#define DEBUG") else "#define DEBUG 1\n" for l in f]
    f.seek(0)
    f.writelines(lines)
    f.truncate()
