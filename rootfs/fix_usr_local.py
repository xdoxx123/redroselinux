from pathlib import Path
import os
import shutil

UsrPath = Path(__file__).parent.resolve() / "filesystem" / "usr"

def merge_dirs(src: Path, dst: Path):
    for item in src.iterdir():
        target = dst / item.name

        if item.is_dir():
            target.mkdir(parents=True, exist_ok=True)
            merge_dirs(item, target)
        else:
            if target.exists():
                print(f"Replacing {target}")
                target.unlink()

            print(f"Merging {item} -> {target}")
            shutil.move(str(item), str(target))

def check_and_fix():
    local = UsrPath / "local"

    if local.exists():
        print("Found /usr/local, fixing")
        merge_dirs(local, UsrPath)
        shutil.rmtree(local)
        print("Done")
