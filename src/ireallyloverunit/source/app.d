import std.stdio;
import std.file;
import std.format : format;
import core.stdc.stdlib : exit;
import std.algorithm : endsWith;

import systemctl : systemctl_main;
import has_sysd_service;

void main(string[] args)
{
    auto argc = args.length;

    /*
        Our sv wrapper named systemctl for dummies using AI to get help (sorry); uses the same approach as busybox
        If called from a symlink, e. g. /usr/bin/systemctl -> ireallylove runit, start the main() from systemctl.d
    */
    if (args[0].endsWith("systemctl"))
    {
        systemctl_main(args);
        exit(0);
    }

    if (argc == 1)
    {
        writeln("ireallyloverunit: an argument is required");
        writeln("hint: use -h to show a help message");
    }
    else
    {
        if (args[1] == "-h" || args[1] == "--help")
        {
            writeln("ireallyloverunit: a tool for systemd users to get used to runit");
            writeln();
            writeln("commands:");
            writeln("   install-systemctl       install the sv wrapper called systemctl");
            writeln("   systemctl               use the sv wrapper without installing");
            writeln("   check-systemd-service   check if a systemd service is present");
        }
        else if (args[1] == "install-systemctl")
        {
            string path = "/usr/bin";
            if (argc > 2)
            {
                // there is something after install-systemctl
                if (args[2] == "--path")
                {
                    if (argc != 4)
                    {
                        writeln("you must include a path");
                        exit(2);
                    }

                    path = args[3];
                }
            }
            writefln("installing systemctl to %s/systemctl...", path);
            try
            {
                symlink(thisExePath(), format("%s/systemctl", path));
            }
            catch (FileException e)
            {
                writefln("error: failed writing to %s/systemctl.", path);
                writeln(
                    "hint: if testing on a systemd distro, use '--path .' or any other path you like.");
                writeln("hint: maybe you have insufficient permissions?");
                writeln(
                    "hint: you can use systemctl without installing: ireallyloverunit systemctl to start");
                exit(1);
            }
            writeln("installed sucesfully");
        }
        else if (args[1] == "systemctl")
        {
            systemctl_main(args[1 .. $]);
        }
        else if (args[1] == "check-systemd-service")
        {
            has_systemd_service();
        }
        else
        {
            writefln("unknown arg: %s", args[1]);
            exit(2);
        }
    }
}
