import std.stdio;
import std.file;
import std.format : format;

/*
    Function that checks if the current system we are on has a systemd service present.
    This is useful for checking if packages are broken.
*/
void has_systemd_service()
{
    foreach (dir; ["/etc", "/usr/lib"])
    {
        foreach (name; dirEntries(dir, SpanMode.shallow))
        {
            if (name.name == format("%s/systemd", dir))
            {
                writefln("found a systemd config dir: %s/systemd", dir);
            }
        }
    }
}
