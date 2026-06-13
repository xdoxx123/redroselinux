use std::env;
use std::fs;
use std::io::Write;
use std::process::exit;
mod generate;

fn usage(short: bool) {
    if !short {
        println!("Usage: mkfstab [OPTIONS] root(default:/) {{mkfstab /}}");
        println!("");
        println!("Options:");
        println!("  -h, --help     Print this help message");
        println!("  -o, --output   Output file path (default: /etc/fstab)");
        println!("  -P, --pseudo   Include pseudo filesystems (false if not passed)");
        println!("  --yes          Automatically say yes to every prompt");
        println!("  --no           Automatically say no to every prompt");
        println!("");
        println!("mkfstab is a utility for generating the fstab(5) file, inspired by genfstab from Arch Linux's 'arch-install-scripts'.");
    } else {
        println!("Usage: mkfstab [OPTIONS] root(default:/) {{mkfstab /}}");
        println!("Use the -h or --help option for more information.");
    }
}

fn main() {
    let argv: Vec<String> = env::args().collect();
    let argc = argv.len();

    if argc < 2 {
        usage(true);
        return;
    }

    let mut yes = false;
    let mut no = false;
    let mut pseudo = false;
    let mut root = "/";
    let mut output = "/etc/fstab";

    let mut i = 1;
    while i < argc {
        match argv[i].as_str() {
            "-h" | "--help" => {
                usage(false);
                return;
            }
            "--yes" => yes = true,
            "--no" => no = true,
            "-P" | "--pseudo" => pseudo = true,
            "-o" | "--output" => {
                if i + 1 < argc {
                    output = argv[i + 1].as_str();
                    i += 1;
                }
            }
            _ => {
                if argv[i].starts_with('-') {
                    eprintln!("error: unknown option '{}'", argv[i]);
                    exit(1);
                }
                root = argv[i].as_str();
            }
        }
        i += 1;
    }

    match fs::metadata(output) {
        Ok(_) => {
            print!("\x1b[91moutput file {} already exists!\x1b[0m", output);

            let should_overwrite = if yes {
                println!("\x1b[2m proceeding automatically (--yes).\x1b[0m");
                true
            } else if no {
                println!("\x1b[2m aborting automatically (--no).\x1b[0m");
                exit(1);
            } else {
                print!(" do you want to overwrite it? [y/N] ");
                std::io::stdout().flush().unwrap();

                let mut input = String::new();
                std::io::stdin().read_line(&mut input).unwrap();
                input.trim().to_lowercase() == "y"
            };

            if !should_overwrite {
                exit(0);
            }
        }
        Err(_) => {}
    }

    generate::generate_fstab(output, root, pseudo);
}
