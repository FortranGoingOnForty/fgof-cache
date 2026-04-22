#include <dirent.h>
#include <errno.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <time.h>
#include <unistd.h>

static int prune_directory(const char *path, int remove_self, long long cutoff_seconds,
                           long long *scanned_count, long long *removed_count, int *error_code);
static char *join_child_path(const char *parent, const char *name);

int fgof_cache_path_exists(const char *path) {
    struct stat st;

    if (path == NULL || path[0] == '\0') {
        return 0;
    }

    return stat(path, &st) == 0 ? 1 : 0;
}

int fgof_cache_remove_file(const char *path, int *error_code) {
    if (error_code != NULL) {
        *error_code = 0;
    }

    if (path == NULL || path[0] == '\0') {
        if (error_code != NULL) {
            *error_code = EINVAL;
        }
        return 0;
    }

    if (remove(path) != 0) {
        if (error_code != NULL) {
            *error_code = errno;
        }
        return 0;
    }

    return 1;
}

int fgof_cache_stat_path(const char *path, int *regular_file,
                         long long *size_bytes, long long *modified_time_seconds, int *error_code) {
    struct stat st;

    if (error_code != NULL) {
        *error_code = 0;
    }
    if (regular_file != NULL) {
        *regular_file = 0;
    }
    if (size_bytes != NULL) {
        *size_bytes = 0;
    }
    if (modified_time_seconds != NULL) {
        *modified_time_seconds = 0;
    }

    if (path == NULL || path[0] == '\0') {
        if (error_code != NULL) {
            *error_code = EINVAL;
        }
        return 0;
    }

    if (stat(path, &st) != 0) {
        if (error_code != NULL) {
            *error_code = errno;
        }
        return 0;
    }

    if (size_bytes != NULL) {
        *size_bytes = (long long)st.st_size;
    }
    if (modified_time_seconds != NULL) {
        *modified_time_seconds = (long long)st.st_mtime;
    }
    if (regular_file != NULL) {
        *regular_file = S_ISREG(st.st_mode) ? 1 : 0;
    }

    return 1;
}

int fgof_cache_directory_exists(const char *path) {
    struct stat st;

    if (path == NULL || path[0] == '\0') {
        return 0;
    }

    if (stat(path, &st) != 0) {
        return 0;
    }

    return S_ISDIR(st.st_mode) ? 1 : 0;
}

int fgof_cache_ensure_directory(const char *path, int *error_code) {
    char *buffer;
    char *cursor;
    size_t length;
    struct stat st;

    if (error_code != NULL) {
        *error_code = 0;
    }

    if (path == NULL || path[0] == '\0') {
        if (error_code != NULL) {
            *error_code = EINVAL;
        }
        return 0;
    }

    if (stat(path, &st) == 0) {
        if (S_ISDIR(st.st_mode)) {
            return 1;
        }
        if (error_code != NULL) {
            *error_code = ENOTDIR;
        }
        return 0;
    }

    buffer = strdup(path);
    if (buffer == NULL) {
        if (error_code != NULL) {
            *error_code = ENOMEM;
        }
        return 0;
    }

    length = strlen(buffer);
    while (length > 1 && buffer[length - 1] == '/') {
        buffer[length - 1] = '\0';
        --length;
    }

    for (cursor = buffer + 1; *cursor != '\0'; ++cursor) {
        if (*cursor != '/') {
            continue;
        }

        *cursor = '\0';
        if (buffer[0] != '\0' && mkdir(buffer, 0700) != 0 && errno != EEXIST) {
            if (error_code != NULL) {
                *error_code = errno;
            }
            free(buffer);
            return 0;
        }
        *cursor = '/';
    }

    if (mkdir(buffer, 0700) != 0 && errno != EEXIST) {
        if (error_code != NULL) {
            *error_code = errno;
        }
        free(buffer);
        return 0;
    }

    if (stat(buffer, &st) != 0 || !S_ISDIR(st.st_mode)) {
        if (error_code != NULL) {
            *error_code = errno != 0 ? errno : ENOTDIR;
        }
        free(buffer);
        return 0;
    }

    free(buffer);
    return 1;
}

long long fgof_cache_now_seconds(void) {
    return (long long)time(NULL);
}

int fgof_cache_prune_stale(const char *path, long long cutoff_seconds,
                           long long *scanned_count, long long *removed_count, int *error_code) {
    struct stat st;

    if (error_code != NULL) {
        *error_code = 0;
    }
    if (scanned_count != NULL) {
        *scanned_count = 0;
    }
    if (removed_count != NULL) {
        *removed_count = 0;
    }

    if (path == NULL || path[0] == '\0') {
        if (error_code != NULL) {
            *error_code = EINVAL;
        }
        return 0;
    }

    if (stat(path, &st) != 0) {
        if (error_code != NULL) {
            *error_code = errno;
        }
        return 0;
    }
    if (!S_ISDIR(st.st_mode)) {
        if (error_code != NULL) {
            *error_code = ENOTDIR;
        }
        return 0;
    }

    return prune_directory(path, 0, cutoff_seconds, scanned_count, removed_count, error_code);
}

static int prune_directory(const char *path, int remove_self, long long cutoff_seconds,
                           long long *scanned_count, long long *removed_count, int *error_code) {
    DIR *dir;
    struct dirent *entry;
    int close_error;

    dir = opendir(path);
    if (dir == NULL) {
        if (error_code != NULL) {
            *error_code = errno;
        }
        return 0;
    }

    while ((entry = readdir(dir)) != NULL) {
        char *child_path;
        struct stat st;

        if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0) {
            continue;
        }

        child_path = join_child_path(path, entry->d_name);
        if (child_path == NULL) {
            if (error_code != NULL) {
                *error_code = ENOMEM;
            }
            closedir(dir);
            return 0;
        }

        if (lstat(child_path, &st) != 0) {
            if (error_code != NULL) {
                *error_code = errno;
            }
            free(child_path);
            closedir(dir);
            return 0;
        }

        if (S_ISDIR(st.st_mode)) {
            if (!prune_directory(child_path, 1, cutoff_seconds, scanned_count, removed_count, error_code)) {
                free(child_path);
                closedir(dir);
                return 0;
            }
        } else if (S_ISREG(st.st_mode)) {
            if (scanned_count != NULL) {
                *scanned_count += 1;
            }
            if ((long long)st.st_mtime <= cutoff_seconds) {
                if (unlink(child_path) != 0) {
                    if (error_code != NULL) {
                        *error_code = errno;
                    }
                    free(child_path);
                    closedir(dir);
                    return 0;
                }
                if (removed_count != NULL) {
                    *removed_count += 1;
                }
            }
        }

        free(child_path);
    }

    close_error = closedir(dir);
    if (close_error != 0) {
        if (error_code != NULL) {
            *error_code = errno;
        }
        return 0;
    }

    if (remove_self) {
        if (rmdir(path) != 0) {
            if (errno != ENOTEMPTY && errno != EEXIST) {
                if (error_code != NULL) {
                    *error_code = errno;
                }
                return 0;
            }
        }
    }

    return 1;
}

static char *join_child_path(const char *parent, const char *name) {
    size_t parent_length;
    size_t name_length;
    char *path;

    parent_length = strlen(parent);
    name_length = strlen(name);
    path = (char *)malloc(parent_length + 1 + name_length + 1);
    if (path == NULL) {
        return NULL;
    }

    memcpy(path, parent, parent_length);
    path[parent_length] = '/';
    memcpy(path + parent_length + 1, name, name_length);
    path[parent_length + 1 + name_length] = '\0';
    return path;
}
