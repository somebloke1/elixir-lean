/*
 * beam-init.c - Minimal init for MicroBEAM
 * 
 * This program runs as PID 1 and:
 * 1. Mounts essential filesystems
 * 2. Sets up minimal environment
 * 3. Execs BEAM to replace itself
 */

#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/mount.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <errno.h>
#include <string.h>

#define BEAM_PATH "/usr/lib/erlang/erts-14.0/bin/beam.smp"
#define APP_PATH "/app/bin/microbeam"

static void mount_fs(const char *source, const char *target, 
                     const char *fstype, unsigned long flags) {
    mkdir(target, 0755);
    if (mount(source, target, fstype, flags, NULL) != 0) {
        // Ignore errors - may already be mounted
    }
}

static void setup_env(void) {
    putenv("HOME=/");
    putenv("PATH=/usr/bin:/bin:/usr/sbin:/sbin");
    putenv("TERM=linux");
    putenv("LANG=en_US.UTF-8");
    putenv("ERL_CRASH_DUMP=/dev/null");
    putenv("RELEASE_NODE=microbeam");
    putenv("RELEASE_COOKIE=microbeam-secret-cookie");
}

int main(int argc, char *argv[]) {
    // Mount essential filesystems
    mount_fs("proc", "/proc", "proc", MS_NODEV | MS_NOSUID | MS_NOEXEC);
    mount_fs("sysfs", "/sys", "sysfs", MS_NODEV | MS_NOSUID | MS_NOEXEC);
    mount_fs("devtmpfs", "/dev", "devtmpfs", MS_NOSUID);
    mount_fs("devpts", "/dev/pts", "devpts", MS_NOSUID | MS_NOEXEC);
    mount_fs("tmpfs", "/run", "tmpfs", MS_NODEV | MS_NOSUID);
    mount_fs("tmpfs", "/tmp", "tmpfs", MS_NODEV | MS_NOSUID);

    // Create essential device nodes if devtmpfs failed
    mknod("/dev/null", S_IFCHR | 0666, makedev(1, 3));
    mknod("/dev/zero", S_IFCHR | 0666, makedev(1, 5));
    mknod("/dev/random", S_IFCHR | 0666, makedev(1, 8));
    mknod("/dev/urandom", S_IFCHR | 0666, makedev(1, 9));
    mknod("/dev/console", S_IFCHR | 0600, makedev(5, 1));

    // Setup environment
    setup_env();

    // Direct exec to BEAM - check if release script exists
    if (access(APP_PATH, X_OK) == 0) {
        // Use the release start script
        char *args[] = { APP_PATH, "foreground", NULL };
        execv(APP_PATH, args);
    } else if (access(BEAM_PATH, X_OK) == 0) {
        // Fallback to direct BEAM execution
        char *args[] = { 
            BEAM_PATH,
            "-root", "/usr/lib/erlang",
            "-progname", "erl",
            "-noshell",
            "-noinput", 
            "-eval", "application:ensure_all_started(microbeam)",
            NULL 
        };
        execv(BEAM_PATH, args);
    }

    // If we get here, exec failed
    printf("Failed to start BEAM: %s\n", strerror(errno));
    
    // Emergency shell fallback
    if (access("/bin/sh", X_OK) == 0) {
        char *sh_args[] = { "/bin/sh", NULL };
        execv("/bin/sh", sh_args);
    }

    // Nothing worked, halt
    while (1) {
        sleep(3600);
    }
    
    return 0;
}