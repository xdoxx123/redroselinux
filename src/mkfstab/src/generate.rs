use std::collections::HashMap;
use std::fs;

pub fn generate_fstab(output: &str, root: &str, pseudo: bool) {
    let proc_mounts: Vec<String> = fs::read_to_string(format!("{}/proc/mounts", root))
        .expect("failed to read /proc/mounts")
        .lines()
        .map(|l| l.to_string())
        .collect();

    let uuid_map = build_uuid_map(root);

    let mut rows: Vec<Vec<String>> = Vec::new();
    let mut widths = vec![0; 6];

    for line in proc_mounts {
        let mut fields: Vec<String> = line.split_whitespace().map(|s| s.to_string()).collect();
        if fields.len() < 6 {
            continue;
        }

        if !pseudo {
            let pseudo_fs = [
                "tmpfs", "devtmpfs", "proc", "sysfs", "debugfs",
                "mqueue", "fusectl", "securityfs", "configfs",
                "hugetlbfs", "devpts", "cgroup2", "efivarfs",
                "bpf", "systemd-1", "tracefs", "binfmt_misc",
                "portal", "gvfsd-fuse", "none", "autofs", "overlay",
            ];
            if pseudo_fs.contains(&fields[0].as_str()) || pseudo_fs.contains(&fields[2].as_str()) {
                continue;
            }
        }

        if let Some(uuid) = uuid_map.get(&fields[0]) {
            fields[0] = format!("UUID={}", uuid);
        }

        if fields[1] == "/" {
            fields[4] = "0".to_string();
            fields[5] = "2".to_string();
        }

        for i in 0..6 {
            widths[i] = widths[i].max(fields[i].len());
        }
        rows.push(fields);
    }

    let mut fstab = String::from("# /etc/fstab: static file system information.\n");
    fstab.push_str("#\n");
    fstab.push_str("# Use 'blkid' to print the universally unique identifier for a\n");
    fstab.push_str("# device; this may be used with UUID= as a more robust way to name\n");
    fstab.push_str("# devices that works even if disks are added and removed. See fstab(5).\n");
    fstab.push_str("#\n");
    fstab.push_str("# <file system> <mount point>   <type>  <opts>  <dump>  <pass>\n");

    for row in &rows {
        println!(
            "\x1b[1mfound\x1b[0m: \x1b[2;3mfs\x1b[0m {:<w0$}  \x1b[2;3mmntpnt\x1b[0m {:<w1$}  \x1b[2;3mtype\x1b[0m {:<w2$}  \x1b[2;3mopts\x1b[0m {:<w3$}  \x1b[2;3mdump\x1b[0m {:<w4$}  \x1b[2;3mpass\x1b[0m {:<w5$}",
            row[0], row[1], row[2], row[3], row[4], row[5],
            w0 = widths[0], w1 = widths[1], w2 = widths[2],
            w3 = widths[3], w4 = widths[4], w5 = widths[5]
        );

        fstab.push_str(&format!(
            "{:<w0$} {:<w1$} {:<w2$} {:<w3$} {:<w4$} {:<w5$}\n",
            row[0], row[1], row[2], row[3], row[4], row[5],
            w0 = widths[0], w1 = widths[1], w2 = widths[2],
            w3 = widths[3], w4 = widths[4], w5 = widths[5]
        ));
    }

    fs::write(output, fstab).expect("failed to write fstab");
}

fn build_uuid_map(root: &str) -> HashMap<String, String> {
    let mut map = HashMap::new();
    let by_uuid_dir = format!("{}/dev/disk/by-uuid", root);

    let dir = match fs::read_dir(&by_uuid_dir) {
        Ok(d) => d,
        Err(_) => return map,
    };

    for entry in dir.flatten() {
        let path = entry.path();
        let uuid = match path.file_name().and_then(|n| n.to_str()) {
            Some(u) => u.to_string(),
            None => continue,
        };
        let target = match fs::read_link(&path) {
            Ok(t) => t,
            Err(_) => continue,
        };
        let parent = match path.parent() {
            Some(p) => p.to_path_buf(),
            None => continue,
        };
        let full = parent.join(target);
        if let Ok(canonical) = fs::canonicalize(&full) {
            map.insert(canonical.to_string_lossy().to_string(), uuid);
        }
    }

    map
}
